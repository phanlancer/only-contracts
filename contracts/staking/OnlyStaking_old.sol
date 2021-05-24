pragma solidity ^0.6.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./StakingTreasury.sol";

contract OnlyStaking is Ownable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
    }

    struct PoolInfo {
        IERC20 stakingToken;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    // Keeps reward tokens
    StakingTreasury public treasury;

    IERC20 public rewardToken;
    uint256 public rewardPerBlock = 1 * 1e18; // default 1 token
    uint256 public divider = 1e18;

    // base 1000, value * % / 100
    uint256 public feePercent = 0;
    uint256 public collectedFees;

    PoolInfo public liquidityMining;
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event StakingTreasuryCreated(address indexed treasury, address manager);

    constructor() public {
        treasury = new StakingTreasury();
        emit StakingTreasuryCreated(address(treasury), address(this));
    }

    function setDivider(uint256 _divider) external onlyOwner {
        divider = _divider;
    }

    function setPoolInfo(IERC20 _rewardToken, IERC20 _stakingToken) external onlyOwner {
        require(address(rewardToken) == address(0) && address(liquidityMining.stakingToken) == address(0), "Token is already set");
        rewardToken = _rewardToken;
        liquidityMining = PoolInfo({stakingToken : _stakingToken, lastRewardBlock : 0, accRewardPerShare : 0});
        treasury.allowClaiming(_rewardToken);
    }

    function startMining() external onlyOwner {
        require(liquidityMining.lastRewardBlock == 0, "Mining already started");
        liquidityMining.lastRewardBlock = block.number;
    }

    function pendingRewards(address _user) external view returns (uint256) {
        if (liquidityMining.lastRewardBlock == 0 || block.number < liquidityMining.lastRewardBlock) {
            return 0;
        }

        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = liquidityMining.accRewardPerShare;
        uint256 stakingTokenSupply = liquidityMining.stakingToken.balanceOf(address(this));

        if (block.number > liquidityMining.lastRewardBlock && stakingTokenSupply != 0) {
            uint256 perBlock = rewardPerBlock;
            uint256 multiplier = block.number - liquidityMining.lastRewardBlock;
            uint256 reward = multiplier * perBlock;
            accRewardPerShare = accRewardPerShare + (reward * divider / stakingTokenSupply);
        }

        return (user.amount * accRewardPerShare / divider) - user.rewardDebt + user.pendingRewards;
    }

    function updatePool() internal {
        require(liquidityMining.lastRewardBlock > 0 && block.number >= liquidityMining.lastRewardBlock, "Mining not yet started");
        if (block.number <= liquidityMining.lastRewardBlock) {
            return;
        }
        uint256 stakingTokenSupply = liquidityMining.stakingToken.balanceOf(address(this));
        if (stakingTokenSupply == 0) {
            liquidityMining.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number - liquidityMining.lastRewardBlock;
        uint256 tokensReward = multiplier * rewardPerBlock;
        liquidityMining.accRewardPerShare = liquidityMining.accRewardPerShare + (tokensReward * divider / stakingTokenSupply);
        liquidityMining.lastRewardBlock = block.number;
    }

    function deposit(uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();

        uint256 accRewardPerShare = liquidityMining.accRewardPerShare;

        if (user.amount > 0) {
            uint256 pending = (user.amount * accRewardPerShare / divider) - user.rewardDebt;
            if (pending > 0) {
                user.pendingRewards = user.pendingRewards + pending;
            }
        }
        if (amount > 0) {
            liquidityMining.stakingToken.safeTransferFrom(address(msg.sender), address(this), amount);

            if (feePercent > 0) {
                uint256 fee = amount * feePercent / 1000;
                amount = amount - fee;
                collectedFees = collectedFees + fee;
            }

            user.amount = user.amount + amount;
        }
        user.rewardDebt = user.amount * accRewardPerShare / divider;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= amount, "Withdrawing more than you have!");
        updatePool();

        uint256 accRewardPerShare = liquidityMining.accRewardPerShare;

        uint256 pending = (user.amount * accRewardPerShare / divider) - user.rewardDebt;
        if (pending > 0) {
            user.pendingRewards = user.pendingRewards + pending;
        }
        if (amount > 0) {
            user.amount = user.amount - amount;

            if (feePercent > 0) {
                uint256 fee = amount * feePercent / 1000;
                amount = amount - fee;
                collectedFees = collectedFees + fee;
            }

            liquidityMining.stakingToken.safeTransfer(address(msg.sender), amount);
        }
        user.rewardDebt = user.amount * accRewardPerShare / divider;
        emit Withdraw(msg.sender, amount);
    }

    function claim() external {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();

        uint256 accRewardPerShare = liquidityMining.accRewardPerShare;

        uint256 pending = (user.amount * accRewardPerShare / divider) - user.rewardDebt;
        if (pending > 0 || user.pendingRewards > 0) {
            user.pendingRewards = user.pendingRewards + pending;
            uint256 claimedAmount = safeRewardTransfer(msg.sender, user.pendingRewards);
            emit Claim(msg.sender, claimedAmount);
            user.pendingRewards = user.pendingRewards - claimedAmount;
        }
        user.rewardDebt = user.amount * accRewardPerShare / divider;
    }

    function safeRewardTransfer(address to, uint256 amount) internal returns (uint256) {
        uint256 balance = rewardToken.balanceOf(address(treasury));
        require(amount > 0, "Reward amount must be more than zero");
        require(balance >= amount, "Not enough reward tokens");

        rewardToken.safeTransferFrom(address(treasury), to, amount);
        return amount;
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(_rewardPerBlock > 0, "Reward per block should be greater than 0");
        rewardPerBlock = _rewardPerBlock;
    }

    function setFee(uint256 fee) external onlyOwner {
        require(fee >= 0, "Fee is too small");
        require(fee <= 50, "Fee is too big");
        feePercent = fee;
    }

    function withdrawFees(address payable withdrawalAddress) external onlyOwner {
        liquidityMining.stakingToken.safeTransfer(withdrawalAddress, collectedFees);
        collectedFees = 0;
    }
}
