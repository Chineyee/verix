;; Verix - Decentralized Identity System

(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-EXPIRED (err u410))
(define-constant ERR-INVALID-INPUT (err u400))
(define-constant MAX-EXPIRATION u52560)

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

;; Private Functions
(define-private (validate-string (str (string-utf8 500)))
    (and 
        (> (len str) u0)
        (<= (len str) u500)))

(define-private (validate-optional-string (opt-str (optional (string-utf8 256))))
    (match opt-str
        value (and 
            (> (len value) u0)
            (<= (len value) u256))
        true))

(define-private (validate-identity-input (name (string-utf8 50)) 
                                       (bio (string-utf8 280)) 
                                       (avatar (optional (string-utf8 256))))
    (and 
        (> (len name) u0)
        (<= (len name) u50)
        (> (len bio) u0)
        (<= (len bio) u280)
        (validate-optional-string avatar)))

;; Public Functions
(define-public (create-identity (name (string-utf8 50)) 
                              (bio (string-utf8 280))
                              (avatar (optional (string-utf8 256))))
    (let ((existing-identity (get-identity tx-sender)))
        (asserts! (is-none existing-identity) ERR-INVALID-INPUT)
        (asserts! (validate-identity-input name bio avatar) ERR-INVALID-INPUT)
        (ok (map-set identities tx-sender
            { name: name,
              bio: bio,
              avatar: avatar,
              social-links: (list),
              created-at: block-height,
              updated-at: block-height,
              verification-level: u0 }))))

(define-public (update-identity (name (string-utf8 50))
                              (bio (string-utf8 280))
                              (avatar (optional (string-utf8 256))))
    (let ((identity (unwrap! (get-identity tx-sender) ERR-NOT-FOUND)))
        (asserts! (validate-identity-input name bio avatar) ERR-INVALID-INPUT)
        (ok (map-set identities tx-sender
            { name: name,
              bio: bio,
              avatar: avatar,
              social-links: (get social-links identity),
              created-at: (get created-at identity),
              updated-at: block-height,
              verification-level: (get verification-level identity) }))))

(define-public (add-social-link (link (string-utf8 100)))
    (let ((identity (unwrap! (get-identity tx-sender) ERR-NOT-FOUND)))
        (asserts! (and 
            (> (len link) u0)
            (<= (len link) u100)
            (< (len (get social-links identity)) u5)) ERR-INVALID-INPUT)
        (ok (map-set identities tx-sender
            { name: (get name identity),
              bio: (get bio identity),
              avatar: (get avatar identity),
              social-links: (unwrap! (as-max-len? (append (get social-links identity) link) u5) ERR-INVALID-INPUT),
              created-at: (get created-at identity),
              updated-at: block-height,
              verification-level: (get verification-level identity) }))))

(define-public (verify-identity (user principal) 
                              (proof (string-utf8 500))
                              (expiration uint))
    (begin
        (asserts! (and 
            (> (len proof) u0)
            (<= (len proof) u500)
            (<= expiration MAX-EXPIRATION)) ERR-INVALID-INPUT)
        (asserts! (is-some (get-identity user)) ERR-NOT-FOUND)
        (ok (map-set verifications
            { user: user, verifier: tx-sender }
            { status: true,
              timestamp: block-height,
              expiration: (+ block-height expiration),
              proof: proof }))))

;; Read-Only Functions
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