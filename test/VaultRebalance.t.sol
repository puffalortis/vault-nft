// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { VaultRebalancerNFT } from "../src/VaultRebalancerNFT.sol";

contract VaultRebalanceTest is Test {
    VaultRebalancerNFT vault;

    function setUp() public {
        vault = new VaultRebalancerNFT(
            address(this),
            address(0xBEEF) // stub execution vault
        );
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

