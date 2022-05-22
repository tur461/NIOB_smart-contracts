// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";

contract ContractCloner {
  event Cloned(address indexed by, address original_,  address cloned_);
  constructor() {}
  
  function clone(address original_) external returns(address) {
    require(original_ != address(0), "address must be valid!");
    address clone = Clones.clone(_idoOriginal);
    emit Cloned(msg.sender, original_, Clone);
    return clone;
  }
}
