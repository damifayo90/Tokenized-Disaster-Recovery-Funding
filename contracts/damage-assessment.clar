;; Damage Assessment Contract
;; Records impact on properties and infrastructure

(define-data-var admin principal tx-sender)

;; Map of damage assessments
(define-map damage-assessments
  { assessment-id: uint }
  {
    area-id: uint,
    property-address: (string-ascii 100),
    damage-level: uint,  ;; 1-5 scale
    infrastructure-type: (string-ascii 50),
    estimated-cost: uint,
    assessed-by: principal,
    assessment-date: uint,
    verified: bool
  }
)

;; Counter for assessment IDs
(define-data-var assessment-id-counter uint u0)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Get the next assessment ID and increment counter
(define-private (get-next-assessment-id)
  (let ((current-id (var-get assessment-id-counter)))
    (var-set assessment-id-counter (+ current-id u1))
    current-id
  )
)

;; Add a new damage assessment
(define-public (add-damage-assessment
  (area-id uint)
  (property-address (string-ascii 100))
  (damage-level uint)
  (infrastructure-type (string-ascii 50))
  (estimated-cost uint))
  (begin
    ;; Validate damage level is between 1-5
    (asserts! (and (>= damage-level u1) (<= damage-level u5)) (err u400))

    (let ((new-id (get-next-assessment-id)))
      (map-set damage-assessments
        { assessment-id: new-id }
        {
          area-id: area-id,
          property-address: property-address,
          damage-level: damage-level,
          infrastructure-type: infrastructure-type,
          estimated-cost: estimated-cost,
          assessed-by: tx-sender,
          assessment-date: block-height,
          verified: false
        }
      )
      (ok new-id)
    )
  )
)

;; Verify a damage assessment (admin only)
(define-public (verify-assessment (assessment-id uint))
  (begin
    (asserts! (is-admin) (err u403))
    (let ((assessment (unwrap! (map-get? damage-assessments { assessment-id: assessment-id }) (err u404))))
      (map-set damage-assessments
        { assessment-id: assessment-id }
        (merge assessment { verified: true })
      )
      (ok true)
    )
  )
)

;; Get damage assessment details
(define-read-only (get-damage-assessment (assessment-id uint))
  (map-get? damage-assessments { assessment-id: assessment-id })
)

;; Get all assessments for an area (simplified - in a real contract you'd need pagination)
(define-read-only (get-area-assessments (area-id uint))
  ;; This is a simplified version. In reality, you'd need to implement pagination
  ;; or another mechanism to return multiple assessments.
  (ok true)
)

;; Transfer admin rights (admin only)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
