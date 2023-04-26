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
	Counters.Counter private _buyingRequestIdCounter;

	enum BuyingRequestStatus {
		PENDING,
		ACCEPTED,
		REJECTED
	}

	struct BuyingRequest {
		uint256 id;
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
	mapping(uint256 => SellingListing) public sellingListing;

	struct TokenMetadata {
		uint256 creationDate;
		string title;
		string description;
	}

	mapping(uint256 => TokenMetadata) public tokenMetadata;

	constructor() ERC721('Encode', 'ENC') {}

	function safeMint(
		address to,
		string memory uri,
		string memory title,
		string memory description
	) public {
		uint256 tokenId = _tokenIdCounter.current();
		_tokenIdCounter.increment();

		_safeMint(to, tokenId);
		_setTokenURI(tokenId, uri);

		tokenMetadata[tokenId].creationDate = block.timestamp;
		tokenMetadata[tokenId].title = title;
		tokenMetadata[tokenId].description = description;
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

		uint256 requestId = _buyingRequestIdCounter.current();
		_buyingRequestIdCounter.increment();

		buyingRequests[tokenId].push(
			BuyingRequest(
				requestId,
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

	function acceptBuyingRequest(uint256 tokenId, uint256 requestId) public {
		require(
			ownerOf(tokenId) == msg.sender,
			'You cannot accept buying requests for NFTs that you do not own'
		);

		BuyingRequest[] storage requests = buyingRequests[tokenId];
		for (uint256 i = 0; i < requests.length; i++) {
			if (requests[i].id == requestId) {
				requests[i].status = BuyingRequestStatus.ACCEPTED;
				// transfer token
				safeTransferFrom(msg.sender, requests[i].buyer, tokenId);

				// transfer funds
				payable(msg.sender).transfer(requests[i].offer);
			} else {
				requests[i].status = BuyingRequestStatus.REJECTED;
			}
		}
	}

	function createSellingListing(uint256 tokenId, uint256 price) public {
		require(
			ownerOf(tokenId) == msg.sender,
			'You cannot sell NFTs that you do not own'
		);
		require(price > 0, 'Price must be greater than 0');

		approve(address(this), tokenId);
		sellingListing[tokenId] = SellingListing(price, block.timestamp);
	}

	function getSellingListings(
		uint256 tokenId
	) public view returns (SellingListing memory) {
		return sellingListing[tokenId];
	}

	function buyToken(uint256 tokenId) public payable {
		require(ownerOf(tokenId) != msg.sender, 'You cannot buy your own NFT');
		require(sellingListing[tokenId].price > 0, 'This NFT is not for sale');
		require(
			msg.value >= sellingListing[tokenId].price,
			'You must send enough ETH to buy this NFT'
		);

		address seller = ownerOf(tokenId);
		address buyer = msg.sender;

		// transfer token
		safeTransferFrom(seller, buyer, tokenId);

		// transfer funds
		payable(seller).transfer(msg.value);
	}

	struct TokenInfo {
		uint256 id;
		string uri;
		address owner;
		TokenMetadata metadata;
	}

	function getTokensOfOwner(
		address addr
	) public view returns (TokenInfo[] memory) {
		uint256 balance = balanceOf(addr);
		TokenInfo[] memory tokens = new TokenInfo[](balance);
		for (uint256 i = 0; i < balance; i++) {
			uint256 tokenId = tokenOfOwnerByIndex(addr, i);

			TokenMetadata memory metadata = tokenMetadata[tokenId];

			tokens[i] = TokenInfo(
				tokenId,
				tokenURI(tokenId),
				ownerOf(tokenId),
				metadata
			);
		}

		return tokens;
	}

	function getToken(uint256 tokenId) public view returns (TokenInfo memory) {
		TokenMetadata memory metadata = tokenMetadata[tokenId];

		return
			TokenInfo(tokenId, tokenURI(tokenId), ownerOf(tokenId), metadata);
	}

	function listTokens() public view returns (TokenInfo[] memory) {
		uint256 totalSupply = totalSupply();
		TokenInfo[] memory tokens = new TokenInfo[](totalSupply);
		for (uint256 i = 0; i < totalSupply; i++) {
			uint256 tokenId = tokenByIndex(i);

			TokenMetadata memory metadata = tokenMetadata[tokenId];

			tokens[i] = TokenInfo(
				tokenId,
				tokenURI(tokenId),
				ownerOf(tokenId),
				metadata
			);
		}

		return tokens;
	}
}
