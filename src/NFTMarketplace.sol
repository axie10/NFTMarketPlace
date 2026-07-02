// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ReentrancyGuard, Ownable {
    // STRUCTS
    struct Listing {
        address seller;
        address nftAdrress;
        uint256 tokenId;
        uint256 price;
    }

    // EVENTS
    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);

    event ItemCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);

    event ItemBought(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);

    // CUSTOM ERRORS
    error AlreadyListed(address nftAddress, uint256 tokenId);
    error NotOwner();
    error NotListed(address nftAddress, uint256 tokenId);

    // MODIFIER
    // we verify caller is owner of NFT
    modifier isOwner(address nftAddress, uint256 tokenId, address caller) {
        if (IERC721(nftAddress).ownerOf(tokenId) != caller) {
            revert NotOwner();
        }
        _;
    }

    // we verify NFT is not listed
    modifier notListed(address nftAddress, uint256 tokenId) {
        if (listings[nftAddress][tokenId].price > 0) {
            revert AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    // we verify NFT is listed
    modifier isListed(address nftAddress, uint256 tokenId) {
        if (listings[nftAddress][tokenId].price == 0) {
            revert NotListed(nftAddress, tokenId);
        }
        _;
    }

    // VARIABLES
    // nftAddress => tokenId => Listing
    // Para poder saber dentro de smart contract a que nft nos referimos, el id del nft y el objeto entero del nft
    mapping(address => mapping(uint256 => Listing)) public listings;

    constructor() Ownable(msg.sender) {}

    // FUNCTIONS: List NFTs, Buy NFTs (tranfers nft to buyer and transfer tokens to seller), Cancel list
    // Necessary requirements: not exist nft and nfts owner is who list
    function listNFT(address _nftAdrress, uint256 _tokenId, uint256 _price)
        external
        nonReentrant
        notListed(_nftAdrress, _tokenId)
        isOwner(_nftAdrress, _tokenId, msg.sender)
    {
        require(_price > 0, "Precie must be up to cero");

        // create struct - one NFT
        Listing memory _listing =
            Listing({seller: msg.sender, nftAdrress: _nftAdrress, tokenId: _tokenId, price: _price});

        // save doblemapping/nested mapping
        listings[_nftAdrress][_tokenId] = _listing;

        emit ItemListed(msg.sender, _nftAdrress, _tokenId, _price);
    }

    // Necessary requirements: exist nft
    function buyNFT(address _nftAdrress, uint256 _tokenId) external payable nonReentrant isListed(_nftAdrress, _tokenId) {
        require(msg.value == listings[_nftAdrress][_tokenId].price, "Incorrects price");

        // CEI Patterns: first update, second transfer
        Listing memory item = listings[_nftAdrress][_tokenId];
        delete listings[nftAddress][tokenId];

        IERC721(_nftAdrress).safeTransferFrom(item.seller, msg.sender, _tokenId);

        (bool success,) = item.seller.call{value: msg.value}("");
        require(success, "Transaction failed");


        emit ItemBought(msg.sender, _nftAdrress, _tokenId, item.price);
    }

    // Necessary requirements: exist nft and owner of nft
    function cancelListing(address _nftAdrress, uint256 _tokenId)
        external
        nonReentrant
        isListed(_nftAdrress, _tokenId)
        isOwner(_nftAdrress, _tokenId, msg.sender)
    {
        delete listings[_nftAdrress][_tokenId];
        emit ItemCanceled(msg.sender, _nftAdrress, _tokenId);
    }
}
