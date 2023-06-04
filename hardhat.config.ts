import 'dotenv/config';
import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';

const config: HardhatUserConfig = {
	solidity: {
		version: '0.8.19',
		settings: {
			optimizer: {
				enabled: true,
				runs: 200
			}
		}
	},
	networks: {
		goerli: {
			url: process.env.ALCHEMY_GOERLI_URL,
			accounts: [process.env.GOERLI_WALLET_PRIVATE_KEY!]
		},
		sepolia: {
			url: process.env.ALCHEMY_SEPOLIA_URL,
			accounts: [process.env.SEPOLIA_WALLET_PRIVATE_KEY!]
		}
	}
};

export default config;
