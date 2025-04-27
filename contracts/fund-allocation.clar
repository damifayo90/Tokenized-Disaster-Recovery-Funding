;; Fund Allocation Contract
;; Manages distribution of recovery resources

(define-data-var admin principal tx-sender)
(define-data-var total-funds uint u0)

;; Map of fund allocations
(define-map fund-allocations
  { allocation-id: uint }
  {
    area-id: uint,
    amount: uint,
    recipient: principal,
    purpose: (string-ascii 100),
    allocation-date: uint,
    status: (string-ascii 20)  ;; "pending", "approved", "disbursed", "completed"
  }
)

;; Counter for allocation IDs
(define-data-var allocation-id-counter uint u0)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Get the next allocation ID and increment counter
(define-private (get-next-allocation-id)
  (let ((current-id (var-get allocation-id-counter)))
    (var-set allocation-id-counter (+ current-id u1))
    current-id
  )
)

;; Add funds to the contract
(define-public (add-funds (amount uint))
  (begin
    (var-set total-funds (+ (var-get total-funds) amount))
    (ok true)
  )
)

;; Create a new fund allocation (admin only)
(define-public (create-allocation
  (area-id uint)
  (amount uint)
  (recipient principal)
  (purpose (string-ascii 100)))
  (begin
    (asserts! (is-admin) (err u403))
    ;; Check if we have enough funds
    (asserts! (>= (var-get total-funds) amount) (err u400))

    (let ((new-id (get-next-allocation-id)))
      (map-set fund-allocations
        { allocation-id: new-id }
        {
          area-id: area-id,
          amount: amount,
          recipient: recipient,
          purpose: purpose,
          allocation-date: block-height,
          status: "pending"
        }
      )
      ;; Reduce available funds
      (var-set total-funds (- (var-get total-funds) amount))
      (ok new-id)
    )
  )
)

;; Update allocation status (admin only)
(define-public (update-allocation-status (allocation-id uint) (new-status (string-ascii 20)))
  (begin
    (asserts! (is-admin) (err u403))
    (let ((allocation (unwrap! (map-get? fund-allocations { allocation-id: allocation-id }) (err u404))))
      (map-set fund-allocations
        { allocation-id: allocation-id }
        (merge allocation { status: new-status })
      )
      (ok true)
    )
  )
)

;; Get allocation details
(define-read-only (get-allocation (allocation-id uint))
  (map-get? fund-allocations { allocation-id: allocation-id })
)

;; Get total available funds
(define-read-only (get-available-funds)
  (var-get total-funds)
)

;; Transfer admin rights (admin only)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
