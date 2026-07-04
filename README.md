# 🏪 NFT Marketplace

A decentralized NFT Marketplace smart contract built with **Foundry** and **OpenZeppelin**. Allows users to list, buy, and cancel NFT listings from any ERC-721 collection without intermediaries.

---

## 📋 Overview

This marketplace implements the core functionality of platforms like OpenSea at the smart contract level. NFTs remain in the seller's wallet (approve pattern) until purchased, providing better UX and lower gas costs.

### Key Features

- **List any ERC-721 NFT** — works with any collection, not just one
- **Buy with ETH** — atomic swap: ETH for NFT in a single transaction
- **Cancel listings** — only the NFT owner can cancel
- **Nested mappings** — `nftAddress => tokenId => Listing` for multi-collection support
- **Security** — ReentrancyGuard, CEI pattern, custom errors

---

## 🏗️ Project Structure

nft-marketplace/
│
├── src/
│   └── NFTMarketplace.sol        # Main contract
│
├── test/
│   └── NFTMarketplaceTest.t.sol  # Test suite
│
├── foundry.toml
└── README.md

---

## 📄 Contract — `NFTMarketplace.sol`

### Data Structures

| Structure | Fields | Purpose |
|---|---|---|
| `Listing` | `seller`, `nftAddress`, `tokenId`, `price` | Represents an NFT listed for sale |
| `listings` | `mapping(address => mapping(uint256 => Listing))` | Nested mapping storing all active listings |

### Custom Errors

| Error | When it triggers |
|---|---|
| `AlreadyListed(nftAddress, tokenId)` | Trying to list an NFT that's already listed |
| `NotOwner()` | Caller is not the owner of the NFT |
| `NotListed(nftAddress, tokenId)` | Operating on an NFT that isn't listed |

### Modifiers

| Modifier | Description |
|---|---|
| `isOwner(nftAddress, tokenId, caller)` | Verifies caller owns the NFT via `IERC721.ownerOf()` |
| `notListed(nftAddress, tokenId)` | Verifies the NFT is not already listed |
| `isListed(nftAddress, tokenId)` | Verifies the NFT is currently listed |

### Functions

| Function | Access | Description |
|---|---|---|
| `listNFT(nftAddress, tokenId, price)` | External | Lists an NFT for sale. Requires prior `approve()` on the NFT contract |
| `buyNFT(nftAddress, tokenId)` | External payable | Buys a listed NFT. Must send exact price in ETH |
| `cancelListing(nftAddress, tokenId)` | External | Cancels a listing. Only the NFT owner can cancel |

---

## 🔄 How It Works

LIST:

Seller calls approve(marketplace, tokenId) on the NFT contract
Seller calls listNFT(nftAddress, tokenId, price)
Listing is stored in the nested mapping
BUY:

Buyer calls buyNFT(nftAddress, tokenId) sending exact ETH
Contract follows CEI pattern:
a. Saves listing data and deletes listing (Effects)
b. Transfers NFT from seller to buyer via safeTransferFrom (Interaction)
c. Sends ETH to seller via call (Interaction)
CANCEL:

Seller calls cancelListing(nftAddress, tokenId)
Listing is deleted — NFT was never moved from seller's wallet

---

## 🛡️ Security Patterns

**CEI (Checks-Effects-Interactions)** — In `buyNFT`, the listing is deleted before any external calls (NFT transfer and ETH transfer), preventing reentrancy exploits.

**ReentrancyGuard** — Applied to `listNFT`, `buyNFT`, and `cancelListing` as an additional layer of protection via OpenZeppelin's `nonReentrant` modifier.

**Custom Errors** — Gas-efficient error handling with descriptive error types instead of `require` strings.

**Approve Pattern** — NFTs stay in the seller's wallet. The marketplace only moves them upon purchase using the approval granted by the seller.

---
