// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDexAdapter} from "../interfaces/IDexAdapter.sol";

interface IAerodromeRouter {
    struct Route {
        address from;
        address to;
        bool stable;
        address factory;
    }
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, Route[] calldata routes, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function getAmountsOut(uint256 amountIn, Route[] memory routes) external view returns (uint256[] memory amounts);
}

contract AerodromeDexAdapterLive is IDexAdapter, Ownable {
    using SafeERC20 for IERC20;
    IAerodromeRouter public immutable router;
    address public immutable executionVault;
    bool public swapsEnabled;
    mapping(address => mapping(address => bool)) public useStablePool;
    error SwapsDisabled();
    error NotExecutionVault();
    error InvalidRouter();
    error InvalidVault();
    error InvalidAmount();
    event SwapsEnabledUpdated(bool enabled);
    event PoolTypeSet(address indexed tokenA, address indexed tokenB, bool stable);
    event SwapExecuted(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, address recipient);
    modifier onlyVault() {
        if (msg.sender != executionVault) revert NotExecutionVault();
        _;
    }
    constructor(address _router, address _executionVault, address _owner) Ownable(_owner) {
        if (_router == address(0)) revert InvalidRouter();
        if (_executionVault == address(0)) revert InvalidVault();
        router = IAerodromeRouter(_router);
        executionVault = _executionVault;
        swapsEnabled = false;
    }
    function setSwapsEnabled(bool enabled) external onlyOwner {
        swapsEnabled = enabled;
        emit SwapsEnabledUpdated(enabled);
    }
    function setPoolType(address tokenA, address tokenB, bool stable) external onlyOwner {
        useStablePool[tokenA][tokenB] = stable;
        useStablePool[tokenB][tokenA] = stable;
        emit PoolTypeSet(tokenA, tokenB, stable);
    }
    function previewSwap(address tokenIn, address tokenOut, uint256 amountIn) external view override returns (uint256 amountOut) {
        if (amountIn == 0) return 0;
        IAerodromeRouter.Route[] memory routes = new IAerodromeRouter.Route[](1);
        routes[0] = IAerodromeRouter.Route({from: tokenIn, to: tokenOut, stable: useStablePool[tokenIn][tokenOut], factory: address(0)});
        try router.getAmountsOut(amountIn, routes) returns (uint256[] memory amounts) {
            amountOut = amounts[amounts.length - 1];
        } catch {
            amountOut = amountIn;
        }
    }
    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, address recipient, bytes calldata data) external override onlyVault returns (uint256 amountOut) {
        if (!swapsEnabled) revert SwapsDisabled();
        if (amountIn == 0) revert InvalidAmount();
        bool stable = useStablePool[tokenIn][tokenOut];
        if (data.length > 0) {
            stable = abi.decode(data, (bool));
        }
        IERC20(tokenIn).forceApprove(address(router), 0);
        IERC20(tokenIn).forceApprove(address(router), amountIn);
        IAerodromeRouter.Route[] memory routes = new IAerodromeRouter.Route[](1);
        routes[0] = IAerodromeRouter.Route({from: tokenIn, to: tokenOut, stable: stable, factory: address(0)});
        uint256[] memory amounts = router.swapExactTokensForTokens(amountIn, minAmountOut, routes, recipient, block.timestamp + 300);
        amountOut = amounts[amounts.length - 1];
        IERC20(tokenIn).forceApprove(address(router), 0);
        emit SwapExecuted(tokenIn, tokenOut, amountIn, amountOut, recipient);
    }
    function recoverToken(address token, uint256 amount, address to) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}
