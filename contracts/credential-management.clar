;; Credential Management Contract

(define-map credentials
  { credential-id: uint }
  {
    issuer: principal,
    holder: principal,
    credential-type: (string-ascii 64),
    metadata: (string-utf8 1024),
    issued-at: uint,
    expires-at: (optional uint),
    revoked: bool
  }
)

(define-map holder-credentials
  { holder: principal }
  { credential-ids: (list 100 uint) }
)

(define-data-var credential-id-nonce uint u0)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_EXPIRED (err u410))
(define-constant ERR_REVOKED (err u411))

(define-read-only (get-credential (credential-id uint))
  (map-get? credentials { credential-id: credential-id })
)

(define-read-only (get-holder-credentials (holder principal))
  (map-get? holder-credentials { holder: holder })
)

(define-public (issue-credential (holder principal) (credential-type (string-ascii 64)) (metadata (string-utf8 1024)) (expires-at (optional uint)))
  (let
    ((new-credential-id (+ (var-get credential-id-nonce) u1))
     (holder-cred-list (default-to { credential-ids: (list) } (map-get? holder-credentials { holder: holder }))))
    (map-set credentials
      { credential-id: new-credential-id }
      {
        issuer: tx-sender,
        holder: holder,
        credential-type: credential-type,
        metadata: metadata,
        issued-at: block-height,
        expires-at: expires-at,
        revoked: false
      }
    )
    (map-set holder-credentials
      { holder: holder }
      { credential-ids: (unwrap! (as-max-len? (append (get credential-ids holder-cred-list) new-credential-id) u100) ERR_UNAUTHORIZED) }
    )
    (var-set credential-id-nonce new-credential-id)
    (ok new-credential-id)
  )
)

(define-public (revoke-credential (credential-id uint))
  (let
    ((credential (unwrap! (map-get? credentials { credential-id: credential-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq (get issuer credential) tx-sender) ERR_UNAUTHORIZED)
    (ok (map-set credentials
      { credential-id: credential-id }
      (merge credential { revoked: true })
    ))
  )
)

(define-public (update-credential-metadata (credential-id uint) (new-metadata (string-utf8 1024)))
  (let
    ((credential (unwrap! (map-get? credentials { credential-id: credential-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq (get issuer credential) tx-sender) ERR_UNAUTHORIZED)
    (ok (map-set credentials
      { credential-id: credential-id }
      (merge credential { metadata: new-metadata })
    ))
  )
)

(define-read-only (verify-credential (credential-id uint))
  (let
    ((credential (unwrap! (map-get? credentials { credential-id: credential-id }) ERR_NOT_FOUND)))
    (asserts! (not (get revoked credential)) ERR_REVOKED)
    (match (get expires-at credential)
      expiry (asserts! (> expiry block-height) ERR_EXPIRED)
      true
    )
    (ok true)
  )
)

