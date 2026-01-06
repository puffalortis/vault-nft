// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

// IMPORT THE ACTUAL ADAPTER THAT EXISTS
import {AerodromeDexAdapterLive} from "../src/adapters/AerodromeDexAdapterLive.sol";

/**
 * @title DeployAerodromeDexAdapter
 *
 * @notice
 *  Deploy script for the *live* Aerodrome adapter.
 *  This script was previously pointing at a deleted file.
 */
contract DeployAerodromeDexAdapter is Script {
    function run() external returns (AerodromeDexAdapterLive adapter) {
        // ---------------------------------------------------------------------
        // CONFIG — SET EXPLICITLY
        // ---------------------------------------------------------------------

        // Aerodrome Router on Base (REPLACE WITH REAL ADDRESS)
        address ROUTER = 0x0000000000000000000000000000000000000000;

        // ---------------------------------------------------------------------
        // DEPLOY
        // ---------------------------------------------------------------------

        vm.startBroadcast();

        adapter = new AerodromeDexAdapterLive(ROUTER);

        vm.stopBroadcast();

        // ---------------------------------------------------------------------
        // LOG
        // ---------------------------------------------------------------------

        console2.log("AerodromeDexAdapterLive deployed at:", address(adapter));
        console2.log("Router bound to:", ROUTER);
    }
}
