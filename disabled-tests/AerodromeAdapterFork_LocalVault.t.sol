// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import { VaultRebalancerNFT } from "../src/VaultRebalancerNFT.sol";
import { AerodromeDexAdapter } from "../src/adapters/AerodromeDexAdapter.sol";

contract AerodromeAdapterFork_LocalVault_Test is Test {
    // ------------------------------------------------------------
    // Base mainnet constants
    // ------------------------------------------------------------

    address constant CBBTC =
        0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC
    address constant DOWN =
        0x4200000000000000000000000000000000000006; // WETH

    address constant AERODROME_ROUTER =
        0x9c12939390052919aF3155f41Bf4160Fd3666A6f;

    // ------------------------------------------------------------
    // Fork-local contracts
    // ------------------------------------------------------------
    VaultRebalancerNFT vault;
    AerodromeDexAdapter adapter;

    address owner = address(this);

    function setUp() public {
        adapter = new AerodromeDexAdapter(AERODROME_ROUTER);

        vault = new VaultRebalancerNFT(
            CBBTC,
            DOWN,
            owner,
            address(adapter)
        );

        // Deterministic fork-only balances
        deal(CBBTC, address(vault), 1_000e6);   // 1,000 USDC
        deal(DOWN,  address(vault), 0.5 ether); // 0.5 WETH
    }

    function test_fork_local_execution_is_safe() public {
        // previewRebalance must be safe to call before execution
        vault.previewRebalance();

        // Enable swaps
        adapter.setSwapsEnabled(true);

        // rebalance must be safe to call
        vault.rebalance();

        // previewRebalance must still be safe to call afterward
        vault.previewRebalance();

        // Disable swaps again
        adapter.setSwapsEnabled(false);
    }
}

