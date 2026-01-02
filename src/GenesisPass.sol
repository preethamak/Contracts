// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title GenesisPass
 * @dev BlockAI Genesis Pass NFT - Early access and ecosystem participation token
 *
 * Features:
 * - Limited supply: 1,000 NFTs
 * - Fixed price minting: 0.005 ETH (~$10)
 * - Points system for community rewards (15% tokenomics)
 * - Token allocation: 100 BlockAI tokens per NFT (claimable)
 * - Access control: Tiered MVP access levels
 * - Airdrop eligibility with multipliers
 * - Abuse prevention via wallet tracking
 */
contract GenesisPass is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    // Constants
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant TOKENS_PER_NFT = 100;
    uint256 public constant INITIAL_MINT_PRICE = 0.005 ether; // ~$10

    // State variables
    uint256 private _nextTokenId = 1;
    uint256 public mintPrice = INITIAL_MINT_PRICE;
    bool public mintingEnabled = false;
    bool public tokenClaimEnabled = false;

    // Token data structures
    struct PassData {
        uint256 points;
        bool tokensClaimed;
        uint256 accessLevel; // 0 = Genesis, 1 = Alpha, extensible
        bool airdropEligible;
        uint256 airdropMultiplier; // 100 = 1x, 200 = 2x, etc.
    }

    mapping(uint256 => PassData) private _passData;
    mapping(address => bool) private _hasMinted; // Abuse prevention
    mapping(address => uint256) private _walletPoints; // Wallet-level points tracking

    // Events
    event Minted(address indexed to, uint256 indexed tokenId, uint256 price);
    event PointsAwarded(uint256 indexed tokenId, uint256 points, uint256 totalPoints);
    event TokensClaimed(uint256 indexed tokenId, address indexed claimer);
    event AccessLevelUpdated(uint256 indexed tokenId, uint256 newLevel);
    event AirdropEligibilityUpdated(uint256 indexed tokenId, bool eligible, uint256 multiplier);
    event MintPriceUpdated(uint256 newPrice);
    event MintingToggled(bool enabled);
    event TokenClaimToggled(bool enabled);

    constructor(address initialOwner) ERC721("BlockAI Genesis Pass", "BGEN") Ownable(initialOwner) {
        // Contract initialized
    }

    // ============ MINTING ============

    /**
     * @dev Mint a Genesis Pass NFT
     * @param to Address to mint the NFT to
     */
    function mint(address to) external payable nonReentrant {
        require(mintingEnabled, "Minting is disabled");
        require(msg.value >= mintPrice, "Insufficient payment");
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        require(!_hasMinted[to], "Address already minted");

        uint256 tokenId = _nextTokenId++;
        _hasMinted[to] = true;

        // Initialize pass data
        _passData[tokenId] = PassData({
            points: 0,
            tokensClaimed: false,
            accessLevel: 0, // Default: Genesis level
            airdropEligible: false,
            airdropMultiplier: 100 // Default: 1x
        });

        _safeMint(to, tokenId);

        // Refund excess payment
        if (msg.value > mintPrice) {
            payable(to).transfer(msg.value - mintPrice);
        }

        emit Minted(to, tokenId, mintPrice);
    }

    // ============ TOKEN ALLOCATION ============

    /**
     * @dev Claim 100 BlockAI ecosystem tokens for a Genesis Pass
     * @param tokenId The token ID to claim tokens for
     */
    function claimTokens(uint256 tokenId) external {
        require(tokenClaimEnabled, "Token claiming is disabled");
        require(_ownerOf(tokenId) == msg.sender, "Not token owner");
        require(!_passData[tokenId].tokensClaimed, "Tokens already claimed");

        _passData[tokenId].tokensClaimed = true;

        emit TokensClaimed(tokenId, msg.sender);
    }

    // ============ POINTS SYSTEM ============

    /**
     * @dev Award points to a specific token (owner-controlled)
     * @param tokenId The token ID to award points to
     * @param points The amount of points to award
     */
    function awardPoints(uint256 tokenId, uint256 points) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        address tokenOwner = _ownerOf(tokenId);
        _passData[tokenId].points += points;
        _walletPoints[tokenOwner] += points;

        emit PointsAwarded(tokenId, points, _passData[tokenId].points);
    }

    /**
     * @dev Batch award points to multiple tokens (gas efficient)
     * @param tokenIds Array of token IDs
     * @param pointsArray Array of points to award (must match tokenIds length)
     */
    function batchAwardPoints(uint256[] calldata tokenIds, uint256[] calldata pointsArray) external onlyOwner {
        require(tokenIds.length == pointsArray.length, "Arrays length mismatch");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_ownerOf(tokenIds[i]) != address(0), "Token does not exist");

            address tokenOwner = _ownerOf(tokenIds[i]);
            _passData[tokenIds[i]].points += pointsArray[i];
            _walletPoints[tokenOwner] += pointsArray[i];

            emit PointsAwarded(tokenIds[i], pointsArray[i], _passData[tokenIds[i]].points);
        }
    }

    // ============ ACCESS CONTROL ============

    /**
     * @dev Set access level for a token (tiered structure)
     * @param tokenId The token ID
     * @param level The access level (0 = Genesis, 1 = Alpha, extensible)
     */
    function setAccessLevel(uint256 tokenId, uint256 level) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        _passData[tokenId].accessLevel = level;

        emit AccessLevelUpdated(tokenId, level);
    }

    /**
     * @dev Check MVP access level for a token
     * @param tokenId The token ID
     * @return level The access level
     */
    function checkAccess(uint256 tokenId) external view returns (uint256) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return _passData[tokenId].accessLevel;
    }

    // ============ AIRDROP SYSTEM ============

    /**
     * @dev Set airdrop eligibility for a token
     * @param tokenId The token ID
     * @param eligible Whether the token is eligible for airdrop
     * @param multiplier The airdrop multiplier (100 = 1x, 200 = 2x, etc.)
     */
    function setAirdropEligibility(uint256 tokenId, bool eligible, uint256 multiplier) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(multiplier >= 100, "Multiplier must be at least 100 (1x)");

        _passData[tokenId].airdropEligible = eligible;
        _passData[tokenId].airdropMultiplier = multiplier;

        emit AirdropEligibilityUpdated(tokenId, eligible, multiplier);
    }

    /**
     * @dev Batch set airdrop eligibility (gas efficient)
     * @param tokenIds Array of token IDs
     * @param eligibleArray Array of eligibility statuses
     * @param multiplierArray Array of multipliers
     */
    function batchSetAirdropEligibility(
        uint256[] calldata tokenIds,
        bool[] calldata eligibleArray,
        uint256[] calldata multiplierArray
    ) external onlyOwner {
        require(
            tokenIds.length == eligibleArray.length && tokenIds.length == multiplierArray.length,
            "Arrays length mismatch"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_ownerOf(tokenIds[i]) != address(0), "Token does not exist");
            require(multiplierArray[i] >= 100, "Multiplier must be at least 100 (1x)");

            _passData[tokenIds[i]].airdropEligible = eligibleArray[i];
            _passData[tokenIds[i]].airdropMultiplier = multiplierArray[i];

            emit AirdropEligibilityUpdated(tokenIds[i], eligibleArray[i], multiplierArray[i]);
        }
    }

    /**
     * @dev Check if a token is eligible for airdrop
     * @param tokenId The token ID
     * @return eligible Whether the token is eligible
     * @return multiplier The airdrop multiplier
     */
    function isAirdropEligible(uint256 tokenId) external view returns (bool eligible, uint256 multiplier) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        PassData memory data = _passData[tokenId];
        return (data.airdropEligible, data.airdropMultiplier);
    }

    // ============ VIEW FUNCTIONS ============

    /**
     * @dev Get all pass data for a token
     * @param tokenId The token ID
     * @return points Accumulated points
     * @return tokensClaimed Whether tokens have been claimed
     * @return accessLevel Current access level
     * @return airdropEligible Airdrop eligibility status
     * @return airdropMultiplier Airdrop multiplier
     */
    function getPassData(uint256 tokenId)
        external
        view
        returns (
            uint256 points,
            bool tokensClaimed,
            uint256 accessLevel,
            bool airdropEligible,
            uint256 airdropMultiplier
        )
    {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        PassData memory data = _passData[tokenId];
        return (data.points, data.tokensClaimed, data.accessLevel, data.airdropEligible, data.airdropMultiplier);
    }

    /**
     * @dev Get accumulated points for a token
     * @param tokenId The token ID
     * @return points The accumulated points
     */
    function getPoints(uint256 tokenId) external view returns (uint256) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return _passData[tokenId].points;
    }

    /**
     * @dev Get wallet-level points (for abuse prevention)
     * @param wallet The wallet address
     * @return points The total points across all tokens owned
     */
    function getWalletPoints(address wallet) external view returns (uint256) {
        return _walletPoints[wallet];
    }

    /**
     * @dev Check if an address has minted
     * @param account The address to check
     * @return hasMinted Whether the address has minted
     */
    function hasMinted(address account) external view returns (bool) {
        return _hasMinted[account];
    }

    // ============ OWNER FUNCTIONS ============

    /**
     * @dev Enable or disable minting
     * @param enabled Whether minting should be enabled
     */
    function setMintingEnabled(bool enabled) external onlyOwner {
        mintingEnabled = enabled;
        emit MintingToggled(enabled);
    }

    /**
     * @dev Enable or disable token claiming
     * @param enabled Whether token claiming should be enabled
     */
    function setTokenClaimEnabled(bool enabled) external onlyOwner {
        tokenClaimEnabled = enabled;
        emit TokenClaimToggled(enabled);
    }

    /**
     * @dev Update mint price
     * @param newPrice The new mint price in wei
     */
    function setMintPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be greater than 0");
        mintPrice = newPrice;
        emit MintPriceUpdated(newPrice);
    }

    /**
     * @dev Reset mint restriction for an address (for special cases)
     * @param account The address to reset
     */
    function resetMintRestriction(address account) external onlyOwner {
        _hasMinted[account] = false;
    }

    /**
     * @dev Withdraw contract funds
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    // ============ OVERRIDES ============

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

