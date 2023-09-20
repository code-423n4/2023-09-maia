// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {IBranchRouter as IRouter} from "./interfaces/IBranchRouter.sol";

import {BranchBridgeAgent} from "./BranchBridgeAgent.sol";
import {BridgeAgentConstants} from "./interfaces/BridgeAgentConstants.sol";
import {SettlementParams, SettlementMultipleParams} from "./interfaces/IBranchBridgeAgent.sol";

/// @title Library for Branch Bridge Agent Executor Deployment
library DeployBranchBridgeAgentExecutor {
    function deploy() external returns (address) {
        return address(new BranchBridgeAgentExecutor());
    }
}

/**
 * @title  Branch Bridge Agent Executor Contract
 * @author MaiaDAO
 * @notice This contract is used for requesting token deposit clearance and
 *         executing transactions in response to requests from the root environment.
 * @dev    Execution is "sandboxed" meaning upon tx failure both token deposits
 *         and interactions with external contracts should be reverted and caught.
 */
contract BranchBridgeAgentExecutor is Ownable, BridgeAgentConstants {
    using SafeTransferLib for address;
    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Branch Bridge Agent Executor.
     * @dev    Sets the owner of the contract to the Branch Bridge Agent that deploys it.
     */
    constructor() {
        _initializeOwner(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                        EXECUTOR EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to execute a cross-chain request without any settlement.
     * @param _router Address of the router contract to execute the request.
     * @param _payload Data received from the messaging layer.
     * @dev SETTLEMENT FLAG: 0 (No settlement)
     */
    function executeNoSettlement(address _router, bytes calldata _payload) external payable onlyOwner {
        // Execute Calldata if there is code in the destination router
        IRouter(_router).executeNoSettlement{value: msg.value}(_payload[PARAMS_TKN_START_SIGNED:]);
    }

    /**
     * @notice Function to execute a cross-chain request with a single settlement.
     * @param _recipient Address of the recipient of the settlement.
     * @param _router Address of the router contract to execute the request.
     * @param _payload Data received from the messaging layer.
     * @dev Router is responsible for managing the msg.value either using it for more remote calls or sending to user.
     * @dev SETTLEMENT FLAG: 1 (Single Settlement)
     */
    function executeWithSettlement(address _recipient, address _router, bytes calldata _payload)
        external
        payable
        onlyOwner
    {
        // Clear Token / Execute Settlement
        SettlementParams memory sParams = SettlementParams({
            settlementNonce: uint32(bytes4(_payload[PARAMS_START_SIGNED:PARAMS_TKN_START_SIGNED])),
            recipient: _recipient,
            hToken: address(uint160(bytes20(_payload[PARAMS_TKN_START_SIGNED:45]))),
            token: address(uint160(bytes20(_payload[45:65]))),
            amount: uint256(bytes32(_payload[65:97])),
            deposit: uint256(bytes32(_payload[97:PARAMS_SETTLEMENT_OFFSET]))
        });

        // Bridge In Assets
        BranchBridgeAgent(payable(msg.sender)).clearToken(
            sParams.recipient, sParams.hToken, sParams.token, sParams.amount, sParams.deposit
        );

        // Execute Calldata if there is any
        if (_payload.length > PARAMS_SETTLEMENT_OFFSET) {
            // Execute remote request
            IRouter(_router).executeSettlement{value: msg.value}(_payload[PARAMS_SETTLEMENT_OFFSET:], sParams);
        } else {
            // Send reamininig native / gas token to recipient
            _recipient.safeTransferETH(address(this).balance);
        }
    }

    /**
     * @notice Function to execute a cross-chain request with multiple settlements.
     * @param _recipient Address of the recipient of the settlement.
     * @param _router Address of the router contract to execute the request.
     * @param _payload Data received from the messaging layer.
     * @dev Router is responsible for managing the msg.value either using it for more remote calls or sending to user.
     * @dev SETTLEMENT FLAG: 2 (Multiple Settlements)
     */
    function executeWithSettlementMultiple(address _recipient, address _router, bytes calldata _payload)
        external
        payable
        onlyOwner
    {
        // Parse Values
        uint256 assetsOffset = uint8(bytes1(_payload[PARAMS_START_SIGNED])) * PARAMS_TKN_SET_SIZE_MULTIPLE;
        uint256 settlementEndOffset = PARAMS_START_SIGNED + PARAMS_TKN_START + assetsOffset;

        // Bridge In Assets and Save Deposit Params
        SettlementMultipleParams memory sParams = BranchBridgeAgent(payable(msg.sender)).clearTokens(
            _payload[PARAMS_START_SIGNED:settlementEndOffset], _recipient
        );

        // Execute Calldata if there is any
        if (_payload.length > settlementEndOffset) {
            // Execute the remote request
            IRouter(_router).executeSettlementMultiple{value: msg.value}(
                _payload[PARAMS_END_SIGNED_OFFSET + assetsOffset:], sParams
            );
        } else {
            // Send reamininig native / gas token to recipient
            _recipient.safeTransferETH(address(this).balance);
        }
    }
}
