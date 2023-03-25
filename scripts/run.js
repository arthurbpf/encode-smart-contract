const main = async () => {
	const [owner, randomPerson] = await hre.ethers.getSigners();
	const waveContractFactory = await hre.ethers.getContractFactory('Encode');
	const waveContract = await waveContractFactory.deploy({
		value: hre.ethers.utils.parseEther('0.1')
	});
	await waveContract.deployed();

	console.log('Contract deployed to:', waveContract.address);
	console.log('Contract deployed by:', owner.address);

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
