// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";
import "../interfaces/IPrimaryMarket.sol";
import "../interfaces/IERC20.sol";
import "./TicketNFT.sol";

contract PrimaryMarket is IPrimaryMarket {
    address public _admin;
    IERC20 public immutable _purchaseToken;
    uint256 public constant TOKEN_PRICE = 100e18;
    uint256 public constant TOKEN_LIMIT = 1000;
    ITicketNFT public _ticketNFT;
    uint256 public minted = 0;

    constructor(IERC20 purchaseToken) {
        _admin = msg.sender;
        _purchaseToken = purchaseToken;
        _ticketNFT = new TicketNFT(address(this));
    }

    function admin() external view returns (address) {
        return _admin;
    }

    function getTicketNFT() external view returns (address) {
        return address(_ticketNFT);
    }

    function purchase(string memory holderName) external {
        require(minted < TOKEN_LIMIT, "no more tickets can be purchased");
        require(
            _purchaseToken.balanceOf(msg.sender) >= TOKEN_PRICE,
            "insufficient balance"
        );
        require(
            _purchaseToken.allowance(msg.sender, address(this)) >= TOKEN_PRICE,
            "insufficient allowance"
        );
        _purchaseToken.transferFrom(msg.sender, _admin, TOKEN_PRICE);
        _ticketNFT.mint(msg.sender, holderName);
        minted += 1;
        emit Purchase(msg.sender, holderName);
    }
}
