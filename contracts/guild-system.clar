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
(define-constant ERR-UINTENDED-TAKER (err u2006))
(define-constant ERR-ASSET-CONTRACT-NOT-WHITELISTED (err u2007))
(define-constant ERR-PAYMENY-CONTRACT-NOT-WHITELISTED (err u2008))

(define-map whitelisted-asset-contracts principal bool)

