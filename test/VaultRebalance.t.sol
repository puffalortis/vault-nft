// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { VaultRebalancerNFT } from "../src/VaultRebalancerNFT.sol";
import { ExecutionVault } from "../src/ExecutionVault.sol";
import { StubDexAdapter } from "../src/adapters/StubDexAdapter.sol";

contract VaultRebalanceTest is Test {
    VaultRebalancerNFT vault;
    ExecutionVault execVault;
    StubDexAdapter adapter;

    function setUp() public {
        execVault = new ExecutionVault(200);
        adapter = new StubDexAdapter();
        execVault.setAdapter(address(adapter));
        vault = new VaultRebalancerNFT(address(this), address(execVault));
        execVault.setExecutor(address(vault), true);
    }

    function test_previewRebalance_doesNotRevert() public {
        (bool shouldRebalance, uint256 amount) = vault.previewRebalance();
        assertEq(shouldRebalance, false);
        assertEq(amount, 0);
    }

    function test_rebalance_executes() public {
        vault.rebalance();
    }

    function test_rebalance_idempotent() public {
        vault.rebalance();
        vault.rebalance();
    }
}
