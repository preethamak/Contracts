/**
 * BlockAI Genesis Pass NFT - Frontend Integration Example
 * 
 * This example demonstrates how to interact with the GenesisPass contract
 * from a frontend application using ethers.js or web3.js
 */

// ============ CONFIGURATION ============
const CONTRACT_ADDRESS = "0x..."; // Replace with deployed contract address
const CONTRACT_ABI = []; // Import from GenesisPassABI.json

// ============ ETHERJS EXAMPLE ============

import { ethers } from "ethers";
import GenesisPassABI from "./GenesisPassABI.json";

// Initialize provider and signer
const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();
const genesisPass = new ethers.Contract(CONTRACT_ADDRESS, GenesisPassABI, signer);

// ============ MINTING ============

/**
 * Mint a Genesis Pass NFT
 */
async function mintGenesisPass() {
    try {
        const mintPrice = await genesisPass.mintPrice();
        const mintingEnabled = await genesisPass.mintingEnabled();
        
        if (!mintingEnabled) {
            throw new Error("Minting is currently disabled");
        }
        
        const tx = await genesisPass.mint(await signer.getAddress(), {
            value: mintPrice
        });
        
        const receipt = await tx.wait();
        console.log("Mint successful! Transaction:", receipt.transactionHash);
        
        // Extract token ID from Transfer event
        const transferEvent = receipt.logs.find(
            log => log.topics[0] === ethers.id("Transfer(address,address,uint256)")
        );
        const tokenId = BigInt(transferEvent.topics[3]);
        console.log("Token ID:", tokenId.toString());
        
        return tokenId;
    } catch (error) {
        console.error("Mint failed:", error);
        throw error;
    }
}

// ============ VIEW FUNCTIONS ============

/**
 * Get all pass data for a token
 */
async function getPassData(tokenId) {
    try {
        const [points, tokensClaimed, accessLevel, airdropEligible, airdropMultiplier] = 
            await genesisPass.getPassData(tokenId);
        
        return {
            points: points.toString(),
            tokensClaimed,
            accessLevel: accessLevel.toString(),
            airdropEligible,
            airdropMultiplier: airdropMultiplier.toString()
        };
    } catch (error) {
        console.error("Failed to get pass data:", error);
        throw error;
    }
}

/**
 * Get accumulated points for a token
 */
async function getPoints(tokenId) {
    try {
        const points = await genesisPass.getPoints(tokenId);
        return points.toString();
    } catch (error) {
        console.error("Failed to get points:", error);
        throw error;
    }
}

/**
 * Check MVP access level
 */
async function checkAccess(tokenId) {
    try {
        const level = await genesisPass.checkAccess(tokenId);
        const levels = {
            0: "Genesis",
            1: "Alpha"
        };
        return {
            level: level.toString(),
            name: levels[level] || "Unknown"
        };
    } catch (error) {
        console.error("Failed to check access:", error);
        throw error;
    }
}

/**
 * Check airdrop eligibility
 */
async function checkAirdropEligibility(tokenId) {
    try {
        const [eligible, multiplier] = await genesisPass.isAirdropEligible(tokenId);
        return {
            eligible,
            multiplier: multiplier.toString(),
            multiplierX: (Number(multiplier) / 100).toFixed(1) + "x"
        };
    } catch (error) {
        console.error("Failed to check airdrop eligibility:", error);
        throw error;
    }
}

/**
 * Get user's NFTs
 */
async function getUserNFTs(userAddress) {
    try {
        const balance = await genesisPass.balanceOf(userAddress);
        const tokenIds = [];
        
        for (let i = 0; i < balance; i++) {
            const tokenId = await genesisPass.tokenOfOwnerByIndex(userAddress, i);
            tokenIds.push(tokenId.toString());
        }
        
        return tokenIds;
    } catch (error) {
        console.error("Failed to get user NFTs:", error);
        throw error;
    }
}

/**
 * Check if user has minted
 */
async function hasUserMinted(userAddress) {
    try {
        return await genesisPass.hasMinted(userAddress);
    } catch (error) {
        console.error("Failed to check mint status:", error);
        throw error;
    }
}

// ============ USER ACTIONS ============

/**
 * Claim 100 BlockAI ecosystem tokens
 */
async function claimTokens(tokenId) {
    try {
        const claimEnabled = await genesisPass.tokenClaimEnabled();
        if (!claimEnabled) {
            throw new Error("Token claiming is currently disabled");
        }
        
        const tx = await genesisPass.claimTokens(tokenId);
        const receipt = await tx.wait();
        console.log("Tokens claimed! Transaction:", receipt.transactionHash);
        return receipt;
    } catch (error) {
        console.error("Token claim failed:", error);
        throw error;
    }
}

// ============ CONTRACT INFO ============

/**
 * Get contract information
 */
async function getContractInfo() {
    try {
        const [
            maxSupply,
            totalSupply,
            mintPrice,
            mintingEnabled,
            tokenClaimEnabled,
            tokensPerNFT
        ] = await Promise.all([
            genesisPass.MAX_SUPPLY(),
            genesisPass.totalSupply(),
            genesisPass.mintPrice(),
            genesisPass.mintingEnabled(),
            genesisPass.tokenClaimEnabled(),
            genesisPass.TOKENS_PER_NFT()
        ]);
        
        return {
            maxSupply: maxSupply.toString(),
            totalSupply: totalSupply.toString(),
            remaining: (maxSupply - totalSupply).toString(),
            mintPrice: ethers.formatEther(mintPrice) + " ETH",
            mintingEnabled,
            tokenClaimEnabled,
            tokensPerNFT: tokensPerNFT.toString()
        };
    } catch (error) {
        console.error("Failed to get contract info:", error);
        throw error;
    }
}

// ============ EVENT LISTENERS ============

/**
 * Listen for mint events
 */
function listenForMints(callback) {
    genesisPass.on("Minted", (to, tokenId, price, event) => {
        callback({
            to,
            tokenId: tokenId.toString(),
            price: ethers.formatEther(price),
            transactionHash: event.transactionHash
        });
    });
}

/**
 * Listen for points awarded events
 */
function listenForPointsAwarded(callback) {
    genesisPass.on("PointsAwarded", (tokenId, points, totalPoints, event) => {
        callback({
            tokenId: tokenId.toString(),
            points: points.toString(),
            totalPoints: totalPoints.toString(),
            transactionHash: event.transactionHash
        });
    });
}

// ============ EXAMPLE USAGE ============

/**
 * Complete example: Mint, check data, claim tokens
 */
async function exampleWorkflow() {
    try {
        // 1. Check contract info
        const info = await getContractInfo();
        console.log("Contract Info:", info);
        
        // 2. Check if user can mint
        const userAddress = await signer.getAddress();
        const hasMinted = await hasUserMinted(userAddress);
        
        if (!hasMinted && info.mintingEnabled) {
            // 3. Mint NFT
            const tokenId = await mintGenesisPass();
            console.log("Minted token ID:", tokenId);
            
            // 4. Get pass data
            const passData = await getPassData(tokenId);
            console.log("Pass Data:", passData);
            
            // 5. Check access level
            const access = await checkAccess(tokenId);
            console.log("Access Level:", access);
            
            // 6. Check airdrop eligibility
            const airdrop = await checkAirdropEligibility(tokenId);
            console.log("Airdrop Status:", airdrop);
            
            // 7. Claim tokens (if enabled)
            if (info.tokenClaimEnabled && !passData.tokensClaimed) {
                await claimTokens(tokenId);
                console.log("Tokens claimed successfully!");
            }
        } else {
            // Get user's existing NFTs
            const tokenIds = await getUserNFTs(userAddress);
            console.log("Your NFTs:", tokenIds);
            
            // Get data for each NFT
            for (const tokenId of tokenIds) {
                const data = await getPassData(tokenId);
                console.log(`Token ${tokenId}:`, data);
            }
        }
    } catch (error) {
        console.error("Workflow error:", error);
    }
}

// Export functions for use in your app
export {
    mintGenesisPass,
    getPassData,
    getPoints,
    checkAccess,
    checkAirdropEligibility,
    getUserNFTs,
    hasUserMinted,
    claimTokens,
    getContractInfo,
    listenForMints,
    listenForPointsAwarded,
    exampleWorkflow
};
