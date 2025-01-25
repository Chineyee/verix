;; Verix - Decentralized Identity System

(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-EXPIRED (err u410))
(define-constant ERR-INVALID-INPUT (err u400))
(define-constant ERR-ALREADY-RATED (err u409))
(define-constant MAX-EXPIRATION u52560)
(define-constant MIN-RATING u1)
(define-constant MAX-RATING u5)

;; Data Maps
(define-map identities 
    principal 
    { name: (string-utf8 50),
      bio: (string-utf8 280),
      avatar: (optional (string-utf8 256)),
      social-links: (list 5 (string-utf8 100)),
      created-at: uint,
      updated-at: uint,
      verification-level: uint,
      total-ratings: uint,
      rating-sum: uint,
      average-rating: (optional uint) })

(define-map verifications
    { user: principal, verifier: principal }
    { status: bool,
      timestamp: uint,
      expiration: uint,
      proof: (string-utf8 500) })

;; New: Rating System Map
(define-map ratings
    { rater: principal, rated: principal }
    { rating: uint,
      comment: (optional (string-utf8 280)),
      timestamp: uint })

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

(define-private (validate-rating (rating uint))
    (and 
        (>= rating MIN-RATING)
        (<= rating MAX-RATING)))

(define-private (calculate-average-rating (sum uint) (count uint))
    (if (> count u0)
        (some (/ (* sum u100) count))  ;; Multiply by 100 for 2 decimal precision
        none))

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
              verification-level: u0,
              total-ratings: u0,
              rating-sum: u0,
              average-rating: none }))))

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
              verification-level: (get verification-level identity),
              total-ratings: (get total-ratings identity),
              rating-sum: (get rating-sum identity),
              average-rating: (get average-rating identity) }))))

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
              verification-level: (get verification-level identity),
              total-ratings: (get total-ratings identity),
              rating-sum: (get rating-sum identity),
              average-rating: (get average-rating identity) }))))

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

;; New: Rating Functions
(define-public (rate-identity (user principal)
                            (rating uint)
                            (comment (optional (string-utf8 280))))
    (begin
        ;; First validate user exists and is not the sender
        (asserts! (not (is-eq tx-sender user)) ERR-UNAUTHORIZED)
        (let ((identity (unwrap! (get-identity user) ERR-NOT-FOUND)))
            ;; Then check if rating already exists
            (let ((existing-rating (map-get? ratings { rater: tx-sender, rated: user })))
                (asserts! (is-none existing-rating) ERR-ALREADY-RATED)
                (asserts! (validate-rating rating) ERR-INVALID-INPUT)
                ;; Validate optional comment if present
                (asserts! (match comment
                    value (validate-string value)
                    true) ERR-INVALID-INPUT)
                
                ;; Fetch validated identity data
                (let ((validated-identity (unwrap! (get-identity user) ERR-NOT-FOUND))
                      (current-total (get total-ratings validated-identity))
                      (current-sum (get rating-sum validated-identity))
                      (new-total (+ current-total u1))
                      (new-sum (+ current-sum rating)))
                    
                    ;; Create the rating first
                    (map-set ratings 
                        { rater: tx-sender, rated: user }
                        { rating: rating,
                          comment: comment,
                          timestamp: block-height })
                    
                    ;; Then update the identity with validated data
                    (ok (map-set identities user
                        { name: (get name validated-identity),
                          bio: (get bio validated-identity),
                          avatar: (get avatar validated-identity),
                          social-links: (get social-links validated-identity),
                          created-at: (get created-at validated-identity),
                          updated-at: block-height,
                          verification-level: (get verification-level validated-identity),
                          total-ratings: new-total,
                          rating-sum: new-sum,
                          average-rating: (calculate-average-rating new-sum new-total) })))))))

(define-public (update-rating (user principal)
                            (rating uint)
                            (comment (optional (string-utf8 280))))
    (begin
        ;; First validate the user exists and is not the sender
        (asserts! (not (is-eq tx-sender user)) ERR-UNAUTHORIZED)
        (let ((identity (unwrap! (get-identity user) ERR-NOT-FOUND)))
            ;; Then validate the rating exists
            (let ((existing-rating (unwrap! (map-get? ratings { rater: tx-sender, rated: user }) ERR-NOT-FOUND)))
                (asserts! (validate-rating rating) ERR-INVALID-INPUT)
                ;; Validate optional comment if present
                (asserts! (match comment
                    value (validate-string value)
                    true) ERR-INVALID-INPUT)
                
                ;; Calculate the new rating sum after validation
                (let ((current-rating (get rating existing-rating))
                      (current-sum (get rating-sum identity))
                      (current-total (get total-ratings identity))
                      (new-sum (+ (- current-sum current-rating) rating)))
                    
                    ;; Update the rating first
                    (map-set ratings 
                        { rater: tx-sender, rated: user }
                        { rating: rating,
                          comment: comment,
                          timestamp: block-height })
                    
                    ;; Then update the identity with validated data
                    (ok (map-set identities user
                        (merge identity
                            { updated-at: block-height,
                              total-ratings: current-total,
                              rating-sum: new-sum,
                              average-rating: (calculate-average-rating new-sum current-total) }))))))))

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

;; New: Rating Read Functions
(define-read-only (get-rating (rater principal) (rated principal))
    (map-get? ratings { rater: rater, rated: rated }))

(define-read-only (get-user-ratings (user principal))
    (map-get? identities user))

