// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router.sol";

/**
 * @title 部署UniswapV2Router的脚本
 * @notice 此脚本部署UniswapV2Factory和UniswapV2Router
 */
contract DeployRouterScript is Script {
    function run() public {
    
        vm.startBroadcast();

        // 部署Factory
        UniswapV2Factory factory = new UniswapV2Factory(msg.sender);
        console.log("UniswapV2Factory deployed: ", address(factory));

        // 部署Router
        UniswapV2Router router = new UniswapV2Router(address(factory));
        console.log("UniswapV2Router deployed: ", address(router));

        vm.stopBroadcast();
    }
} 