// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract Encode is ERC721, ERC721URIStorage, ERC721Burnable {
	using Counters for Counters.Counter;
	Counters.Counter private _tokenIdCounter;

	enum BuyingRequestStatus {
		PENDING,
		ACCEPTED,
		REJECTED
	}

	struct BuyingRequest {
		address buyer;
		uint256 offer;
		uint256 timestamp;
		BuyingRequestStatus status;
	}

	// maps token id to buying requests
	mapping(uint256 => BuyingRequest[]) public buyingRequests;

	struct SellingListing {
		uint256 price;
		uint256 timestamp;
	}

	// maps address to selling listings
	mapping(uint256 => SellingListing) public sellingListings;

	constructor() ERC721('Encode', 'ENC') {}

	function safeMint(address to, string memory uri) public {
		uint256 tokenId = _tokenIdCounter.current();
		_tokenIdCounter.increment();
		_safeMint(to, tokenId);
		_setTokenURI(tokenId, uri);
	}

	function _burn(
		uint256 tokenId
	) internal override(ERC721, ERC721URIStorage) {
		super._burn(tokenId);
	}

	function tokenURI(
		uint256 tokenId
	) public view override(ERC721, ERC721URIStorage) returns (string memory) {
		return super.tokenURI(tokenId);
	}

	function createBuyingRequest(uint256 tokenId, uint256 offer) public {
		require(ownerOf(tokenId) != msg.sender, 'You cannot buy your own NFT');
		require(offer > 0, 'Offer must be greater than 0');

		buyingRequests[tokenId].push(
			BuyingRequest(
				msg.sender,
				offer,
				block.timestamp,
				BuyingRequestStatus.PENDING
			)
		);
	}

	function getBuyingRequests(
		uint256 tokenId
	) public view returns (BuyingRequest[] memory) {
		return buyingRequests[tokenId];
	}

	function createSellingListing(uint256 tokenId, uint256 price) public {
		require(
			ownerOf(tokenId) == msg.sender,
			'You cannot sell NFTs that you do not own'
		);
		require(price > 0, 'Price must be greater than 0');

		approve(address(this), tokenId);
		sellingListings[tokenId] = SellingListing(price, block.timestamp);
	}

	function getSellingListing(
		uint256 tokenId
	) public view returns (SellingListing memory) {
		return sellingListings[tokenId];
	}
}
