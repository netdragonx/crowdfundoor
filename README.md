```

                                _  __                 _
                               | |/ _|               | |
       ___ _ __ _____      ____| | |_ _   _ _ __   __| | ___   ___  _ __
      / __| '__/ _ \ \ /\ / / _` |  _| | | | '_ \ / _` |/ _ \ / _ \| '__|
     | (__| | | (_) \ V  V / (_| | | | |_| | | | | (_| | (_) | (_) | |
      \___|_|  \___/ \_/\_/ \__,_|_|  \__,_|_| |_|\__,_|\___/ \___/|_|

                                                     by netdragonx.eth

```

Crowdfundoor is a smart contract that allows users to crowdfund the purchase of an ERC721 token.

The intended use is to help recover stolen assets.

### How to Use

**How to connect to Etherscan:**

You'll need to use [Etherscan](https://etherscan.io) to interact with this contract.

1. Browse to the contract on Etherscan
2. Click `Contract` tab
3. Click `Write Contract` inner tab
4. Click `Connect to Web3` and connect your wallet.

---

**Start a new campaign:**

`startCampaign(tokenAddress, tokenId, recipient)`

1. Set `tokenAddress` to the contract address of the NFT collection
2. Set `tokenId` to the token of the NFT you hope to recover
3. Set `recipient` to the 0x address of who will ultimately receive it
4. Click `Write`
5. Confirm with your wallet

---

**Donate ether to campaign:**

`donate(campaignId)`

1. Set payable field to how much ether you want to donate
2. Set `campaignId` to the ID of the campaign you're donating to
3. Click `Write`
4. Confirm with your wallet

---

**Accept a campaign offer:**

Here are the steps to accept an outstanding offer from donors.

_Important:_ Before calling `accept`, you must first approve the contract

1. Go to the contract for the NFT collection you're going to transfer
2. Call `approve` with your NFT (`tokenId`) and **Crowdfundoor** address (`to`)

`accept(campaignId, minimumAmount)`

1. Set `campaignId` to the ID of the campaign you're accepting
2. Set `minimumAmount` to current campaign amount in `wei` to avoid frontrunning.
   - Example: For a 1 ETH offer, you would use 1000000000000000000 here.
   - For other amounts, you can use [eth-converter.com](https://eth-converter.com/)
3. Click `Write`
4. Confirm with your wallet

---

**Withdraw your donation:**

If the campaign hasn't been accepted, you can withdraw your donation at any time.

`withdraw(campaignId)`

1. Set `campaignId` to the ID of the campaign you're withdrawing from
2. Click `Write`
3. Confirm with your wallet
