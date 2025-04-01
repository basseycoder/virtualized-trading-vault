;; -------------------------------------------------------------
;; Virtualized Trading Vault Contract
;; Secure transaction platform for virtual collectibles on Stacks blockchain
;; -------------------------------------------------------------

;; Core tracking variable for vault request sequence
(define-data-var current-vault-sequence uint u0)

;; Storage for all active and past vaults
(define-map VaultRegistry
  { vault-sequence: uint }
  {
    requester: principal,
    provider: principal,
    item-identifier: uint,
    payment-amount: uint,
    vault-state: (string-ascii 10),
    initiation-block: uint,
    termination-block: uint
  }
)

;; -------------------------------------------------------------
;; System Constants & Error Codes
;; -------------------------------------------------------------

;; Administrative role assignment
(define-constant VAULT_ADMINISTRATOR tx-sender)

;; Duration parameters
(define-constant VAULT_DURATION_BLOCKS u1008) ;; Approximately one week

;; System error definitions
(define-constant ERR_PERMISSION_DENIED (err u100))
(define-constant ERR_VAULT_NONEXISTENT (err u101))
(define-constant ERR_ALREADY_FINALIZED (err u102))
(define-constant ERR_OPERATION_FAILED (err u103))
(define-constant ERR_SEQUENCE_INVALID (err u104))
(define-constant ERR_PAYMENT_INVALID (err u105))
(define-constant ERR_PROVIDER_INVALID (err u106))
(define-constant ERR_VAULT_EXPIRED (err u107))

;; -------------------------------------------------------------
;; Internal Validation Functions
;; -------------------------------------------------------------

;; Verify provider eligibility
(define-private (verify-provider-eligibility (provider principal))
  (and 
    (not (is-eq provider tx-sender))
    (not (is-eq provider (as-contract tx-sender)))
  )
)

;; Verify vault sequence validity
(define-private (verify-sequence-validity (sequence uint))
  (<= sequence (var-get current-vault-sequence))
)

;; -------------------------------------------------------------
;; Primary Interaction Functions
;; -------------------------------------------------------------

;; Initialize a new trading vault
(define-public (initialize-vault (provider principal) (item-identifier uint) (payment-amount uint))
  (let 
    (
      (next-sequence (+ (var-get current-vault-sequence) u1))
      (termination-height (+ block-height VAULT_DURATION_BLOCKS))
    )
    (asserts! (> payment-amount u0) ERR_PAYMENT_INVALID)
    (asserts! (verify-provider-eligibility provider) ERR_PROVIDER_INVALID)

    (match (stx-transfer? payment-amount tx-sender (as-contract tx-sender))
      success-result
        (begin
          (var-set current-vault-sequence next-sequence)

          (print {event: "vault_initialized", sequence: next-sequence, requester: tx-sender, 
                  provider: provider, item: item-identifier, payment: payment-amount})
          (ok next-sequence)
        )
      failure-result ERR_OPERATION_FAILED
    )
  )
)

;; Execute vault completion process
(define-public (complete-vault-transaction (sequence uint))
  (begin
    (asserts! (verify-sequence-validity sequence) ERR_SEQUENCE_INVALID)
    (let
      (
        (vault-data (unwrap! (map-get? VaultRegistry { vault-sequence: sequence }) ERR_VAULT_NONEXISTENT))
        (provider (get provider vault-data))
        (payment (get payment-amount vault-data))
        (item (get item-identifier vault-data))
      )
      (asserts! (or (is-eq tx-sender VAULT_ADMINISTRATOR) (is-eq tx-sender (get requester vault-data))) ERR_PERMISSION_DENIED)
      (asserts! (is-eq (get vault-state vault-data) "pending") ERR_ALREADY_FINALIZED)
      (asserts! (<= block-height (get termination-block vault-data)) ERR_VAULT_EXPIRED)

      (match (as-contract (stx-transfer? payment tx-sender provider))
        success-result
          (begin
            (map-set VaultRegistry
              { vault-sequence: sequence }
              (merge vault-data { vault-state: "completed" })
            )
            (print {event: "vault_completed", sequence: sequence, provider: provider, 
                    item: item, payment: payment})
            (ok true)
          )
        failure-result ERR_OPERATION_FAILED
      )
    )
  )
)

;; Return payment to requester for canceled transactions
(define-public (return-payment (sequence uint))
  (begin
    (asserts! (verify-sequence-validity sequence) ERR_SEQUENCE_INVALID)
    (let
      (
        (vault-data (unwrap! (map-get? VaultRegistry { vault-sequence: sequence }) ERR_VAULT_NONEXISTENT))
        (requester (get requester vault-data))
        (payment (get payment-amount vault-data))
      )
      (asserts! (is-eq tx-sender VAULT_ADMINISTRATOR) ERR_PERMISSION_DENIED)
      (asserts! (is-eq (get vault-state vault-data) "pending") ERR_ALREADY_FINALIZED)

      (match (as-contract (stx-transfer? payment tx-sender requester))
        success-result
          (begin
            (map-set VaultRegistry
              { vault-sequence: sequence }
              (merge vault-data { vault-state: "canceled" })
            )
            (print {event: "payment_returned", sequence: sequence, requester: requester, 
                    payment: payment})
            (ok true)
          )
        failure-result ERR_OPERATION_FAILED
      )
    )
  )
)

;; -------------------------------------------------------------
;; Query Functions
;; -------------------------------------------------------------

;; Retrieve vault transaction details
(define-read-only (get-vault-details (sequence uint))
  (begin
    (asserts! (verify-sequence-validity sequence) ERR_SEQUENCE_INVALID)
    (match (map-get? VaultRegistry { vault-sequence: sequence })
      vault-info (ok vault-info)
      ERR_VAULT_NONEXISTENT
    )
  )
)

;; Get the most recent vault sequence number
(define-read-only (get-latest-sequence)
  (ok (var-get current-vault-sequence))
)
