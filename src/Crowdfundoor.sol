// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Crowdfundoor {
    mapping(address => mapping(uint256 => uint256)) public funds;
    mapping(address => mapping(uint256 => mapping(address => uint256))) public donations;
    mapping(address => mapping(uint256 => address)) public destinationAddresses;

    error AlreadyRecovered();
    error DonationRequired();
    error InvalidFund();
    error NoDonationToWithdraw();
    error NotTokenOwner();
    error TransferFailed();

    event Recovered(address indexed tokenAddress, uint256 indexed tokenId, address indexed recoveror, address destinationAddress);
    event Donation(address indexed tokenAddress, uint256 indexed tokenId, address indexed donor, uint256 amount);
    event Withdrawal(address indexed tokenAddress, uint256 indexed tokenId, address indexed donor, uint256 amount);

    /*
        Donate ether to raise funds for recovering a lost token.
        Specify a destination address where the token should be transferred if recovered.
    */
    function donate(address tokenAddress, uint256 tokenId, address destinationAddress) external payable {
        if (msg.value == 0) revert DonationRequired();
        if (IERC721(tokenAddress).ownerOf(tokenId) == destinationAddress) revert AlreadyRecovered();

        funds[tokenAddress][tokenId] += msg.value;
        donations[tokenAddress][tokenId][msg.sender] += msg.value;
        destinationAddresses[tokenAddress][tokenId] = destinationAddress;

        emit Donation(tokenAddress, tokenId, msg.sender, msg.value);
    }

    /*
        If you change your mind, withdraw before the fund is used.
    */
    function withdraw(address tokenAddress, uint256 tokenId) external {
        if (donations[tokenAddress][tokenId][msg.sender] == 0) revert NoDonationToWithdraw();

        uint256 donation = donations[tokenAddress][tokenId][msg.sender];
        donations[tokenAddress][tokenId][msg.sender] = 0;
        funds[tokenAddress][tokenId] -= donation;

        (bool success, ) = payable(msg.sender).call{value: donation}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(tokenAddress, tokenId, msg.sender, donation);
    }

    /*
        To use the fund, first call approve or setApprovalForAll on your NFT's contract.
        Set minimumAmount to value of current fund to prevent frontrunning withdrawals.
    */
    function accept(address tokenAddress, uint256 tokenId, uint256 minimumAmount) external {
        if (IERC721(tokenAddress).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if (funds[tokenAddress][tokenId] < minimumAmount) revert InvalidFund();
        if (funds[tokenAddress][tokenId] == 0) revert InvalidFund();

        uint256 amount = funds[tokenAddress][tokenId];
        funds[tokenAddress][tokenId] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        IERC721(tokenAddress).transferFrom(msg.sender, destinationAddresses[tokenAddress][tokenId], tokenId);

        emit Recovered(tokenAddress, tokenId, msg.sender, destinationAddresses[tokenAddress][tokenId]);
    }
}
