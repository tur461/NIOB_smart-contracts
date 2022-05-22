// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//a mock token for cflu (coinfluence ido lp native token)
contract CFLUToken is ERC20 {
    constructor(uint256 totalSupply_) ERC20("CoinFluence erc20 Token", "CFLU") {
        _mint(msg.sender, totalSupply_);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}
