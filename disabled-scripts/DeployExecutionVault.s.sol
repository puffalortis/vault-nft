// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {ExecutionVault} from "../src/ExecutionVault.sol";

contract DeployExecutionVault is Script {
    /// -----------------------------------------------------------------------
    /// CONFIG — UPDATE ONLY IF YOU MEAN TO
    /// -----------------------------------------------------------------------

    // Newly deployed AerodromeDexAdapter
    address constant DEX_ADAPTER =
        0x3074028c973a2C15d513D4e31805C62dd1930dAB;

    // Initial max slippage (in basis points)
    // 200 = 2%
    uint256 constant MAX_SLIPPAGE_BPS = 200;

    /// -----------------------------------------------------------------------
    /// Script entry
    /// -----------------------------------------------------------------------

    function run() external returns (ExecutionVault vault) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        vault = new ExecutionVault(
            DEX_ADAPTER,
            MAX_SLIPPAGE_BPS
        );

        vm.stopBroadcast();
    }
}
