// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";
import "../interfaces/IPrimaryMarket.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ISecondaryMarket.sol";
import "./TicketNFT.sol";

contract SecondaryMarket is ISecondaryMarket {
    IPrimaryMarket public _primaryMarket;
    IERC20 public _purchaseToken;
    ITicketNFT public _ticketNFT;
    uint8 public immutable PURCHASE_FEE_PERCENT = 5;

    constructor(address primaryMarket, IERC20 purchaseToken) {
        _primaryMarket = IPrimaryMarket(primaryMarket);
        _purchaseToken = IERC20(purchaseToken);
        _ticketNFT = ITicketNFT(_primaryMarket.getTicketNFT());
    }

    struct TicketMeta {
        address holder;
        uint256 price;
    }

    mapping(uint256 => TicketMeta) public _listing;

    function listTicket(uint256 ticketID, uint256 price) external {
        require(
            _ticketNFT.holderOf(ticketID) == msg.sender,
            "only the ticket holder can list the ticket"
        );
        require(
            !_ticketNFT.isExpiredOrUsed(ticketID),
            "ticket is expired or used");
        require(
            _listing[ticketID].holder == address(0),
            "ticket is already listed"
        );
        _listing[ticketID] = TicketMeta(msg.sender, price);
        _ticketNFT.transferFrom(msg.sender, address(this), ticketID);
        emit Listing(ticketID, msg.sender, price);
    }

    function delistTicket(uint256 ticketID) external {
        require(
            _listing[ticketID].holder != address(0),
            "ticket is not listed"
        );
        require(
            _listing[ticketID].holder == msg.sender,
            "only the ticket holder can delist the ticket"
        );
        _ticketNFT.transferFrom(address(this), msg.sender, ticketID);
        delete _listing[ticketID];
        emit Delisting(ticketID);
    }

    function purchase(uint256 ticketID, string calldata name) external {
        TicketMeta memory listing = _listing[ticketID];
        require(
            _listing[ticketID].holder != address(0),
            "ticket is not listed"
        );
        require(
            !_ticketNFT.isExpiredOrUsed(ticketID),
            "ticket is expired or used");
        require(
            _purchaseToken.balanceOf(msg.sender) >= listing.price,
            "insufficient balance"
        );
        require(_purchaseToken.allowance(msg.sender, address(this)) >= listing.price,
            "insufficient allowance"
        );
        uint256 fee = listing.price * PURCHASE_FEE_PERCENT / 100;
        uint256 price = listing.price - fee;
        _purchaseToken.transferFrom(msg.sender, listing.holder, price);
        _purchaseToken.transferFrom(msg.sender, _primaryMarket.admin(), fee);
        _ticketNFT.updateHolderName(ticketID, name);
        _ticketNFT.transferFrom(address(this), msg.sender, ticketID);
        delete _listing[ticketID];
        emit Purchase(msg.sender, ticketID, listing.price, name);
    }
}
