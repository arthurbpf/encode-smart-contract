// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract Encode is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable {
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

	// The following functions are overrides required by Solidity.

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId,
		uint256 batchSize
	) internal override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId, batchSize);
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

	function supportsInterface(
		bytes4 interfaceId
	) public view override(ERC721, ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
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

	function getSellingListings(
		uint256 tokenId
	) public view returns (SellingListing memory) {
		return sellingListings[tokenId];
	}

	struct tokenInfo {
		uint256 id;
		string uri;
	}

	function getTokensOfOwner(
		address addr
	) public view returns (tokenInfo[] memory) {
		uint256 balance = balanceOf(addr);
		tokenInfo[] memory tokens = new tokenInfo[](balance);
		for (uint256 i = 0; i < balance; i++) {
			uint256 tokenId = tokenOfOwnerByIndex(addr, i);
			tokens[i] = tokenInfo(tokenId, tokenURI(tokenId));
		}

		return tokens;
	}
}
