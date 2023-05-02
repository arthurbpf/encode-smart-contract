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
		let legalTransferTxn = await encodeContract[
			'safeTransferFrom(address,address,uint256)'
		](owner.address, randomPerson.address, 0);

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
		'Balance of owner before placing requests:',
		randomPersonBalance.toString()
	);

	let buyingRequestTxn = await encodeContract.createBuyingRequest(0, {
		value: hre.ethers.utils.parseEther('0.005')
	});
	await buyingRequestTxn.wait();

	randomPersonBalance = await hre.ethers.provider.getBalance(owner.address);
	console.log(
		'Balance of owner after placing requests:',
		randomPersonBalance.toString()
	);

	let contractBalance = await hre.ethers.provider.getBalance(
		encodeContract.address
	);
	console.log('Contract balance:', contractBalance.toString());

	let getBuyingRequests = await encodeContract.getBuyingRequests(0);
	console.log(getBuyingRequests);

	const acceptRequestTxn = await encodeContract
		.connect(randomPerson)
		.acceptBuyingRequest(0, 0);
	acceptRequestTxn.wait();

	contractBalance = await hre.ethers.provider.getBalance(
		encodeContract.address
	);
	console.log('Contract balance:', contractBalance.toString());
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
