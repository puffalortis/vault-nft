// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal Chainlink Aggregator interface
interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
}

/// @title OracleConstants
/// @notice Canonical oracle addresses and helpers shared across contracts
/// @dev Keep this file small and boring on purpose
library OracleConstants {
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Chainlink BTC / USD price feed on Base Mainnet
    /// @dev Source: https://data.chain.link/feeds/base/base/btc-usd
    address internal constant BTC_USD_CHAINLINK_BASE =
        0x64C9C1f63e1a5e31cEbc2BC01e848Be9D852848f;

    /*//////////////////////////////////////////////////////////////
                             ORACLE HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Read BTC/USD price normalized to 18 decimals
    /// @return price BTC/USD with 18 decimals
    function btcUsdPrice18() internal view returns (uint256 price) {
        AggregatorV3Interface feed =
            AggregatorV3Interface(BTC_USD_CHAINLINK_BASE);

        (, int256 answer,,,) = feed.latestRoundData();
        require(answer > 0, "oracle: invalid price");

        uint8 decimals = feed.decimals();

        if (decimals < 18) {
            return uint256(answer) * (10 ** (18 - decimals));
        } else if (decimals > 18) {
            return uint256(answer) / (10 ** (decimals - 18));
        } else {
            return uint256(answer);
        }
    }

    /// @notice Read raw BTC/USD price and metadata
    /// @dev Useful for off-chain parity or diagnostics
    function btcUsdRaw()
        internal
        view
        returns (
            uint256 price,
            uint8 decimals,
            uint256 updatedAt
        )
    {
        AggregatorV3Interface feed =
            AggregatorV3Interface(BTC_USD_CHAINLINK_BASE);

        (, int256 answer,, uint256 updated, ) = feed.latestRoundData();
        require(answer > 0, "oracle: invalid price");

        return (uint256(answer), feed.decimals(), updated);
    }
}
