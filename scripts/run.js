const main = async () => {
	const [owner, randomPerson] = await hre.ethers.getSigners();
	const encodeContractFactory = await hre.ethers.getContractFactory('Encode');
	const encodeContract = await encodeContractFactory.deploy();
	await encodeContract.deployed();

	console.log('Contract deployed to:', encodeContract.address);
	console.log('Contract deployed by:', owner.address);

	let balance = await encodeContract.balanceOf(randomPerson.address);
	console.log('Balance of owner:', balance.toString());

	let mintTxn = await encodeContract.safeMint(
		owner.address,
		'https://test',
		'title',
		'description'
	);
	await mintTxn.wait();

	balance = await encodeContract.balanceOf(owner.address);
	console.log('Balance of owner after minting:', balance.toString());

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

	let randomPersonBalance = await hre.ethers.provider.getBalance(
		randomPerson.address
	);
	console.log(
		'Balance of randomPerson before placing requests:',
		randomPersonBalance.toString()
	);

	let buyingRequestTxn = await encodeContract
		.connect(randomPerson)
		.createBuyingRequest(0, 100);
	await buyingRequestTxn.wait();

	let buyingRequestTxn2 = await encodeContract
		.connect(randomPerson)
		.createBuyingRequest(0, 1000);
	await buyingRequestTxn2.wait();

	randomPersonBalance = await hre.ethers.provider.getBalance(
		randomPerson.address
	);
	console.log(
		'Balance of randomPerson after placing requests:',
		randomPersonBalance.toString()
	);

	let getBuyingRequests = await encodeContract.getBuyingRequests(0);
	console.log(getBuyingRequests);
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
