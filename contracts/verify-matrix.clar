;; Verix - Decentralized Identity System
;; A system for managing verified digital identities on Stacks blockchain

(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-EXPIRED (err u410))
(define-constant ERR-INVALID-INPUT (err u400))

;; Data Maps
(define-map identities 
    principal 
    { name: (string-utf8 50),
      bio: (string-utf8 280),
      avatar: (optional (string-utf8 256)),
      social-links: (list 5 (string-utf8 100)),
      created-at: uint,
      updated-at: uint,
      verification-level: uint })

(define-map verifications
    { user: principal, verifier: principal }
    { status: bool,
      timestamp: uint,
      expiration: uint,
      proof: (string-utf8 500) })

;; Public Functions
(define-public (create-identity (name (string-utf8 50)) 
                              (bio (string-utf8 280))
                              (avatar (optional (string-utf8 256))))
    (let ((existing-identity (get-identity tx-sender)))
        (if (is-some existing-identity)
            ERR-UNAUTHORIZED
            (begin
                (map-set identities tx-sender
                    { name: name,
                      bio: bio,
                      avatar: avatar,
                      social-links: (list),
                      created-at: block-height,
                      updated-at: block-height,
                      verification-level: u0 })
                (ok true)))))

(define-public (update-identity (name (string-utf8 50))
                              (bio (string-utf8 280))
                              (avatar (optional (string-utf8 256))))
    (let ((existing-identity (get-identity tx-sender)))
        (match existing-identity
            identity (begin
                (map-set identities tx-sender
                    (merge identity
                        { name: name,
                          bio: bio,
                          avatar: avatar,
                          updated-at: block-height }))
                (ok true))
            ERR-NOT-FOUND)))

(define-public (add-social-link (link (string-utf8 100)))
    (let ((existing-identity (get-identity tx-sender)))
        (match existing-identity
            identity (begin
                (map-set identities tx-sender
                    (merge identity
                        { social-links: (append (get social-links identity) link),
                          updated-at: block-height }))
                (ok true))
            ERR-NOT-FOUND)))

(define-public (verify-identity (user principal) 
                              (proof (string-utf8 500))
                              (expiration uint))
    (begin
        (map-set verifications
            { user: user, verifier: tx-sender }
            { status: true,
              timestamp: block-height,
              expiration: (+ block-height expiration),
              proof: proof })
        (ok true)))

;; Read-only Functions
(define-read-only (get-identity (user principal))
    (map-get? identities user))

(define-read-only (get-verification (user principal) (verifier principal))
    (map-get? verifications { user: user, verifier: verifier }))

(define-read-only (is-verified (user principal) (verifier principal))
    (match (get-verification user verifier)
        verification (and 
            (get status verification)
            (< block-height (get expiration verification)))
        false))