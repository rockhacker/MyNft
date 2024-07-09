// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTMarket {
    IERC20 public token;

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event Listed(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint256 price);
    event Bought(address indexed nftContract, uint256 indexed tokenId, address indexed buyer, uint256 price);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    // 上架函数
    function list(address nftContract, uint256 tokenId, uint256 price) external {
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, unicode"您不是该NFT的持有者");
        require(nft.getApproved(tokenId) == address(this), unicode"NFT未授权给市场");

        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        listings[nftContract][tokenId] = Listing(msg.sender, price);

        emit Listed(nftContract, tokenId, msg.sender, price);
    }

    // 购买NFT函数
    function buyNFT(address nftContract, uint256 tokenId) external {
        Listing memory listing = listings[nftContract][tokenId];
        require(listing.price > 0, unicode"NFT未上架");
        require(token.balanceOf(msg.sender) >= listing.price, unicode"Token余额不足");

        require(token.transferFrom(msg.sender, listing.seller, listing.price), unicode"Token转移失败");

        IERC721 nft = IERC721(nftContract);
        nft.safeTransferFrom(address(this), msg.sender, tokenId);

        delete listings[nftContract][tokenId];

        emit Bought(nftContract, tokenId, msg.sender, listing.price);
    }
}