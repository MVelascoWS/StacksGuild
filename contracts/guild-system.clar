(use-trait nft-trait .sip009-trait.sip009-trait)

(define-constant CONTRACT-OWNER tx-sender)
;; listing errors
(define-constant ERR-EXPIRY-IN-PAST (err u1000))
(define-constant ERR-PRICE-ZERO (err u1001))
;; cancelling and fulfilling errors
(define-constant ERR-UNKNOWN-LISTING (err u2000))
(define-constant ERR-UNAUTHORISED (err u2001))
(define-constant ERR-LISTING-EXPIRED (err u2002))
(define-constant ERR-NFT-ASSET-MISMATCH (err u2003))
(define-constant ERR-PAYMENY-ASSET-MISMATCH (err u2004))
(define-constant ERR-MAKER-TAKER-EQUAL (err u2005))
(define-constant ERR-UINTENDED-BORROWER (err u2006))
(define-constant ERR-ASSET-CONTRACT-NOT-WHITELISTED (err u2007))
(define-constant ERR-PAYMENT-CONTRACT-NOT-WHITELISTED (err u2008))
(define-constant ERR-LEND-DURATION-ZERO (err u2009))
(define-constant ERR-ALREADY-LENT (err u2010))

;; Listing data for lending
(define-map listings
	uint
	{
		lender: principal,
		borrower: (optional principal),
		token-id: uint,
		nft-asset-contract: principal,
		expiry: uint,
		price-per-block: uint
	}
)

(define-data-var listing-nonce uint u0)

(define-map whitelisted-asset-contracts principal bool)

;;Check if the NFT contract is whitelisted
(define-read-only (is-whitelisted (asset-contract principal))
	(default-to false (map-get? whitelisted-asset-contracts asset-contract))
)
;;Whitelist a NFT contract
(define-public (set-whitelisted (asset-contract principal) (whitelisted bool))
	(begin
		(asserts! (is-eq CONTRACT-OWNER tx-sender) ERR-UNAUTHORISED)
		(ok (map-set whitelisted-asset-contracts asset-contract whitelisted))
	)
)

;;List a NFT for lending in a non-custodial way
(define-public (list-asset (nft-asset-contract <nft-trait>) (nft-asset {borrower: (optional principal), token-id: uint, expiry: uint, price-per-block: uint}))
	(let ((listing-id (var-get listing-nonce)))
        ;;Validates if the NFT contract is whitelisted
		(asserts! (is-whitelisted (contract-of nft-asset-contract)) ERR-ASSET-CONTRACT-NOT-WHITELISTED)
        ;;Validates if the listing doesn't expires
		(asserts! (> (get expiry nft-asset) block-height) ERR-EXPIRY-IN-PAST)
        ;;Validates if the lend price is no zero
		(asserts! (> (get price-per-block nft-asset) u0) ERR-PRICE-ZERO)
        ;;Validates if the NFT is currently lended comparing its expires
        (asserts! (> (contract-call? .guild-nft get-expires (get token-id nft-asset)) block-height) ERR-ALREADY-LENT)
        ;;List the NFT with all the settings
		(map-set listings listing-id (merge {lender: tx-sender, nft-asset-contract: (contract-of nft-asset-contract)} nft-asset))
		(var-set listing-nonce (+ listing-id u1))
		(ok listing-id)
	)
)

(define-read-only (get-listing (listing-id uint))
	(map-get? listings listing-id)
)

;;Delist a NFT for lending
(define-public (cancel-listing (listing-id uint) (nft-asset-contract <nft-trait>))
	(let 
        (
		    (listing (unwrap! (map-get? listings listing-id) ERR-UNKNOWN-LISTING))
		    (lender (get lender listing))
		)
        ;;Only de lender can delist the NFT
		(asserts! (is-eq lender tx-sender) ERR-UNAUTHORISED)
        ;;Validates the NFT contract listed
		(asserts! (is-eq (get nft-asset-contract listing) (contract-of nft-asset-contract)) ERR-NFT-ASSET-MISMATCH)
		(map-delete listings listing-id)
		(ok listing-id)
	)
)

(define-private (assert-can-fulfil (nft-asset-contract principal) (payment-asset-contract (optional principal)) (listing {lender: principal, borrower: (optional principal), token-id: uint, nft-asset-contract: principal, expiry: uint, price-per-block: uint}))
	(begin
        ;;Validates that the lender is different than the borrower
		(asserts! (not (is-eq (get lender listing) tx-sender)) ERR-MAKER-TAKER-EQUAL)
		(asserts! (match (get borrower listing) intended-borrower (is-eq intended-borrower tx-sender) true) ERR-UINTENDED-BORROWER)
		(asserts! (< block-height (get expiry listing)) ERR-LISTING-EXPIRED)
        ;;Validates if the NFT lending already expires base on the block height
        (asserts! (> (contract-call? .guild-nft get-expires (get token-id listing)) block-height) ERR-ALREADY-LENT)
		(asserts! (is-eq (get nft-asset-contract listing) nft-asset-contract) ERR-NFT-ASSET-MISMATCH)
		(ok true)
	)
)

;;Validates the NFT lend duration is greater than zero
(define-private (assert-duration-zero (duration uint)) 
    (begin
        (asserts!  (> duration u0) ERR-LEND-DURATION-ZERO)
        (ok true)
    )
)

;;Fullfill the listing NFT
(define-public (fulfil-listing-stx (listing-id uint) (nft-asset-contract <nft-trait>) (duration uint))
	(let
        (
            (listing (unwrap! (map-get? listings listing-id) ERR-UNKNOWN-LISTING))
            (borrower tx-sender)
		)
        ;;Validates the lend duration is greater than zero
        (try! (assert-duration-zero duration))        
		(try! (assert-can-fulfil (contract-of nft-asset-contract) none listing))		
        ;;Set the borrower as the NFTs user role and the duration base on the sum of the current block plus the intended duration
        (try! (contract-call? .guild-nft set-user listing-id borrower (+ block-height duration)))
        ;;The cost is calculated based on the price per block and the number of blocks that the loan will last.
		(try! (stx-transfer? (* duration (get price-per-block listing)) borrower (get lender listing)))
        ;;The listing is dispatched
		(map-delete listings listing-id)
		(ok listing-id)
	)
)
