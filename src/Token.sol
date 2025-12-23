// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/* ===================== OZ IMPORTS (v5.x) ===================== */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/* ============================================================= */
/* 1. PROTO TOKEN (ERC20)                                        */
/* ============================================================= */
contract ProtoToken is ERC20, Ownable, Pausable {
    constructor()
        ERC20("Protocol Token", "PROTO")
        Ownable(msg.sender)
    {
        _mint(msg.sender, 100 * 10 ** 18);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /* OZ v5 hook */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._update(from, to, amount);
    }
}

/* ============================================================= */
/* 2. PROTO STAKING                                              */
/* ============================================================= */
contract ProtoStaking is Ownable {
    IERC20 public protoToken;

    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public lastRewardTime;
    mapping(address => uint256) public rewardsEarned;

    uint256 public totalStaked;
    uint256 public rewardRatePerSecond = 1157407407407407;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(address _protoToken) Ownable(msg.sender) {
        protoToken = IERC20(_protoToken);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(
            protoToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        _updateRewards(msg.sender);

        stakedAmount[msg.sender] += amount;
        totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(stakedAmount[msg.sender] >= amount, "Insufficient stake");

        _updateRewards(msg.sender);

        stakedAmount[msg.sender] -= amount;
        totalStaked -= amount;

        require(protoToken.transfer(msg.sender, amount), "Transfer failed");

        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external {
        _updateRewards(msg.sender);

        uint256 rewards = rewardsEarned[msg.sender];
        require(rewards > 0, "No rewards");

        rewardsEarned[msg.sender] = 0;
        require(protoToken.transfer(msg.sender, rewards), "Transfer failed");

        emit RewardClaimed(msg.sender, rewards);
    }

    function getPendingRewards(address user)
        external
        view
        returns (uint256)
    {
        if (stakedAmount[user] == 0) return rewardsEarned[user];

        uint256 timePassed = block.timestamp - lastRewardTime[user];
        uint256 reward = (stakedAmount[user] *
            rewardRatePerSecond *
            timePassed) / totalStaked;

        return rewardsEarned[user] + reward;
    }

    function _updateRewards(address user) internal {
        if (lastRewardTime[user] == 0) {
            lastRewardTime[user] = block.timestamp;
            return;
        }

        uint256 timePassed = block.timestamp - lastRewardTime[user];
        if (timePassed > 0 && stakedAmount[user] > 0 && totalStaked > 0) {
            uint256 reward = (stakedAmount[user] *
                rewardRatePerSecond *
                timePassed) / totalStaked;
            rewardsEarned[user] += reward;
        }

        lastRewardTime[user] = block.timestamp;
    }

    function setRewardRate(uint256 newRate) external onlyOwner {
        rewardRatePerSecond = newRate;
    }

    function withdrawRewardPool(uint256 amount) external onlyOwner {
        require(protoToken.transfer(msg.sender, amount), "Transfer failed");
    }
}

/* ============================================================= */
/* 3. PROTO VESTING                                              */
/* ============================================================= */
contract ProtoVesting is Ownable {
    IERC20 public protoToken;

    struct VestingSchedule {
        address beneficiary;
        uint256 totalAmount;
        uint256 startTime;
        uint256 duration;
        uint256 claimedAmount;
    }

    VestingSchedule[] public vestingSchedules;
    mapping(address => uint256[]) public userSchedules;

    event VestingScheduleCreated(
        address indexed beneficiary,
        uint256 amount,
        uint256 duration
    );
    event TokensClaimed(address indexed beneficiary, uint256 amount);

    constructor(address _protoToken) Ownable(msg.sender) {
        protoToken = IERC20(_protoToken);
    }

    function createVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 durationDays
    ) external onlyOwner {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(totalAmount > 0, "Invalid amount");

        vestingSchedules.push(
            VestingSchedule({
                beneficiary: beneficiary,
                totalAmount: totalAmount,
                startTime: block.timestamp,
                duration: durationDays * 1 days,
                claimedAmount: 0
            })
        );

        userSchedules[beneficiary].push(vestingSchedules.length - 1);

        emit VestingScheduleCreated(
            beneficiary,
            totalAmount,
            durationDays * 1 days
        );
    }

    function claimVestedTokens(uint256 index) external {
        VestingSchedule storage s = vestingSchedules[index];
        require(s.beneficiary == msg.sender, "Not beneficiary");

        uint256 vested = getVestedAmount(index);
        uint256 claimable = vested - s.claimedAmount;
        require(claimable > 0, "Nothing to claim");

        s.claimedAmount += claimable;
        require(protoToken.transfer(msg.sender, claimable), "Transfer failed");

        emit TokensClaimed(msg.sender, claimable);
    }

    function getVestedAmount(uint256 index)
        public
        view
        returns (uint256)
    {
        VestingSchedule memory s = vestingSchedules[index];
        if (block.timestamp <= s.startTime) return 0;

        uint256 elapsed = block.timestamp - s.startTime;
        if (elapsed >= s.duration) return s.totalAmount;

        return (s.totalAmount * elapsed) / s.duration;
    }
}

/* ============================================================= */
/* 4. PROTO NFT (ERC721)                                         */
/* ============================================================= */
contract ProtoNFT is ERC721, ERC721Enumerable, Ownable {
    IERC20 public protoToken;
    uint256 public nextTokenId = 1;
    uint256 public mintPrice = 1e18;

    mapping(uint256 => string) public tokenMetadata;

    event NFTMinted(address indexed to, uint256 tokenId);

    constructor(address _protoToken)
        ERC721("Protocol Identity", "PROTO-ID")
        Ownable(msg.sender)
    {
        protoToken = IERC20(_protoToken);
    }

    function mint(string memory metadata) external returns (uint256) {
        require(
            protoToken.transferFrom(msg.sender, address(this), mintPrice),
            "Payment failed"
        );

        uint256 tokenId = nextTokenId++;
        _safeMint(msg.sender, tokenId);
        tokenMetadata[tokenId] = metadata;

        emit NFTMinted(msg.sender, tokenId);
        return tokenId;
    }

    function setMetadata(uint256 tokenId, string memory metadata)
        external
        onlyOwner
    {
        tokenMetadata[tokenId] = metadata;
    }

    function withdrawFees(uint256 amount) external onlyOwner {
        require(protoToken.transfer(msg.sender, amount), "Transfer failed");
    }

    /* REQUIRED v5 overrides */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

/* ============================================================= */
/* 5. PROTO SUBSCRIPTION                                         */
/* ============================================================= */
contract ProtoSubscription is Ownable {
    IERC20 public protoToken;

    uint256 public subscriptionPrice = 5e18;
    uint256 public subscriptionDuration = 30 days;

    mapping(address => uint256) public subscriptionExpiry;

    event SubscriptionCreated(address indexed user, uint256 expiry);

    constructor(address _protoToken) Ownable(msg.sender) {
        protoToken = IERC20(_protoToken);
    }

    function subscribe() external {
        require(
            protoToken.transferFrom(
                msg.sender,
                address(this),
                subscriptionPrice
            ),
            "Payment failed"
        );

        subscriptionExpiry[msg.sender] =
            block.timestamp +
            subscriptionDuration;

        emit SubscriptionCreated(
            msg.sender,
            subscriptionExpiry[msg.sender]
        );
    }

    function isSubscribed(address user) external view returns (bool) {
        return subscriptionExpiry[user] > block.timestamp;
    }

    function withdrawFees(uint256 amount) external onlyOwner {
        require(protoToken.transfer(msg.sender, amount), "Transfer failed");
    }
}

/* ============================================================= */
/* 6. PROTO AGENT REGISTRY                                       */
/* ============================================================= */
contract ProtoAgentRegistry is Ownable {
    struct Agent {
        address agentAddress;
        string name;
        string description;
        string category;
        bool active;
        uint256 registeredAt;
    }

    Agent[] public agents;
    mapping(address => uint256[]) public userAgents;
    mapping(address => bool) public isRegisteredAgent;

    event AgentRegistered(address agent, string name, string category);
    event AgentDeactivated(address agent);

    constructor() Ownable(msg.sender) {}

    function registerAgent(
        address agentAddress,
        string memory name,
        string memory description,
        string memory category
    ) external {
        require(!isRegisteredAgent[agentAddress], "Already registered");

        agents.push(
            Agent({
                agentAddress: agentAddress,
                name: name,
                description: description,
                category: category,
                active: true,
                registeredAt: block.timestamp
            })
        );

        userAgents[msg.sender].push(agents.length - 1);
        isRegisteredAgent[agentAddress] = true;

        emit AgentRegistered(agentAddress, name, category);
    }

    function deactivateAgent(uint256 index) external {
        Agent storage a = agents[index];
        require(
            msg.sender == a.agentAddress || msg.sender == owner(),
            "Not allowed"
        );
        a.active = false;
        emit AgentDeactivated(a.agentAddress);
    }
}
