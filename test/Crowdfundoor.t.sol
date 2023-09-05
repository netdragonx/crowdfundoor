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

    uint256 initialBalance = 100 ether;

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

        vm.deal(donor1, initialBalance);
        vm.deal(donor2, initialBalance);
        vm.deal(donor3, initialBalance);
        vm.deal(hodler1, initialBalance);
    }

    // for test mapping reference:
    //
    // struct Campaign {
    //     uint256 amount;
    //     uint256 tokenId;
    //     address tokenAddress;
    //     address recipient;
    //     bool isAccepted;
    //     mapping(address => uint256) donations;
    // }

    function testStart() public {
        uint256 campaignId = crowdfundoor.startCampaign(address(mock721), tokenId, recipient1);

        (uint256 amount,,,, bool isAccepted) = crowdfundoor.campaigns(campaignId);

        assertEq(campaignId, 0);
        assertEq(amount, 0);
        assertEq(isAccepted, false);
    }

    function testStartMultiple() public {
        uint256 campaignId1 = crowdfundoor.startCampaign(address(mock721), tokenId, recipient1);
        uint256 campaignId2 = crowdfundoor.startCampaign(address(mock721), tokenId, recipient1);

        (uint256 amount1,,,, bool isAccepted1) = crowdfundoor.campaigns(campaignId1);
        (uint256 amount2,,,, bool isAccepted2) = crowdfundoor.campaigns(campaignId2);

        assertEq(campaignId1, 0);
        assertEq(campaignId2, 1);
        assertEq(amount1, 0);
        assertEq(amount2, 0);
        assertEq(isAccepted1, false);
        assertEq(isAccepted2, false);
    }

    function testDonate() public {
        uint256 campaignId = crowdfundoor.startCampaign(address(mock721), tokenId, recipient1);
        uint256 donationAmount = 1 ether;

        vm.prank(donor1);
        crowdfundoor.donate{value: donationAmount}(campaignId);

        (uint256 amount,,,, bool isAccepted) = crowdfundoor.campaigns(campaignId);

        assertEq(amount, donationAmount);
        assertEq(isAccepted, false);
        assertEq(donor1.balance, initialBalance - donationAmount);
    }

    function testDonateFromTwoDonors() public {
        uint256 campaignId = crowdfundoor.startCampaign(address(mock721), tokenId, recipient1);
        uint256 donationAmount = 1 ether;

        vm.prank(donor1);
        crowdfundoor.donate{value: donationAmount}(campaignId);

        vm.prank(donor2);
        crowdfundoor.donate{value: donationAmount}(campaignId);

        (uint256 amount,,,, bool isAccepted) = crowdfundoor.campaigns(campaignId);

        assertEq(amount, donationAmount * 2);
        assertEq(isAccepted, false);
        assertEq(donor1.balance, initialBalance - donationAmount);
        assertEq(donor2.balance, initialBalance - donationAmount);
    }

    function testDonateMultipleFromSameDonor() public {
        uint256 campaignId = crowdfundoor.startCampaign(address(mock721), tokenId, recipient1);

        uint256 donationAmount1 = 1 ether;
        uint256 donationAmount2 = 2 ether;

        vm.startPrank(donor1);
        crowdfundoor.donate{value: donationAmount1}(campaignId);
        crowdfundoor.donate{value: donationAmount2}(campaignId);

        (uint256 amount,,,, bool isAccepted) = crowdfundoor.campaigns(campaignId);

        assertEq(amount, donationAmount1 + donationAmount2);
        assertEq(isAccepted, false);
        assertEq(donor1.balance, initialBalance - donationAmount1 - donationAmount2);
    }

    function testDonateMultipleFromSeparateDonors() public {
        uint256 campaignId = crowdfundoor.startCampaign(address(mock721), tokenId, recipient1);
        uint256 donationAmount1 = 1 ether;
        uint256 donationAmount2 = 2 ether;

        vm.prank(donor1);
        crowdfundoor.donate{value: donationAmount1}(campaignId);

        vm.prank(donor2);
        crowdfundoor.donate{value: donationAmount2}(campaignId);

        vm.prank(donor1);
        crowdfundoor.donate{value: donationAmount1}(campaignId);

        vm.prank(donor2);
        crowdfundoor.donate{value: donationAmount2}(campaignId);

        (uint256 amount,,,, bool isAccepted) = crowdfundoor.campaigns(campaignId);

        assertEq(amount, donationAmount1 * 2 + donationAmount2 * 2);
        assertEq(isAccepted, false);
        assertEq(donor1.balance, 100 ether - donationAmount1 * 2);
        assertEq(donor2.balance, 100 ether - donationAmount2 * 2);
    }

    function testWithdraw() public {
        uint256 campaignId = crowdfundoor.startCampaign(address(mock721), tokenId, recipient1);
        uint256 donationAmount = 1 ether;

        vm.startPrank(donor1);
        crowdfundoor.donate{value: donationAmount}(campaignId);
        crowdfundoor.withdraw(campaignId);

        (uint256 amount,,,, bool isAccepted) = crowdfundoor.campaigns(campaignId);

        assertEq(amount, 0);
        assertEq(isAccepted, false);
    }

    function testAccept() public {
        uint256 campaignId = crowdfundoor.startCampaign(address(mock721), tokenId, recipient1);
        uint256 donationAmount = 1 ether;

        vm.prank(donor1);
        crowdfundoor.donate{value: donationAmount}(campaignId);

        vm.startPrank(hodler1);
        mock721.approve(address(crowdfundoor), tokenId);
        crowdfundoor.accept(campaignId, donationAmount);

        (uint256 amount,,,, bool isAccepted) = crowdfundoor.campaigns(campaignId);

        assertEq(amount, 0);
        assertEq(isAccepted, true);
        assertEq(mock721.ownerOf(tokenId), recipient1);
        assertEq(hodler1.balance, initialBalance + donationAmount);
    }

    function testAcceptWhenOwnerAccepts() public {
        uint256 campaignId = crowdfundoor.startCampaign(address(mock721), tokenId, recipient1);
        uint256 donationAmount = 1 ether;

        vm.prank(donor1);
        crowdfundoor.donate{value: donationAmount}(campaignId);

        vm.prank(hodler1);
        mock721.transferFrom(address(hodler1), recipient1, tokenId);

        assertEq(recipient1.balance, 0 ether);

        vm.startPrank(recipient1);
        mock721.approve(address(crowdfundoor), tokenId);
        crowdfundoor.accept(campaignId, donationAmount);
        vm.stopPrank();

        (uint256 amount,,,, bool isAccepted) = crowdfundoor.campaigns(campaignId);

        assertEq(amount, 0);
        assertEq(isAccepted, true);
        assertEq(mock721.ownerOf(tokenId), recipient1);
        assertEq(recipient1.balance, donationAmount);
    }

    function testFailAcceptDueToMinimumNotMet() public {
        uint256 campaignId = crowdfundoor.startCampaign(address(mock721), tokenId, recipient1);
        uint256 donationAmount = 1 ether;
        uint256 minimumAmount = 3 ether;

        vm.prank(donor1);
        crowdfundoor.donate{value: donationAmount}(campaignId);

        vm.prank(donor2);
        crowdfundoor.donate{value: donationAmount}(campaignId);

        vm.prank(donor3);
        crowdfundoor.donate{value: donationAmount}(campaignId);

        vm.prank(hodler1);
        mock721.approve(address(crowdfundoor), tokenId);

        vm.prank(donor3);
        crowdfundoor.withdraw(campaignId);

        vm.prank(hodler1);
        crowdfundoor.accept(campaignId, minimumAmount);
    }

    function testRedonationAfterWithdrawal() public {
        uint256 campaignId = crowdfundoor.startCampaign(address(mock721), tokenId, recipient1);
        uint256 donationAmount = 2 ether;
        uint256 redonationAmount = 1 ether;

        vm.startPrank(donor1);
        crowdfundoor.donate{value: donationAmount}(campaignId);
        crowdfundoor.withdraw(campaignId);
        crowdfundoor.donate{value: redonationAmount}(campaignId);

        (uint256 amount,,,,) = crowdfundoor.campaigns(campaignId);

        assertEq(amount, redonationAmount);
    }

    function testChainedRecipientsForSameToken() public {
        uint256 campaignId1 = crowdfundoor.startCampaign(address(mock721), tokenId, recipient1);
        uint256 campaignId2 = crowdfundoor.startCampaign(address(mock721), tokenId, recipient2);

        uint256 donationAmount1 = 1 ether;
        uint256 donationAmount2 = 2 ether;

        vm.prank(donor1);
        crowdfundoor.donate{value: donationAmount1}(campaignId1);

        vm.prank(donor2);
        crowdfundoor.donate{value: donationAmount2}(campaignId2);

        (uint256 amount1,,,,) = crowdfundoor.campaigns(campaignId1);
        (uint256 amount2,,,,) = crowdfundoor.campaigns(campaignId2);

        assertEq(amount1, donationAmount1);
        assertEq(amount2, donationAmount2);

        vm.startPrank(hodler1);
        mock721.approve(address(crowdfundoor), tokenId);
        crowdfundoor.accept(campaignId1, donationAmount1);

        assertEq(mock721.ownerOf(tokenId), recipient1);

        vm.startPrank(recipient1);
        mock721.approve(address(crowdfundoor), tokenId);
        crowdfundoor.accept(campaignId2, donationAmount2);

        (amount1,,,,) = crowdfundoor.campaigns(campaignId1);
        (amount2,,,,) = crowdfundoor.campaigns(campaignId2);

        assertEq(mock721.ownerOf(tokenId), recipient2);
        assertEq(amount1, 0);
        assertEq(amount2, 0);
    }
}
