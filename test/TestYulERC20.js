const { ethers } = require("hardhat")
const { expect } = require("chai");
require("dotenv").config();

async function impersonateAddress(address) {
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [address],
    });
    const signer = await ethers.provider.getSigner(address);
    signer.address = signer.address;
    return signer;
}

describe("TestYulERC20", function () {
    let YulERC20;
    before(async function () {
        let signers = await ethers.getSigners();
        console.log(signers, 'signers');
        owner = signers[0];
        user1 = signers[1];
        user2 = signers[2];

        YulERC20 = await ethers.deployContract('contracts/YulERC20.sol:YulERC20', [
            "Test Yul ERC20",
            "TSTYULERC20",
            ethers.parseUnits('1000', 18)
        ]);
        await YulERC20.waitForDeployment();
    });

    it("Test state params", async function () {
        console.log(await YulERC20.name(), 'name');
        console.log(await YulERC20.symbol(), 'symbol');
        console.log(await YulERC20.balanceOf(owner.address), 'balanceOf');
        console.log(await YulERC20.totalSupply(), 'totalSupply');
        return;
        let tx = await YulERC20.setName("asdasd");
        await tx.wait(1);
        
        console.log(await ethers.provider.getStorage(YulERC20.target, 0), 'getStorage');

        tx = await YulERC20.setName("asdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasd");
        await tx.wait(1);
        console.log(await ethers.provider.getStorage(YulERC20.target, ethers.solidityPackedKeccak256(['uint256'], [0])), 'getStorage');

        console.log(await ethers.provider.getStorage(
            YulERC20.target, 
            BigInt(ethers.solidityPackedKeccak256(['uint256'], [0])) + 1n
        ), 'getStorage');

        // rules to store a string in state:
            // if size of string is lesser than 31 bytes then the string content and the length get stored inside the string base storage slot

    });
});
