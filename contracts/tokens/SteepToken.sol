// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//a mock token for busd
contract SteepToken is ERC20 {
    constructor(uint256 totalSupply_) ERC20("steep labs erc20 token", "STEEP") {
        _mint(msg.sender, totalSupply_);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}
