;; Impact Measurement Contract
;; Records effectiveness of interventions

(define-data-var admin principal tx-sender)

;; Map of impact assessments
(define-map impact-assessments
  { assessment-id: uint }
  {
    project-id: uint,
    area-id: uint,
    metrics: (list 10 {
      name: (string-ascii 50),
      value: uint,
      unit: (string-ascii 20)
    }),
    assessment-date: uint,
    assessed-by: principal,
    notes: (string-ascii 255)
  }
)

;; Map of community feedback
(define-map community-feedback
  { feedback-id: uint }
  {
    project-id: uint,
    area-id: uint,
    rating: uint,  ;; 1-5 scale
    comments: (string-ascii 255),
    submitted-by: principal,
    submission-date: uint
  }
)

;; Counters for IDs
(define-data-var assessment-id-counter uint u0)
(define-data-var feedback-id-counter uint u0)

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

;; Get the next feedback ID and increment counter
(define-private (get-next-feedback-id)
  (let ((current-id (var-get feedback-id-counter)))
    (var-set feedback-id-counter (+ current-id u1))
    current-id
  )
)

;; Create a new impact assessment (admin only)
(define-public (create-impact-assessment
  (project-id uint)
  (area-id uint)
  (metrics (list 10 {
    name: (string-ascii 50),
    value: uint,
    unit: (string-ascii 20)
  }))
  (notes (string-ascii 255)))
  (begin
    (asserts! (is-admin) (err u403))
    (let ((new-id (get-next-assessment-id)))
      (map-set impact-assessments
        { assessment-id: new-id }
        {
          project-id: project-id,
          area-id: area-id,
          metrics: metrics,
          assessment-date: block-height,
          assessed-by: tx-sender,
          notes: notes
        }
      )
      (ok new-id)
    )
  )
)

;; Submit community feedback
(define-public (submit-feedback
  (project-id uint)
  (area-id uint)
  (rating uint)
  (comments (string-ascii 255)))
  (begin
    ;; Validate rating is between 1-5
    (asserts! (and (>= rating u1) (<= rating u5)) (err u400))

    (let ((new-id (get-next-feedback-id)))
      (map-set community-feedback
        { feedback-id: new-id }
        {
          project-id: project-id,
          area-id: area-id,
          rating: rating,
          comments: comments,
          submitted-by: tx-sender,
          submission-date: block-height
        }
      )
      (ok new-id)
    )
  )
)

;; Get impact assessment details
(define-read-only (get-impact-assessment (assessment-id uint))
  (map-get? impact-assessments { assessment-id: assessment-id })
)

;; Get feedback details
(define-read-only (get-feedback (feedback-id uint))
  (map-get? community-feedback { feedback-id: feedback-id })
)

;; Get average rating for a project
(define-read-only (get-project-average-rating (project-id uint))
  ;; This is a simplified version. In reality, you'd need to implement
  ;; a mechanism to calculate the average across all feedback entries.
  (ok u0)
)

;; Transfer admin rights (admin only)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
