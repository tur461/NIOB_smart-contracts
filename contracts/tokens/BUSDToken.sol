// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//a mock token for busd
contract BUSDToken is ERC20 {
    constructor(uint256 totalSupply_) ERC20("custom busd erc20 Token", "BUSD") {
        _mint(msg.sender, totalSupply_);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}
