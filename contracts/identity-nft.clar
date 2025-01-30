;; Identity NFT Contract

(define-non-fungible-token identity-nft uint)

(define-map identity-nft-data
  { token-id: uint }
  {
    identity-id: uint,
    owner: principal,
    metadata: (string-utf8 256)
  }
)

(define-data-var token-id-nonce uint u0)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))

(define-read-only (get-last-token-id)
  (ok (var-get token-id-nonce))
)

(define-read-only (get-token-uri (token-id uint))
  (ok none)
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? identity-nft token-id))
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR_UNAUTHORIZED)
    (nft-transfer? identity-nft token-id sender recipient)
  )
)

(define-public (mint-identity-nft (identity-id uint) (metadata (string-utf8 256)))
  (let
    ((new-token-id (+ (var-get token-id-nonce) u1)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (nft-get-owner? identity-nft new-token-id)) ERR_ALREADY_EXISTS)
    (try! (nft-mint? identity-nft new-token-id tx-sender))
    (map-set identity-nft-data
      { token-id: new-token-id }
      {
        identity-id: identity-id,
        owner: tx-sender,
        metadata: metadata
      }
    )
    (var-set token-id-nonce new-token-id)
    (ok new-token-id)
  )
)

(define-read-only (get-identity-nft-data (token-id uint))
  (map-get? identity-nft-data { token-id: token-id })
)

