// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TrusterHelper {
    function getCalldata(address _player, uint256 _amount) public pure returns (bytes memory data) {
        data = abi.encodeWithSelector(IERC20.approve.selector, _player, _amount);
        return data;
    }
}
