const { ethers } = require("hardhat")
const { expect } = require("chai");

describe("TestYulERC20", function () {
    let YulERC20;
    const contractParams = {
        name: 'Test Yul ERC20',
        symbol: 'TSTYULERC20',
        decimals: 18
    };
    before(async function () {
        let signers = await ethers.getSigners();
        user1 = signers[0];
        user2 = signers[1];

        YulERC20 = await ethers.deployContract('contracts/YulERC20.sol:YulERC20', [
            contractParams.name,
            contractParams.symbol,
            ethers.parseUnits('1000', contractParams.decimals)
            
        ]);
        await YulERC20.waitForDeployment();
    });

    it("Test name()", async function () {
        expect(removeNullBytes(await YulERC20.name())).to.eq(contractParams.name);
    });

    it("Test symbol()", async function () {
        expect(removeNullBytes(await YulERC20.symbol())).to.eq(contractParams.symbol);
    });

    it("Test transfer", async function () {
        const user1Balance = await YulERC20.balanceOf(user1.address);
        const user2Balance = await YulERC20.balanceOf(user2.address);

        const transferAmount = ethers.parseUnits('5', contractParams.decimals);
        let tx = await YulERC20.connect(user1).transfer(user2.address, transferAmount);
        await tx.wait();

        const user1BalanceAfter = await YulERC20.balanceOf(user1.address);
        const user2BalanceAfter = await YulERC20.balanceOf(user2.address);
        expect(user1Balance).to.be.greaterThan(user1BalanceAfter);
        expect(user1Balance).to.eq(user1BalanceAfter + transferAmount);
        expect(user2BalanceAfter).to.be.greaterThan(user2Balance);
        expect(user2BalanceAfter).to.eq(user2Balance + transferAmount);
    });

    it("Test approve", async function () {
        const user2Allowance = await YulERC20.allowance(user1.address, user2.address);
        const newApprove = user2Allowance + ethers.parseUnits('10', contractParams.decimals);

        let tx = await YulERC20.connect(user1).approve(user2.address, newApprove);
        await tx.wait();

        const user2AllowanceAfter = await YulERC20.allowance(user1.address, user2.address);
        expect(user2AllowanceAfter).to.be.greaterThan(user2Allowance);
    });

    it("Test transferFrom", async function () {
        const user1Balance = await YulERC20.balanceOf(user1.address);
        const user2Balance = await YulERC20.balanceOf(user2.address);
        const allowance = await YulERC20.allowance(user1.address, user2.address);

        const transferAmount = ethers.parseUnits('5', contractParams.decimals);
        let tx = await YulERC20.connect(user2).transferFrom(user1.address, user2.address, transferAmount);
        await tx.wait(); 

        const allowanceAfter = await YulERC20.allowance(user1.address, user2.address);
        const user1BalanceAfter = await YulERC20.balanceOf(user1.address);
        const user2BalanceAfter = await YulERC20.balanceOf(user2.address);
        expect(allowance).to.be.greaterThan(allowanceAfter);
        expect(allowance).to.eq(allowanceAfter + transferAmount);
        
        expect(user2BalanceAfter).to.be.greaterThan(user2Balance);
        expect(user2BalanceAfter).to.eq(user2Balance + transferAmount);
        expect(user1Balance).to.be.greaterThan(user1BalanceAfter);
        expect(user1Balance).to.eq(user1BalanceAfter + transferAmount);
    });

    it("Test approval revoke", async function () {
        const user2Allowance = await YulERC20.allowance(user1.address, user2.address);

        let tx = await YulERC20.connect(user1).approve(user2.address, 0);
        await tx.wait();

        const user2AllowanceAfter = await YulERC20.allowance(user1.address, user2.address);
        expect(user2Allowance).to.be.greaterThan(user2AllowanceAfter);
        expect(user2AllowanceAfter).to.eq(0);
    });
});

function removeNullBytes(str){
    return str.split("").filter(char => char.codePointAt(0)).join("")
}