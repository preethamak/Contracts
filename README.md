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
