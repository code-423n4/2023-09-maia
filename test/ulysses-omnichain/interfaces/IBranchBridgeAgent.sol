// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILayerZeroReceiver} from "./ILayerZeroReceiver.sol";

import {
    GasParams,
    Deposit,
    DepositInput,
    DepositMultipleInput,
    DepositParams,
    DepositMultipleParams,
    SettlementParams,
    SettlementMultipleParams
} from "./BridgeAgentStructs.sol";

/*///////////////////////////////////////////////////////////////
                            ENUMS
//////////////////////////////////////////////////////////////*/

/**
 * @title  Branch Bridge Agent Contract
 * @author MaiaDAO
 * @notice Contract for deployment in Branch Chains of Omnichain System, responsible for
 *         interfacing with Users and Routers acting as a middleman to access LayerZero cross-chain
 *         messaging and requesting/depositing assets in the Branch Chain's Ports.
 * @dev    Bridge Agents allow for the encapsulation of business logic as well as the standardized
 *         cross-chain communication, allowing for the creation of custom Routers to perform
 *         actions as a response to remote user requests. This contract for deployment in the Branch
 *         Chains of the Ulysses Omnichain Liquidity System.
 *         The Branch Bridge Agent is responsible for sending/receiving requests to/from the LayerZero Messaging Layer
 *         for execution, as well as requests tokens clearances and tx execution to the `BranchBridgeAgentExecutor`.
 *         Remote execution is "sandboxed" within 2 different layers/nestings:
 *         - 1: Upon receiving a request from LayerZero Messaging Layer to avoid blocking future requests due to
 *              execution reversion, ensuring our app is Non-Blocking.
 *              (See https://github.com/LayerZero-Labs/solidity-examples/blob/8e62ebc886407aafc89dbd2a778e61b7c0a25ca0/contracts/lzApp/NonblockingLzApp.sol)
 *         - 2: The call to `BranchBridgeAgentExecutor` is in charge of requesting token deposits for each remote
 *              interaction as well as performing the Router calls, if any of the calls initiated by the Router lead
 *              to an invalid state change both the token deposit clearances as well as the external interactions
 *              will be reverted and caught by the `BranchBridgeAgent`.
 *
 *         Func IDs for calling these functions through the messaging layer:
 *
 *         BRANCH BRIDGE AGENT SETTLEMENT FLAGS
 *         ------------------------------
 *         ID   | DESCRIPTION
 *         -----+------------------------
 *         0x00 | Call to Branch without Settlement.
 *         0x01 | Call to Branch with Settlement.
 *         0x02 | Call to Branch with Settlement of Multiple Tokens.
 *         0x03 | Call to `retrieveSettlement()´. (trigger `_fallback` for a settlement that has not been executed)
 *         0x04 | Call to `_fallback()`. (reopens a deposit for asset redemption)
 *
 *
 *         Encoding Scheme for different Root Bridge Agent Deposit Flags:
 *
 *           - ht = hToken
 *           - t = Token
 *           - A = Amount
 *           - D = Deposit
 *           - b = bytes
 *           - n = number of assets
 *   __________________________________________________________________________________________________________________
 *  |            Flag               |           Deposit Info           |             Token Info             |   DATA   |
 *  |           1 byte              |            4-25 bytes            |        104 or (128 * n) bytes      |   ---	   |
 *  |                               |                                  |            hT - t - A - D          |          |
 *  |_______________________________|__________________________________|____________________________________|__________|
 *  | callOut = 0x0                 |  20b(recipient) + 4b(nonce)      |            -------------           |   ---	   |
 *  | callOutSingle = 0x1           |  20b(recipient) + 4b(nonce)      |         20b + 20b + 32b + 32b      |   ---	   |
 *  | callOutMultiple0x2            |  1b(n) + 20b(recipient) + 4b     |   	     32b + 32b + 32b + 32b      |   ---	   |
 *  |_______________________________|__________________________________|____________________________________|__________|
 *
 *          Generic Contract Interaction Flow:
 *
 *                 BridgeAgent.lzReceive()
 *                           |
 *                           V
 *              BridgeAgentExecutor.execute**()
 *                           |
 *                           V
 *                   Router.execute**()
 *                           |
 *                           V
 *            BridgeAgentExecutor (txExecuted)
 *
 */
interface IBranchBridgeAgent is ILayerZeroReceiver {
    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice External function to return the Branch Chain's Local Port Address.
     * @return address of the Branch Chain's Local Port.
     */
    function localPortAddress() external view returns (address);
    /**
     * @notice External function to return the Branch Bridge Agent Executor Address.
     * @return address of the Branch Bridge Agent Executor.
     *
     */
    function bridgeAgentExecutorAddress() external view returns (address);

    /**
     * @notice External function that returns a given deposit entry.
     *    @param depositNonce Identifier for user deposit.
     *
     */
    function getDepositEntry(uint32 depositNonce) external view returns (Deposit memory);

    /**
     * @notice External function that returns the message value needed for a cross-chain call according to given
     *         calldata and gas requirements.
     *    @param _gasLimit Gas limit for the cross-chain call.
     *    @param _remoteBranchExecutionGas Gas is required for the remote execution.
     *    @param _payload Calldata for the cross-chain call.
     *    @return _fee Message value needed for the cross-chain call.
     *
     */
    function getFeeEstimate(uint256 _gasLimit, uint256 _remoteBranchExecutionGas, bytes calldata _payload)
        external
        view
        returns (uint256 _fee);

    /*///////////////////////////////////////////////////////////////
                    USER AND BRANCH ROUTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function performs call to Layerzero Enpoint Contract for cross-chain messaging.
     *   @param gasRefundee address to return excess gas deposited in `msg.value` to.
     *   @param params calldata for omnichain execution.
     *   @param gasParams gas parameters for the cross-chain call.
     *   @dev DEPOSIT ID: 0 (System Call / Response)
     *   @dev this flag allows for identifying system emitted request/responses.
     *
     */
    function callOutSystem(address payable gasRefundee, bytes calldata params, GasParams calldata gasParams)
        external
        payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Router without token deposit.
     *   @param gasRefundee address to return excess gas deposited in `msg.value` to.
     *   @param params enconded parameters to execute on the root chain router.
     *   @param gasParams gas parameters for the cross-chain call.
     *   @dev DEPOSIT ID: 1 (Call without deposit)
     *
     */
    function callOut(address payable gasRefundee, bytes calldata params, GasParams calldata gasParams)
        external
        payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Router while depositing a single asset.
     *   @param gasRefundee address to return excess gas deposited in `msg.value` to.
     *   @param params enconded parameters to execute on the root chain router.
     *   @param depositParams additional token deposit parameters.
     *   @param gasParams gas parameters for the cross-chain call.
     *   @dev DEPOSIT ID: 2 (Call with single deposit)
     *
     */
    function callOutAndBridge(
        address payable gasRefundee,
        bytes calldata params,
        DepositInput memory depositParams,
        GasParams calldata gasParams
    ) external payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Router while depositing two or more assets.
     *   @param gasRefundee address to return excess gas deposited in `msg.value` to.
     *   @param params enconded parameters to execute on the root chain router.
     *   @param depositParams additional token deposit parameters.
     *   @param gasParams gas parameters for the cross-chain call.
     *   @dev DEPOSIT ID: 3 (Call with multiple deposit)
     *
     */
    function callOutAndBridgeMultiple(
        address payable gasRefundee,
        bytes calldata params,
        DepositMultipleInput memory depositParams,
        GasParams calldata gasParams
    ) external payable;

    /**
     * @notice Perform a call to the Root Omnichain Router without token deposit with msg.sender information.
     *   @param gasRefundee address to return excess gas deposited in `msg.value` to.
     *   @param params enconded parameters to execute on the root chain router.
     *   @param gasParams gas parameters for the cross-chain call.
     *   @dev DEPOSIT ID: 4 (Call without deposit and verified sender)
     *
     */
    function callOutSigned(address payable gasRefundee, bytes calldata params, GasParams calldata gasParams)
        external
        payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Router while depositing a single asset msg.sender.
     *   @param gasRefundee address to return excess gas deposited in `msg.value` to.
     *   @param params enconded parameters to execute on the root chain router.
     *   @param depositParams additional token deposit parameters.
     *   @param gasParams gas parameters for the cross-chain call.
     *   @param hasFallbackToggled flag to indicate if the fallback function was toggled.
     *   @dev DEPOSIT ID: 5 (Call with single deposit and verified sender)
     *
     */
    function callOutSignedAndBridge(
        address payable gasRefundee,
        bytes calldata params,
        DepositInput memory depositParams,
        GasParams calldata gasParams,
        bool hasFallbackToggled
    ) external payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Router while
     *         depositing two or more assets with msg.sender.
     *   @param gasRefundee address to return excess gas deposited in `msg.value` to.
     *   @param params enconded parameters to execute on the root chain router.
     *   @param depositParams additional token deposit parameters.
     *   @param gasParams gas parameters for the cross-chain call.
     *   @param hasFallbackToggled flag to indicate if the fallback function was toggled.
     *   @dev DEPOSIT ID: 6 (Call with multiple deposit and verified sender)
     *
     */
    function callOutSignedAndBridgeMultiple(
        address payable gasRefundee,
        bytes calldata params,
        DepositMultipleInput memory depositParams,
        GasParams calldata gasParams,
        bool hasFallbackToggled
    ) external payable;

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to perform a call to the Root Omnichain Environment
     *         retrying a failed deposit that hasn't been executed yet.
     *   @param isSigned Flag to indicate if the deposit was signed.
     *   @param depositNonce Identifier for user deposit.
     *   @param params parameters to execute on the root chain router.
     *   @param gasParams gas parameters for the cross-chain call.
     *   @param hasFallbackToggled flag to indicate if the fallback function was toggled.
     */
    function retryDeposit(
        bool isSigned,
        uint32 depositNonce,
        bytes calldata params,
        GasParams calldata gasParams,
        bool hasFallbackToggled
    ) external payable;

    /**
     * @notice External function to request tokens back to branch chain after failing omnichain environment interaction.
     *    @param depositNonce Identifier for user deposit to retrieve.
     *    @param gasParams gas parameters for the cross-chain call.
     *    @dev DEPOSIT ID: 8
     *
     */
    function retrieveDeposit(uint32 depositNonce, GasParams calldata gasParams) external payable;

    /**
     * @notice External function to retry a failed Deposit entry on this branch chain.
     *    @param depositNonce Identifier for user deposit.
     *
     */
    function redeemDeposit(uint32 depositNonce) external;

    /*///////////////////////////////////////////////////////////////
                    SETTLEMENT EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice External function to retry a failed Settlement entry on the root chain.
     *   @param settlementNonce Identifier for user settlement.
     *   @param params parameters to execute on the root chain router.
     *   @param gasParams gas parameters for the cross-chain call to root chain and for the settlement to branch.
     *   @param hasFallbackToggled flag to indicate if the fallback function should be toggled.
     *   @dev DEPOSIT ID: 7
     *
     */
    function retrySettlement(
        uint32 settlementNonce,
        bytes calldata params,
        GasParams[2] calldata gasParams,
        bool hasFallbackToggled
    ) external payable;

    /*///////////////////////////////////////////////////////////////
                    TOKEN MANAGEMENT EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to request balance clearance from a Port to a given user.
     *     @param recipient token receiver.
     *     @param hToken  local hToken addresse to clear balance for.
     *     @param token  native / underlying token addresse to clear balance for.
     *     @param amount amounts of hToken to clear balance for.
     *     @param deposit amount of native / underlying tokens to clear balance for.
     *
     */
    function clearToken(address recipient, address hToken, address token, uint256 amount, uint256 deposit) external;

    /**
     * @notice Function to request balance clearance from a Port to a given address.
     *     @param sParams encode packed multiple settlement info.
     *
     */
    function clearTokens(bytes calldata sParams, address recipient)
        external
        returns (SettlementMultipleParams memory);

    /*///////////////////////////////////////////////////////////////
                            LAYER ZERO FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice External function to receive cross-chain messages from LayerZero Endpoint Contract without blocking.
     *   @param _endpoint address of the LayerZero Endpoint Contract.
     *   @param _srcAddress address path of the recipient + sender.
     *   @param _payload Calldata for function call.
     */
    function lzReceiveNonBlocking(address _endpoint, bytes calldata _srcAddress, bytes calldata _payload) external;

    /*///////////////////////////////////////////////////////////////
                        EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogExecute(uint256 indexed nonce);
    event LogFallback(uint256 indexed nonce);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error UnknownFlag();
    error ExecutionFailure();

    error LayerZeroUnauthorizedCaller();
    error LayerZeroUnauthorizedEndpoint();

    error AlreadyExecutedTransaction();

    error InvalidInput();
    error InsufficientGas();

    error NotDepositOwner();
    error DepositRetryUnavailableUseCallout();
    error DepositRedeemUnavailable();

    error UnrecognizedRouter();
    error UnrecognizedBridgeAgentExecutor();
}
