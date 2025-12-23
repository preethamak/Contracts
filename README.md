# Protocol Contracts - DeFi Demo MVP

Complete smart contract suite for Base Sepolia testnet demonstration.

## Quick Start

### 1. Install Dependencies
```bash
# Install Foundry (if not already installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone and setup
git clone <your-repo>
cd protocol-contracts
forge install
```

### 2. Set Environment Variables
```bash
cp .env.example .env
# Edit .env with your private key and RPC URL
```

### 3. Deploy to Base Sepolia
```bash
# Compile
forge build

# Test (optional)
forge test

# Deploy
source .env
forge script script/Deploy.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
```

## Contracts Overview

### 1. **ProtoToken** (ERC20)
- Initial supply: 100 PROTO tokens
- Owner can mint additional tokens
- Pausable (emergency freeze)
- Used by: Staking, Vesting, Subscription, NFT minting

### 2. **ProtoStaking**
- Deposit PROTO → earn rewards daily
- Reward rate: 0.1 tokens per day (proportional to stake)
- Unstake anytime (no lock period)
- Claim rewards anytime

### 3. **ProtoVesting**
- 3 hardcoded vesting schedules:
  - Team: 25 tokens over 365 days
  - Investor: 35 tokens over 180 days
  - Partners: 20 tokens over 90 days
- Linear vesting (no cliff)
- Claim available tokens anytime

### 4. **ProtoGovernor**
- Token-based voting (1 token = 1 vote)
- Vote immediately after proposal (0 delay)
- 1 day voting period
- 10% quorum
- Anyone with ≥1 token can propose
- Executes immediately after voting passes

### 5. **ProtoNFT** (ERC721)
- Mint for 1 PROTO token per NFT
- Each NFT = one identity in the system
- Transferable (can be traded)
- Simple metadata (owner's custom string)

### 6. **ProtoSubscription**
- Subscribe for 5 PROTO tokens
- 30-day subscription period
- Manual renewal (no auto-charge)
- Status: `isSubscribed(address)` returns bool

### 7. **ProtoAgentRegistry**
- Register AI agents (free)
- Store: address, name, description, category
- Agents can be activated/deactivated
- Query: Get all agents, get active agents only

---

## Deployment Addresses (Base Sepolia)

After running `forge script`, you'll get addresses like:

```
ProtoToken: 0x...
ProtoStaking: 0x...
ProtoVesting: 0x...
ProtoGovernor: 0x...
ProtoNFT: 0x...
ProtoSubscription: 0x...
ProtoAgentRegistry: 0x...
```

Save these for frontend integration.

---

## Integration with React Frontend

### 1. Get Contract ABIs
```bash
# ABIs are generated in out/ after build
ls -la out/
```

### 2. Use with ethers.js or viem
```javascript
import { useContractRead, useContractWrite } from 'wagmi';

// Read user's staking balance
const { data: stakedAmount } = useContractRead({
  address: STAKING_ADDRESS,
  abi: STAKING_ABI,
  functionName: 'stakedAmount',
  args: [userAddress],
});

// Stake tokens
const { write: stake } = useContractWrite({
  address: STAKING_ADDRESS,
  abi: STAKING_ABI,
  functionName: 'stake',
});
```

---

## Testing

### Run All Tests
```bash
forge test
```

### Run Specific Test File
```bash
forge test --match-path "**/ProtoToken.t.sol"
```

### Run with Gas Report
```bash
forge test --gas-report
```

---

## Architecture Diagram

```
User
  ↓
ProtoToken (ERC20) ←─────────────────┐
  ↓ ↓ ↓ ↓ ↓ ↓                        │
Staking Vesting Governor NFT Subscription Registry
  ↓      ↓       ↓        ↓    ↓         ↓
[Deposit] [Claim] [Vote] [Mint] [Subscribe] [Register]
```

All contracts interact with **ProtoToken** as the base currency.

---

## Contract Interactions Example

### Scenario: Full Demo Flow

1. **Deploy**: All contracts initialized
2. **Token Distribution**: Owner gives test tokens to demo users
3. **Staking**: User A stakes 10 PROTO, earns 0.1 PROTO/day
4. **Vesting**: Team member claims vested tokens monthly
5. **Governance**: User B creates proposal to increase rewards
6. **Voting**: Holders vote (need 10% quorum)
7. **Execution**: Proposal passes, reward rate increases
8. **NFT**: User C buys identity NFT for 1 PROTO
9. **Subscription**: User D subscribes for 5 PROTO
10. **Registry**: User E registers AI agent, visible to all

---

## Security Notes (Demo Only)

⚠️ **This is a demo, not production:**
- No formal audit
- Basic access control (owner-based)
- No emergency pause on all contracts
- No rate limiting
- No flash loan guards

For **production**:
- Get professional audit
- Add timelock governance
- Multi-sig admin
- Emergency pause systems
- Formal verification

---

## File Structure

```
protocol-contracts/
├── src/
│   ├── ProtoToken.sol          (ERC20 token)
│   ├── ProtoStaking.sol        (Staking pool)
│   ├── ProtoVesting.sol        (Token vesting)
│   ├── ProtoGovernor.sol       (Governance)
│   ├── ProtoNFT.sol            (ERC721 identity)
│   ├── ProtoSubscription.sol   (Subscription service)
│   └── ProtoAgentRegistry.sol  (Agent registry)
│
├── test/
│   ├── ProtoToken.t.sol
│   ├── ProtoStaking.t.sol
│   ├── ProtoVesting.t.sol
│   ├── ProtoGovernor.t.sol
│   ├── ProtoNFT.t.sol
│   ├── ProtoSubscription.t.sol
│   └── ProtoAgentRegistry.t.sol
│
├── script/
│   ├── Deploy.s.sol            (Main deployment)
│   └── Interaction.s.sol       (Demo interactions)
│
├── foundry.toml
├── .env.example
├── README.md
└── lib/                        (OpenZeppelin dependencies)
```

---

## Helpful Commands

### Compile
```bash
forge build
```

### Test
```bash
forge test
```

### Coverage
```bash
forge coverage
```

### Format
```bash
forge fmt
```

### Deploy (dry run)
```bash
forge script script/Deploy.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL
```

### Deploy (broadcast)
```bash
forge script script/Deploy.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
```

### Verify Contract (Etherscan)
```bash
forge verify-contract <ADDRESS> <CONTRACT_NAME> --rpc-url $BASE_SEPOLIA_RPC_URL
```

---

## Support & Next Steps

### If issues:
1. Check `.env` is set correctly
2. Verify RPC endpoint is responding
3. Ensure wallet has Base Sepolia ETH for gas
4. Check Foundry version: `forge --version`

### Next: Frontend Integration
1. Export ABIs from `out/`
2. Use contract addresses from deployment
3. Integrate with React + wagmi
4. Show live contract state on website

---
