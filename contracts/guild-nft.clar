;; sip009-nft
;; A SIP009-compliant NFT with a mint function.
(impl-trait .sip009-trait.sip009-trait)

;; Role errors
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-TOKEN-OWNER (err u101))
;; Lending errors
(define-constant ERR-TOKEN-ALREADY-LENT (err u201))
(define-constant MINT-FEE u00001000)

;; Withdraw wallets
(define-constant WALLET_1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

(define-non-fungible-token Guild-Genesis uint)

(define-data-var last-token-id uint u0)

;; Variable to control who is the user for a specific NFT
(define-map users uint (optional principal))
;; Variable to control if an NFT is current lent based on the block height
(define-map expires uint uint)

(define-read-only (get-last-token-id)
	(ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
	(ok none)
)

(define-read-only (get-owner (token-id uint))
	(ok (nft-get-owner? Guild-Genesis token-id))
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
	(begin
		(asserts! (is-eq tx-sender sender) ERR-NOT-TOKEN-OWNER)
		(nft-transfer? Guild-Genesis token-id sender recipient)
	)
)

(define-public (mint (recipient principal))
	(let
		(
			(token-id (+ (var-get last-token-id) u1))
		)
		(asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
		(try! (stx-transfer? MINT-FEE tx-sender WALLET_1))
		(try! (nft-mint? Guild-Genesis token-id recipient))
		(var-set last-token-id token-id)
		(map-set users token-id none)
		(map-set expires token-id u0)
		(ok token-id)
	)
)

;; User of a given token identifier
(define-read-only (get-user (token-id uint))
	(ok (map-get? users token-id))
)

;; Retrieve expiration block of a given token identifier
;; Zero indicates that there is no user
(define-read-only (get-expires (token-id uint))	
	(default-to u0 (map-get? expires token-id))
)

;;Set a User of a given token identifier
(define-public (set-user (token-id uint) (borrower principal) (newExpires uint))	
	(begin 		
		(asserts! (< (get-expires token-id) block-height) ERR-TOKEN-ALREADY-LENT)
		(map-set expires token-id newExpires)
		(ok (map-set users token-id (some borrower)))
	)	
)
;;Validate the caller is the owner
(define-private (is-sender-owner (token-id uint))
  	(let ((owner (unwrap! (nft-get-owner? Guild-Genesis token-id) false)))
    	(is-eq tx-sender owner)
	)
)

