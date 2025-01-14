# YulERC20
    
### PURPOSE
The following [smart contract](https://github.com/mnedelchev-vn/yul-erc20/tree/main/contracts/YulERC20.sol) represents a ERC20 token standard written entirely with Yul language. The idea is to dive deep into how memory and state locations work on a lower level inside Solidity. The following actions are performed in inline assembly:
* math operations; `if` conditions with `eq()`, `lt()`, `gt()`; iterations with `for`
* storing of a mapping value; storing of a mapping value inside another mapping
* storing, caching, converting & returning state data directly in assembly
* emitting events with indexed parameters in assembly
* reverting custom errors with parameters in assembly

### Project setup commands
* ```npm install``` - Downloading required packages.
* ```npx hardhat test test/TestYulERC20.js --network hardhat``` - Test the YulERC20 smart contract methods.

### Before starting make sure to create .env file at the root of the project containing the following data:
```
    MAINNET_NODE=XYZ
```
