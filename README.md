# EIP712 DEMO

### Project setup commands:
* ```npm install``` - Downloading required packages.
* ```npx hardhat test --network hardhat test/TestVerifyEIP721.js``` - Test the permit deposit on a local hardhat fork.

### Before starting make sure to create .env file at the root of the project containing the following data:
```
    MAINNET_NODE=XYZ
```
    
### PURPOSE:
This is a **DEMO** project just to test the functionality of EIP712. ```contracts/TestContract.sol``` has a method called ```depositWithPermit``` which is verifying off-chain signed messages. Run ```npx hardhat test test/TestVerifyEIP721.js``` to reproduce the submission of the off-chain presigned transaction & the on-chain validation.

**Important** - using EIP712 is double edged sword, because it opens the possibility for malicious acts by reusing the already signed message. This is why I've added two extra validations:
- **By chainId** - making sure the signed message won't get executed on different EVM supported chain.
- **By nonce** - making sure the signed message won't be reused again in the same contract thus making infinite loop of deposits until the holder is out of tokens.