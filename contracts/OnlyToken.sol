// SPDX-License-Identifier: Apache License, Version 2.0
pragma solidity ^0.6.10;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OnlyToken is ERC20("NFT Only Club Token","ONLY") {
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (uint256 _totalSupply) public {
        _mint(_msgSender(), _totalSupply);
    }
}
