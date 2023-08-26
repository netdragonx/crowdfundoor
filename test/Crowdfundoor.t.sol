// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Mock721.sol";
import "../src/Crowdfundoor.sol";

contract CrowdfundoorTest is Test {
    Crowdfundoor public crowdfundoor;
    Mock721 public mock721;
    uint256 public tokenId;

    address public donor1;
    address public donor2;
    address public donor3;
    address public hodler1;
    address public recipient1;
    address public recipient2;

    function setUp() public {
        crowdfundoor = new Crowdfundoor();
        mock721 = new Mock721();
        tokenId = 0;

        donor1 = vm.addr(1);
        donor2 = vm.addr(2);
        donor3 = vm.addr(3);
        hodler1 = vm.addr(4);
        recipient1 = vm.addr(5);
        recipient2 = vm.addr(6);

        mock721.mint(hodler1, 1);

        vm.deal(donor1, 100 ether);
        vm.deal(donor2, 100 ether);
        vm.deal(donor3, 100 ether);
        vm.deal(hodler1, 100 ether);
    }

    function testDonate() public {
        uint256 donationAmount = 1 ether;

        vm.startPrank(donor1);
        crowdfundoor.donate{value: donationAmount}(address(mock721), tokenId, recipient1);

        assertEq(crowdfundoor.donations(address(mock721), tokenId, recipient1), donationAmount);
        assertEq(crowdfundoor.receipts(address(mock721), tokenId, recipient1, donor1), donationAmount);
        assertEq(crowdfundoor.accepted(address(mock721), tokenId, recipient1), false);
    }

    function testDonateMultipleFromOneDonor() public {
        uint256 donationAmount1 = 1 ether;
        uint256 donationAmount2 = 2 ether;

        vm.startPrank(donor1);
        crowdfundoor.donate{value: donationAmount1}(address(mock721), tokenId, recipient1);
        crowdfundoor.donate{value: donationAmount2}(address(mock721), tokenId, recipient1);

        assertEq(crowdfundoor.donations(address(mock721), tokenId, recipient1), donationAmount1 + donationAmount2);
    }

    function testDonateMultipleFromSeparateDonors() public {
        uint256 donationAmount1 = 1 ether;
        uint256 donationAmount2 = 2 ether;

        vm.startPrank(donor1);
        crowdfundoor.donate{value: donationAmount1}(address(mock721), tokenId, recipient1);

        vm.startPrank(donor2);
        crowdfundoor.donate{value: donationAmount2}(address(mock721), tokenId, recipient1);

        vm.startPrank(donor1);
        crowdfundoor.donate{value: donationAmount1}(address(mock721), tokenId, recipient1);

        vm.startPrank(donor2);
        crowdfundoor.donate{value: donationAmount2}(address(mock721), tokenId, recipient1);

        assertEq(
            crowdfundoor.donations(address(mock721), tokenId, recipient1), donationAmount1 * 2 + donationAmount2 * 2
        );
    }

    function testWithdraw() public {
        uint256 donationAmount = 1 ether;

        vm.startPrank(donor1);
        crowdfundoor.donate{value: donationAmount}(address(mock721), tokenId, recipient1);
        crowdfundoor.withdraw(address(mock721), tokenId, recipient1);

        assertEq(crowdfundoor.donations(address(mock721), tokenId, recipient1), 0);
        assertEq(crowdfundoor.donations(address(mock721), tokenId, donor1), 0);
    }

    function testAccept() public {
        uint256 donationAmount = 1 ether;

        vm.startPrank(donor1);
        crowdfundoor.donate{value: donationAmount}(address(mock721), tokenId, recipient1);

        vm.startPrank(hodler1);
        mock721.approve(address(crowdfundoor), tokenId);
        crowdfundoor.accept(address(mock721), tokenId, recipient1, donationAmount);

        assertEq(crowdfundoor.donations(address(mock721), tokenId, recipient1), 0);
        assertEq(mock721.ownerOf(tokenId), recipient1);
    }

    function testFailAcceptDueToMinimumNotMet() public {
        uint256 donationAmount = 1 ether;
        uint256 minimumAmount = 3 ether;

        vm.prank(donor1);
        crowdfundoor.donate{value: donationAmount}(address(mock721), tokenId, recipient1);

        vm.prank(donor2);
        crowdfundoor.donate{value: donationAmount}(address(mock721), tokenId, recipient1);

        vm.prank(donor3);
        crowdfundoor.donate{value: donationAmount}(address(mock721), tokenId, recipient1);

        vm.prank(hodler1);
        mock721.approve(address(crowdfundoor), tokenId);

        vm.prank(donor3);
        crowdfundoor.withdraw(address(mock721), tokenId, recipient1);

        vm.prank(hodler1);
        crowdfundoor.accept(address(mock721), tokenId, recipient1, minimumAmount);
    }

    function testRedonationAfterWithdrawal() public {
        uint256 donationAmount = 2 ether;
        uint256 redonationAmount = 1 ether;

        vm.startPrank(donor1);
        crowdfundoor.donate{value: donationAmount}(address(mock721), tokenId, recipient1);
        crowdfundoor.withdraw(address(mock721), tokenId, recipient1);
        crowdfundoor.donate{value: redonationAmount}(address(mock721), tokenId, recipient1);

        assertEq(crowdfundoor.donations(address(mock721), tokenId, recipient1), redonationAmount);
        assertEq(crowdfundoor.receipts(address(mock721), tokenId, recipient1, donor1), redonationAmount);
    }

    function testDifferentRecipientsSameToken() public {
        uint256 donationAmount1 = 1 ether;
        uint256 donationAmount2 = 2 ether;

        vm.startPrank(donor1);
        crowdfundoor.donate{value: donationAmount1}(address(mock721), tokenId, recipient1);

        vm.startPrank(donor2);
        crowdfundoor.donate{value: donationAmount2}(address(mock721), tokenId, recipient2);

        assertEq(crowdfundoor.accepted(address(mock721), tokenId, recipient1), false);
    }

    function testChangeRecipientAfterSignificantDonation() public {
        uint256 donationAmount1 = 10 ether;
        uint256 donationAmount2 = 1 ether;

        vm.startPrank(donor1);
        crowdfundoor.donate{value: donationAmount1}(address(mock721), tokenId, recipient1);

        vm.startPrank(donor3);
        crowdfundoor.donate{value: donationAmount2}(address(mock721), tokenId, recipient2);

        assertEq(crowdfundoor.donations(address(mock721), tokenId, recipient1), donationAmount1);
        assertEq(crowdfundoor.donations(address(mock721), tokenId, recipient2), donationAmount2);
    }

    function testWithdrawAndRedonateDifferentRecipient() public {
        uint256 donationAmount = 2 ether;
        uint256 redonationAmount = 1 ether;

        vm.startPrank(donor1);

        crowdfundoor.donate{value: donationAmount}(address(mock721), tokenId, recipient1);
        assertEq(crowdfundoor.donations(address(mock721), tokenId, recipient1), donationAmount);

        crowdfundoor.withdraw(address(mock721), tokenId, recipient1);
        crowdfundoor.donate{value: redonationAmount}(address(mock721), tokenId, recipient2);

        assertEq(crowdfundoor.donations(address(mock721), tokenId, recipient1), 0);
        assertEq(crowdfundoor.donations(address(mock721), tokenId, recipient2), redonationAmount);
    }
}
