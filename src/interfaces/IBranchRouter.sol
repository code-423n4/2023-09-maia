// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    GasParams,
    Deposit,
    DepositInput,
    DepositMultipleInput,
    SettlementParams,
    SettlementMultipleParams
} from "./IBranchBridgeAgent.sol";

/**
 * @title  BaseBranchRouter Contract
 * @author MaiaDAO
 * @notice Base Branch Contract for interfacing with Branch Bridge Agents.
 *         This contract for deployment in Branch Chains of the Ulysses Omnichain System,
 *         additional logic can be implemented to perform actions before sending cross-chain
 *         requests, as well as in response to requests from the Root Omnichain Environment.
 */
interface IBranchRouter {
    /*///////////////////////////////////////////////////////////////
                            VIEW / STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice External function to return the Branch Chain's Local Port Address.
    function localPortAddress() external view returns (address);

    /// @notice Address for local Branch Bridge Agent who processes requests and interacts with local port.
    function localBridgeAgentAddress() external view returns (address);

    /// @notice Local Bridge Agent Executor Address.
    function bridgeAgentExecutorAddress() external view returns (address);

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to perform a call to the Root Omnichain Router without token deposit.
     *   @param params RLP enconded parameters to execute on the root chain.
     *   @param gParams gas parameters for the cross-chain call.
     *   @dev ACTION ID: 1 (Call without deposit)
     *
     */
    function callOut(bytes calldata params, GasParams calldata gParams) external payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Router while depositing a single asset.
     *   @param params encoded parameters to execute on the root chain.
     *   @param dParams additional token deposit parameters.
     *   @param gParams gas parameters for the cross-chain call.
     *   @dev ACTION ID: 2 (Call with single deposit)
     *
     */
    function callOutAndBridge(bytes calldata params, DepositInput calldata dParams, GasParams calldata gParams)
        external
        payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Router while depositing two or more assets.
     *   @param params encoded parameters to execute on the root chain.
     *   @param dParams additional token deposit parameters.
     *   @param gParams gas parameters for the cross-chain call.
     *   @dev ACTION ID: 3 (Call with multiple deposit)
     *
     */
    function callOutAndBridgeMultiple(
        bytes calldata params,
        DepositMultipleInput calldata dParams,
        GasParams calldata gParams
    ) external payable;

    /**
     * @notice External function that returns a given deposit entry.
     *     @param depositNonce Identifier for user deposit.
     *
     */
    function getDepositEntry(uint32 depositNonce) external view returns (Deposit memory);

    /*///////////////////////////////////////////////////////////////
                        LAYERZERO EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function responsible of executing a branch router response.
     *     @param params data received from messaging layer.
     */
    function executeNoSettlement(bytes calldata params) external payable;

    /**
     * @dev Function responsible of executing a crosschain request without any deposit.
     *     @param params data received from messaging layer.
     *     @param sParams SettlementParams struct.
     */
    function executeSettlement(bytes calldata params, SettlementParams calldata sParams) external payable;

    /**
     * @dev Function responsible of executing a crosschain request which contains
     *      cross-chain deposit information attached.
     *     @param params data received from messaging layer.
     *     @param sParams SettlementParams struct containing deposit information.
     *
     */
    function executeSettlementMultiple(bytes calldata params, SettlementMultipleParams calldata sParams)
        external
        payable;

    /*///////////////////////////////////////////////////////////////
                             ERRORS
    //////////////////////////////////////////////////////////////*/

    error UnrecognizedFunctionId();

    error UnrecognizedBridgeAgentExecutor();
}
