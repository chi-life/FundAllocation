# FundAllocation

A transparent voting system for DAO treasury spending and investment decisions built on the Stacks blockchain using Clarity smart contracts.

## Description

FundAllocation enables DAO members to propose funding allocations, vote on proposals, and execute approved funding decisions through a democratic and transparent process. The contract implements a weighted voting system with configurable quorum and approval thresholds to ensure proper governance over treasury funds.

## Features

- **Member Management**: Add and remove DAO members with voting rights
- **Treasury Management**: Deposit and track STX funds in the DAO treasury
- **Proposal System**: Create detailed funding proposals with recipient and amount specifications
- **Democratic Voting**: Members can vote for or against proposals during defined voting periods
- **Weighted Voting**: Support for different voting power levels per member
- **Quorum Requirements**: Configurable minimum participation thresholds (30% default)
- **Approval Thresholds**: Configurable approval percentage requirements (60% default)
- **Automatic Execution**: Approved proposals can be executed to transfer funds
- **Transparency**: All votes and proposals are publicly viewable on-chain
- **Time-bounded Voting**: 24-hour voting periods (144 blocks) for proposal decisions

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2.0
- **Contract Version**: 1.0.0
- **Epoch**: 2.5
- **Voting Period**: 144 blocks (~24 hours)
- **Quorum Threshold**: 30% of total members
- **Approval Threshold**: 60% of votes cast

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity runtime packaged as a CLI
- [Node.js](https://nodejs.org/) (v16 or higher)
- [Git](https://git-scm.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd FundAllocation
```

2. Install dependencies:
```bash
cd FundAllocation_contract
npm install
```

3. Verify installation:
```bash
clarinet check
```

## Usage Examples

### Basic Contract Interaction

#### Deploy and Initialize
```clarity
;; The contract automatically initializes with the deployer as the first member
```

#### Add DAO Members
```clarity
;; Only contract owner can add members
(contract-call? .FundAllocation add-member 'SP1EXAMPLE...)
```

#### Deposit Treasury Funds
```clarity
;; Any address can deposit STX to the treasury
(contract-call? .FundAllocation deposit-to-treasury u1000000) ;; 1 STX in microSTX
```

#### Create a Proposal
```clarity
;; Members can create funding proposals
(contract-call? .FundAllocation create-proposal
  "Marketing Campaign"
  "Fund Q4 marketing initiatives for ecosystem growth"
  u500000
  'SP2RECIPIENT...)
```

#### Vote on Proposals
```clarity
;; Members vote true for support, false for opposition
(contract-call? .FundAllocation vote u1 true)
```

#### Finalize and Execute
```clarity
;; Anyone can finalize after voting period ends
(contract-call? .FundAllocation finalize-proposal u1)

;; Execute approved proposals
(contract-call? .FundAllocation execute-proposal u1)
```

## Contract Functions Documentation

### Public Functions

#### Member Management
- `add-member(member: principal)` - Add a new DAO member (owner only)
- `remove-member(member: principal)` - Remove a DAO member (owner only)

#### Treasury Operations
- `deposit-to-treasury(amount: uint)` - Deposit STX to treasury
- `get-treasury-balance()` - View current treasury balance

#### Proposal Management
- `create-proposal(title, description, amount, recipient)` - Create new funding proposal
- `vote(proposal-id: uint, support: bool)` - Vote on a proposal
- `finalize-proposal(proposal-id: uint)` - Finalize voting after period ends
- `execute-proposal(proposal-id: uint)` - Execute approved proposal

### Read-Only Functions

#### Information Queries
- `is-member(address: principal)` - Check if address is a DAO member
- `get-proposal(proposal-id: uint)` - Get complete proposal details
- `get-vote(proposal-id, voter)` - Get specific vote details
- `get-total-members()` - Get total number of DAO members
- `get-proposal-counter()` - Get total number of proposals created
- `get-voting-power(member: principal)` - Get member's voting weight
- `check-proposal-result(proposal-id: uint)` - Preview proposal outcome

### Error Codes

- `u100` - ERR_UNAUTHORIZED: Caller lacks required permissions
- `u101` - ERR_NOT_FOUND: Requested resource doesn't exist
- `u102` - ERR_ALREADY_VOTED: Member has already voted on this proposal
- `u103` - ERR_PROPOSAL_EXPIRED: Voting period has ended
- `u104` - ERR_PROPOSAL_NOT_PASSED: Proposal didn't meet approval criteria
- `u105` - ERR_INSUFFICIENT_FUNDS: Treasury lacks required funds
- `u106` - ERR_ALREADY_EXECUTED: Proposal has already been executed
- `u107` - ERR_VOTING_PERIOD_ACTIVE: Action requires voting period to end

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contracts
```

3. Run tests:
```bash
npm test
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`

2. Deploy to testnet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`

2. Deploy to mainnet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Security Notes

### Access Controls
- Only the contract owner can add/remove members
- Only DAO members can create proposals and vote
- Anyone can finalize proposals after voting periods end
- Anyone can execute approved proposals

### Voting Integrity
- Members can only vote once per proposal
- Votes are immutable once cast
- Voting periods are enforced by block height
- Double-voting protection prevents manipulation

### Treasury Security
- Funds are held in contract-controlled address
- Execution requires proposal approval and sufficient funds
- All transfers are recorded on-chain
- Treasury balance is publicly auditable

### Governance Parameters
- Quorum threshold ensures minimum participation
- Approval threshold requires majority consensus
- Time-bounded voting prevents rushed decisions
- Member management prevents unauthorized participation

### Potential Risks
- Contract owner has significant control over membership
- No mechanism for removing the contract owner
- Fixed voting periods may not suit all proposal types
- Simple majority voting without delegation features

### Best Practices
- Regularly audit member list for accuracy
- Monitor treasury balance and proposal amounts
- Ensure adequate voting participation
- Consider multi-sig for contract ownership
- Test all functions thoroughly before mainnet deployment

## Development

### Running Tests
```bash
cd FundAllocation_contract
npm test
```

### Test Coverage
```bash
npm run test:report
```

### Watch Mode
```bash
npm run test:watch
```

### Code Analysis
The contract includes static analysis configuration in `Clarinet.toml` for security verification.

## License

ISC

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## Support

For questions, issues, or contributions, please refer to the project's issue tracker or documentation.