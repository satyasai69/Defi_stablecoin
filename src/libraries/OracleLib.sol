//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title OracleLib
 * @author me
 * @notice This library is used to check the chainlink Oracle for stale data
 * If a price is stale, functions will revert, and render the DSCEngine unusable - this is by design.
 * We want the DSCEngine to freeze if prices become stale.
 *
 * So if the Chainlink network explodes and you have a lot of money locked in the protocol... too bad.
 */
library OracleLib {}
