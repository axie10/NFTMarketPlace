// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {Test} from "forge-std/Test.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "forge-std/console.sol";

contract MockNFT is ERC721 {
    constructor() ERC721("MockNFT", "NFT") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract NFTMarketplaceTest is Test {
    struct Listing {
        address seller;
        address nftAdrress;
        uint256 tokenId;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    NFTMarketplace marketplace;
    MockNFT mockNFT;
    address deployer;
    address account2;
    uint256 tokenId = 0;

    function setUp() public {
        deployer = vm.addr(1);
        account2 = vm.addr(2);

        vm.startPrank(deployer);
        marketplace = new NFTMarketplace();
        mockNFT = new MockNFT();
        vm.stopPrank();

        vm.startPrank(account2);
        mockNFT.mint(account2, tokenId);
        vm.stopPrank();
    }

    //* check nft is minted
    function testMintsNFT() public view {
        // require(IERC721(mockNFT).ownerOf(tokenId) == account2, "Not owner of nft");
        address userNFT = mockNFT.ownerOf(tokenId);
        assert(userNFT == account2);
        // assert(IERC721(mockNFT).ownerOf(tokenId) == account2);
    }

    //* Listing
    function testListNFT1() public {
        vm.startPrank(account2);

        uint256 price = 1 ether;
        // uint256 tokenId_1 = 1;

        (address sellerBefore,,,) = marketplace.listings(address(mockNFT), tokenId);

        marketplace.listNFT(address(mockNFT), tokenId, price);

        (address sellerAfter,,,) = marketplace.listings(address(mockNFT), tokenId);

        assert(sellerBefore == address(0));
        assert(sellerAfter == account2);
        vm.stopPrank();
    }

    function testListNFT2MintOtherToken() public {
        vm.startPrank(account2);

        uint256 price = 1 ether;
        uint256 tokenId_1 = 1;

        mockNFT.mint(account2, tokenId_1);

        // test
        (address sellerBefore,,,) = marketplace.listings(address(mockNFT), tokenId_1);

        marketplace.listNFT(address(mockNFT), tokenId_1, price);

        (address sellerAfter,,,) = marketplace.listings(address(mockNFT), tokenId_1);

        assert(sellerBefore == address(0));
        assert(sellerAfter == account2);
        vm.stopPrank();
    }

    function testListNFTRevertPriceNotEnough() public {
        vm.startPrank(account2);
        uint256 price = 0 ether;
        vm.expectRevert();
        marketplace.listNFT(address(mockNFT), tokenId, price);
        vm.stopPrank();
    }

    function testListNFTRevertNotWoner() public {
        vm.startPrank(deployer);
        uint256 price = 1 ether;
        vm.expectRevert();
        marketplace.listNFT(address(mockNFT), tokenId, price);
        vm.stopPrank();
    }

    function testListNFTRevertListedYet() public {
        vm.startPrank(account2);
        uint256 price = 1 ether;
        marketplace.listNFT(address(mockNFT), tokenId, price);
        vm.expectRevert();
        marketplace.listNFT(address(mockNFT), tokenId, price);
        vm.stopPrank();
    }

    //* CancelList
    function testCancelListNotOwner() public {
        vm.startPrank(deployer);
        uint256 tokenId_2 = 1;
        mockNFT.mint(address(mockNFT), tokenId_2);
        vm.stopPrank();

        vm.startPrank(account2);
        vm.expectRevert();
        marketplace.cancelListing(address(mockNFT), tokenId_2);
        vm.stopPrank();
    }

    function testCancelListNotListing() public {
        vm.startPrank(account2);
        uint256 tokenId_new = 2;
        uint256 price = 1 ether;
        marketplace.listNFT(address(mockNFT), tokenId, price);
        vm.expectRevert();
        marketplace.cancelListing(address(mockNFT), tokenId_new);
        vm.stopPrank();
    }

    function testCancelListCorrectly() public {
        vm.startPrank(account2);
        uint256 price = 1 ether;
        marketplace.listNFT(address(mockNFT), tokenId, price);
        marketplace.cancelListing(address(mockNFT), tokenId);
        (address sellerAfter,,,) = marketplace.listings(address(mockNFT), tokenId);
        assert(sellerAfter == address(0));
        vm.stopPrank();
    }
}
