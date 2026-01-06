// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { VaultRebalancerNFT } from "../src/VaultRebalancerNFT.sol";
import { ExecutionVault } from "../src/ExecutionVault.sol";
import { AerodromeDexAdapterLive } from "../src/adapters/AerodromeDexAdapterLive.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title AerodromeIntegrationTest
 * @notice Integration test for Aerodrome on Base
 * @dev Run with: forge test --match-contract AerodromeIntegration --fork-url https://base.llamarpc.com -vvv
 */
contract AerodromeIntegrationTest is Test {
    VaultRebalancerNFT vault;
    ExecutionVault execVault;
    AerodromeDexAdapterLive adapter;

    // Base Mainnet addresses
    address constant AERODROME_ROUTER = 0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    
    address owner = address(this);
    uint256 constant INITIAL_ETH = 1 ether;

    function setUp() public {
        // Deploy ExecutionVault with 5% max slippage for testing
        execVault = new ExecutionVault(500);
        
        // Deploy Aerodrome adapter
        adapter = new AerodromeDexAdapterLive(
            AERODROME_ROUTER,
            address(execVault),  // Only ExecutionVault can call
            owner
        );
        
        // Configure ExecutionVault
        execVault.setAdapter(address(adapter));
        
        // Deploy VaultRebalancerNFT
        vault = new VaultRebalancerNFT(
            owner,
            address(execVault)
        );
        
        // Set VaultRebalancerNFT as executor
        execVault.setExecutor(address(vault), true);
        
        // Configure WETH/USDC pool as volatile (not stable)
        adapter.setPoolType(WETH, USDC, false);
        
        // Enable swaps
        adapter.setSwapsEnabled(true);
        
        // Fund ExecutionVault with WETH
        vm.deal(address(this), INITIAL_ETH);
        (bool success,) = WETH.call{value: INITIAL_ETH}("");
        require(success, "WETH wrap failed");
        IERC20(WETH).transfer(address(execVault), INITIAL_ETH);
    }

    function test_adapter_configuration() public {
        assertEq(adapter.swapsEnabled(), true);
        assertEq(adapter.executionVault(), address(execVault));
        assertEq(address(adapter.router()), AERODROME_ROUTER);
    }

    function test_previewSwap() public view {
        uint256 amountIn = 0.1 ether;
        uint256 expected = adapter.previewSwap(WETH, USDC, amountIn);
        assertGt(expected, 0, "Preview should return non-zero");
    }

    function test_executeSwap_viaExecutionVault() public {
        uint256 amountIn = 0.1 ether;
        
        // Preview expected output
        uint256 expectedOut = adapter.previewSwap(WETH, USDC, amountIn);
        
        uint256 balanceBefore = IERC20(USDC).balanceOf(address(execVault));
        
        // Execute swap
        uint256 amountOut = execVault.executeSwap(
            WETH,
            USDC,
            amountIn,
            expectedOut
        );
        
        uint256 balanceAfter = IERC20(USDC).balanceOf(address(execVault));
        
        assertGt(amountOut, 0, "Should receive USDC");
        assertEq(balanceAfter - balanceBefore, amountOut, "Balance should match");
    }

    function test_rebalance_fullFlow() public {
        // Configure rebalancing: 50% WETH, 50% USDC
        vault.configurePreview(
            WETH,
            USDC,
            5000, // 50% target weight for WETH
            100   // 1% minimum deviation to trigger
        );
        
        // Check preview (should rebalance since 100% WETH currently)
        (bool shouldRebalance, uint256 amount) = vault.previewRebalance();
        assertTrue(shouldRebalance, "Should need rebalancing");
        assertGt(amount, 0, "Should have amount to rebalance");
        
        // Enable live execution
        vault.setLiveExecutionEnabled(true);
        
        // Execute rebalance
        vault.rebalance();
        
        // Verify balances moved closer to target
        uint256 wethBalance = IERC20(WETH).balanceOf(address(execVault));
        uint256 usdcBalance = IERC20(USDC).balanceOf(address(execVault));
        
        assertGt(usdcBalance, 0, "Should have USDC after rebalance");
        assertLt(wethBalance, INITIAL_ETH, "WETH should be reduced");
    }

    function test_swaps_disabled_by_default() public {
        // Deploy new adapter with swaps disabled
        AerodromeDexAdapterLive newAdapter = new AerodromeDexAdapterLive(
            AERODROME_ROUTER,
            address(execVault),
            owner
        );
        
        assertEq(newAdapter.swapsEnabled(), false, "Swaps should be disabled by default");
    }

    function test_onlyVault_restriction() public {
        adapter.setSwapsEnabled(true);
        
        // Fund adapter directly (shouldn't work)
        IERC20(WETH).transfer(address(adapter), 0.1 ether);
        
        // Try to call swap directly (not from ExecutionVault)
        vm.expectRevert(AerodromeDexAdapterLive.NotExecutionVault.selector);
        adapter.swap(WETH, USDC, 0.1 ether, 0, address(this), "");
    }
}// (Copy from aerodrome-integration-test artifact above)
