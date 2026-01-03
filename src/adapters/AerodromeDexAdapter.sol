// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*//////////////////////////////////////////////////////////////
                            INTERFACES
//////////////////////////////////////////////////////////////*/

interface IDexAdapter {
    function previewSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address recipient
    ) external returns (uint256 amountOut);
}

/*//////////////////////////////////////////////////////////////
                        AERODROME ADAPTER
//////////////////////////////////////////////////////////////*/

contract AerodromeDexAdapter is IDexAdapter, Ownable {
    address public immutable router;
    address public immutable vault;

    error SwapsDisabled();
    error OnlyVault();

    constructor(
        address _router,
        address _vault,
        address _owner
    ) Ownable(_owner) {
        require(_router != address(0), "router=0");
        require(_vault != address(0), "vault=0");
        require(_owner != address(0), "owner=0");

        router = _router;
        vault = _vault;
    }

    function previewSwap(
        address,
        address,
        uint256 amountIn
    ) external pure override returns (uint256) {
        return amountIn;
    }

    function swap(
        address,
        address,
        uint256,
        address
    ) external pure override returns (uint256) {
        revert("SWAPS_DISABLED");
    }
}
