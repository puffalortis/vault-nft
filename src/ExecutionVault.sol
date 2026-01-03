// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IDexAdapter.sol";

/**
 * @title ExecutionVault
 * @notice Executes controlled swaps on behalf of VaultRebalancerNFT
 * @dev Holds funds and performs swaps; no NFT custody
 */
contract ExecutionVault is Ownable, Pausable {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NotAuthorized();
    error MaxSlippageExceeded();
    error ZeroAmount();

    /// -----------------------------------------------------------------------
    /// Storage
    /// -----------------------------------------------------------------------

    IDexAdapter public immutable dexAdapter;

    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public maxSlippageBps; // e.g. 200 = 2%

    mapping(address => bool) public executors;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event ExecutorSet(address indexed executor, bool allowed);
    event MaxSlippageUpdated(uint256 oldBps, uint256 newBps);
    event SwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        address dexAdapter_,
        uint256 maxSlippageBps_
    ) Ownable(msg.sender) {
        require(dexAdapter_ != address(0), "adapter zero");
        require(maxSlippageBps_ <= 1_000, "slippage too high"); // ≤10%

        dexAdapter = IDexAdapter(dexAdapter_);
        maxSlippageBps = maxSlippageBps_;
    }

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    modifier onlyExecutor() {
        if (!executors[msg.sender]) revert NotAuthorized();
        _;
    }

    /// -----------------------------------------------------------------------
    /// Admin
    /// -----------------------------------------------------------------------

    function setExecutor(address executor, bool allowed) external onlyOwner {
        executors[executor] = allowed;
        emit ExecutorSet(executor, allowed);
    }

    function setMaxSlippageBps(uint256 newBps) external onlyOwner {
        require(newBps <= 1_000, "slippage too high");
        uint256 old = maxSlippageBps;
        maxSlippageBps = newBps;
        emit MaxSlippageUpdated(old, newBps);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// -----------------------------------------------------------------------
    /// Execution
    /// -----------------------------------------------------------------------

    /**
     * @notice Execute a guarded swap via the adapter
     */
    function executeSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 expectedAmountOut
    )
        external
        whenNotPaused
        onlyExecutor
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert ZeroAmount();

        uint256 minOut =
            (expectedAmountOut * (BPS_DENOMINATOR - maxSlippageBps))
                / BPS_DENOMINATOR;

        IERC20(tokenIn).approve(address(dexAdapter), amountIn);

        amountOut = dexAdapter.swap(
            tokenIn,
            tokenOut,
            amountIn,
            minOut,
            address(this),   // recipient
            bytes("")        // adapter-specific data
        );

        if (amountOut < minOut) revert MaxSlippageExceeded();

        emit SwapExecuted(tokenIn, tokenOut, amountIn, amountOut);
    }
}

