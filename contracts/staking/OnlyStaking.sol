// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title OnlyStaking
 * @author Only
 *
 * ERC20 extended contract for distribute reward per staking. Stake ONLY and get reward as ONLY
 */
contract OnlyStaking is ERC20 {
    using SafeMath for uint256;

    /* ============ Events ============ */

    event Stake(address indexed _staker, uint256 _amount);
    event Withdraw(address indexed _receiver, uint256 _resultAmount);

    /* ============ State Variable ============ */

    address public stakingToken;                            // address of staking token
    mapping(address => uint256) public stakedOf;            // staked amount of each address
    uint256 public totalStaked;                             // total staked amount

    mapping(address => uint256) public rewardAllocationOf;  // reward allocation of each address
    uint256 public totalRewardAllocation;                   // total reward allocation

    /* ============ Constructor ============ */
    /**
     * When the staking contract is created, initializes the contract addresses of staking token and reward token
     *
     * @param _stakingToken           Contract address of staking token
     */
    constructor(address _stakingToken) public ERC20("Staking ONLY", "sONLY") {
        stakingToken = _stakingToken;
    }

    /* ============ Public/External Functions ============ */

    /**
     * Get total amount of reward tokens in the contract
     */
    function getTotalRewardTokens() public view returns (uint256) {
        return IERC20(stakingToken).balanceOf(address(this)) - totalStaked;
    }

    /**
     * Get reward amount of of an address
     *
     * @param _account                  Address to get reward amount
     */
    function rewardOf(address _account) public view returns (uint256) {
        uint256 rewardAllocation = rewardAllocationOf[_account];
        return getTotalRewardTokens().mul(rewardAllocation).div(totalRewardAllocation);
    }

    /**
     * Stake the specified amount of stakingToken. Mint sONLY same as the staked amount
     *
     * @param _amount                   Amount to stake
     */
    function stake(uint256 _amount) public {
        require(
            IERC20(stakingToken).transferFrom(msg.sender, address(this), _amount),
            "transfer failed"
        );

        uint256 currentAllocation = totalRewardAllocation;
        uint256 currentReserve = totalStaked.add(getTotalRewardTokens());

        totalStaked = totalStaked.add(_amount);
        stakedOf[msg.sender] = stakedOf[msg.sender].add(_amount);

        // calculate allocation for the staking amount
        if (currentAllocation == 0) {
            rewardAllocationOf[msg.sender] = _amount;
            totalRewardAllocation = totalRewardAllocation.add(_amount);
        } else {
            uint256 allocationAmount = _amount.mul(currentAllocation).div(currentReserve);
            rewardAllocationOf[msg.sender] = rewardAllocationOf[msg.sender].add(allocationAmount);
            totalRewardAllocation = totalRewardAllocation.add(allocationAmount);
        }
        // mint sONLY
        _mint(msg.sender, _amount);

        emit Stake(msg.sender, _amount);
    }

    /**
     * Withraw all the staked tokens and claim reward tokens. Burn sONLY
     */
    function withdraw() public {
        uint256 stakedAmount = stakedOf[msg.sender];
        require(stakedAmount >= 0, "nothing to withdraw");

        uint256 resultAmount = rewardOf(msg.sender).add(stakedAmount);

        // remove staked amount
        totalStaked = totalStaked.sub(stakedAmount);
        stakedOf[msg.sender] = 0;
        // remove reward allocation
        uint256 rewardAllocation = rewardAllocationOf[msg.sender];
        totalRewardAllocation = totalRewardAllocation.sub(rewardAllocation);
        rewardAllocationOf[msg.sender] = 0;
        // withdraw staked token
        IERC20(stakingToken).transfer(msg.sender, resultAmount);
        // burn sONLY
        _burn(msg.sender, stakedAmount);

        emit Withdraw(msg.sender, resultAmount);
    }
}
