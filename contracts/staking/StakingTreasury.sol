pragma solidity ^0.6.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingTreasury is Ownable {
    function allowClaiming(IERC20 _rewardToken) external onlyOwner {
        _rewardToken.approve(this.owner(), 100000000 ether);
    }
}
