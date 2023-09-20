// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IBranchBridgeAgent as IBridgeAgent, GasParams} from "./interfaces/IBranchBridgeAgent.sol";
import {IBranchBridgeAgentFactory as IBridgeAgentFactory} from "./interfaces/IBranchBridgeAgentFactory.sol";
import {IArbitrumBranchPort as IPort} from "./interfaces/IArbitrumBranchPort.sol";

import {CoreBranchRouter} from "./CoreBranchRouter.sol";

/**
 * @title  Arbitrum Core Branch Router Contract
 * @author MaiaDAO
 * @notice Core Branch Router implementation for Arbitrum deployment.
 *         This contract is responsible for permissionlessly adding new
 *         tokens or Bridge Agents to the system as well as key governance
 *         enabled system functions (i.e. `addBridgeAgentFactory`).
 * @dev    The function `addGlobalToken` is is not available since it's used
 *         to add a global token to a given Branch Chain and the Arbitrum Branch
 *         is already in the same network as the Root Environment and all the global
 *         tokens.
 *
 *         Func IDs for calling these functions through messaging layer:
 *
 *         CROSS-CHAIN MESSAGING FUNCIDs
 *         -----------------------------
 *         FUNC ID      | FUNC NAME
 *         -------------+---------------
 *         0x02         | addBridgeAgent
 *         0x03         | toggleBranchBridgeAgentFactory
 *         0x04         | removeBranchBridgeAgent
 *         0x05         | manageStrategyToken
 *         0x06         | managePortStrategy
 *
 */
contract ArbitrumCoreBranchRouter is CoreBranchRouter {
    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Constructor for Arbitrum Core Branch Router.
     */
    constructor() CoreBranchRouter(address(0)) {}

    /*///////////////////////////////////////////////////////////////
                    TOKEN MANAGEMENT EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    ///@inheritdoc CoreBranchRouter
    function addLocalToken(address _underlyingAddress, GasParams calldata) external payable override {
        //Encode Data, no need to create local token since we are already in the global environment
        bytes memory params = abi.encode(
            _underlyingAddress,
            address(0),
            string.concat("Arbitrum Ulysses ", ERC20(_underlyingAddress).name()),
            string.concat("arb-u", ERC20(_underlyingAddress).symbol()),
            ERC20(_underlyingAddress).decimals()
        );

        // Pack FuncId
        bytes memory payload = abi.encodePacked(bytes1(0x02), params);

        //Send Cross-Chain request (System Response/Request)
        IBridgeAgent(localBridgeAgentAddress).callOutSystem(payable(msg.sender), payload, GasParams(0, 0));
    }

    /*///////////////////////////////////////////////////////////////
                BRIDGE AGENT MANAGEMENT INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to deploy/add a token already active in the global environment in the Root Chain.
     * @dev Must be called from another chain.
     *    @param _newBranchRouter the address of the new branch router.
     *    @param _branchBridgeAgentFactory the address of the branch bridge agent factory.
     *    @param _rootBridgeAgent the address of the root bridge agent.
     *    @param _rootBridgeAgentFactory the address of the root bridge agent factory.
     *    @param _refundee the address of the excess gas receiver.
     *    @param _gParams Gas parameters for remote execution.
     *    @dev FUNC ID: 2
     *    @dev all hTokens have 18 decimals.
     *
     */
    function _receiveAddBridgeAgent(
        address _newBranchRouter,
        address _branchBridgeAgentFactory,
        address _rootBridgeAgent,
        address _rootBridgeAgentFactory,
        address _refundee,
        GasParams memory _gParams
    ) internal override {
        // Cache local port address
        address _localPortAddress = localPortAddress;

        // Check if msg.sender is a valid BridgeAgentFactory
        if (!IPort(_localPortAddress).isBridgeAgentFactory(_branchBridgeAgentFactory)) {
            revert UnrecognizedBridgeAgentFactory();
        }

        // Create Token
        address newBridgeAgent = IBridgeAgentFactory(_branchBridgeAgentFactory).createBridgeAgent(
            _newBranchRouter, _rootBridgeAgent, _rootBridgeAgentFactory
        );

        // Check BridgeAgent Address
        if (!IPort(_localPortAddress).isBridgeAgent(newBridgeAgent)) {
            revert UnrecognizedBridgeAgent();
        }

        // Encode Params
        bytes memory data = abi.encode(newBridgeAgent, _rootBridgeAgent);

        // Pack FuncId and Params to create payload
        bytes memory payload = abi.encodePacked(bytes1(0x04), data);

        //Send Cross-Chain request
        IBridgeAgent(localBridgeAgentAddress).callOutSystem(payable(_refundee), payload, _gParams);
    }

    /*///////////////////////////////////////////////////////////////
                    LAYERZERO EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    ///@inheritdoc CoreBranchRouter
    function executeNoSettlement(bytes calldata _data) external payable override requiresAgentExecutor {
        if (_data[0] == 0x02) {
            (
                address newBranchRouter,
                address branchBridgeAgentFactory,
                address rootBridgeAgent,
                address rootBridgeAgentFactory,
                address refundee,
            ) = abi.decode(_data[1:], (address, address, address, address, address, GasParams));

            _receiveAddBridgeAgent(
                newBranchRouter,
                branchBridgeAgentFactory,
                rootBridgeAgent,
                rootBridgeAgentFactory,
                refundee,
                GasParams(0, 0)
            );

            /// _toggleBranchBridgeAgentFactory
        } else if (_data[0] == 0x03) {
            (address bridgeAgentFactoryAddress) = abi.decode(_data[1:], (address));

            _toggleBranchBridgeAgentFactory(bridgeAgentFactoryAddress);

            /// _removeBranchBridgeAgent
        } else if (_data[0] == 0x04) {
            (address branchBridgeAgent) = abi.decode(_data[1:], (address));
            _removeBranchBridgeAgent(branchBridgeAgent);

            /// _manageStrategyToken
        } else if (_data[0] == 0x05) {
            (address underlyingToken, uint256 minimumReservesRatio) = abi.decode(_data[1:], (address, uint256));
            _manageStrategyToken(underlyingToken, minimumReservesRatio);

            /// _managePortStrategy
        } else if (_data[0] == 0x06) {
            (address portStrategy, address underlyingToken, uint256 dailyManagementLimit, bool isUpdateDailyLimit) =
                abi.decode(_data[1:], (address, address, uint256, bool));
            _managePortStrategy(portStrategy, underlyingToken, dailyManagementLimit, isUpdateDailyLimit);

            /// Unrecognized Function Selector
        } else {
            revert UnrecognizedFunctionId();
        }
    }
}
