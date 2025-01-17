// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";
import "../interfaces/IPrimaryMarket.sol";

contract TicketNFT is ITicketNFT {
    uint256 public lastID;
    IPrimaryMarket _primaryMarket;
    uint256 immutable EXPIRY_TIME = 10 days;

    struct TicketMeta {
        uint256 ID;
        string holderName;
        uint256 timestamp;
        bool used;
    }

    mapping(uint256 => TicketMeta) internal _IDtoOwner;
    mapping(uint256 => address) internal _owner;
    mapping(address => uint256) internal _balance;
    mapping(uint256 => address) internal _approved;

    constructor(address primaryMarket){
        _primaryMarket = IPrimaryMarket(primaryMarket);
        lastID = 0;
    }

    function mint(address holder, string memory holderName) external {
        require(
            msg.sender == address(_primaryMarket),
            "Tickets can only be minted by the primary market"
        );
        uint256 currID = lastID + 1;
        TicketMeta memory ticket = TicketMeta(
            currID,
            holderName,
            block.timestamp + EXPIRY_TIME,
            false
        );
        _IDtoOwner[currID] = ticket;
        _owner[currID] = holder;
        _balance[holder] += 1;
        lastID = currID;
        emit Transfer(address(0), holder, currID);
    }

    function balanceOf(address holder) external view returns (uint256 balance) {
        return _balance[holder];
    }

    function holderOf(uint256 ticketID) external view returns (address holder) {
        return _owner[ticketID];
    }

    function transferFrom(address from, address to, uint256 ticketID
    ) external {
        require(from != address(0), "cannot transfer from zero address");
        require(to != address(0), "cannot transfer to zero address");
        require(ticketID <= lastID, "ticket does not exist");
        address owner = _owner[ticketID];
        require(
            owner == msg.sender || _approved[ticketID] == msg.sender,
            "ticket is neither owned by sender nor approved for transfer"
        );
        _balance[from] -= 1;
        _owner[ticketID] = to;
        _balance[to] += 1;
        _approved[ticketID] = address(0);
        emit Transfer(from, to, ticketID);
        emit Approval(to, address(0), ticketID);
    }

    function approve(address to, uint256 ticketID) external {
        address owner = _owner[ticketID];
        require(ticketID <= lastID, "ticket does not exist");
        require(owner == msg.sender, "caller does not own ticket");
        _approved[ticketID] = to;
        emit Approval(msg.sender, to, ticketID);
    }

    function getApproved(uint256 ticketID)
        external
        view
        returns (address operator)
    {
        require(ticketID <= lastID, "ticket does not exist");
        return _approved[ticketID];
    }

    function holderNameOf(uint256 ticketID)
        external
        view
        returns (string memory holderName)
    {
        require(ticketID <= lastID, "ticket does not exist");
        return _IDtoOwner[ticketID].holderName;
    }

    function updateHolderName(uint256 ticketID, string calldata newName)
        external
    {
        address owner = _owner[ticketID];
        require(msg.sender == owner, "caller does not own ticket");
        require(ticketID <= lastID, "ticket does not exist");
        _IDtoOwner[ticketID].holderName = newName;
    }

    function setUsed(uint256 ticketID) external {
        require(ticketID <= lastID, "ticket does not exist");
        require(!_IDtoOwner[ticketID].used, "ticket already used");
        require(block.timestamp < _IDtoOwner[ticketID].timestamp, "ticket expired");
        require(msg.sender == _primaryMarket.admin(), "caller not the admin of the primary market");
        _IDtoOwner[ticketID].used = true;
    }

    function isExpiredOrUsed(uint256 ticketID) external view returns (bool) {
        require(ticketID <= lastID, "ticket does not exist");
        return (_IDtoOwner[ticketID].used ||_IDtoOwner[ticketID].timestamp < block.timestamp);
    }

}
