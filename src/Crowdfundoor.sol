// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//
//                            _  __                 _
//                           | |/ _|               | |
//   ___ _ __ _____      ____| | |_ _   _ _ __   __| | ___   ___  _ __
//  / __| '__/ _ \ \ /\ / / _` |  _| | | | '_ \ / _` |/ _ \ / _ \| '__|
// | (__| | | (_) \ V  V / (_| | | | |_| | | | | (_| | (_) | (_) | |
//  \___|_|  \___/ \_/\_/ \__,_|_|  \__,_|_| |_|\__,_|\___/ \___/|_|
//
//                                                 by netdragonx.eth
//
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Crowdfundoor {
    mapping(address => mapping(uint256 => mapping(address => bool))) public accepted;
    mapping(address => mapping(uint256 => mapping(address => uint256))) public donations;
    mapping(address => mapping(uint256 => mapping(address => mapping(address => uint256)))) public receipts;

    error AlreadyAccepted();
    error AlreadyOwned();
    error DonationRequired();
    error InvalidFund();
    error InvalidRecipient();
    error NoDonationToWithdraw();
    error NotTokenOwner();
    error TransferFailed();

    event Accepted(address indexed tokenAddress, uint256 indexed tokenId, address indexed recipient);
    event Donation(address indexed tokenAddress, uint256 indexed tokenId, address indexed recipient, uint256 amount);
    event Withdrawal(address indexed tokenAddress, uint256 indexed tokenId, address indexed recipient, uint256 amount);

    function donate(address tokenAddress, uint256 tokenId, address recipient) external payable {
        if (accepted[tokenAddress][tokenId][recipient]) {
            revert AlreadyAccepted();
        }

        if (msg.value == 0) {
            revert DonationRequired();
        }

        if (IERC721(tokenAddress).ownerOf(tokenId) == recipient) {
            revert AlreadyOwned();
        }

        receipts[tokenAddress][tokenId][recipient][msg.sender] += msg.value;
        donations[tokenAddress][tokenId][recipient] += msg.value;

        emit Donation(tokenAddress, tokenId, recipient, msg.value);
    }

    function withdraw(address tokenAddress, uint256 tokenId, address recipient) external {
        if (accepted[tokenAddress][tokenId][recipient]) {
            revert AlreadyAccepted();
        }

        if (receipts[tokenAddress][tokenId][recipient][msg.sender] == 0) {
            revert NoDonationToWithdraw();
        }

        uint256 donation = receipts[tokenAddress][tokenId][recipient][msg.sender];
        receipts[tokenAddress][tokenId][recipient][msg.sender] = 0;
        donations[tokenAddress][tokenId][recipient] -= donation;

        (bool success,) = payable(msg.sender).call{value: donation}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(tokenAddress, tokenId, recipient, donation);
    }

    function accept(address tokenAddress, uint256 tokenId, address recipient, uint256 minimumAmount) external {
        if (IERC721(tokenAddress).ownerOf(tokenId) != msg.sender) {
            revert NotTokenOwner();
        }

        uint256 amount = donations[tokenAddress][tokenId][recipient];
        if (amount < minimumAmount || amount == 0) {
            revert InvalidFund();
        }

        donations[tokenAddress][tokenId][recipient] = 0;
        accepted[tokenAddress][tokenId][recipient] = true;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        IERC721(tokenAddress).transferFrom(msg.sender, recipient, tokenId);

        emit Accepted(tokenAddress, tokenId, recipient);
    }
}
