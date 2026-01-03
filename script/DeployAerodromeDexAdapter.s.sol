// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {AerodromeDexAdapter} from "../src/adapters/AerodromeDexAdapter.sol";

contract DeployAerodromeDexAdapter is Script {
    // Base mainnet Aerodrome Router
    address constant AERODROME_ROUTER =
        0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43;

    // Your already-deployed ExecutionVault
    address constant EXECUTION_VAULT =
        0xcDd7a8712c3EE5571ba302dBf665BEc7F4e5d377;

    // Your operator / owner EOA
    address constant OWNER =
        0xe2fF7725626961945449C220cD07EaE6f398E744;

    function run() external returns (AerodromeDexAdapter adapter) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        adapter = new AerodromeDexAdapter(
            AERODROME_ROUTER,
            EXECUTION_VAULT,
            OWNER
        );

        vm.stopBroadcast();
    }
}

