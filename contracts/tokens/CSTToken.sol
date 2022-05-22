// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "../interfaces/IMintableERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//a mock token for busd
contract CSTToken is ERC20, IMintableERC20, Ownable {
    address _faucet;
    constructor(uint256 mintAmount_) ERC20("crypto-star erc20 token", "CST") {
      _mint(msg.sender, mintAmount_);
    }
  
    function mint(address to_, uint256 amount_) public override {
        require(msg.sender == _faucet, 'forbidden!, u r ! faucet.');
        _mint(to_, amount_);
    }

    function setFaucet(address faucet_) external onlyOwner {
      _faucet = faucet_;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}
