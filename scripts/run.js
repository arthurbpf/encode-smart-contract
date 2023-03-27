const main = async () => {
	const [owner, randomPerson] = await hre.ethers.getSigners();
	const encodeContractFactory = await hre.ethers.getContractFactory('Encode');
	const encodeContract = await encodeContractFactory.deploy();
	await encodeContract.deployed();

	console.log('Contract deployed to:', encodeContract.address);
	console.log('Contract deployed by:', owner.address);

	let balance = await encodeContract.balanceOf(randomPerson.address);
	console.log('Balance of randomPerson:', balance.toString());

	let mintTxn = await encodeContract
		.connect(randomPerson)
		.safeMint(randomPerson.address, 'https://test');
	await mintTxn.wait();

	balance = await encodeContract.balanceOf(randomPerson.address);
	console.log('Balance of randomPerson after minting:', balance.toString());

	let tokenURI = await encodeContract.tokenURI(0);
	console.log('Token URI: ', tokenURI);

	try {
		let illegalTransferTxn = await encodeContract[
			'safeTransferFrom(address,address,uint256)'
		](randomPerson.address, owner.address, 0);
		await illegalTransferTxn.wait();
	} catch (error) {
		console.error('Error: ', "You don't own this token");
	}

	try {
		let legalTransferTxn = await encodeContract
			.connect(randomPerson)
			['safeTransferFrom(address,address,uint256)'](
				randomPerson.address,
				owner.address,
				0
			);

		await legalTransferTxn.wait();
	} catch (error) {
		console.error('Error: ', error);
	}

	balance = await encodeContract.balanceOf(randomPerson.address);
	console.log('Balance of randomPerson after transfer:', balance.toString());

	balance = await encodeContract.balanceOf(owner.address);
	console.log('Balance of owner after transfer:', balance.toString());

	/*
	let contractBalance = await hre.ethers.provider.getBalance(
		waveContract.address
	);

	console.log(
		'Contract balance:',
		hre.ethers.utils.formatEther(contractBalance)
	);

	let waveTxn = await waveContract.wave('Primeira mensagem!');
	await waveTxn.wait();

	contractBalance = await hre.ethers.provider.getBalance(waveContract.address);

	console.log(
		'Contract balance:',
		hre.ethers.utils.formatEther(contractBalance)
	);

	waveTxn = await waveContract.connect(randomPerson).wave('Outra mensagem!');
	await waveTxn.wait();

	contractBalance = await hre.ethers.provider.getBalance(waveContract.address);

	console.log(
		'Contract balance:',
		hre.ethers.utils.formatEther(contractBalance)
	);

	let allWaves = await waveContract.getAllWaves();
	console.log(allWaves);

	// Should not complete given cooldown strategy
	waveTxn = await waveContract.connect(randomPerson).wave('Outra mensagem!');
	await waveTxn.wait();
	*/
};

const runMain = async () => {
	try {
		await main();
		process.exit(0);
	} catch (error) {
		console.log(error);
		process.exit(1);
	}
};

runMain();
