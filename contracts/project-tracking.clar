;; Project Tracking Contract
;; Monitors rebuilding and restoration efforts

(define-data-var admin principal tx-sender)

;; Map of recovery projects
(define-map recovery-projects
  { project-id: uint }
  {
    area-id: uint,
    allocation-id: uint,
    title: (string-ascii 100),
    description: (string-ascii 255),
    start-date: uint,
    estimated-completion: uint,
    actual-completion: (optional uint),
    status: (string-ascii 20),  ;; "planned", "in-progress", "completed", "delayed"
    contractor: principal
  }
)

;; Map of project milestones
(define-map project-milestones
  { milestone-id: uint }
  {
    project-id: uint,
    title: (string-ascii 100),
    description: (string-ascii 255),
    target-date: uint,
    completion-date: (optional uint),
    status: (string-ascii 20)  ;; "pending", "completed", "delayed"
  }
)

;; Counters for IDs
(define-data-var project-id-counter uint u0)
(define-data-var milestone-id-counter uint u0)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Get the next project ID and increment counter
(define-private (get-next-project-id)
  (let ((current-id (var-get project-id-counter)))
    (var-set project-id-counter (+ current-id u1))
    current-id
  )
)

;; Get the next milestone ID and increment counter
(define-private (get-next-milestone-id)
  (let ((current-id (var-get milestone-id-counter)))
    (var-set milestone-id-counter (+ current-id u1))
    current-id
  )
)

;; Create a new recovery project (admin only)
(define-public (create-project
  (area-id uint)
  (allocation-id uint)
  (title (string-ascii 100))
  (description (string-ascii 255))
  (start-date uint)
  (estimated-completion uint)
  (contractor principal))
  (begin
    (asserts! (is-admin) (err u403))
    (let ((new-id (get-next-project-id)))
      (map-set recovery-projects
        { project-id: new-id }
        {
          area-id: area-id,
          allocation-id: allocation-id,
          title: title,
          description: description,
          start-date: start-date,
          estimated-completion: estimated-completion,
          actual-completion: none,
          status: "planned",
          contractor: contractor
        }
      )
      (ok new-id)
    )
  )
)

;; Update project status (admin or contractor)
(define-public (update-project-status (project-id uint) (new-status (string-ascii 20)))
  (let ((project (unwrap! (map-get? recovery-projects { project-id: project-id }) (err u404))))
    (asserts! (or (is-admin) (is-eq tx-sender (get contractor project))) (err u403))
    (map-set recovery-projects
      { project-id: project-id }
      (merge project { status: new-status })
    )
    (ok true)
  )
)

;; Mark project as completed (admin or contractor)
(define-public (complete-project (project-id uint))
  (let ((project (unwrap! (map-get? recovery-projects { project-id: project-id }) (err u404))))
    (asserts! (or (is-admin) (is-eq tx-sender (get contractor project))) (err u403))
    (map-set recovery-projects
      { project-id: project-id }
      (merge project {
        status: "completed",
        actual-completion: (some block-height)
      })
    )
    (ok true)
  )
)

;; Add a milestone to a project (admin or contractor)
(define-public (add-milestone
  (project-id uint)
  (title (string-ascii 100))
  (description (string-ascii 255))
  (target-date uint))
  (let ((project (unwrap! (map-get? recovery-projects { project-id: project-id }) (err u404))))
    (asserts! (or (is-admin) (is-eq tx-sender (get contractor project))) (err u403))
    (let ((new-id (get-next-milestone-id)))
      (map-set project-milestones
        { milestone-id: new-id }
        {
          project-id: project-id,
          title: title,
          description: description,
          target-date: target-date,
          completion-date: none,
          status: "pending"
        }
      )
      (ok new-id)
    )
  )
)

;; Complete a milestone (admin or contractor)
(define-public (complete-milestone (milestone-id uint))
  (let (
    (milestone (unwrap! (map-get? project-milestones { milestone-id: milestone-id }) (err u404)))
    (project (unwrap! (map-get? recovery-projects { project-id: (get project-id milestone) }) (err u404)))
  )
    (asserts! (or (is-admin) (is-eq tx-sender (get contractor project))) (err u403))
    (map-set project-milestones
      { milestone-id: milestone-id }
      (merge milestone {
        status: "completed",
        completion-date: (some block-height)
      })
    )
    (ok true)
  )
)

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? recovery-projects { project-id: project-id })
)

;; Get milestone details
(define-read-only (get-milestone (milestone-id uint))
  (map-get? project-milestones { milestone-id: milestone-id })
)

;; Transfer admin rights (admin only)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
