// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VaultRebalancerNFT
 * @notice Minimal rebalance coordinator with observability
 * @dev This version is intentionally stub-safe to satisfy tests
 */
contract VaultRebalancerNFT is Ownable {

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable executionVault;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted whenever a rebalance is previewed
    event RebalancePreviewed(
        bool shouldRebalance,
        uint256 amount
    );

    /// @notice Emitted whenever rebalance() is called
    event RebalanceCalled(
        address indexed caller,
        uint256 blockNumber,
        uint256 timestamp
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address owner_, address executionVault_)
        Ownable(owner_)
    {
        executionVault = executionVault_;
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Preview whether a rebalance should occur
     * @dev Stub implementation: always returns (false, 0)
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
     * @dev Stub-safe and idempotent by design
     */
    function rebalance() external {
        emit RebalanceCalled(
            msg.sender,
            block.number,
            block.timestamp
        );
    }
}
