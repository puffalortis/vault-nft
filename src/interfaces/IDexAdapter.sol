// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice DEX-agnostic swap execution interface
/// @dev Implemented by Aerodrome, UniswapV3, CowSwap, etc.
interface IDexAdapter {
    /// @notice Preview expected output for a swap (non-mutating)
    /// @param tokenIn ERC20 being sold
    /// @param tokenOut ERC20 being bought
    /// @param amountIn Exact amount of tokenIn to swap
    /// @return amountOut Expected amount of tokenOut
    function previewSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    /// @notice Execute a token swap
    /// @param tokenIn ERC20 being sold
    /// @param tokenOut ERC20 being bought
    /// @param amountIn Exact amount of tokenIn to swap
    /// @param minAmountOut Slippage protection
    /// @param recipient Receiver of output tokens
    /// @param data DEX-specific calldata (paths, fees, pool ids, etc.)
    /// @return amountOut Actual amount received
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 amountOut);
}
