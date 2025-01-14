// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "./interfaces/IERC20.sol";


/// @title YulERC20
/// @author https://twitter.com/mnedelchev_
contract YulERC20 is IERC20 {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    error ERC20InvalidLength(); // 0xe11358408f7461198dab0938f0667f759a23b367d71c2af8dcb5a300f1c9aae3
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed); // 0xe450d38cd8d9f7d95077d567d60ed49c7254716e6ad08fc9872816c97e0ffec6
    error ERC20InvalidSender(address sender); // 0x96c6fd1edd0cd6ef7ff0ecc0facdf53148dc0048b57fe58af65755250a7a96bd
    error ERC20InvalidReceiver(address receiver); // 0xec442f055133b72f3b2f9f0bb351c406b178527de2040a7d1feb4e058771f613
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed); // 0xfb8f41b23e99d2101d86da76cdfa87dd51c82ed07d3cb62cbc473e469dbc75c3
    error ERC20InvalidApprover(address approver); // 0xe602df05cc75712490294c6c104ab7c17f4030363910a7a2626411c6d3118847
    error ERC20InvalidSpender(address spender); // 0x94280d62c347d8d9f4d59a76ea321452406db88df38e0c9da304f58b57b373a2

    constructor(string memory name_, string memory symbol_, uint256 mintedTokens) {
        assembly {
            let currentMemoryPointer := mload(0x40)

            let nameLen := mload(name_)
            if gt(nameLen, 31) {
                mstore(currentMemoryPointer, 0xe11358408f7461198dab0938f0667f759a23b367d71c2af8dcb5a300f1c9aae3)
                revert(currentMemoryPointer, 0x04)
            }

            let symbolLen := mload(symbol_)
            if gt(symbolLen, 31) {
                mstore(currentMemoryPointer, 0xe11358408f7461198dab0938f0667f759a23b367d71c2af8dcb5a300f1c9aae3)
                revert(currentMemoryPointer, 0x04)
            }

            // copy token name in memory in order to save it state
            for { let i := 0 } lt(i, nameLen) { i := add(i, 1) } {
                mstore(add(currentMemoryPointer, i), mload(add(name_, add(0x20, i))))
            }
            mstore8(sub(add(currentMemoryPointer, 0x20), 1), mul(nameLen, 2))

            // set token name in the state
            sstore(_name.slot, mload(currentMemoryPointer))
            currentMemoryPointer := add(currentMemoryPointer, 0x20)

            // copy token symbol in memory in order to save it state
            for { let i := 0 } lt(i, symbolLen) { i := add(i, 1) } {
                mstore(add(currentMemoryPointer, i), mload(add(symbol_, add(0x20, i))))
            }
            mstore8(sub(add(currentMemoryPointer, 0x20), 1), mul(symbolLen, 2))

            // set token symbol in the state
            sstore(_symbol.slot, mload(currentMemoryPointer))
            currentMemoryPointer := add(currentMemoryPointer, 0x20)

            // mint tokens to the deployer
            mstore(currentMemoryPointer, caller())
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            mstore(currentMemoryPointer, _balances.slot)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            sstore(keccak256(sub(currentMemoryPointer, 0x40), 0x40), mintedTokens)

            // increase totalSupply, because we mint tokens to the deployer
            sstore(_totalSupply.slot, mintedTokens)

            // update free memory pointer
            mstore(0x40, currentMemoryPointer)
        }
    }

    function name() public view virtual returns (string memory) {
        return _getStateStringValue(0);
    }

    function symbol() public view virtual returns (string memory) {
        return _getStateStringValue(1);
    }

    function _getStateStringValue(uint256 slot) internal view returns (string memory) {
        assembly {
            let currentMemoryPointer := mload(0x40)
            let data := sload(slot)
            
            // copy string from state to memory
            mstore(currentMemoryPointer, 0x20)
            mstore(add(currentMemoryPointer, 0x20), and(data, 0xff))
            mstore(add(currentMemoryPointer, 0x40), data)
            // strings in state contain the string length on right-most byte; this is not needed when storing in memory
            mstore8(sub(add(currentMemoryPointer, 0x60), 1), 0)

            // Return the string from memory
            return(currentMemoryPointer, 0x60)
        }
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        assembly {
            let currentMemoryPointer := mload(0x40)
            mstore(currentMemoryPointer, sload(_totalSupply.slot))

            // update free memory pointer
            mstore(0x40, add(currentMemoryPointer, 0x20))

            return (currentMemoryPointer, 0x20)
        }
    }

    function balanceOf(address account) external view returns (uint256) {
        assembly {
            let currentMemoryPointer := mload(0x40)

            // copy balance from state to memory
            mstore(currentMemoryPointer, account)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            mstore(currentMemoryPointer, _balances.slot)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            mstore(currentMemoryPointer, sload(keccak256(sub(currentMemoryPointer, 0x40), 0x40)))

            // update free memory pointer
            mstore(0x40, add(currentMemoryPointer, 0x20))
            return (currentMemoryPointer, 0x20)
        }
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        assembly {
            let currentMemoryPointer := mload(0x40)

            // get the storage slot of the _allowances[owner] mapping
            mstore(currentMemoryPointer, owner)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            mstore(currentMemoryPointer, _allowances.slot)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)

            // get the storage slot of the _allowances[owner][spender] mapping
            mstore(currentMemoryPointer, spender)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            mstore(currentMemoryPointer, keccak256(sub(currentMemoryPointer, 0x60), 0x40))
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            mstore(currentMemoryPointer, sload(keccak256(sub(currentMemoryPointer, 0x40), 0x40)))

            // update free memory pointer
            mstore(0x40, add(currentMemoryPointer, 0x20))
            return (currentMemoryPointer, 0x20)
        }
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= value, ERC20InsufficientAllowance(
            msg.sender,
            currentAllowance,
            value
        ));
        _approve(from, msg.sender, currentAllowance - value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        assembly {
            let currentMemoryPointer := mload(0x40)
            
            if iszero(from) {
                mstore(currentMemoryPointer, 0x96c6fd1edd0cd6ef7ff0ecc0facdf53148dc0048b57fe58af65755250a7a96bd)
                mstore(add(currentMemoryPointer, 0x04), from)
                revert(currentMemoryPointer, add(0x04, 0x20))
            }
            if iszero(to) {
                mstore(currentMemoryPointer, 0xec442f055133b72f3b2f9f0bb351c406b178527de2040a7d1feb4e058771f613)
                mstore(add(currentMemoryPointer, 0x04), to)
                revert(currentMemoryPointer, add(0x04, 0x20))
            }

            // get the storage slot of the _balances[from] mapping
            mstore(currentMemoryPointer, from)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            mstore(currentMemoryPointer, _balances.slot)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)

            // cache from address balance to reduce sload opCode requests
            mstore(currentMemoryPointer, sload(keccak256(sub(currentMemoryPointer, 0x40), 0x40)))
            currentMemoryPointer := add(currentMemoryPointer, 0x20)

            // revert if from address's balance is lesser than value
            if lt(mload(sub(currentMemoryPointer, 0x20)), value) {
                mstore(currentMemoryPointer, 0xe450d38cd8d9f7d95077d567d60ed49c7254716e6ad08fc9872816c97e0ffec6)
                mstore(add(currentMemoryPointer, 0x04), from)
                mstore(add(currentMemoryPointer, add(0x04, 0x20)), mload(sub(currentMemoryPointer, 0x20)))
                mstore(add(currentMemoryPointer, add(0x04, 0x40)), value)
                revert(currentMemoryPointer, add(0x04, 0x60))
            }

            // decrease balance of from
            sstore(keccak256(sub(currentMemoryPointer, 0x60), 0x40), sub(mload(sub(currentMemoryPointer, 0x20)), value))

            // get the storage slot of the _balances[to] mapping
            mstore(currentMemoryPointer, to)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            mstore(currentMemoryPointer, _balances.slot)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)

            // increase balance of to
            sstore(keccak256(sub(currentMemoryPointer, 0x40), 0x40), add(sload(keccak256(sub(currentMemoryPointer, 0x40), 0x40)), value))

            // store value in memory in order to log it into an event
            mstore(currentMemoryPointer, value)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)

            // emit Transfer event
            log3(
                sub(currentMemoryPointer, 0x20),
                0x20,
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, // keccak("Approval(address,address,uint256)")
                mload(sub(currentMemoryPointer, 0xa0)), // topic1 from
                mload(sub(currentMemoryPointer, 0x60))  // topic2 to
            )

            // update free memory pointer
            mstore(0x40, currentMemoryPointer)
        }
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        assembly {
            let currentMemoryPointer := mload(0x40)
            if iszero(owner) {
                mstore(currentMemoryPointer, 0xe602df05cc75712490294c6c104ab7c17f4030363910a7a2626411c6d3118847)
                mstore(add(currentMemoryPointer, 0x04), owner)
                revert(currentMemoryPointer, add(0x04, 0x20))
            }
            if iszero(spender) {
                mstore(currentMemoryPointer, 0x94280d62c347d8d9f4d59a76ea321452406db88df38e0c9da304f58b57b373a2)
                mstore(add(currentMemoryPointer, 0x04), spender)
                revert(currentMemoryPointer, add(0x04, 0x20))
            }

            // get the storage slot of the _allowances[owner] mapping
            mstore(currentMemoryPointer, owner)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            mstore(currentMemoryPointer, _allowances.slot)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)

            // get the storage slot of the _allowances[owner][spender] mapping
            mstore(currentMemoryPointer, spender)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            mstore(currentMemoryPointer, keccak256(sub(currentMemoryPointer, 0x60), 0x40))
            currentMemoryPointer := add(currentMemoryPointer, 0x20)

            // set the _allowances[owner][spender] allowance
            sstore(keccak256(sub(currentMemoryPointer, 0x40), 0x40), value)

            // store value in memory in order to log it into an event
            mstore(currentMemoryPointer, value)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)

            // emit Approval event
            if eq(emitEvent, true) {
                log3(
                    sub(currentMemoryPointer, 0x20),
                    0x20,
                    0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, // keccak("Approval(address,address,uint256)")
                    mload(sub(currentMemoryPointer, 0xa0)), // topic1 owner
                    mload(sub(currentMemoryPointer, 0x60))  // topic2 spender
                )
            }

            // update free memory pointer
            mstore(0x40, currentMemoryPointer)
        }
    }
}