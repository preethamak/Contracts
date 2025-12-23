// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// Import all contracts
import "../src/Token.sol";

contract Deploy is Script {
    function run() public {
        // Start broadcasting transactions
        vm.startBroadcast();

        // 1. Deploy Token
        console.log("Deploying ProtoToken...");
        ProtoToken token = new ProtoToken();
        console.log("ProtoToken deployed at:", address(token));

        // 2. Deploy Staking
        console.log("Deploying ProtoStaking...");
        ProtoStaking staking = new ProtoStaking(address(token));
        console.log("ProtoStaking deployed at:", address(staking));

        // 3. Deploy Vesting
        console.log("Deploying ProtoVesting...");
        ProtoVesting vesting = new ProtoVesting(address(token));
        console.log("ProtoVesting deployed at:", address(vesting));

        // 4. Create vesting schedules
        console.log("Creating vesting schedules...");
        vesting.createVestingSchedule(
            0x1111111111111111111111111111111111111111, // Team address (placeholder)
            25 * 10 ** 18, // 25 tokens
            365 // 365 days
        );
        vesting.createVestingSchedule(
            0x2222222222222222222222222222222222222222, // Investor address (placeholder)
            35 * 10 ** 18, // 35 tokens
            180 // 180 days
        );
        vesting.createVestingSchedule(
            0x3333333333333333333333333333333333333333, // Partners address (placeholder)
            20 * 10 ** 18, // 20 tokens
            90 // 90 days
        );

        // 5. Deploy Governor (Simplified voting contract)
        console.log("Deploying ProtoGovernor...");
        ProtoGovernor governor = new ProtoGovernor(address(token));
        console.log("ProtoGovernor deployed at:", address(governor));

        // 6. Deploy NFT
        console.log("Deploying ProtoNFT...");
        ProtoNFT nft = new ProtoNFT(address(token));
        console.log("ProtoNFT deployed at:", address(nft));

        // 7. Deploy Subscription
        console.log("Deploying ProtoSubscription...");
        ProtoSubscription subscription = new ProtoSubscription(address(token));
        console.log("ProtoSubscription deployed at:", address(subscription));

        // 8. Deploy Registry
        console.log("Deploying ProtoAgentRegistry...");
        ProtoAgentRegistry registry = new ProtoAgentRegistry();
        console.log("ProtoAgentRegistry deployed at:", address(registry));

        // 9. Transfer tokens to contracts for rewards
        console.log("Transferring tokens to staking pool...");
        token.transfer(address(staking), 50 * 10 ** 18); // 50 tokens for rewards

        console.log("Transferring tokens to vesting...");
        token.transfer(address(vesting), 80 * 10 ** 18); // 80 tokens for vesting (25+35+20)

        // Stop broadcasting
        vm.stopBroadcast();

        // Log summary
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("ProtoToken:", address(token));
        console.log("ProtoStaking:", address(staking));
        console.log("ProtoVesting:", address(vesting));
        console.log("ProtoGovernor:", address(governor));
        console.log("ProtoNFT:", address(nft));
        console.log("ProtoSubscription:", address(subscription));
        console.log("ProtoAgentRegistry:", address(registry));
        console.log("===========================\n");
    }
}

/// ============================================================================
/// PROTO GOVERNOR (Simplified Token-Based Voting)
/// ============================================================================

contract ProtoGovernor {
    IERC20 public token;
    address public owner;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startBlock;
        uint256 endBlock;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    uint256 public constant VOTING_PERIOD = 1 days;
    uint256 public constant QUORUM_PERCENTAGE = 10;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description
    );
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support
    );
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }

    /// @notice Create a proposal
    function createProposal(string memory description) external {
        require(
            token.balanceOf(msg.sender) >= 1 * 10 ** 18,
            "Need at least 1 token to propose"
        );

        uint256 proposalId = proposalCount++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.startBlock = block.timestamp;
        newProposal.endBlock = block.timestamp + VOTING_PERIOD;

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /// @notice Vote on a proposal
    function castVote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];

        require(
            block.timestamp < proposal.endBlock,
            "Voting period ended"
        );
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(
            token.balanceOf(msg.sender) > 0,
            "Must hold tokens to vote"
        );

        uint256 votes = token.balanceOf(msg.sender);
        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }

        emit VoteCast(proposalId, msg.sender, support);
    }

    /// @notice Check if proposal passed
    function proposalPassed(uint256 proposalId) public view returns (bool) {
        Proposal storage proposal = proposals[proposalId];

        require(
            block.timestamp >= proposal.endBlock,
            "Voting still ongoing"
        );

        // Need majority and quorum
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 quorum = (token.balanceOf(address(this)) * QUORUM_PERCENTAGE) /
            100;

        return proposal.forVotes > proposal.againstVotes &&
            totalVotes >= quorum;
    }

    /// @notice Execute a passed proposal (owner only)
    function executeProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];

        require(!proposal.executed, "Already executed");
        require(proposalPassed(proposalId), "Proposal did not pass");

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    /// @notice Get proposal details
    function getProposal(uint256 proposalId)
        external
        view
        returns (
            address proposer,
            string memory description,
            uint256 forVotes,
            uint256 againstVotes,
            bool executed
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.executed
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}