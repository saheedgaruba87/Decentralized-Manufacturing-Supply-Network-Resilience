;; Entity Verification Contract
;; Validates supply chain participants

(define-data-var admin principal tx-sender)

;; Entity types: 1 = Manufacturer, 2 = Supplier, 3 = Distributor, 4 = Retailer
(define-map entities
  { entity-id: (string-ascii 64) }
  {
    owner: principal,
    name: (string-ascii 100),
    entity-type: uint,
    verified: bool,
    verification-date: uint
  }
)

(define-read-only (get-entity (entity-id (string-ascii 64)))
  (map-get? entities { entity-id: entity-id })
)

(define-public (register-entity
    (entity-id (string-ascii 64))
    (name (string-ascii 100))
    (entity-type uint))
  (begin
    (asserts! (and (>= entity-type u1) (<= entity-type u4)) (err u1)) ;; Valid entity type
    (asserts! (is-none (get-entity entity-id)) (err u2)) ;; Entity ID not already used

    (map-set entities
      { entity-id: entity-id }
      {
        owner: tx-sender,
        name: name,
        entity-type: entity-type,
        verified: false,
        verification-date: u0
      }
    )
    (ok true)
  )
)

(define-public (verify-entity (entity-id (string-ascii 64)))
  (let ((entity (unwrap! (get-entity entity-id) (err u3))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u4)) ;; Only admin can verify

    (map-set entities
      { entity-id: entity-id }
      (merge entity {
        verified: true,
        verification-date: block-height
      })
    )
    (ok true)
  )
)

(define-public (transfer-entity-ownership
    (entity-id (string-ascii 64))
    (new-owner principal))
  (let ((entity (unwrap! (get-entity entity-id) (err u3))))
    (asserts! (is-eq tx-sender (get owner entity)) (err u5)) ;; Only owner can transfer

    (map-set entities
      { entity-id: entity-id }
      (merge entity {
        owner: new-owner,
        verified: false ;; Require re-verification after ownership transfer
      })
    )
    (ok true)
  )
)
