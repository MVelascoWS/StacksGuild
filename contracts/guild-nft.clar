;; sip009-nft
;; A SIP009-compliant NFT with a mint function.
(impl-trait .sip009-trait.sip009-trait)

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-TOKEN-OWNER (err u101))

(define-constant ERR-TOKEN-ALREADY-LENDED (err u201))
;; Withdraw wallets
(define-constant WALLET_1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

(define-non-fungible-token Guild-Genesis uint)

(define-data-var last-token-id uint u0)

(define-map users uint (optional principal))
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

;; Set a User of a given token identifier
(define-public (set-user (token-id uint) (borrower principal) (newExpires uint))
	(begin 
		(asserts! (< (get-expires token-id) block-height) ERR-TOKEN-ALREADY-LENDED)
		(map-set expires token-id newExpires)
		(ok (map-set users token-id (some borrower)))
	)
)

