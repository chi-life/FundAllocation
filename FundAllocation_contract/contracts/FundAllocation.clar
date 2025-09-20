
;; title: FundAllocation
;; version: 1.0.0
;; summary: A transparent voting system for DAO treasury spending and investment decisions
;; description: This contract enables DAO members to propose funding allocations, vote on proposals, and execute approved funding decisions

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VOTED (err u102))
(define-constant ERR_PROPOSAL_EXPIRED (err u103))
(define-constant ERR_PROPOSAL_NOT_PASSED (err u104))
(define-constant ERR_INSUFFICIENT_FUNDS (err u105))
(define-constant ERR_ALREADY_EXECUTED (err u106))
(define-constant ERR_VOTING_PERIOD_ACTIVE (err u107))

;; Voting parameters
(define-constant VOTING_PERIOD u144) ;; ~24 hours in blocks (assuming 10 min blocks)
(define-constant QUORUM_THRESHOLD u30) ;; 30% of total members needed
(define-constant APPROVAL_THRESHOLD u60) ;; 60% approval needed

;; data vars
(define-data-var proposal-counter uint u0)
(define-data-var total-members uint u0)
(define-data-var treasury-balance uint u0)

;; data maps
;; DAO members
(define-map members principal bool)

;; Proposals
(define-map proposals uint {
  proposer: principal,
  title: (string-ascii 100),
  description: (string-ascii 500),
  amount: uint,
  recipient: principal,
  start-block: uint,
  end-block: uint,
  votes-for: uint,
  votes-against: uint,
  total-voters: uint,
  executed: bool,
  passed: bool
})

;; Voting records
(define-map votes {proposal-id: uint, voter: principal} {vote: bool, amount: uint})

;; Member voting power (for weighted voting if needed)
(define-map voting-power principal uint)

;; public functions

;; Add a new member to the DAO
(define-public (add-member (member principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (default-to false (map-get? members member))) ERR_UNAUTHORIZED)
    (map-set members member true)
    (map-set voting-power member u1)
    (var-set total-members (+ (var-get total-members) u1))
    (ok true)
  )
)

;; Remove a member from the DAO
(define-public (remove-member (member principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (default-to false (map-get? members member)) ERR_NOT_FOUND)
    (map-delete members member)
    (map-delete voting-power member)
    (var-set total-members (- (var-get total-members) u1))
    (ok true)
  )
)

;; Deposit funds to treasury
(define-public (deposit-to-treasury (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set treasury-balance (+ (var-get treasury-balance) amount))
    (ok amount)
  )
)

;; Create a funding proposal
(define-public (create-proposal (title (string-ascii 100)) (description (string-ascii 500)) (amount uint) (recipient principal))
  (let ((proposal-id (+ (var-get proposal-counter) u1))
        (start-block block-height)
        (end-block (+ block-height VOTING_PERIOD)))
    (begin
      (asserts! (default-to false (map-get? members tx-sender)) ERR_UNAUTHORIZED)
      (asserts! (<= amount (var-get treasury-balance)) ERR_INSUFFICIENT_FUNDS)

      (map-set proposals proposal-id {
        proposer: tx-sender,
        title: title,
        description: description,
        amount: amount,
        recipient: recipient,
        start-block: start-block,
        end-block: end-block,
        votes-for: u0,
        votes-against: u0,
        total-voters: u0,
        executed: false,
        passed: false
      })

      (var-set proposal-counter proposal-id)
      (ok proposal-id)
    )
  )
)

;; Vote on a proposal
(define-public (vote (proposal-id uint) (support bool))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR_NOT_FOUND))
        (voter-power (default-to u1 (map-get? voting-power tx-sender))))
    (begin
      (asserts! (default-to false (map-get? members tx-sender)) ERR_UNAUTHORIZED)
      (asserts! (<= block-height (get end-block proposal)) ERR_PROPOSAL_EXPIRED)
      (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR_ALREADY_VOTED)

      ;; Record the vote
      (map-set votes {proposal-id: proposal-id, voter: tx-sender} {vote: support, amount: voter-power})

      ;; Update proposal vote counts
      (map-set proposals proposal-id
        (merge proposal {
          votes-for: (if support (+ (get votes-for proposal) voter-power) (get votes-for proposal)),
          votes-against: (if support (get votes-against proposal) (+ (get votes-against proposal) voter-power)),
          total-voters: (+ (get total-voters proposal) u1)
        })
      )

      (ok true)
    )
  )
)

;; Finalize proposal (can be called by anyone after voting period ends)
(define-public (finalize-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR_NOT_FOUND)))
    (begin
      (asserts! (> block-height (get end-block proposal)) ERR_VOTING_PERIOD_ACTIVE)
      (asserts! (not (get executed proposal)) ERR_ALREADY_EXECUTED)

      (let ((total-votes (+ (get votes-for proposal) (get votes-against proposal)))
            (quorum-met (>= (get total-voters proposal) (/ (* (var-get total-members) QUORUM_THRESHOLD) u100)))
            (approval-met (>= (* (get votes-for proposal) u100) (* total-votes APPROVAL_THRESHOLD))))

        (let ((passed (and quorum-met approval-met)))
          (map-set proposals proposal-id (merge proposal {passed: passed}))
          (ok passed)
        )
      )
    )
  )
)

;; Execute an approved proposal
(define-public (execute-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) ERR_NOT_FOUND)))
    (begin
      (asserts! (get passed proposal) ERR_PROPOSAL_NOT_PASSED)
      (asserts! (not (get executed proposal)) ERR_ALREADY_EXECUTED)
      (asserts! (>= (var-get treasury-balance) (get amount proposal)) ERR_INSUFFICIENT_FUNDS)

      ;; Transfer funds
      (try! (as-contract (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))))

      ;; Update treasury balance
      (var-set treasury-balance (- (var-get treasury-balance) (get amount proposal)))

      ;; Mark as executed
      (map-set proposals proposal-id (merge proposal {executed: true}))

      (ok true)
    )
  )
)

;; read only functions

;; Check if an address is a member
(define-read-only (is-member (address principal))
  (default-to false (map-get? members address))
)

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

;; Get vote details
(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes {proposal-id: proposal-id, voter: voter})
)

;; Get treasury balance
(define-read-only (get-treasury-balance)
  (var-get treasury-balance)
)

;; Get total members
(define-read-only (get-total-members)
  (var-get total-members)
)

;; Get proposal counter
(define-read-only (get-proposal-counter)
  (var-get proposal-counter)
)

;; Get voting power
(define-read-only (get-voting-power (member principal))
  (default-to u0 (map-get? voting-power member))
)

;; Check if proposal has passed (after voting period)
(define-read-only (check-proposal-result (proposal-id uint))
  (match (map-get? proposals proposal-id)
    proposal
    (let ((total-votes (+ (get votes-for proposal) (get votes-against proposal)))
          (quorum-met (>= (get total-voters proposal) (/ (* (var-get total-members) QUORUM_THRESHOLD) u100)))
          (approval-met (>= (* (get votes-for proposal) u100) (* total-votes APPROVAL_THRESHOLD))))
      {
        quorum-met: quorum-met,
        approval-met: approval-met,
        would-pass: (and quorum-met approval-met),
        votes-for: (get votes-for proposal),
        votes-against: (get votes-against proposal),
        total-voters: (get total-voters proposal)
      }
    )
    {quorum-met: false, approval-met: false, would-pass: false, votes-for: u0, votes-against: u0, total-voters: u0}
  )
)

;; private functions

;; Initialize contract with owner as first member
(begin
  (map-set members CONTRACT_OWNER true)
  (map-set voting-power CONTRACT_OWNER u1)
  (var-set total-members u1)
)
