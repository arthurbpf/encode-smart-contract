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

	// map address to eth balance
	mapping(address => uint256) public balances;

	// event to be fired when a user sends eth to the contract
	event Received(address indexed sender, uint256 amount);

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

	struct TokenInfo {
		uint256 id;
		string uri;
		address owner;
		TokenMetadata metadata;
		SellingListing sellingListing;
	}

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

	// Custom overrides
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public override(ERC721, IERC721) {
		delete buyingRequests[_tokenId];
		delete sellingListing[_tokenId];

		// Call the parent implementation of the function
		super.safeTransferFrom(_from, _to, _tokenId);
	}

	// Custom functions

	receive() external payable {
		emit Received(msg.sender, msg.value);
	}

	function createBuyingRequest(uint256 tokenId) public payable {
		require(ownerOf(tokenId) != msg.sender, 'You cannot buy your own NFT');
		require(msg.value > 0, 'Offer must be greater than 0');

		// check if there is no other pending request from same buyer
		BuyingRequest[] storage requests = buyingRequests[tokenId];
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

		uint256 requestId = _buyingRequestIdCounter.current();
		_buyingRequestIdCounter.increment();

		buyingRequests[tokenId].push(
			BuyingRequest(
				requestId,
				msg.sender,
				msg.value,
				block.timestamp,
				BuyingRequestStatus.PENDING
			)
		);
	}

	function cancelBuyingRequest(uint256 tokenId, uint256 requestId) public {
		BuyingRequest[] storage requests = buyingRequests[tokenId];
		for (uint256 i = 0; i < requests.length; i++) {
			if (requests[i].id == requestId) {
				require(
					requests[i].buyer == msg.sender,
					'You cannot cancel buying requests that you did not create'
				);
				require(
					requests[i].status == BuyingRequestStatus.PENDING,
					'You cannot cancel buying requests that are not pending'
				);

				requests[i].status = BuyingRequestStatus.REJECTED;
				payable(msg.sender).transfer(requests[i].offer);
			}
		}
	}

	function getBuyingRequests(
		uint256 tokenId
	) public view returns (BuyingRequest[] memory) {
		// return buyingRequests with pending status
		BuyingRequest[] storage requests = buyingRequests[tokenId];
		BuyingRequest[] memory pendingRequests = new BuyingRequest[](
			requests.length
		);
		uint256 pendingRequestsCount = 0;
		for (uint256 i = 0; i < requests.length; i++) {
			if (requests[i].status == BuyingRequestStatus.PENDING) {
				pendingRequests[pendingRequestsCount] = requests[i];
				pendingRequestsCount++;
			}
		}

		BuyingRequest[] memory result = new BuyingRequest[](
			pendingRequestsCount
		);
		for (uint256 i = 0; i < pendingRequestsCount; i++) {
			result[i] = pendingRequests[i];
		}

		return result;
	}

	function acceptBuyingRequest(uint256 tokenId, uint256 requestId) public {
		require(
			ownerOf(tokenId) == msg.sender,
			'You cannot accept buying requests for NFTs that you do not own'
		);

		BuyingRequest[] storage requests = buyingRequests[tokenId];
		for (uint256 i = 0; i < requests.length; i++) {
			if (requests[i].status != BuyingRequestStatus.PENDING) {
				continue;
			}

			if (requests[i].id == requestId) {
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

	function createSellingListing(uint256 tokenId, uint256 price) public {
		require(
			ownerOf(tokenId) == msg.sender,
			'You cannot sell NFTs that you do not own'
		);
		require(price > 0, 'Price must be greater than 0');

		approve(address(this), tokenId);
		sellingListing[tokenId] = SellingListing(price, block.timestamp);
	}

	function cancelSellingListing(uint256 tokenId) public {
		require(
			ownerOf(tokenId) == msg.sender,
			'You cannot cancel selling listings for NFTs that you do not own'
		);

		approve(address(0), tokenId);
		delete sellingListing[tokenId];
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

		// cancel all buying buyingRequests
		BuyingRequest[] storage requests = buyingRequests[tokenId];
		for (uint256 i = 0; i < requests.length; i++) {
			if (requests[i].status == BuyingRequestStatus.PENDING) {
				requests[i].status = BuyingRequestStatus.REJECTED;
				payable(requests[i].buyer).transfer(requests[i].offer);
			}
		}

		// transfer token
		_transfer(seller, buyer, tokenId);

		// delete listing
		delete sellingListing[tokenId];

		// transfer funds
		payable(seller).transfer(msg.value);
	}

	function getTokensOfOwner(
		address addr
	) public view returns (TokenInfo[] memory) {
		uint256 balance = balanceOf(addr);
		TokenInfo[] memory tokens = new TokenInfo[](balance);
		for (uint256 i = 0; i < balance; i++) {
			uint256 tokenId = tokenOfOwnerByIndex(addr, i);

			TokenMetadata memory metadata = tokenMetadata[tokenId];
			SellingListing memory listing = sellingListing[tokenId];

			tokens[i] = TokenInfo(
				tokenId,
				tokenURI(tokenId),
				ownerOf(tokenId),
				metadata,
				listing
			);
		}

		return tokens;
	}

	function getToken(uint256 tokenId) public view returns (TokenInfo memory) {
		TokenMetadata memory metadata = tokenMetadata[tokenId];
		SellingListing memory listing = sellingListing[tokenId];

		return
			TokenInfo(
				tokenId,
				tokenURI(tokenId),
				ownerOf(tokenId),
				metadata,
				listing
			);
	}

	function listTokens() public view returns (TokenInfo[] memory) {
		uint256 totalSupply = totalSupply();
		TokenInfo[] memory tokens = new TokenInfo[](totalSupply);
		for (uint256 i = 0; i < totalSupply; i++) {
			uint256 tokenId = tokenByIndex(i);

			TokenMetadata memory metadata = tokenMetadata[tokenId];
			SellingListing memory listing = sellingListing[tokenId];

			tokens[i] = TokenInfo(
				tokenId,
				tokenURI(tokenId),
				ownerOf(tokenId),
				metadata,
				listing
			);
		}

		return tokens;
	}
}
