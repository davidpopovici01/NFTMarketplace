// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/PrimaryMarket.sol"; 
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/TicketNFT.sol";

contract BasePrimaryMarketTest is Test {
    PrimaryMarket primaryMarket;
    PurchaseToken purchaseToken;
    TicketNFT ticketNFT;

    address public admin = makeAddr("admin");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public colin = makeAddr("colin");

    event Purchase(
        address indexed holder,
         string indexed holderName
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function setUp() public virtual {
        purchaseToken = new PurchaseToken();
        vm.prank(admin);
        primaryMarket = new PrimaryMarket(purchaseToken);
        // vm.deal(alice, 1_000 ether);
        // vm.prank(alice);
        // purchaseToken.mint{value: 1_000 ether};
    }
}

contract PrimaryMarketTest is BasePrimaryMarketTest {
    
        function testAdmin() public {
            assertEq(primaryMarket.admin(), admin);
        }
    
        function testPurchase() public {
            assertEq(purchaseToken.balanceOf(alice), 0);
            vm.deal(alice, 100e18);
            vm.startPrank(alice);
            purchaseToken.approve(address(primaryMarket), 100e18);
            purchaseToken.mint{value : 100e18}();

            vm.expectEmit(true, true, true, true);
            emit Purchase(alice, "alice");

            primaryMarket.purchase("alice");
            vm.stopPrank();
            assertEq(primaryMarket._ticketNFT().holderNameOf(1), "alice");
        }
    
        function testPurchaseWithNoAllowance() public {
            vm.deal(alice, 100e18);
            vm.startPrank(alice);
            purchaseToken.approve(address(primaryMarket), 50e18);
            purchaseToken.mint{value : 100e18}();
            vm.expectRevert("insufficient allowance");
            primaryMarket.purchase("alice");
        }

        function testPurchaseWithNoBalance() public {
            vm.deal(bob, 50e18);
            purchaseToken.approve(address(primaryMarket), 100e18);
            vm.prank(bob);
            vm.expectRevert("insufficient balance");
            primaryMarket.purchase("bob");
        }
    
        function testPurchaseWithNoMoreTickets() public {
            vm.startPrank(alice);
            for (uint256 i = 0; i < 1000; i++) {
                vm.deal(alice, 1_000 ether);
                purchaseToken.approve(address(primaryMarket), 100e18);
                purchaseToken.mint{value : 100e18}();
                primaryMarket.purchase("alice");
            }
            vm.expectRevert("no more tickets can be purchased");
            primaryMarket.purchase("alice");
            vm.stopPrank();
        }
}

