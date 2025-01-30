;; Digital Identity Management Contract

(define-map identities
  { identity-id: uint }
  {
    owner: principal,
    metadata: (string-utf8 1024),
    created-at: uint,
    updated-at: uint,
    active: bool
  }
)

(define-map identity-by-owner
  { owner: principal }
  { identity-id: uint }
)

(define-data-var identity-id-nonce uint u0)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))

(define-read-only (get-identity (identity-id uint))
  (map-get? identities { identity-id: identity-id })
)

(define-read-only (get-identity-by-owner (owner principal))
  (map-get? identity-by-owner { owner: owner })
)

(define-public (create-identity (metadata (string-utf8 1024)))
  (let
    ((new-identity-id (+ (var-get identity-id-nonce) u1)))
    (asserts! (is-none (get-identity-by-owner tx-sender)) ERR_ALREADY_EXISTS)
    (map-set identities
      { identity-id: new-identity-id }
      {
        owner: tx-sender,
        metadata: metadata,
        created-at: block-height,
        updated-at: block-height,
        active: true
      }
    )
    (map-set identity-by-owner
      { owner: tx-sender }
      { identity-id: new-identity-id }
    )
    (var-set identity-id-nonce new-identity-id)
    (ok new-identity-id)
  )
)

(define-public (update-identity (identity-id uint) (new-metadata (string-utf8 1024)))
  (let
    ((identity (unwrap! (map-get? identities { identity-id: identity-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq (get owner identity) tx-sender) ERR_UNAUTHORIZED)
    (ok (map-set identities
      { identity-id: identity-id }
      (merge identity
        {
          metadata: new-metadata,
          updated-at: block-height
        }
      )
    ))
  )
)

(define-public (deactivate-identity (identity-id uint))
  (let
    ((identity (unwrap! (map-get? identities { identity-id: identity-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq (get owner identity) tx-sender) ERR_UNAUTHORIZED)
    (ok (map-set identities
      { identity-id: identity-id }
      (merge identity
        {
          active: false,
          updated-at: block-height
        }
      )
    ))
  )
)

(define-public (reactivate-identity (identity-id uint))
  (let
    ((identity (unwrap! (map-get? identities { identity-id: identity-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq (get owner identity) tx-sender) ERR_UNAUTHORIZED)
    (ok (map-set identities
      { identity-id: identity-id }
      (merge identity
        {
          active: true,
          updated-at: block-height
        }
      )
    ))
  )
)

