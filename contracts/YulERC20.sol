// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IERC20} from "./interfaces/IERC20.sol";


/// @title YulERC20
/// @author https://twitter.com/mnedelchev_
contract YulERC20 is IERC20 {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    constructor(string memory name_, string memory symbol_, uint256 mintedTokens) {
        assembly {
            let currentMemoryPointer := mload(0x40)

            let nameLen := mload(name_)
            if gt(nameLen, 31) {
                revert(0, 0)
            }

            let symbolLen := mload(symbol_)
            if gt(symbolLen, 31) {
                revert(0, 0)
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
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
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

            mstore(currentMemoryPointer, owner)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            mstore(currentMemoryPointer, _allowances.slot)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)

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
        require(_allowances[from][msg.sender] >= value, "ERROR: invalid allowance");
        _approve(from, msg.sender, _allowances[from][msg.sender] - value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        assembly {
            if iszero(from) {
                revert(0, 0)
            }
            if iszero(to) {
                revert(0, 0)
            }
            let currentMemoryPointer := mload(0x40)

            // decrease msg.sender balance
            mstore(currentMemoryPointer, from)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            mstore(currentMemoryPointer, _balances.slot)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            sstore(keccak256(sub(currentMemoryPointer, 0x40), 0x40), sub(sload(keccak256(sub(currentMemoryPointer, 0x40), 0x40)), value))

            // increase to balance
            mstore(currentMemoryPointer, to)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)
            mstore(currentMemoryPointer, _balances.slot)
            currentMemoryPointer := add(currentMemoryPointer, 0x20)

            sstore(keccak256(sub(currentMemoryPointer, 0x40), 0x40), add(sload(keccak256(sub(currentMemoryPointer, 0x40), 0x40)), value))

            // transfer event 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef

            // update free memory pointer
            mstore(0x40, currentMemoryPointer)
        }
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        assembly {
            if iszero(owner) {
                revert(0, 0)
            }
            if iszero(spender) {
                revert(0, 0)
            }
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

            // set the _allowances[owner][spender] allowance
            sstore(keccak256(sub(currentMemoryPointer, 0x40), 0x40), value)

            /* if eq(emitEvent, true) {
                log2(
                    keccak256(0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, 0x20), 
                    owner, 
                    spender, 
                    value
                )
            } */

            // update free memory pointer
            mstore(0x40, currentMemoryPointer)
        }
    }
}