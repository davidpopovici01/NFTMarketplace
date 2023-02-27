// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/PrimaryMarket.sol"; 
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/TicketNFT.sol";

contract BaseTicketNFTTest is Test {
    PrimaryMarket primaryMarket;
    PurchaseToken purchaseToken;
    TicketNFT ticketNFT;

    address public admin = makeAddr("admin");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public colin = makeAddr("colin");

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed ticketID
    );

    event Approval(
        address indexed holder,
        address indexed approved,
        uint256 indexed ticketID
    );


    function setUp() public {
        purchaseToken = new PurchaseToken();
        vm.prank(admin);
        primaryMarket = new PrimaryMarket(purchaseToken);
        ticketNFT = new TicketNFT(address(primaryMarket));
    }
}

contract TicketNFTMintTest is BaseTicketNFTTest {

    function testMintAsAdmin() public {
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
    }

    function testMintAsNonAdmin() public {
        vm.prank(alice);
        vm.expectRevert("Tickets can only be minted by the primary market");
        ticketNFT.mint(alice, "alice");
    }

    function testMintMultipleAsAdmin() public {
        vm.startPrank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        ticketNFT.mint(bob, "bob");
        ticketNFT.mint(alice, "alice");
        ticketNFT.mint(colin, "colin");
        ticketNFT.mint(alice, "alice");
        vm.stopPrank();
        assertEq(ticketNFT.balanceOf(alice), 3);
        assertEq(ticketNFT.balanceOf(bob), 1);
        assertEq(ticketNFT.balanceOf(colin), 1);
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderOf(3), alice);
        assertEq(ticketNFT.holderOf(5), alice);
        assertEq(ticketNFT.holderOf(2), bob);
        assertEq(ticketNFT.holderOf(4), colin);
    }
}
