// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ExecutionVault } from "./ExecutionVault.sol";

/**
 * @title VaultRebalancerNFT
 * @notice Rebalance coordinator with staged execution
 * @dev Starts stub-safe; real execution is admin-enabled
 */
contract VaultRebalancerNFT is Ownable {

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    ExecutionVault public immutable executionVault;

    /// @notice Enables real ExecutionVault calls when true
    bool public liveExecutionEnabled = false;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted whenever a rebalance is previewed
    event RebalancePreviewed(
        bool shouldRebalance,
        uint256 amount
    );

    /// @notice Emitted when rebalance() is called (always)
    event RebalanceCalled(
        address indexed caller,
        bool liveExecutionEnabled,
        uint256 blockNumber,
        uint256 timestamp
    );

    /// @notice Emitted when a live execution occurs
    event RebalanceExecutedLive(
        address indexed executor,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 expectedAmountOut,
        uint256 actualAmountOut
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address owner_, address executionVault_)
        Ownable(owner_)
    {
        executionVault = ExecutionVault(executionVault_);
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @notice Enable or disable live ExecutionVault calls
    function setLiveExecutionEnabled(bool enabled) external onlyOwner {
        liveExecutionEnabled = enabled;
    }

    /*//////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Preview whether a rebalance should occur
     * @dev Stub-safe: real logic will be added later
     */
    function previewRebalance()
        external
        view
        returns (bool shouldRebalance, uint256 amount)
    {
        shouldRebalance = false;
        amount = 0;
    }

    /*//////////////////////////////////////////////////////////////
                                ACTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Execute a rebalance
     * @dev Safe in stub mode; live mode requires precomputed params
     */
    function rebalance() external {
        emit RebalanceCalled(
            msg.sender,
            liveExecutionEnabled,
            block.number,
            block.timestamp
        );

        if (!liveExecutionEnabled) {
            // Stub mode: no-op, idempotent, test-safe
            return;
        }

        /**
         * Live execution path (intentionally conservative):
         * - Parameters must be precomputed off-chain
         * - This avoids embedding strategy logic prematurely
         *
         * NOTE:
         * These are placeholder values for now and will be
         * wired to real strategy math in the next iteration.
         */
        address tokenIn = address(0);
        address tokenOut = address(0);
        uint256 amountIn = 0;
        uint256 expectedAmountOut = 0;

        uint256 actualAmountOut =
            executionVault.executeSwap(
                tokenIn,
                tokenOut,
                amountIn,
                expectedAmountOut
            );

        emit RebalanceExecutedLive(
            msg.sender,
            tokenIn,
            tokenOut,
            amountIn,
            expectedAmountOut,
            actualAmountOut
        );
    }
}
