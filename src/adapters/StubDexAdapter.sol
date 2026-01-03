// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IDexAdapter.sol";

/// @notice Stub adapter used for testing vault + NFT wiring.
/// @dev Provides a view-safe previewSwap even though the interface
///      only standardizes swap().
contract StubDexAdapter is IDexAdapter {

    /// -----------------------------------------------------------------------
    /// Preview (NON-STANDARD, VIEW-SAFE)
    /// -----------------------------------------------------------------------

    /// @notice Deterministic preview used by VaultRebalancerNFT
    /// @dev Not part of IDexAdapter, but expected by the vault
    function previewSwap(
        address,
        address,
        uint256 amountIn
    ) external pure returns (uint256) {
        // Stub behavior: 1:1 quote
        return amountIn;
    }

    /// -----------------------------------------------------------------------
    /// Execution (INTERFACE-COMPLIANT)
    /// -----------------------------------------------------------------------

    /// @inheritdoc IDexAdapter
    function swap(
        address,
        address,
        uint256 amountIn,
        uint256,        // minAmountOut (ignored in stub)
        address,        // recipient (ignored in stub)
        bytes calldata // data (ignored in stub)
    ) external pure returns (uint256 amountOut) {
        // Stub behavior: 1:1 execution
        return amountIn;
    }
}

