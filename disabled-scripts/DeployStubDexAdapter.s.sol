// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/adapters/StubDexAdapter.sol";

contract DeployStubDexAdapter is Script {
    function run() external {
        vm.startBroadcast();
        new StubDexAdapter();
        vm.stopBroadcast();
    }
}
