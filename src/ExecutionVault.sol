// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IDexAdapter.sol";

contract ExecutionVault is Ownable, Pausable {
    using SafeERC20 for IERC20;
    error NotAuthorized();
    error MaxSlippageExceeded();
    error ZeroAmount();
    error NoAdapter();
    IDexAdapter public dexAdapter;
    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public maxSlippageBps;
    mapping(address => bool) public executors;
    event ExecutorSet(address indexed executor, bool allowed);
    event AdapterSet(address indexed adapter);
    event MaxSlippageUpdated(uint256 oldBps, uint256 newBps);
    event SwapExecuted(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    constructor(uint256 maxSlippageBps_) Ownable(msg.sender) {
        require(maxSlippageBps_ <= 1_000, "slippage too high");
        maxSlippageBps = maxSlippageBps_;
    }
    modifier onlyExecutor() {
        if (!executors[msg.sender]) revert NotAuthorized();
        _;
    }
    function setExecutor(address executor, bool allowed) external onlyOwner {
        executors[executor] = allowed;
        emit ExecutorSet(executor, allowed);
    }
    function setAdapter(address adapter_) external onlyOwner {
        require(adapter_ != address(0), "adapter zero");
        dexAdapter = IDexAdapter(adapter_);
        emit AdapterSet(adapter_);
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
    function executeSwap(address tokenIn, address tokenOut, uint256 amountIn, uint256 expectedAmountOut) external whenNotPaused onlyExecutor returns (uint256 amountOut) {
        if (amountIn == 0) revert ZeroAmount();
        if (address(dexAdapter) == address(0)) revert NoAdapter();
        uint256 minOut;
        if (expectedAmountOut == 0) {
            minOut = 0;
        } else {
            minOut = (expectedAmountOut * (BPS_DENOMINATOR - maxSlippageBps)) / BPS_DENOMINATOR;
        }
        IERC20(tokenIn).safeTransfer(address(dexAdapter), amountIn);
        amountOut = dexAdapter.swap(tokenIn, tokenOut, amountIn, minOut, address(this), bytes(""));
        if (minOut > 0 && amountOut < minOut) {
            revert MaxSlippageExceeded();
        }
        emit SwapExecuted(tokenIn, tokenOut, amountIn, amountOut);
    }
}
