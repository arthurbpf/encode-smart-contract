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

	// map address to eth balance
	mapping(address => uint256) public balances;

	// event to be fired when a user sends eth to the contract
	event Received(address indexed sender, uint256 amount);

	enum BuyingRequestStatus {
		PENDING,
		CANCELED,
		ACCEPTED,
		REJECTED
	}

	struct BuyingRequest {
		address buyer;
		uint256 offer;
		uint256 timestamp;
		BuyingRequestStatus status;
	}

	// maps token id to buying requests, the first array is for the selling iteration, while the second is the request id
	mapping(uint256 => mapping(uint256 => BuyingRequest[]))
		public buyingRequests;

	enum SellingListingStatus {
		PENDING,
		CANCELED,
		ACCEPTED
	}

	struct SellingListing {
		address seller;
		uint256 price;
		uint256 timestamp;
		SellingListingStatus status;
	}

	// maps token id to selling listings, the first array is for the selling iteration, while the second is the listing id
	mapping(uint256 => mapping(uint256 => SellingListing[]))
		public sellingListings;

	struct TokenMetadata {
		address author;
		uint256 creationDate;
		string title;
		string description;
		uint256 timesSold;
	}

	// maps token id to metadata
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

		TokenMetadata storage metadata = tokenMetadata[tokenId];

		metadata.creationDate = block.timestamp;
		metadata.title = title;
		metadata.description = description;
		metadata.timesSold = 0;
	}

	// The following functions are overrides required by Solidity.

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId,
		uint256 batchSize
	) internal override(ERC721, ERC721Enumerable) {
		if (from != address(0) && to != address(0)) {
			TokenMetadata storage metadata = tokenMetadata[tokenId];
			BuyingRequest[] storage requests = buyingRequests[tokenId][
				metadata.timesSold
			];

			for (uint256 i = 0; i < requests.length; i++) {
				if (requests[i].status == BuyingRequestStatus.PENDING) {
					requests[i].status = BuyingRequestStatus.REJECTED;
					payable(requests[i].buyer).transfer(requests[i].offer);
				}
			}

			SellingListing[] storage listings = sellingListings[tokenId][
				metadata.timesSold
			];

			for (uint256 i = 0; i < listings.length; i++) {
				if (listings[i].status == SellingListingStatus.PENDING) {
					listings[i].status = SellingListingStatus.CANCELED;
				}
			}

			metadata.timesSold += 1;
		}

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

	receive() external payable {
		emit Received(msg.sender, msg.value);
	}

	// Custom functions

	// Buying requests handling
	function createBuyingRequest(uint256 tokenId) public payable {
		require(ownerOf(tokenId) != msg.sender, 'You cannot buy your own NFT');
		require(msg.value > 0, 'Offer must be greater than 0');

		TokenMetadata memory metadata = tokenMetadata[tokenId];

		// check if there is no other pending request from same buyer
		BuyingRequest[] memory requests = buyingRequests[tokenId][
			metadata.timesSold
		];
		for (uint256 i = 0; i < requests.length; i++) {
			if (requests[i].buyer == msg.sender) {
				require(
					requests[i].status != BuyingRequestStatus.PENDING,
					'You already have a pending buying request for this NFT'
				);
			}
		}

		payable(address(this)).transfer(msg.value);
		balances[msg.sender] += msg.value;

		buyingRequests[tokenId][metadata.timesSold].push(
			BuyingRequest(
				msg.sender,
				msg.value,
				block.timestamp,
				BuyingRequestStatus.PENDING
			)
		);
	}

	function cancelBuyingRequest(uint256 tokenId, uint256 requestId) public {
		TokenMetadata memory metadata = tokenMetadata[tokenId];
		BuyingRequest storage request = buyingRequests[tokenId][
			metadata.timesSold
		][requestId];

		require(
			request.buyer == msg.sender,
			'You cannot cancel buying requests that you did not create'
		);
		require(
			request.status == BuyingRequestStatus.PENDING,
			'You cannot cancel buying requests that are not pending'
		);

		request.status = BuyingRequestStatus.CANCELED;
		payable(msg.sender).transfer(request.offer);
	}

	function acceptBuyingRequest(uint256 tokenId, uint256 requestId) public {
		require(
			ownerOf(tokenId) == msg.sender,
			'You cannot accept buying requests for NFTs that you do not own'
		);

		TokenMetadata memory metadata = tokenMetadata[tokenId];
		BuyingRequest[] storage requests = buyingRequests[tokenId][
			metadata.timesSold
		];
		for (uint256 i = 0; i < requests.length; i++) {
			if (requests[i].status != BuyingRequestStatus.PENDING) {
				continue;
			}

			if (i == requestId) {
				requests[i].status = BuyingRequestStatus.ACCEPTED;
				// transfer funds
				payable(msg.sender).transfer(requests[i].offer);

				// transfer token
				safeTransferFrom(msg.sender, requests[i].buyer, tokenId);
			} else {
				requests[i].status = BuyingRequestStatus.REJECTED;
				payable(requests[i].buyer).transfer(requests[i].offer);
			}
		}
	}

	function getBuyingRequests(
		uint256 tokenId
	) public view returns (BuyingRequest[] memory) {
		TokenMetadata memory metadata = tokenMetadata[tokenId];

		return buyingRequests[tokenId][metadata.timesSold];
	}

	// Selling listings handling

	function createSellingListing(uint256 tokenId, uint256 price) public {
		require(
			ownerOf(tokenId) == msg.sender,
			'You cannot sell NFTs that you do not own'
		);
		require(price > 0, 'Price must be greater than 0');

		TokenMetadata memory metadata = tokenMetadata[tokenId];
		SellingListing[] storage listings = sellingListings[tokenId][
			metadata.timesSold
		];

		for (uint256 i = 0; i < listings.length; i++) {
			if (listings[i].status == SellingListingStatus.PENDING) {
				listings[i].status = SellingListingStatus.CANCELED;
			}
		}

		approve(address(this), tokenId);
		listings.push(
			SellingListing(
				msg.sender,
				price,
				block.timestamp,
				SellingListingStatus.PENDING
			)
		);
	}

	function cancelSellingListing(uint256 tokenId) public {
		require(
			ownerOf(tokenId) == msg.sender,
			'You cannot cancel selling listings for NFTs that you do not own'
		);

		TokenMetadata memory metadata = tokenMetadata[tokenId];
		SellingListing[] storage listings = sellingListings[tokenId][
			metadata.timesSold
		];

		require(
			listings.length > 0,
			'There is no selling listing for this NFT'
		);

		SellingListing storage listing = listings[listings.length - 1];

		require(
			listing.status == SellingListingStatus.PENDING,
			'The selling listing must be pending'
		);

		approve(address(0), tokenId);
		listing.status = SellingListingStatus.CANCELED;
	}

	function buyToken(uint256 tokenId) public payable {
		require(ownerOf(tokenId) != msg.sender, 'You cannot buy your own NFT');

		TokenMetadata memory metadata = tokenMetadata[tokenId];
		SellingListing[] storage listings = sellingListings[tokenId][
			metadata.timesSold
		];

		require(
			listings.length > 0,
			'There is no selling listing for this NFT'
		);

		SellingListing storage listing = listings[listings.length - 1];

		require(
			listing.status == SellingListingStatus.PENDING,
			'The selling listing must be pending'
		);

		require(
			msg.value >= listing.price,
			'You must send enough ETH to buy this NFT'
		);

		listing.status = SellingListingStatus.ACCEPTED;

		address seller = ownerOf(tokenId);
		address buyer = msg.sender;

		// transfer token
		_transfer(seller, buyer, tokenId);

		// transfer funds
		payable(seller).transfer(msg.value);
	}

	// Token listing functions

	struct TokenInfo {
		uint256 id;
		string uri;
		address owner;
		TokenMetadata metadata;
		SellingListing sellingListing;
	}

	function getToken(uint256 tokenId) public view returns (TokenInfo memory) {
		TokenMetadata memory metadata = tokenMetadata[tokenId];
		SellingListing[] memory listings = sellingListings[tokenId][
			metadata.timesSold
		];

		SellingListing memory listing;

		if (listings.length > 0) {
			listing = listings[listings.length - 1];
		}

		return
			TokenInfo(
				tokenId,
				tokenURI(tokenId),
				ownerOf(tokenId),
				metadata,
				listing
			);
	}

	function getTokensOfOwner(
		address addr
	) public view returns (TokenInfo[] memory) {
		uint256 balance = balanceOf(addr);
		TokenInfo[] memory tokens = new TokenInfo[](balance);
		for (uint256 i = 0; i < balance; i++) {
			uint256 tokenId = tokenOfOwnerByIndex(addr, i);
			tokens[i] = getToken(tokenId);
		}

		return tokens;
	}

	function listTokens() public view returns (TokenInfo[] memory) {
		uint256 totalSupply = totalSupply();
		TokenInfo[] memory tokens = new TokenInfo[](totalSupply);
		for (uint256 i = 0; i < totalSupply; i++) {
			uint256 tokenId = tokenByIndex(i);
			tokens[i] = getToken(tokenId);
		}

		return tokens;
	}
}
