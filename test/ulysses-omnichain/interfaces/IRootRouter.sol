// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DepositParams, DepositMultipleParams} from "../interfaces/IRootBridgeAgent.sol";

/**
 * @title  Root Router Contract
 * @author MaiaDAO
 * @notice Base Branch Contract for interfacing with Root Bridge Agents.
 *         This contract for deployment in the Root Chain of the Ulysses Omnichain System,
 *         additional logic can be implemented to perform actions before sending cross-chain
 *         requests to Branch Chains, as well as in response to remote requests.
 */
interface IRootRouter {
    /*///////////////////////////////////////////////////////////////
                        LAYERZERO FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     *     @notice Function to execute Branch Bridge Agent system initiated requests with no asset deposit.
     *     @param params data received from messaging layer.
     *     @param srcChainId chain where the request originated from.
     *
     */
    function executeResponse(bytes memory params, uint16 srcChainId) external payable;

    /**
     *     @notice Function responsible of executing a crosschain request without any deposit.
     *     @param params data received from messaging layer.
     *     @param srcChainId chain where the request originated from.
     *
     */
    function execute(bytes memory params, uint16 srcChainId) external payable;

    /**
     *   @notice Function responsible of executing a crosschain request which contains cross-chain deposit information attached.
     *   @param params execution data received from messaging layer.
     *   @param dParams cross-chain deposit information.
     *   @param srcChainId chain where the request originated from.
     *
     */
    function executeDepositSingle(bytes memory params, DepositParams memory dParams, uint16 srcChainId)
        external
        payable;

    /**
     *   @notice Function responsible of executing a crosschain request which contains cross-chain deposit information for multiple assets attached.
     *   @param params execution data received from messaging layer.
     *   @param dParams cross-chain multiple deposit information.
     *   @param srcChainId chain where the request originated from.
     *
     */
    function executeDepositMultiple(bytes memory params, DepositMultipleParams memory dParams, uint16 srcChainId)
        external
        payable;

    /**
     * @notice Function responsible of executing a crosschain request with msg.sender without any deposit.
     * @param params execution data received from messaging layer.
     * @param userAccount user account address.
     * @param srcChainId chain where the request originated from.
     */
    function executeSigned(bytes memory params, address userAccount, uint16 srcChainId) external payable;

    /**
     * @notice Function responsible of executing a crosschain request which contains cross-chain deposit information and msg.sender attached.
     * @param params execution data received from messaging layer.
     * @param dParams cross-chain deposit information.
     * @param userAccount user account address.
     * @param srcChainId chain where the request originated from.
     */
    function executeSignedDepositSingle(
        bytes memory params,
        DepositParams memory dParams,
        address userAccount,
        uint16 srcChainId
    ) external payable;

    /**
     * @notice Function responsible of executing a crosschain request which contains cross-chain deposit information for multiple assets and msg.sender attached.
     * @param params execution data received from messaging layer.
     * @param dParams cross-chain multiple deposit information.
     * @param userAccount user account address.
     * @param srcChainId chain where the request originated from.
     */
    function executeSignedDepositMultiple(
        bytes memory params,
        DepositMultipleParams memory dParams,
        address userAccount,
        uint16 srcChainId
    ) external payable;

    /*///////////////////////////////////////////////////////////////
                             ERRORS
    //////////////////////////////////////////////////////////////*/

    error UnrecognizedFunctionId();
    error UnrecognizedBridgeAgentExecutor();
}
