// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Encode is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
	constructor() ERC721('Encode', 'ENC') {}

	function safeMint(
		address to,
		uint256 tokenId,
		string memory uri
	) public onlyOwner {
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
}
