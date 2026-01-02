# BlockAI Genesis Pass NFT

A complete, production-ready ERC721 NFT contract for the BlockAI Genesis Pass - an early access and ecosystem participation token.

## 🎯 Overview

Genesis Pass is the first access layer of BlockAI, designed for early users who want to enter the product early, participate actively, and grow with the ecosystem.

**Key Features:**
- Limited supply: 1,000 NFTs
- Fixed price minting: 0.005 ETH (~$10)
- Points system for community rewards (15% tokenomics)
- Token allocation: 100 BlockAI tokens per NFT (claimable)
- Tiered access control (Genesis, Alpha, extensible)
- Airdrop eligibility with multipliers
- Abuse prevention via wallet tracking

## 📁 Project Structure

```
cont/
├── src/
│   └── GenesisPass.sol          # Main NFT contract
├── test/
│   └── GenesisPass.t.sol        # Comprehensive test suite (33 tests)
├── script/
│   └── Deploy.s.sol             # Deployment script
├── abi/
│   └── GenesisPass.json         # Contract ABI
├── frontend/
│   ├── GenesisPassABI.json      # ABI for frontend
│   └── integration-example.js   # Frontend integration example
├── foundry.toml                 # Foundry configuration
├── DEPLOYMENT.md                # Deployment guide
└── README.md                    # This file
```

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Node.js (for frontend integration)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd cont

# Install dependencies (OpenZeppelin is installed via Foundry)
forge install
```

### Build

```bash
forge build
```

### Test

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vv

# Run specific test
forge test --match-test test_Mint_Success
```

### Deploy

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed deployment instructions.

```bash
# Set up .env file with PRIVATE_KEY and SEPOLIA_RPC_URL
forge script script/Deploy.s.sol:DeployScript --rpc-url sepolia --broadcast -vvvv
```

## 📋 Contract Features

### Public Functions (Users)

- `mint(address to)` - Mint NFT (payable, requires 0.005 ETH)
- `claimTokens(uint256 tokenId)` - Claim 100 BlockAI ecosystem tokens
- `checkAccess(uint256 tokenId)` - Check MVP access level
- `getPassData(uint256 tokenId)` - Get all pass data (points, access, airdrop, etc.)
- `getPoints(uint256 tokenId)` - Get accumulated points
- `isAirdropEligible(uint256 tokenId)` - Check airdrop eligibility and multiplier
- `hasMinted(address account)` - Check if address has minted

### Owner Functions (Admin)

- `setMintingEnabled(bool)` - Enable/disable minting
- `setTokenClaimEnabled(bool)` - Enable/disable token claiming
- `setMintPrice(uint256)` - Update mint price
- `awardPoints(uint256 tokenId, uint256 points)` - Award points to a token
- `batchAwardPoints(uint256[] tokenIds, uint256[] points)` - Batch award points
- `setAccessLevel(uint256 tokenId, uint256 level)` - Update access level
- `setAirdropEligibility(uint256 tokenId, bool, uint256)` - Update airdrop eligibility
- `batchSetAirdropEligibility(...)` - Batch update airdrop eligibility
- `withdraw()` - Withdraw contract funds
- `resetMintRestriction(address)` - Reset wallet mint restriction

## 🧪 Testing

The test suite includes 33 comprehensive tests covering:

- ✅ Deployment and initialization
- ✅ Minting functionality (success, failures, edge cases)
- ✅ Points system (award, batch award, accumulation)
- ✅ Token allocation (claiming)
- ✅ Access control (tiered levels)
- ✅ Airdrop eligibility (individual and batch)
- ✅ Owner functions
- ✅ Security checks (access control, reentrancy)
- ✅ Integration workflows

Run tests:
```bash
forge test
```

## 🔐 Security Features

- ✅ OpenZeppelin audited contracts (ERC721, Ownable, ReentrancyGuard)
- ✅ ReentrancyGuard protection
- ✅ Access control via Ownable
- ✅ Supply cap enforcement (1,000 max)
- ✅ Price validation
- ✅ Wallet-based minting restriction (abuse prevention)
- ✅ Input validation on all functions

## 📊 Contract Specifications

- **Standard**: ERC721 with Enumerable extension
- **Total Supply**: 1,000 NFTs (hard cap)
- **Mint Price**: 0.005 ETH (~$10, configurable)
- **Tokens per NFT**: 100 (claimable, one-time)
- **Points**: Unlimited accumulation per token
- **Access Levels**: 0 (Genesis), 1 (Alpha), extensible
- **Solidity Version**: 0.8.24

## 🌐 Frontend Integration

See `frontend/integration-example.js` for a complete integration example using ethers.js.

Key functions:
- Minting NFTs
- Viewing pass data
- Claiming tokens
- Checking access levels
- Airdrop eligibility
- Event listeners

## 📝 Development Commands

```bash
# Compile contracts
forge build

# Run tests
forge test

# Format code
forge fmt

# Generate gas snapshots
forge snapshot

# Deploy to Sepolia
forge script script/Deploy.s.sol:DeployScript --rpc-url sepolia --broadcast -vvvv

# Interact with contract (using cast)
cast call <CONTRACT_ADDRESS> "totalSupply()" --rpc-url sepolia
```

## 🛠️ Technology Stack

- **Foundry** - Development framework
- **Solidity 0.8.24** - Smart contract language
- **OpenZeppelin Contracts v5.5.0** - Security-audited libraries

## ⚠️ Important Notes

- **Testnet First**: Always test thoroughly on testnet before mainnet deployment
- **Security Audit**: Professional security audit recommended before mainnet
- **Private Keys**: Never commit private keys or `.env` files
- **Gas Optimization**: Batch functions available for gas efficiency

## 🎯 Requirements Met

✅ Limited supply (1,000 NFTs)  
✅ $10 minting price (0.005 ETH)  
✅ Points system for community rewards  
✅ 100 tokens per NFT (claimable)  
✅ MVP access control (tiered)  
✅ Airdrop eligibility tracking with multipliers  
✅ Abuse prevention (wallet tracking)  
✅ Tiered structure support (Genesis/Alpha)  
✅ Frontend integration ready  
✅ Comprehensive testing (33 tests)  
✅ Deployment scripts  
✅ ABI generation  

## 📄 License

MIT

---

**Status**: Ready for testnet deployment and testing

Built with Foundry and OpenZeppelin
