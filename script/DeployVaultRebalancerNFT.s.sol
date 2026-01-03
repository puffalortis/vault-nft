// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { VaultRebalancerNFT } from "../src/VaultRebalancerNFT.sol";

contract DeployVaultRebalancerNFT is Script {
    function run() external returns (VaultRebalancerNFT vault) {
        address owner = msg.sender;

        // MUST already exist
        address executionVault = vm.envAddress("EXECUTION_VAULT");

        vm.startBroadcast();

        vault = new VaultRebalancerNFT(
            owner,
            executionVault
        );

        vm.stopBroadcast();
    }
}
