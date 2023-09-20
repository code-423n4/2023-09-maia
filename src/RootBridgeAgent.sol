// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {ExcessivelySafeCall} from "lib/ExcessivelySafeCall.sol";

import {ILayerZeroEndpoint} from "./interfaces/ILayerZeroEndpoint.sol";

import {IBranchBridgeAgent} from "./interfaces/IBranchBridgeAgent.sol";
import {IERC20hTokenRoot} from "./interfaces/IERC20hTokenRoot.sol";

import {BridgeAgentConstants} from "./interfaces/BridgeAgentConstants.sol";
import {
    GasParams,
    DepositParams,
    DepositMultipleParams,
    ILayerZeroReceiver,
    IRootBridgeAgent,
    Settlement,
    SettlementInput,
    SettlementMultipleInput
} from "./interfaces/IRootBridgeAgent.sol";

import {IRootPort as IPort} from "./interfaces/IRootPort.sol";

import {VirtualAccount} from "./VirtualAccount.sol";
import {DeployRootBridgeAgentExecutor, RootBridgeAgentExecutor} from "./RootBridgeAgentExecutor.sol";

/// @title Root Bridge Agent Contract
/// @author MaiaDAO
contract RootBridgeAgent is IRootBridgeAgent, BridgeAgentConstants {
    using SafeTransferLib for address;
    using ExcessivelySafeCall for address;
    /*///////////////////////////////////////////////////////////////
                        ROOT BRIDGE AGENT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Local Chain Id
    uint16 public immutable localChainId;

    /// @notice Bridge Agent Factory Address.
    address public immutable factoryAddress;

    /// @notice Local Core Root Router Address
    address public immutable localRouterAddress;

    /// @notice Local Port Address where funds deposited from this chain are stored.
    address public immutable localPortAddress;

    /// @notice Local Layer Zero Endpoint Address for cross-chain communication.
    address public immutable lzEndpointAddress;

    /// @notice Address of Root Bridge Agent Executor.
    address public immutable bridgeAgentExecutorAddress;

    /*///////////////////////////////////////////////////////////////
                        BRANCH BRIDGE AGENTS STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Chain -> Branch Bridge Agent Address. For N chains, each Root Bridge Agent Address has M =< N Branch Bridge Agent Address.
    mapping(uint256 chainId => address branchBridgeAgent) public getBranchBridgeAgent;

    /// @notice Message Path for each connected Branch Bridge Agent as bytes for Layzer Zero interaction = localAddress + destinationAddress abi.encodePacked()
    mapping(uint256 chainId => bytes branchBridgeAgentPath) public getBranchBridgeAgentPath;

    /// @notice If true, bridge agent manager has allowed for a new given branch bridge agent to be synced/added.
    mapping(uint256 chainId => bool allowed) public isBranchBridgeAgentAllowed;

    /*///////////////////////////////////////////////////////////////
                            SETTLEMENTS STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit nonce used for identifying transaction.
    uint32 public settlementNonce;

    /// @notice Mapping from Settlement nonce to Settlement Struct.
    mapping(uint256 nonce => Settlement settlementInfo) public getSettlement;

    /*///////////////////////////////////////////////////////////////
                            EXECUTOR STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice If true, bridge agent has already served a request with this nonce from  a given chain. Chain -> Nonce -> Bool
    mapping(uint256 chainId => mapping(uint256 nonce => uint256 state)) public executionState;

    /*///////////////////////////////////////////////////////////////
                            REENTRANCY STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Re-entrancy lock modifier state.
    uint256 internal _unlocked = 1;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Bridge Agent.
     *     @param _localChainId Local Chain Id.
     *     @param _lzEndpointAddress Local Layerzero Endpoint Address.
     *     @param _localPortAddress Local Port Address.
     *     @param _localRouterAddress Local Port Address.
     */
    constructor(
        uint16 _localChainId,
        address _lzEndpointAddress,
        address _localPortAddress,
        address _localRouterAddress
    ) {
        require(_lzEndpointAddress != address(0), "Layerzero Enpoint Address cannot be zero address");
        require(_localPortAddress != address(0), "Port Address cannot be zero address");
        require(_localRouterAddress != address(0), "Router Address cannot be zero address");

        factoryAddress = msg.sender;
        localChainId = _localChainId;
        lzEndpointAddress = _lzEndpointAddress;
        localPortAddress = _localPortAddress;
        localRouterAddress = _localRouterAddress;
        bridgeAgentExecutorAddress = DeployRootBridgeAgentExecutor.deploy(address(this));
        settlementNonce = 1;
    }

    /*///////////////////////////////////////////////////////////////
                        FALLBACK FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}

    /*///////////////////////////////////////////////////////////////
                        VIEW EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootBridgeAgent
    function getSettlementEntry(uint32 _settlementNonce) external view override returns (Settlement memory) {
        return getSettlement[_settlementNonce];
    }

    /// @inheritdoc IRootBridgeAgent
    function getFeeEstimate(
        uint256 _gasLimit,
        uint256 _remoteBranchExecutionGas,
        bytes calldata _payload,
        uint16 _dstChainId
    ) external view returns (uint256 _fee) {
        (_fee,) = ILayerZeroEndpoint(lzEndpointAddress).estimateFees(
            _dstChainId,
            address(this),
            _payload,
            false,
            abi.encodePacked(uint16(2), _gasLimit, _remoteBranchExecutionGas, getBranchBridgeAgent[_dstChainId])
        );
    }

    /*///////////////////////////////////////////////////////////////
                    ROOT ROUTER EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootBridgeAgent
    function callOut(
        address payable _refundee,
        address _recipient,
        uint16 _dstChainId,
        bytes calldata _params,
        GasParams calldata _gParams
    ) external payable override lock requiresRouter {
        //Encode Data for call.
        bytes memory payload = abi.encodePacked(bytes1(0x00), _recipient, settlementNonce++, _params);

        //Perform Call to clear hToken balance on destination branch chain.
        _performCall(_dstChainId, _refundee, payload, _gParams);
    }

    /// @inheritdoc IRootBridgeAgent
    function callOutAndBridge(
        address payable _refundee,
        address _recipient,
        uint16 _dstChainId,
        bytes calldata _params,
        SettlementInput calldata _sParams,
        GasParams calldata _gParams,
        bool _hasFallbackToggled
    ) external payable override lock requiresRouter {
        // Create Settlement and Perform call
        bytes memory payload = _createSettlement(
            settlementNonce,
            _refundee,
            _recipient,
            _dstChainId,
            _params,
            _sParams.globalAddress,
            _sParams.amount,
            _sParams.deposit,
            _hasFallbackToggled
        );

        //Perform Call.
        _performCall(_dstChainId, _refundee, payload, _gParams);
    }

    /// @inheritdoc IRootBridgeAgent
    function callOutAndBridgeMultiple(
        address payable _refundee,
        address _recipient,
        uint16 _dstChainId,
        bytes calldata _params,
        SettlementMultipleInput calldata _sParams,
        GasParams calldata _gParams,
        bool _hasFallbackToggled
    ) external payable override lock requiresRouter {
        // Create Settlement and Perform call
        bytes memory payload = _createSettlementMultiple(
            settlementNonce,
            _refundee,
            _recipient,
            _dstChainId,
            _sParams.globalAddresses,
            _sParams.amounts,
            _sParams.deposits,
            _params,
            _hasFallbackToggled
        );

        // Perform Call to destination Branch Chain.
        _performCall(_dstChainId, _refundee, payload, _gParams);
    }

    /*///////////////////////////////////////////////////////////////
                    SETTLEMENT EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootBridgeAgent
    function retrySettlement(
        uint32 _settlementNonce,
        address _recipient,
        bytes calldata _params,
        GasParams calldata _gParams,
        bool _hasFallbackToggled
    ) external payable override lock {
        // Get storage reference
        Settlement storage settlementReference = getSettlement[_settlementNonce];

        // Check if Settlement hasn't been redeemed.
        if (settlementReference.owner == address(0)) revert SettlementRetryUnavailable();

        // Check if caller is Settlement owner
        if (msg.sender != settlementReference.owner) {
            if (msg.sender != address(IPort(localPortAddress).getUserAccount(settlementReference.owner))) {
                revert NotSettlementOwner();
            }
        }

        // Update Settlement Status
        settlementReference.status = STATUS_SUCCESS;

        // Perform Settlement Retry
        _performRetrySettlementCall(
            _hasFallbackToggled,
            settlementReference.hTokens,
            settlementReference.tokens,
            settlementReference.amounts,
            settlementReference.deposits,
            _params,
            _settlementNonce,
            payable(settlementReference.owner),
            _recipient,
            settlementReference.dstChainId,
            _gParams,
            msg.value
        );
    }

    /// @inheritdoc IRootBridgeAgent
    function retrieveSettlement(uint32 _settlementNonce, GasParams calldata _gParams) external payable lock {
        //Get settlement storage reference
        Settlement storage settlementReference = getSettlement[_settlementNonce];

        // Get Settlement owner.
        address settlementOwner = settlementReference.owner;

        // Check if Settlement is Retrieve.
        if (settlementOwner == address(0)) revert SettlementRetrieveUnavailable();

        // Check Settlement Owner
        if (msg.sender != settlementOwner) {
            if (msg.sender != address(IPort(localPortAddress).getUserAccount(settlementOwner))) {
                revert NotSettlementOwner();
            }
        }

        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(bytes1(0x03), settlementOwner, _settlementNonce);

        //Retrieve Deposit
        _performCall(settlementReference.dstChainId, payable(settlementOwner), payload, _gParams);
    }

    /// @inheritdoc IRootBridgeAgent
    function redeemSettlement(uint32 _settlementNonce) external override lock {
        // Get setttlement storage reference
        Settlement storage settlement = getSettlement[_settlementNonce];

        // Get deposit owner.
        address settlementOwner = settlement.owner;

        // Check if Settlement is redeemable.
        if (settlement.status == STATUS_SUCCESS) revert SettlementRedeemUnavailable();
        if (settlementOwner == address(0)) revert SettlementRedeemUnavailable();

        // Check if Settlement Owner is msg.sender or msg.sender is the virtual account of the settlement owner.
        if (msg.sender != settlementOwner) {
            if (msg.sender != address(IPort(localPortAddress).getUserAccount(settlementOwner))) {
                revert NotSettlementOwner();
            }
        }

        // Clear Global hTokens To Recipient on Root Chain cancelling Settlement to Branch
        for (uint256 i = 0; i < settlement.hTokens.length;) {
            // Save to memory
            address _hToken = settlement.hTokens[i];

            // Check if asset
            if (_hToken != address(0)) {
                // Save to memory
                uint24 _dstChainId = settlement.dstChainId;

                // Move hTokens from Branch to Root + Mint Sufficient hTokens to match new port deposit
                IPort(localPortAddress).bridgeToRoot(
                    msg.sender,
                    IPort(localPortAddress).getGlobalTokenFromLocal(_hToken, _dstChainId),
                    settlement.amounts[i],
                    settlement.deposits[i],
                    _dstChainId
                );
            }

            unchecked {
                ++i;
            }
        }

        // Delete Settlement
        delete getSettlement[_settlementNonce];
    }

    /*///////////////////////////////////////////////////////////////
                    TOKEN MANAGEMENT EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootBridgeAgent
    function bridgeIn(address _recipient, DepositParams memory _dParams, uint256 _srcChainId)
        public
        override
        requiresAgentExecutor
    {
        // Deposit can't be greater than amount.
        if (_dParams.amount < _dParams.deposit) revert InvalidInputParams();

        // Cache local port address
        address _localPortAddress = localPortAddress;

        // Check local exists.
        if (_dParams.amount > 0) {
            if (!IPort(_localPortAddress).isLocalToken(_dParams.hToken, _srcChainId)) {
                revert InvalidInputParams();
            }
        }

        // Check underlying exists.
        if (_dParams.deposit > 0) {
            if (IPort(_localPortAddress).getLocalTokenFromUnderlying(_dParams.token, _srcChainId) != _dParams.hToken) {
                revert InvalidInputParams();
            }
        }

        // Move hTokens from Branch to Root + Mint Sufficient hTokens to match new port deposit
        IPort(_localPortAddress).bridgeToRoot(
            _recipient,
            IPort(_localPortAddress).getGlobalTokenFromLocal(_dParams.hToken, _srcChainId),
            _dParams.amount,
            _dParams.deposit,
            _srcChainId
        );
    }

    /// @inheritdoc IRootBridgeAgent
    function bridgeInMultiple(address _recipient, DepositMultipleParams calldata _dParams, uint256 _srcChainId)
        external
        override
        requiresAgentExecutor
    {
        // Cache length
        uint256 length = _dParams.hTokens.length;

        // Check MAX_LENGTH
        if (length > MAX_TOKENS_LENGTH) revert InvalidInputParams();

        // Bridge in assets
        for (uint256 i = 0; i < length;) {
            bridgeIn(
                _recipient,
                DepositParams({
                    hToken: _dParams.hTokens[i],
                    token: _dParams.tokens[i],
                    amount: _dParams.amounts[i],
                    deposit: _dParams.deposits[i],
                    depositNonce: 0
                }),
                _srcChainId
            );

            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                    LAYER ZERO EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ILayerZeroReceiver
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64, bytes calldata _payload) public {
        (bool success,) = address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(this.lzReceiveNonBlocking.selector, msg.sender, _srcChainId, _srcAddress, _payload)
        );

        if (!success) if (msg.sender == getBranchBridgeAgent[localChainId]) revert ExecutionFailure();
    }

    /// @inheritdoc IRootBridgeAgent
    function lzReceiveNonBlocking(
        address _endpoint,
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) public override requiresEndpoint(_endpoint, _srcChainId, _srcAddress) {
        // Deposit Nonce
        uint32 nonce;

        // DEPOSIT FLAG: 0 (System request / response)
        if (_payload[0] == 0x00) {
            // Parse deposit nonce
            nonce = uint32(bytes4(_payload[PARAMS_START:PARAMS_TKN_START]));

            // Check if tx has already been executed
            if (executionState[_srcChainId][nonce] != STATUS_READY) {
                revert AlreadyExecutedTransaction();
            }

            // Avoid stack too deep
            uint16 srcChainId = _srcChainId;

            // Try to execute remote request
            // Flag 0 - RootBridgeAgentExecutor(bridgeAgentExecutorAddress).executeSystemRequest(_localRouterAddress, _payload, _srcChainId)
            _execute(
                nonce,
                abi.encodeWithSelector(
                    RootBridgeAgentExecutor.executeSystemRequest.selector, localRouterAddress, _payload, srcChainId
                ),
                srcChainId
            );

            // DEPOSIT FLAG: 1 (Call without Deposit)
        } else if (_payload[0] == 0x01) {
            // Parse Deposit Nonce
            nonce = uint32(bytes4(_payload[PARAMS_START:PARAMS_TKN_START]));

            // Check if tx has already been executed
            if (executionState[_srcChainId][nonce] != STATUS_READY) {
                revert AlreadyExecutedTransaction();
            }

            // Avoid stack too deep
            uint16 srcChainId = _srcChainId;

            // Try to execute remote request
            // Flag 1 - RootBridgeAgentExecutor(bridgeAgentExecutorAddress).executeNoDeposit(localRouterAddress, payload, _srcChainId)
            _execute(
                nonce,
                abi.encodeWithSelector(
                    RootBridgeAgentExecutor.executeNoDeposit.selector, localRouterAddress, _payload, srcChainId
                ),
                srcChainId
            );

            // DEPOSIT FLAG: 2 (Call with Deposit)
        } else if (_payload[0] == 0x02) {
            //Parse Deposit Nonce
            nonce = uint32(bytes4(_payload[PARAMS_START:PARAMS_TKN_START]));

            //Check if tx has already been executed
            if (executionState[_srcChainId][nonce] != STATUS_READY) {
                revert AlreadyExecutedTransaction();
            }

            // Avoid stack too deep
            uint16 srcChainId = _srcChainId;

            // Try to execute remote request
            // Flag 2 - RootBridgeAgentExecutor(bridgeAgentExecutorAddress).executeWithDeposit(localRouterAddress, _payload, _srcChainId)
            _execute(
                nonce,
                abi.encodeWithSelector(
                    RootBridgeAgentExecutor.executeWithDeposit.selector, localRouterAddress, _payload, srcChainId
                ),
                srcChainId
            );

            // DEPOSIT FLAG: 3 (Call with multiple asset Deposit)
        } else if (_payload[0] == 0x03) {
            // Parse deposit nonce
            nonce = uint32(bytes4(_payload[2:6]));

            // Check if tx has already been executed
            if (executionState[_srcChainId][nonce] != STATUS_READY) {
                revert AlreadyExecutedTransaction();
            }

            // Avoid stack too deep
            uint16 srcChainId = _srcChainId;

            // Try to execute remote request
            // Flag 3 - RootBridgeAgentExecutor(bridgeAgentExecutorAddress).executeWithDepositMultiple(localRouterAddress, _payload, _srcChainId)
            _execute(
                nonce,
                abi.encodeWithSelector(
                    RootBridgeAgentExecutor.executeWithDepositMultiple.selector,
                    localRouterAddress,
                    _payload,
                    srcChainId
                ),
                srcChainId
            );

            // DEPOSIT FLAG: 4 (Call without Deposit + msg.sender)
        } else if (_payload[0] == 0x04) {
            // Parse deposit nonce
            nonce = uint32(bytes4(_payload[PARAMS_START_SIGNED:PARAMS_TKN_START_SIGNED]));

            //Check if tx has already been executed
            if (executionState[_srcChainId][nonce] != STATUS_READY) {
                revert AlreadyExecutedTransaction();
            }

            // Get User Virtual Account
            VirtualAccount userAccount = IPort(localPortAddress).fetchVirtualAccount(
                address(uint160(bytes20(_payload[PARAMS_START:PARAMS_START_SIGNED])))
            );

            // Toggle Router Virtual Account use for tx execution
            IPort(localPortAddress).toggleVirtualAccountApproved(userAccount, localRouterAddress);

            // Avoid stack too deep
            uint16 srcChainId = _srcChainId;

            // Try to execute remote request
            // Flag 4 - RootBridgeAgentExecutor(bridgeAgentExecutorAddress).executeSignedNoDeposit(address(userAccount), localRouterAddress, data, _srcChainId
            _execute(
                nonce,
                abi.encodeWithSelector(
                    RootBridgeAgentExecutor.executeSignedNoDeposit.selector,
                    address(userAccount),
                    localRouterAddress,
                    _payload,
                    srcChainId
                ),
                srcChainId
            );

            // Toggle Router Virtual Account use for tx execution
            IPort(localPortAddress).toggleVirtualAccountApproved(userAccount, localRouterAddress);

            //DEPOSIT FLAG: 5 (Call with Deposit + msg.sender)
        } else if (_payload[0] & 0x7F == 0x05) {
            // Parse deposit nonce
            nonce = uint32(bytes4(_payload[PARAMS_START_SIGNED:PARAMS_TKN_START_SIGNED]));

            //Check if tx has already been executed
            if (executionState[_srcChainId][nonce] != STATUS_READY) {
                revert AlreadyExecutedTransaction();
            }

            // Get User Virtual Account
            VirtualAccount userAccount = IPort(localPortAddress).fetchVirtualAccount(
                address(uint160(bytes20(_payload[PARAMS_START:PARAMS_START_SIGNED])))
            );

            // Toggle Router Virtual Account use for tx execution
            IPort(localPortAddress).toggleVirtualAccountApproved(userAccount, localRouterAddress);

            // Avoid stack too deep
            uint16 srcChainId = _srcChainId;

            // Try to execute remote request
            // Flag 5 - RootBridgeAgentExecutor(bridgeAgentExecutorAddress).executeSignedWithDeposit(address(userAccount), localRouterAddress, data, _srcChainId)
            _execute(
                _payload[0] == 0x85,
                nonce,
                address(uint160(bytes20(_payload[PARAMS_START:PARAMS_START_SIGNED]))),
                abi.encodeWithSelector(
                    RootBridgeAgentExecutor.executeSignedWithDeposit.selector,
                    address(userAccount),
                    localRouterAddress,
                    _payload,
                    srcChainId
                ),
                srcChainId
            );

            // Toggle Router Virtual Account use for tx execution
            IPort(localPortAddress).toggleVirtualAccountApproved(userAccount, localRouterAddress);

            // DEPOSIT FLAG: 6 (Call with multiple asset Deposit + msg.sender)
        } else if (_payload[0] & 0x7F == 0x06) {
            // Parse deposit nonce
            nonce = uint32(bytes4(_payload[PARAMS_START_SIGNED + PARAMS_START:PARAMS_START_SIGNED + PARAMS_TKN_START]));

            // Check if tx has already been executed
            if (executionState[_srcChainId][nonce] != STATUS_READY) {
                revert AlreadyExecutedTransaction();
            }

            // Get User Virtual Account
            VirtualAccount userAccount = IPort(localPortAddress).fetchVirtualAccount(
                address(uint160(bytes20(_payload[PARAMS_START:PARAMS_START_SIGNED])))
            );

            // Toggle Router Virtual Account use for tx execution
            IPort(localPortAddress).toggleVirtualAccountApproved(userAccount, localRouterAddress);

            // Avoid stack too deep
            uint16 srcChainId = _srcChainId;

            // Try to execute remote request
            // Flag 6 - RootBridgeAgentExecutor(bridgeAgentExecutorAddress).executeSignedWithDepositMultiple(address(userAccount), localRouterAddress, data, _srcChainId)
            _execute(
                _payload[0] == 0x86,
                nonce,
                address(uint160(bytes20(_payload[PARAMS_START:PARAMS_START_SIGNED]))),
                abi.encodeWithSelector(
                    RootBridgeAgentExecutor.executeSignedWithDepositMultiple.selector,
                    address(userAccount),
                    localRouterAddress,
                    _payload,
                    srcChainId
                ),
                srcChainId
            );

            // Toggle Router Virtual Account use for tx execution
            IPort(localPortAddress).toggleVirtualAccountApproved(userAccount, localRouterAddress);

            /// DEPOSIT FLAG: 7 (retrySettlement)
        } else if (_payload[0] & 0x7F == 0x07) {
            // Prepare Variables for decoding
            address owner;
            bytes memory params;
            GasParams memory gParams;

            // Decode Input
            (nonce, owner, params, gParams) = abi.decode(_payload[PARAMS_START:], (uint32, address, bytes, GasParams));

            // Get storage reference
            Settlement storage settlementReference = getSettlement[nonce];

            // Check if Settlement hasn't been redeemed.
            if (settlementReference.owner == address(0)) revert SettlementRetryUnavailable();

            // Check settlement owner
            if (owner != settlementReference.owner) {
                if (owner != address(IPort(localPortAddress).getUserAccount(settlementReference.owner))) {
                    revert NotSettlementOwner();
                }
            }

            //Update Settlement Staus
            settlementReference.status = STATUS_SUCCESS;

            //Retry settlement call with new params and gas
            _performRetrySettlementCall(
                _payload[0] == 0x87,
                settlementReference.hTokens,
                settlementReference.tokens,
                settlementReference.amounts,
                settlementReference.deposits,
                params,
                nonce,
                payable(settlementReference.owner),
                settlementReference.recipient,
                settlementReference.dstChainId,
                gParams,
                address(this).balance
            );

            /// DEPOSIT FLAG: 8 (retrieveDeposit)
        } else if (_payload[0] == 0x08) {
            //Parse deposit nonce
            nonce = uint32(bytes4(_payload[PARAMS_START_SIGNED:PARAMS_TKN_START_SIGNED]));

            //Check if deposit is in retrieve mode
            if (executionState[_srcChainId][nonce] == STATUS_DONE) {
                revert AlreadyExecutedTransaction();
            } else {
                //Set settlement to retrieve mode, if not already set.
                if (executionState[_srcChainId][nonce] == STATUS_READY) {
                    executionState[_srcChainId][nonce] = STATUS_RETRIEVE;
                }
                //Trigger fallback/Retry failed fallback
                _performFallbackCall(
                    payable(address(uint160(bytes20(_payload[PARAMS_START:PARAMS_START_SIGNED])))), nonce, _srcChainId
                );
            }

            //DEPOSIT FLAG: 9 (Fallback)
        } else if (_payload[0] == 0x09) {
            // Parse nonce
            nonce = uint32(bytes4(_payload[PARAMS_START:PARAMS_TKN_START]));

            // Reopen Settlement for redemption
            getSettlement[nonce].status = STATUS_FAILED;

            // Emit LogFallback
            emit LogFallback(nonce, _srcChainId);

            // return to prevent unnecessary emits/logic
            return;

            // Unrecognized Function Selector
        } else {
            revert UnknownFlag();
        }

        emit LogExecute(nonce, _srcChainId);
    }

    /*///////////////////////////////////////////////////////////////
                DEPOSIT EXECUTION INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function requests execution from Root Bridge Agent Executor Contract.
     *   @param _depositNonce Identifier for nonce being executed.
     *   @param _calldata Payload of message to be executed by the Root Bridge Agent Executor Contract.
     *   @param _srcChainId Chain ID of source chain where request originates from.
     */
    function _execute(uint256 _depositNonce, bytes memory _calldata, uint16 _srcChainId) private {
        //Update tx state as executed
        executionState[_srcChainId][_depositNonce] = STATUS_DONE;

        //Try to execute the remote request
        (bool success,) = bridgeAgentExecutorAddress.call{value: address(this).balance}(_calldata);

        // No fallback is requested revert allowing for retry.
        if (!success) revert ExecutionFailure();
    }

    /**
     * @notice Internal function requests execution from Root Bridge Agent Executor Contract.
     *   @param _hasFallbackToggled if true, fallback on execution failure is toggled on.
     *   @param _depositNonce Identifier for nonce being executed.
     *   @param _refundee address to refund gas to in case of fallback being triggered.
     *   @param _calldata Calldata to be executed by the Root Bridge Agent Executor Contract.
     *   @param _srcChainId Chain ID of source chain where request originates from.
     */
    function _execute(
        bool _hasFallbackToggled,
        uint32 _depositNonce,
        address _refundee,
        bytes memory _calldata,
        uint16 _srcChainId
    ) private {
        //Update tx state as executed
        executionState[_srcChainId][_depositNonce] = STATUS_DONE;

        //Try to execute the remote request
        (bool success,) = bridgeAgentExecutorAddress.call{value: address(this).balance}(_calldata);

        //Update tx state if execution failed
        if (!success) {
            //Read the fallback flag.
            if (_hasFallbackToggled) {
                // Update tx state as retrieve only
                executionState[_srcChainId][_depositNonce] = STATUS_RETRIEVE;
                // Perform the fallback call
                _performFallbackCall(payable(_refundee), _depositNonce, _srcChainId);
            } else {
                // No fallback is requested revert allowing for retry.
                revert ExecutionFailure();
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                    LAYER ZERO INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function performs call to Layer Zero Endpoint Contract for cross-chain messaging.
     *   @param _refundee address to refund excess gas to.
     *   @param _dstChainId Layer Zero Chain ID of destination chain.
     *   @param _payload Payload of message to be sent to Layer Zero Endpoint Contract.
     *   @param _gParams Gas parameters for cross-chain message execution.
     */

    function _performCall(
        uint16 _dstChainId,
        address payable _refundee,
        bytes memory _payload,
        GasParams calldata _gParams
    ) internal {
        // Get destination Branch Bridge Agent
        address callee = getBranchBridgeAgent[_dstChainId];

        // Check if valid destination
        if (callee == address(0)) revert UnrecognizedBridgeAgent();

        // Check if call to remote chain
        if (_dstChainId != localChainId) {
            //Sends message to Layerzero Enpoint
            ILayerZeroEndpoint(lzEndpointAddress).send{value: msg.value}(
                _dstChainId,
                getBranchBridgeAgentPath[_dstChainId],
                _payload,
                _refundee,
                address(0),
                abi.encodePacked(uint16(2), _gParams.gasLimit, _gParams.remoteBranchExecutionGas, callee)
            );

            // Check if call to local chain
        } else {
            //Send Gas to Local Branch Bridge Agent
            callee.call{value: msg.value}("");
            //Execute locally
            IBranchBridgeAgent(callee).lzReceive(0, "", 0, _payload);
        }
    }

    /**
     * @notice Internal function performs call to Layer Zero Endpoint Contract for cross-chain messaging.
     *   @param _hasFallbackToggled if true, fallback is toggled on.
     *   @param _hTokens deposited global token address.
     *   @param _tokens deposited global token address.
     *   @param _amounts amounts of total hTokens + Tokens output.
     *   @param _deposits amount of underlying/native tokens to output.
     *   @param _params Payload of message to be sent to Layer Zero Endpoint Contract.
     *   @param _gParams Gas parameters for cross-chain message execution.
     *   @param _settlementNonce Identifier for token settlement.
     *   @param _refundee address of token owner and gas refundee.
     *   @param _recipient destination chain receiver address.
     *   @param _dstChainId Chain ID of destination chain.
     */

    function _performRetrySettlementCall(
        bool _hasFallbackToggled,
        address[] memory _hTokens,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _deposits,
        bytes memory _params,
        uint32 _settlementNonce,
        address payable _refundee,
        address _recipient,
        uint16 _dstChainId,
        GasParams memory _gParams,
        uint256 _value
    ) internal {
        // Check if payload is ready for message
        if (_hTokens.length == 0) revert SettlementRetryUnavailableUseCallout();

        // Get packed data
        bytes memory payload;

        // Check if it's a single asset settlement
        if (_hTokens.length == 1) {
            //Pack new Data
            payload = abi.encodePacked(
                _hasFallbackToggled ? bytes1(0x81) : bytes1(0x01),
                _recipient,
                _settlementNonce,
                _hTokens[0],
                _tokens[0],
                _amounts[0],
                _deposits[0],
                _params
            );

            // Check if it's mulitple asset settlement
        } else if (_hTokens.length > 1) {
            //Pack new Data
            payload = abi.encodePacked(
                _hasFallbackToggled ? bytes1(0x82) : bytes1(0x02),
                _recipient,
                uint8(_hTokens.length),
                _settlementNonce,
                _hTokens,
                _tokens,
                _amounts,
                _deposits,
                _params
            );
        }

        // Get destination Branch Bridge Agent
        address callee = getBranchBridgeAgent[_dstChainId];

        // Check if valid destination
        if (callee == address(0)) revert UnrecognizedBridgeAgent();

        // Check if call to remote chain
        if (_dstChainId != localChainId) {
            //Sends message to Layerzero Enpoint
            ILayerZeroEndpoint(lzEndpointAddress).send{value: _value}(
                _dstChainId,
                getBranchBridgeAgentPath[_dstChainId],
                payload,
                payable(_refundee),
                address(0),
                abi.encodePacked(uint16(2), _gParams.gasLimit, _gParams.remoteBranchExecutionGas, callee)
            );

            // Check if call to local chain
        } else {
            //Send Gas to Local Branch Bridge Agent
            callee.call{value: _value}("");
            //Execute locally
            IBranchBridgeAgent(callee).lzReceive(0, "", 0, payload);
        }
    }

    /**
     * @notice Internal function performs call to Layerzero Enpoint Contract for cross-chain messaging.
     *   @param _depositNonce branch deposit nonce.
     *   @param _dstChainId Chain ID of destination chain.
     */
    function _performFallbackCall(address payable _refundee, uint32 _depositNonce, uint16 _dstChainId) internal {
        //Sends message to LayerZero messaging layer
        ILayerZeroEndpoint(lzEndpointAddress).send{value: address(this).balance}(
            _dstChainId,
            getBranchBridgeAgentPath[_dstChainId],
            abi.encodePacked(bytes1(0x04), _depositNonce),
            payable(_refundee),
            address(0),
            ""
        );
    }

    /*///////////////////////////////////////////////////////////////
                    SETTLEMENT INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to settle a single asset and perform a remote call to a branch chain.
     *     @param _settlementNonce Identifier for token settlement.
     *     @param _refundee address of token owner and gas refundee.
     *     @param _recipient destination chain token receiver address.
     *     @param _dstChainId branch chain to bridge to.
     *     @param _params params for branch bridge agent and router execution.
     *     @param _globalAddress global address of the token in root chain.
     *     @param _amount amount of hTokens to be bridged out.
     *     @param _deposit amount of underlying tokens to be cleared from branch port.
     *     @param _hasFallbackToggled if true, fallback is toggled on.
     */
    function _createSettlement(
        uint32 _settlementNonce,
        address payable _refundee,
        address _recipient,
        uint16 _dstChainId,
        bytes memory _params,
        address _globalAddress,
        uint256 _amount,
        uint256 _deposit,
        bool _hasFallbackToggled
    ) internal returns (bytes memory _payload) {
        // Update Settlement Nonce
        settlementNonce = _settlementNonce + 1;

        // Get Local Branch Token Address from Root Port
        address localAddress = IPort(localPortAddress).getLocalTokenFromGlobal(_globalAddress, _dstChainId);

        // Get Underlying Token Address from Root Port
        address underlyingAddress = IPort(localPortAddress).getUnderlyingTokenFromLocal(localAddress, _dstChainId);

        //Update State to reflect bridgeOut
        _updateStateOnBridgeOut(
            msg.sender, _globalAddress, localAddress, underlyingAddress, _amount, _deposit, _dstChainId
        );

        // Prepare data for call
        _payload = abi.encodePacked(
            _hasFallbackToggled ? bytes1(0x81) : bytes1(0x01),
            _recipient,
            _settlementNonce,
            localAddress,
            underlyingAddress,
            _amount,
            _deposit,
            _params
        );

        // Avoid stack too deep
        uint32 cachedSettlementNonce = _settlementNonce;

        // Get Auxiliary Dynamic Arrays
        address[] memory addressArray = new address[](1);
        uint256[] memory uintArray = new uint256[](1);

        // Get storage reference for new Settlement
        Settlement storage settlement = getSettlement[cachedSettlementNonce];

        // Update Setttlement
        settlement.owner = _refundee;
        settlement.recipient = _recipient;

        addressArray[0] = localAddress;
        settlement.hTokens = addressArray;

        addressArray[0] = underlyingAddress;
        settlement.tokens = addressArray;

        uintArray[0] = _amount;
        settlement.amounts = uintArray;

        uintArray[0] = _deposit;
        settlement.deposits = uintArray;

        settlement.dstChainId = _dstChainId;
        settlement.status = STATUS_SUCCESS;
    }

    /**
     * @notice Function to settle multiple assets and perform a remote call to a branch chain.
     *     @param _settlementNonce Identifier for token settlement.
     *     @param _refundee address of token owner and gas refundee.
     *     @param _recipient destination chain token receiver address.
     *     @param _dstChainId branch chain to bridge to.
     *     @param _globalAddresses addresses of the global tokens in root chain.
     *     @param _amounts amounts of hTokens to be bridged out.
     *     @param _deposits amounts of underlying tokens to be cleared from branch port.
     *     @param _params params for branch bridge agent and router execution.
     *     @param _hasFallbackToggled if true, fallback is toggled on.
     */
    function _createSettlementMultiple(
        uint32 _settlementNonce,
        address payable _refundee,
        address _recipient,
        uint16 _dstChainId,
        address[] memory _globalAddresses,
        uint256[] memory _amounts,
        uint256[] memory _deposits,
        bytes memory _params,
        bool _hasFallbackToggled
    ) internal returns (bytes memory _payload) {
        // Check if valid length
        if (_globalAddresses.length > MAX_TOKENS_LENGTH) revert InvalidInputParamsLength();

        // Check if valid length
        if (_globalAddresses.length != _amounts.length) revert InvalidInputParamsLength();
        if (_amounts.length != _deposits.length) revert InvalidInputParamsLength();

        //Update Settlement Nonce
        settlementNonce = _settlementNonce + 1;

        // Create Arrays
        address[] memory hTokens = new address[](_globalAddresses.length);
        address[] memory tokens = new address[](_globalAddresses.length);

        for (uint256 i = 0; i < hTokens.length;) {
            // Populate Addresses for Settlement
            hTokens[i] = IPort(localPortAddress).getLocalTokenFromGlobal(_globalAddresses[i], _dstChainId);
            tokens[i] = IPort(localPortAddress).getUnderlyingTokenFromLocal(hTokens[i], _dstChainId);

            // Avoid stack too deep
            uint16 destChainId = _dstChainId;

            // Update State to reflect bridgeOut
            _updateStateOnBridgeOut(
                msg.sender, _globalAddresses[i], hTokens[i], tokens[i], _amounts[i], _deposits[i], destChainId
            );

            unchecked {
                ++i;
            }
        }

        // Prepare data for call with settlement of multiple assets
        _payload = abi.encodePacked(
            _hasFallbackToggled ? bytes1(0x02) & 0x0F : bytes1(0x02),
            _recipient,
            uint8(hTokens.length),
            _settlementNonce,
            hTokens,
            tokens,
            _amounts,
            _deposits,
            _params
        );

        // Create and Save Settlement
        // Get storage reference
        Settlement storage settlement = getSettlement[_settlementNonce];

        // Update Setttlement
        settlement.owner = _refundee;
        settlement.recipient = _recipient;
        settlement.hTokens = hTokens;
        settlement.tokens = tokens;
        settlement.amounts = _amounts;
        settlement.deposits = _deposits;
        settlement.dstChainId = _dstChainId;
        settlement.status = STATUS_SUCCESS;
    }

    /*///////////////////////////////////////////////////////////////
                    TOKEN MANAGEMENT INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Updates the token balance state by moving assets from root omnichain environment to branch chain,
     *         when a user wants to bridge out tokens from the root bridge agent chain.
     *     @param _depositor address of the token depositor.
     *     @param _globalAddress address of the global token.
     *     @param _localAddress address of the local token.
     *     @param _underlyingAddress address of the underlying token.
     *     @param _amount amount of hTokens to be bridged out.
     *     @param _deposit amount of underlying tokens to be bridged out.
     *     @param _dstChainId chain to bridge to.
     */
    function _updateStateOnBridgeOut(
        address _depositor,
        address _globalAddress,
        address _localAddress,
        address _underlyingAddress,
        uint256 _amount,
        uint256 _deposit,
        uint16 _dstChainId
    ) internal {
        // Check if valid inputs
        if (_amount == 0 && _deposit == 0) revert InvalidInputParams();
        if (_amount < _deposit) revert InvalidInputParams();

        // Check if valid assets
        if (_localAddress == address(0)) revert UnrecognizedLocalAddress();
        if (_underlyingAddress == address(0)) if (_deposit > 0) revert UnrecognizedUnderlyingAddress();

        // Move output hTokens from Root to Branch
        if (_amount - _deposit > 0) {
            unchecked {
                _globalAddress.safeTransferFrom(_depositor, localPortAddress, _amount - _deposit);
            }
        }

        // Clear Underlying Tokens from the destination Branch
        if (_deposit > 0) {
            // Verify there is enough balance to clear native tokens if needed
            if (IERC20hTokenRoot(_globalAddress).getTokenBalance(_dstChainId) < _deposit) {
                revert InsufficientBalanceForSettlement();
            }
            IPort(localPortAddress).burn(_depositor, _globalAddress, _deposit, _dstChainId);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootBridgeAgent
    function approveBranchBridgeAgent(uint256 _branchChainId) external override requiresManager {
        if (getBranchBridgeAgent[_branchChainId] != address(0)) revert AlreadyAddedBridgeAgent();
        isBranchBridgeAgentAllowed[_branchChainId] = true;
    }

    /// @inheritdoc IRootBridgeAgent
    function syncBranchBridgeAgent(address _newBranchBridgeAgent, uint256 _branchChainId)
        external
        override
        requiresPort
    {
        getBranchBridgeAgent[_branchChainId] = _newBranchBridgeAgent;
        getBranchBridgeAgentPath[_branchChainId] = abi.encodePacked(_newBranchBridgeAgent, address(this));
    }

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Modifier for a simple re-entrancy check.
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    /// @notice Internal function to verify msg sender is Bridge Agent's Router.
    modifier requiresRouter() {
        if (msg.sender != localRouterAddress) revert UnrecognizedRouter();
        _;
    }

    /// @notice Modifier verifies the caller is the Layerzero Enpoint or Local Branch Bridge Agent.
    modifier requiresEndpoint(address _endpoint, uint16 _srcChain, bytes calldata _srcAddress) virtual {
        if (msg.sender != address(this)) revert LayerZeroUnauthorizedEndpoint();

        if (_endpoint != getBranchBridgeAgent[localChainId]) {
            if (_endpoint != lzEndpointAddress) revert LayerZeroUnauthorizedEndpoint();

            if (_srcAddress.length != 40) revert LayerZeroUnauthorizedCaller();

            if (getBranchBridgeAgent[_srcChain] != address(uint160(bytes20(_srcAddress[PARAMS_ADDRESS_SIZE:])))) {
                revert LayerZeroUnauthorizedCaller();
            }
        }
        _;
    }

    /// @notice Modifier that verifies msg sender is Bridge Agent Executor.
    modifier requiresAgentExecutor() {
        if (msg.sender != bridgeAgentExecutorAddress) revert UnrecognizedExecutor();
        _;
    }

    /// @notice Modifier that verifies msg sender is the Local Port.
    modifier requiresPort() {
        if (msg.sender != localPortAddress) revert UnrecognizedPort();
        _;
    }

    /// @notice Modifier that verifies msg sender is the Bridge Agent's Manager.
    modifier requiresManager() {
        if (msg.sender != IPort(localPortAddress).getBridgeAgentManager(address(this))) {
            revert UnrecognizedBridgeAgentManager();
        }
        _;
    }
}
