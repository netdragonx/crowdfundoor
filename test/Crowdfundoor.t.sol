// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Crowdfundoor.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CrowdfundoorTest is Test {
    Crowdfundoor public crowdfundoor;
    ERC721 public token;

    address public donor = address(this);
    address public destination = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2; // A random Ethereum address for testing
    uint256 public tokenId = 1;

    function setUp() public {
        crowdfundoor = new Crowdfundoor();
        token = new ERC721("Test Token", "TT");
        token._mint(address(this), tokenId); // Create a test token
    }

    function testDonate() public {
        uint256 donationAmount = 1 ether;
        crowdfundoor.donate{value: donationAmount}(address(token), tokenId, destination);
        assertEq(crowdfundoor.funds(address(token), tokenId), donationAmount);
        assertEq(crowdfundoor.donations(address(token), tokenId, donor), donationAmount);
        assertEq(crowdfundoor.destinationAddresses(address(token), tokenId), destination);
    }

    function testWithdraw() public {
        uint256 donationAmount = 1 ether;
        crowdfundoor.donate{value: donationAmount}(address(token), tokenId, destination);
        crowdfundoor.withdraw(address(token), tokenId);
        assertEq(crowdfundoor.funds(address(token), tokenId), 0);
        assertEq(crowdfundoor.donations(address(token), tokenId, donor), 0);
    }

    function testAccept() public {
        uint256 donationAmount = 1 ether;
        crowdfundoor.donate{value: donationAmount}(address(token), tokenId, destination);
        token.approve(address(crowdfundoor), tokenId);
        crowdfundoor.accept(address(token), tokenId, donationAmount);
        assertEq(crowdfundoor.funds(address(token), tokenId), 0);
        assertEq(token.ownerOf(tokenId), destination);
    }
}

