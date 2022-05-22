// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//a mock sale token for a mock project called as DIY
contract DIYSaleToken is ERC20 {
    constructor(uint256 totalSupply_) ERC20("do-it-yourself erc20 token", "DIY") {
        _mint(msg.sender, totalSupply_);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}
