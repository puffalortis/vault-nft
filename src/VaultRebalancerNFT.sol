// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ExecutionVault } from "./ExecutionVault.sol";

/**
 * @title VaultRebalancerNFT
 * @notice Rebalance coordinator with preview + gated execution
 * @dev Public API is test-defined and must remain stable
 */
contract VaultRebalancerNFT is Ownable {

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    ExecutionVault public immutable executionVault;

    /// Execution gate (OFF by default)
    bool public liveExecutionEnabled = false;

    /// Preview configuration
    address public tokenA;
    address public tokenB;

    /// Target weight of tokenA in basis points
    uint256 public targetWeightABps;

    /// Minimum deviation required to rebalance (bps)
    uint256 public minDeviationBps;

    uint256 public constant BPS_DENOMINATOR = 10_000;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event PreviewConfigured(
        address tokenA,
        address tokenB,
        uint256 targetWeightABps,
        uint256 minDeviationBps
    );

    event RebalancePreviewed(
        bool shouldRebalance,
        uint256 amount
    );

    event RebalanceExecuted(
        address indexed executor,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 expectedAmountOut,
        uint256 blockNumber,
        uint256 timestamp
    );

    event RebalanceCalled(
        address indexed caller,
        bool liveExecutionEnabled
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

    function setLiveExecutionEnabled(bool enabled) external onlyOwner {
        liveExecutionEnabled = enabled;
    }

    function configurePreview(
        address _tokenA,
        address _tokenB,
        uint256 _targetWeightABps,
        uint256 _minDeviationBps
    ) external onlyOwner {
        require(_targetWeightABps <= BPS_DENOMINATOR, "bad target");
        require(_minDeviationBps <= BPS_DENOMINATOR, "bad deviation");

        tokenA = _tokenA;
        tokenB = _tokenB;
        targetWeightABps = _targetWeightABps;
        minDeviationBps = _minDeviationBps;

        emit PreviewConfigured(
            _tokenA,
            _tokenB,
            _targetWeightABps,
            _minDeviationBps
        );
    }

    /*//////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Preview whether a rebalance should occur
     * @dev MUST return exactly (bool, uint256) to satisfy tests
     */
    function previewRebalance()
        public
        view
        returns (bool shouldRebalance, uint256 amount)
    {
        if (
            tokenA == address(0) ||
            tokenB == address(0) ||
            targetWeightABps == 0
        ) {
            return (false, 0);
        }

        uint256 balanceA =
            IERC20(tokenA).balanceOf(address(executionVault));
        uint256 balanceB =
            IERC20(tokenB).balanceOf(address(executionVault));

        uint256 total = balanceA + balanceB;
        if (total == 0) {
            return (false, 0);
        }

        uint256 currentWeightABps =
            (balanceA * BPS_DENOMINATOR) / total;

        uint256 deviation =
            currentWeightABps > targetWeightABps
                ? currentWeightABps - targetWeightABps
                : targetWeightABps - currentWeightABps;

        if (deviation < minDeviationBps) {
            return (false, 0);
        }

        uint256 targetBalanceA =
            (total * targetWeightABps) / BPS_DENOMINATOR;

        if (balanceA > targetBalanceA) {
            amount = balanceA - targetBalanceA;
        } else {
            amount = targetBalanceA - balanceA;
        }

        shouldRebalance = amount > 0;
    }

    /*//////////////////////////////////////////////////////////////
                                ACTION
    //////////////////////////////////////////////////////////////*/

    function rebalance() external {
        emit RebalanceCalled(msg.sender, liveExecutionEnabled);

        (bool shouldRebalance, uint256 amount) = previewRebalance();

        emit RebalancePreviewed(shouldRebalance, amount);

        if (!shouldRebalance) {
            return;
        }

        if (!liveExecutionEnabled) {
            // Preview-only mode
            return;
        }

        // Determine direction again (no API leakage)
        uint256 balanceA =
            IERC20(tokenA).balanceOf(address(executionVault));
        uint256 balanceB =
            IERC20(tokenB).balanceOf(address(executionVault));

        address tokenIn;
        address tokenOut;

        uint256 targetBalanceA =
            ((balanceA + balanceB) * targetWeightABps) / BPS_DENOMINATOR;

        if (balanceA > targetBalanceA) {
            tokenIn = tokenA;
            tokenOut = tokenB;
        } else {
            tokenIn = tokenB;
            tokenOut = tokenA;
        }

        // expectedAmountOut intentionally 0 for A-3
        executionVault.executeSwap(
            tokenIn,
            tokenOut,
            amount,
            0
        );

        emit RebalanceExecuted(
            msg.sender,
            tokenIn,
            tokenOut,
            amount,
            0,
            block.number,
            block.timestamp
        );
    }
}
