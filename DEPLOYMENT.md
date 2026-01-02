# Genesis Pass NFT - Deployment Guide

## Prerequisites

1. **Foundry installed** - [Install Foundry](https://book.getfoundry.sh/getting-started/installation)
2. **Sepolia testnet ETH** - Get from [faucets](https://sepoliafaucet.com/)
3. **Private key** - Your wallet private key (keep secure!)
4. **RPC URL** - Sepolia RPC endpoint (Alchemy, Infura, or public)

## Setup

### 1. Environment Variables

Create a `.env` file in the project root:

```bash
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_api_key
ETHERSCAN_API_KEY=your_etherscan_api_key  # Optional, for verification
```

**⚠️ Security Warning**: Never commit `.env` to version control!

### 2. Verify Configuration

Check `foundry.toml` is configured correctly:

```toml
[rpc_endpoints]
sepolia = "${SEPOLIA_RPC_URL}"

[etherscan]
sepolia = { key = "${ETHERSCAN_API_KEY}" }
```

## Deployment Steps

### Step 1: Compile Contracts

```bash
forge build
```

### Step 2: Deploy to Sepolia

```bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  -vvvv
```

This will:
- Deploy the contract to Sepolia
- Broadcast the transaction
- Verify the contract on Etherscan (if API key provided)
- Show detailed logs

### Step 3: Save Deployment Info

After deployment, save the contract address:

```bash
# Contract deployed at: 0x...
# Owner: 0x...
# Mint Price: 5000000000000000 (0.005 ETH)
# Max Supply: 1000
# Tokens per NFT: 100
```

### Step 4: Initialize Contract

After deployment, you need to enable minting:

```bash
# Using cast (Foundry CLI)
cast send <CONTRACT_ADDRESS> \
  "setMintingEnabled(bool)" true \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

Or use the frontend integration example to call `setMintingEnabled(true)`.

## Post-Deployment Checklist

- [ ] Contract deployed successfully
- [ ] Contract verified on Etherscan
- [ ] Owner address set correctly
- [ ] Minting enabled (if ready)
- [ ] Token claiming enabled (if ready)
- [ ] Contract address saved
- [ ] ABI file copied to frontend

## Testing on Testnet

### Mint an NFT

```bash
cast send <CONTRACT_ADDRESS> \
  "mint(address)" <YOUR_ADDRESS> \
  --value 0.005ether \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

### Check Token Data

```bash
cast call <CONTRACT_ADDRESS> \
  "getPassData(uint256)" 1 \
  --rpc-url sepolia
```

### Award Points (Owner Only)

```bash
cast send <CONTRACT_ADDRESS> \
  "awardPoints(uint256,uint256)" 1 100 \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

## Mainnet Deployment

When ready for mainnet:

1. Update `.env` with mainnet RPC URL
2. Add mainnet configuration to `foundry.toml`:
   ```toml
   [rpc_endpoints]
   mainnet = "${MAINNET_RPC_URL}"
   
   [etherscan]
   mainnet = { key = "${ETHERSCAN_API_KEY}" }
   ```
3. Deploy with:
   ```bash
   forge script script/Deploy.s.sol:DeployScript \
     --rpc-url mainnet \
     --broadcast \
     --verify \
     -vvvv
   ```

## Troubleshooting

### "Insufficient funds"
- Ensure you have enough ETH for gas fees
- Check your wallet balance

### "Nonce too high"
- Wait a moment and try again
- Or manually set nonce with `--nonce` flag

### "Contract verification failed"
- Check Etherscan API key is correct
- Wait a few minutes after deployment before verifying
- Try manual verification on Etherscan

### "Minting disabled"
- Call `setMintingEnabled(true)` as owner
- Verify you're using the owner account

## Security Reminders

- ✅ Never share your private key
- ✅ Use environment variables for secrets
- ✅ Test thoroughly on testnet first
- ✅ Review contract code before mainnet
- ✅ Consider professional audit before mainnet
- ✅ Keep `.env` in `.gitignore`

## Support

For issues or questions:
1. Check contract code and comments
2. Review test files for usage examples
3. See `frontend/integration-example.js` for integration
4. Check Foundry documentation: https://book.getfoundry.sh/
