// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Encode {
	uint256 totalWaves;
	uint256 private seed;

	event NewWave(address indexed from, uint256 timestamp, string message);

	struct Wave {
		address waver; // Endereço do usuário que deu tchauzinho
		string message; // Mensagem que o usuário envio
		uint256 timestamp; // Data/hora de quando o usuário tchauzinhou.
	}

	Wave[] waves;

	mapping(address => uint256) public lastWavedAt;

	constructor() payable {
		seed = (block.timestamp + block.difficulty) % 100;
		console.log('Smart contract constructor ran!');
	}

	function wave(string memory _message) public {
		require(
			lastWavedAt[msg.sender] + 15 minutes < block.timestamp,
			'Wait at least 15 minutes to wave again!'
		);

		lastWavedAt[msg.sender] = block.timestamp;

		totalWaves += 1;
		console.log(
			'%s deu um tchauzinho e mandou dizer "%s"!',
			msg.sender,
			_message
		);

		waves.push(Wave(msg.sender, _message, block.timestamp));

		seed = (block.difficulty + block.timestamp + seed) % 100;
		console.log('random hash generated: %d', seed);

		if (seed <= 50) {
			console.log('%s ganhou!', msg.sender);

			uint256 prizeAmount = 0.0001 ether;
			require(
				prizeAmount <= address(this).balance,
				'Tentando sacar mais dinheiro que o contrato possui.'
			);
			(bool success, ) = (msg.sender).call{value: prizeAmount}('');
			require(success, 'Falhou em sacar dinheiro do contrato.');
		}

		emit NewWave(msg.sender, block.timestamp, _message);
	}

	function getAllWaves() public view returns (Wave[] memory) {
		return waves;
	}

	function getTotalWaves() public view returns (uint256) {
		console.log('Temos um total de %d tchauzinhos!', totalWaves);
		return totalWaves;
	}
}
