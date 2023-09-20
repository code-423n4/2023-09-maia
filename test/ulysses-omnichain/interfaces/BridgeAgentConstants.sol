// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title  Bridge Agent Constants Contract
 * @author MaiaDAO
 * @notice Constants for use in Bridge Agent and Bridge Agent Executor contracts.
 * @dev    Used for encoding and decoding of the cross-chain messages.
 */
contract BridgeAgentConstants {
    // Settlement / Deposit Execution Status

    uint8 internal constant STATUS_READY = 0;

    uint8 internal constant STATUS_DONE = 1;

    uint8 internal constant STATUS_RETRIEVE = 2;

    // Settlement / Deposit Redeeem Status

    uint8 internal constant STATUS_FAILED = 1;

    uint8 internal constant STATUS_SUCCESS = 0;

    // Payload Encoding / Decoding

    uint256 internal constant PARAMS_START = 1;

    uint256 internal constant PARAMS_START_SIGNED = 21;

    uint256 internal constant PARAMS_TKN_START = 5;

    uint256 internal constant PARAMS_TKN_START_SIGNED = 25;

    uint256 internal constant PARAMS_ENTRY_SIZE = 32;

    uint256 internal constant PARAMS_ADDRESS_SIZE = 20;

    uint256 internal constant PARAMS_TKN_SET_SIZE = 109;

    uint256 internal constant PARAMS_TKN_SET_SIZE_MULTIPLE = 128;

    uint256 internal constant ADDRESS_END_OFFSET = 12;

    uint256 internal constant PARAMS_AMT_OFFSET = 64;

    uint256 internal constant PARAMS_DEPOSIT_OFFSET = 96;

    uint256 internal constant PARAMS_END_OFFSET = 6;

    uint256 internal constant PARAMS_END_SIGNED_OFFSET = 26;

    uint256 internal constant PARAMS_SETTLEMENT_OFFSET = 129;

    // Deposit / Settlement Multiple Max

    uint256 internal constant MAX_TOKENS_LENGTH = 255;
}
