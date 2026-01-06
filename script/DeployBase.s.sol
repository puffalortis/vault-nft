// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/ExecutionVault.sol";
import "../src/VaultRebalancerNFT.sol";
import "../src/adapters/AerodromeDexAdapterLive.sol";

/**
 * @title DeployBase
 * @notice Deploy complete vault system to Base MAINNET
 * @dev Run with: forge script script/DeployBase.s.sol --rpc-url $BASE_MAINNET_RPC_URL --broadcast --verify -vvvv
 */
contract DeployBase is Script {
    // Base Mainnet Aerodrome Router
    address constant AERODROME_ROUTER = 0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43;
    
    // Token addresses on Base MAINNET
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // Base Mainnet USDC
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying from:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy ExecutionVault with 2% max slippage
        console.log("\n1. Deploying ExecutionVault...");
        ExecutionVault execVault = new ExecutionVault(200);
        console.log("ExecutionVault deployed at:", address(execVault));
        
        // 2. Deploy Aerodrome Adapter
        console.log("\n2. Deploying AerodromeDexAdapterLive...");
        AerodromeDexAdapterLive adapter = new AerodromeDexAdapterLive(
            AERODROME_ROUTER,
            address(execVault),
            deployer
        );
        console.log("Adapter deployed at:", address(adapter));
        
        // 3. Deploy VaultRebalancerNFT
        console.log("\n3. Deploying VaultRebalancerNFT...");
        VaultRebalancerNFT vault = new VaultRebalancerNFT(
            deployer,
            address(execVault)
        );
        console.log("VaultRebalancerNFT deployed at:", address(vault));
        
        // 4. Configure ExecutionVault
        console.log("\n4. Configuring ExecutionVault...");
        execVault.setAdapter(address(adapter));
        execVault.setExecutor(address(vault), true);
        console.log("ExecutionVault configured");
        
        // 5. Configure Adapter
        console.log("\n5. Configuring Adapter...");
        adapter.setPoolType(WETH, USDC, false); // Volatile pool
        adapter.setSwapsEnabled(true);
        console.log("Adapter configured");
        
        // 6. Configure Vault
        console.log("\n6. Configuring Vault...");
        vault.configurePreview(
            WETH,
            USDC,
            5000, // 50% target weight for WETH
            100   // 1% minimum deviation
        );
        console.log("Vault configured");
        
        vm.stopBroadcast();
        
        // Print deployment summary
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("ExecutionVault:", address(execVault));
        console.log("AerodromeDexAdapter:", address(adapter));
        console.log("VaultRebalancerNFT:", address(vault));
        console.log("========================================");
        console.log("\nNext steps:");
        console.log("1. Fund ExecutionVault with WETH/USDC");
        console.log("2. Enable live execution: vault.setLiveExecutionEnabled(true)");
        console.log("3. Call vault.rebalance() to test");
    }
}
