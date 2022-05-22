//SPDX-License-Idetifier: MIT
pragma solidity ^0.8.4;

interface INiobSwapCallee {
    function NiobSwapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}