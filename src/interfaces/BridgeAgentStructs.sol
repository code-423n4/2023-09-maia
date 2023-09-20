// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*///////////////////////////////////////////////////////////////
                            STRUCTS
//////////////////////////////////////////////////////////////*/

struct GasParams {
    uint256 gasLimit; // gas allocated for the cross-chain call.
    uint256 remoteBranchExecutionGas; //gas allocated for remote branch execution. Must be lower than `gasLimit`.
}

struct Deposit {
    uint8 status;
    address owner;
    address[] hTokens;
    address[] tokens;
    uint256[] amounts;
    uint256[] deposits;
}

struct DepositInput {
    //Deposit Info
    address hToken; //Input Local hTokens Address.
    address token; //Input Native / underlying Token Address.
    uint256 amount; //Amount of Local hTokens deposited for interaction.
    uint256 deposit; //Amount of native tokens deposited for interaction.
}

struct DepositMultipleInput {
    //Deposit Info
    address[] hTokens; //Input Local hTokens Address.
    address[] tokens; //Input Native / underlying Token Address.
    uint256[] amounts; //Amount of Local hTokens deposited for interaction.
    uint256[] deposits; //Amount of native tokens deposited for interaction.
}

struct DepositMultipleParams {
    //Deposit Info
    uint8 numberOfAssets; //Number of assets to deposit.
    uint32 depositNonce; //Deposit nonce.
    address[] hTokens; //Input Local hTokens Address.
    address[] tokens; //Input Native / underlying Token Address.
    uint256[] amounts; //Amount of Local hTokens deposited for interaction.
    uint256[] deposits; //Amount of native tokens deposited for interaction.
}

struct DepositParams {
    //Deposit Info
    uint32 depositNonce; //Deposit nonce.
    address hToken; //Input Local hTokens Address.
    address token; //Input Native / underlying Token Address.
    uint256 amount; //Amount of Local hTokens deposited for interaction.
    uint256 deposit; //Amount of native tokens deposited for interaction.
}

struct Settlement {
    uint16 dstChainId; //Destination chain for interaction.
    uint80 status; //Status of the settlement
    address owner; //Owner of the settlement
    address recipient; //Recipient of the settlement.
    address[] hTokens; //Input Local hTokens Addresses.
    address[] tokens; //Input Native / underlying Token Addresses.
    uint256[] amounts; //Amount of Local hTokens deposited for interaction.
    uint256[] deposits; //Amount of native tokens deposited for interaction.
}

struct SettlementInput {
    address globalAddress; //Input Global hTokens Address.
    uint256 amount; //Amount of Local hTokens deposited for interaction.
    uint256 deposit; //Amount of native tokens deposited for interaction.
}

struct SettlementMultipleInput {
    address[] globalAddresses; //Input Global hTokens Addresses.
    uint256[] amounts; //Amount of Local hTokens deposited for interaction.
    uint256[] deposits; //Amount of native tokens deposited for interaction.
}

struct SettlementParams {
    uint32 settlementNonce; // Settlement nonce.
    address recipient; // Recipient of the settlement.
    address hToken; // Input Local hTokens Address.
    address token; // Input Native / underlying Token Address.
    uint256 amount; // Amount of Local hTokens deposited for interaction.
    uint256 deposit; // Amount of native tokens deposited for interaction.
}

struct SettlementMultipleParams {
    uint8 numberOfAssets; // Number of assets to deposit.
    address recipient; // Recipient of the settlement.
    uint32 settlementNonce; // Settlement nonce.
    address[] hTokens; // Input Local hTokens Addresses.
    address[] tokens; // Input Native / underlying Token Addresses.
    uint256[] amounts; // Amount of Local hTokens deposited for interaction.
    uint256[] deposits; // Amount of native tokens deposited for interaction.
}
