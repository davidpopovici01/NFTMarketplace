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


    function setUp() public virtual {
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
}

contract TicketNFTBalanceTest is BaseTicketNFTTest {

    function testBalanceOf() public {
        assertEq(ticketNFT.balanceOf(alice), 0);
        assertEq(ticketNFT.balanceOf(bob), 0);
        assertEq(ticketNFT.balanceOf(colin), 0);
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
    }    
}

contract TicketNFTHolderTest is BaseTicketNFTTest{
    
    function testHolderOf() public {
        assertEq(ticketNFT.holderOf(1), address(0));
        assertEq(ticketNFT.holderOf(2), address(0));
        assertEq(ticketNFT.holderOf(3), address(0));
        vm.startPrank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        ticketNFT.mint(bob, "bob");
        ticketNFT.mint(alice, "alice");
        ticketNFT.mint(colin, "colin");
        ticketNFT.mint(alice, "alice");
        vm.stopPrank();
        assertEq(ticketNFT.holderOf(1), alice);
        assertEq(ticketNFT.holderOf(2), bob);
        assertEq(ticketNFT.holderOf(3), alice);
        assertEq(ticketNFT.holderOf(4), colin);
        assertEq(ticketNFT.holderOf(5), alice);
    }    

    function testHolderNameOf() public {
        vm.startPrank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
        ticketNFT.mint(bob, "bob");
        ticketNFT.mint(alice, "alice");
        ticketNFT.mint(colin, "colin");
        ticketNFT.mint(alice, "alice");
        vm.stopPrank();
        assertEq(ticketNFT.holderNameOf(1), "alice");
        assertEq(ticketNFT.holderNameOf(2), "bob");
        assertEq(ticketNFT.holderNameOf(3), "alice");
        assertEq(ticketNFT.holderNameOf(4), "colin");
        assertEq(ticketNFT.holderNameOf(5), "alice");
    }

    function TestHolderNameOfTicketDoesNotExist() public {
        vm.expectRevert("Ticket does not exist");
        ticketNFT.holderNameOf(1);
    }
}

contract TicketNFTApproveTest is BaseTicketNFTTest {
    function setUp() public override {
        super.setUp();
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
    }

    function testApproveForNonExistentTicketFails() public {
        uint256 ticketID = 2;
        vm.prank(alice);
        vm.expectRevert("ticket does not exist");
        ticketNFT.approve(bob, ticketID);
    }

    function testOnlyHolderCanApprove() public {
        uint256 ticketID = 1;
        vm.prank(bob);
        vm.expectRevert("caller does not own ticket");
        ticketNFT.approve(bob, ticketID);
    }

    function testApprove() public {
        uint256 ticketID = 1;
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Approval(alice, bob, ticketID);
        ticketNFT.approve(bob, ticketID);

        // Check that the approved is approved
        assertEq(ticketNFT.getApproved(ticketID), bob);
    }
}

contract TicketNFTTransferFromTest is BaseTicketNFTTest {
    function setUp() public override {
        super.setUp();
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
    }
    
    function testTransferToZeroAddressFails() public {
        uint256 ticketID = 1;
        vm.expectRevert("cannot transfer to zero address");
        ticketNFT.transferFrom(alice, address(0), ticketID);
    }

    function testTransferFromZeroAddressFailss() public {
        vm.expectRevert("cannot transfer from zero address");
        uint256 ticketID = 1;
        ticketNFT.transferFrom(address(0), alice, ticketID);
    }

    function testTransferFromTicketDoesNotExistFails() public {
        uint256 ticketID = 2;
        vm.expectRevert("ticket does not exist");
        ticketNFT.transferFrom(alice, bob, ticketID);
    }

    function testTransferAsNotHolderAndNotApprovedFails() public {
        uint256 ticketID = 1;
        vm.prank(colin);
        vm.expectRevert(
            "ticket is neither owned by sender nor approved for transfer"
        );
        ticketNFT.transferFrom(colin, bob, ticketID);
    }

    function testTransferAsHolder() public {
        uint256 ticketID = 1;
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Transfer(alice, bob, ticketID);
        ticketNFT.transferFrom(alice, bob, ticketID);
        assertEq(ticketNFT.balanceOf(alice), 0);
        assertEq(ticketNFT.balanceOf(bob), 1);
        assertEq(ticketNFT.holderOf(ticketID), bob);
        assertEq(ticketNFT.getApproved(ticketID), address(0));
    }

    function testTransferAsApproved() public {
        uint256 ticketID = 1;
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Approval(alice, bob, ticketID);
        ticketNFT.approve(bob, ticketID);

        vm.prank(bob);
        vm.expectEmit(true, true, true, true);
        emit Transfer(alice, bob, ticketID);
        ticketNFT.transferFrom(alice, bob, ticketID);
        assertEq(ticketNFT.balanceOf(alice), 0);
        assertEq(ticketNFT.balanceOf(bob), 1);
        assertEq(ticketNFT.holderOf(ticketID), bob);
        assertEq(ticketNFT.getApproved(ticketID), address(0));
    }

}

contract TicketNFTSetUsedTest is BaseTicketNFTTest {
    function setUp() public override {
        super.setUp();
        vm.prank(address(primaryMarket));
        ticketNFT.mint(alice, "alice");
    }

    function testSetUsedAsNotAdminFails() public {
        uint256 ticketID = 1;
        vm.prank(colin);
        vm.expectRevert("caller not the admin of the primary market");
        ticketNFT.setUsed(ticketID);
    }

        function testSetUsedForExpiredTicketFails() public {
        uint256 ticketID = 1;
        vm.warp(11 days);

        vm.expectRevert("ticket expired");
        vm.prank(admin);
        ticketNFT.setUsed(ticketID);
    }

    function testSetUsedForUsedTicketFails() public {
        uint256 ticketID = 1;
        vm.startPrank(admin);
        ticketNFT.setUsed(ticketID);
        vm.expectRevert("ticket already used");
        ticketNFT.setUsed(ticketID);
        vm.stopPrank();
    }

    function testSetUsedForPrimaryMarketAdmin() public {
        uint256 ticketID = 1;

        vm.prank(admin);
        ticketNFT.setUsed(ticketID);
        assertEq(ticketNFT.isExpiredOrUsed(ticketID), true);
    }

    function testSetUsedForNonExistantTicketFails() public {
        uint256 ticketID = 2;
        vm.expectRevert("ticket does not exist");
        vm.prank(admin);
        ticketNFT.setUsed(ticketID);
    }
}

