;; Affected Area Verification Contract
;; Validates legitimate disaster zones

(define-data-var admin principal tx-sender)

;; Map of verified disaster areas
(define-map disaster-areas
  { area-id: uint }
  {
    name: (string-ascii 100),
    location: (string-ascii 100),
    disaster-type: (string-ascii 50),
    start-date: uint,
    verified: bool
  }
)

;; Counter for area IDs
(define-data-var area-id-counter uint u0)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Get the next area ID and increment counter
(define-private (get-next-area-id)
  (let ((current-id (var-get area-id-counter)))
    (var-set area-id-counter (+ current-id u1))
    current-id
  )
)

;; Add a new disaster area (admin only)
(define-public (add-disaster-area (name (string-ascii 100)) (location (string-ascii 100)) (disaster-type (string-ascii 50)) (start-date uint))
  (begin
    (asserts! (is-admin) (err u403))
    (let ((new-id (get-next-area-id)))
      (map-set disaster-areas
        { area-id: new-id }
        {
          name: name,
          location: location,
          disaster-type: disaster-type,
          start-date: start-date,
          verified: false
        }
      )
      (ok new-id)
    )
  )
)

;; Verify a disaster area (admin only)
(define-public (verify-disaster-area (area-id uint))
  (begin
    (asserts! (is-admin) (err u403))
    (let ((area (unwrap! (map-get? disaster-areas { area-id: area-id }) (err u404))))
      (map-set disaster-areas
        { area-id: area-id }
        (merge area { verified: true })
      )
      (ok true)
    )
  )
)

;; Check if an area is verified
(define-read-only (is-area-verified (area-id uint))
  (default-to false
    (get verified (map-get? disaster-areas { area-id: area-id }))
  )
)

;; Get disaster area details
(define-read-only (get-disaster-area (area-id uint))
  (map-get? disaster-areas { area-id: area-id })
)

;; Transfer admin rights (admin only)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
