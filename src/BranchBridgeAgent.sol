// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ExcessivelySafeCall} from "lib/ExcessivelySafeCall.sol";

import {IBranchPort as IPort} from "./interfaces/IBranchPort.sol";

import {BridgeAgentConstants} from "./interfaces/BridgeAgentConstants.sol";
import {
    Deposit,
    DepositInput,
    DepositMultipleInput,
    GasParams,
    IBranchBridgeAgent,
    ILayerZeroReceiver,
    SettlementMultipleParams
} from "./interfaces/IBranchBridgeAgent.sol";
import {ILayerZeroEndpoint} from "./interfaces/ILayerZeroEndpoint.sol";

import {BranchBridgeAgentExecutor, DeployBranchBridgeAgentExecutor} from "./BranchBridgeAgentExecutor.sol";

/// @title Library for Branch Bridge Agent Deployment
library DeployBranchBridgeAgent {
    function deploy(
        uint16 _rootChainId,
        uint16 _localChainId,
        address _rootBridgeAgentAddress,
        address _lzEndpointAddress,
        address _localRouterAddress,
        address _localPortAddress
    ) external returns (BranchBridgeAgent) {
        return new BranchBridgeAgent(
            _rootChainId,
            _localChainId,
            _rootBridgeAgentAddress,
            _lzEndpointAddress,
            _localRouterAddress,
            _localPortAddress
        );
    }
}

/// @title Branch Bridge Agent Contract
/// @author MaiaDAO
contract BranchBridgeAgent is IBranchBridgeAgent, BridgeAgentConstants {
    using ExcessivelySafeCall for address;

    /*///////////////////////////////////////////////////////////////
                         BRIDGE AGENT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Chain Id for Root Chain where liquidity is virtualized(e.g. 4).
    uint16 public immutable rootChainId;

    /// @notice Chain Id for Local Chain.
    uint16 public immutable localChainId;

    /// @notice Address for Bridge Agent who processes requests submitted for the Root Router Address
    ///         where cross-chain requests are executed in the Root Chain.
    address public immutable rootBridgeAgentAddress;

    /// @notice Layer Zero messaging layer path for Root Bridge Agent Address where cross-chain requests
    ///         are sent to the Root Chain Router.
    bytes private rootBridgeAgentPath;

    /// @notice Local Layerzero Endpoint Address where cross-chain requests are sent to the Root Chain Router.
    address public immutable lzEndpointAddress;

    /// @notice Address for Local Router used for custom actions for different hApps.
    address public immutable localRouterAddress;

    /// @notice Address for Local Port Address
    ///         where funds deposited from this chain are kept, managed and supplied to different Port Strategies.
    address public immutable localPortAddress;

    /// @notice Address for Bridge Agent Executor used for executing cross-chain requests.
    address public immutable bridgeAgentExecutorAddress;

    /*///////////////////////////////////////////////////////////////
                            DEPOSITS STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit nonce used for identifying the transaction.
    uint32 public depositNonce;

    /// @notice Mapping from Pending deposits hash to Deposit Struct.
    mapping(uint256 depositNonce => Deposit depositInfo) public getDeposit;

    /*///////////////////////////////////////////////////////////////
                        SETTLEMENT EXECUTION STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice If true, the bridge agent has already served a request with this nonce from a given chain.
    mapping(uint256 settlementNonce => uint256 state) public executionState;

    /*///////////////////////////////////////////////////////////////
                           REENTRANCY STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Re-entrancy lock modifier state.
    uint256 internal _unlocked = 1;

    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Branch Bridge Agent.
     * @param _rootChainId Chain Id for Root Chain where liquidity is virtualized and assets are managed.
     * @param _localChainId Chain Id for Local Chain.
     * @param _rootBridgeAgentAddress Address for Bridge Agent who processes requests sent to and from the Root Chain.
     * @param _lzEndpointAddress Local Layerzero Endpoint Address where cross-chain requests are sent to the Root Chain Router.
     * @param _localRouterAddress Address for Local Router used for custom actions for different Omnichain dApps.
     * @param _localPortAddress Address for Local Port Address where funds deposited from this chain are kept, managed
     *                          and supplied to different Port Strategies.
     */
    constructor(
        uint16 _rootChainId,
        uint16 _localChainId,
        address _rootBridgeAgentAddress,
        address _lzEndpointAddress,
        address _localRouterAddress,
        address _localPortAddress
    ) {
        require(_rootBridgeAgentAddress != address(0), "Root Bridge Agent Address cannot be the zero address.");
        require(
            _lzEndpointAddress != address(0) || _rootChainId == _localChainId,
            "Layerzero Endpoint Address cannot be the zero address."
        );
        require(_localRouterAddress != address(0), "Local Router Address cannot be the zero address.");
        require(_localPortAddress != address(0), "Local Port Address cannot be the zero address.");

        localChainId = _localChainId;
        rootChainId = _rootChainId;
        rootBridgeAgentAddress = _rootBridgeAgentAddress;
        lzEndpointAddress = _lzEndpointAddress;
        localRouterAddress = _localRouterAddress;
        localPortAddress = _localPortAddress;
        bridgeAgentExecutorAddress = DeployBranchBridgeAgentExecutor.deploy();
        depositNonce = 1;

        rootBridgeAgentPath = abi.encodePacked(_rootBridgeAgentAddress, address(this));
    }

    /*///////////////////////////////////////////////////////////////
                        FALLBACK FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}

    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchBridgeAgent
    function getDepositEntry(uint32 _depositNonce) external view override returns (Deposit memory) {
        return getDeposit[_depositNonce];
    }

    /// @inheritdoc IBranchBridgeAgent
    function getFeeEstimate(uint256 _gasLimit, uint256 _remoteBranchExecutionGas, bytes calldata _payload)
        external
        view
        returns (uint256 _fee)
    {
        (_fee,) = ILayerZeroEndpoint(lzEndpointAddress).estimateFees(
            rootChainId,
            address(this),
            _payload,
            false,
            abi.encodePacked(uint16(2), _gasLimit, _remoteBranchExecutionGas, rootBridgeAgentAddress)
        );
    }

    /*///////////////////////////////////////////////////////////////
                    USER / BRANCH ROUTER EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchBridgeAgent
    function callOutSystem(address payable _refundee, bytes calldata _params, GasParams calldata _gParams)
        external
        payable
        override
        lock
        requiresRouter
    {
        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(bytes1(0x00), depositNonce++, _params);

        //Perform Call
        _performCall(_refundee, payload, _gParams);
    }

    /// @inheritdoc IBranchBridgeAgent
    function callOut(address payable _refundee, bytes calldata _params, GasParams calldata _gParams)
        external
        payable
        override
        lock
    {
        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(bytes1(0x01), depositNonce++, _params);

        //Perform Call
        _performCall(_refundee, payload, _gParams);
    }

    /// @inheritdoc IBranchBridgeAgent
    function callOutAndBridge(
        address payable _refundee,
        bytes calldata _params,
        DepositInput memory _dParams,
        GasParams calldata _gParams
    ) external payable override lock {
        //Cache Deposit Nonce
        uint32 _depositNonce = depositNonce;

        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(
            bytes1(0x02), _depositNonce, _dParams.hToken, _dParams.token, _dParams.amount, _dParams.deposit, _params
        );

        //Create Deposit and Send Cross-Chain request
        _createDeposit(_depositNonce, _refundee, _dParams.hToken, _dParams.token, _dParams.amount, _dParams.deposit);

        //Perform Call
        _performCall(_refundee, payload, _gParams);
    }

    /// @inheritdoc IBranchBridgeAgent
    function callOutAndBridgeMultiple(
        address payable _refundee,
        bytes calldata _params,
        DepositMultipleInput memory _dParams,
        GasParams calldata _gParams
    ) external payable override lock {
        //Cache Deposit Nonce
        uint32 _depositNonce = depositNonce;

        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(
            bytes1(0x03),
            uint8(_dParams.hTokens.length),
            _depositNonce,
            _dParams.hTokens,
            _dParams.tokens,
            _dParams.amounts,
            _dParams.deposits,
            _params
        );

        //Create Deposit and Send Cross-Chain request
        _createDepositMultiple(
            _depositNonce, _refundee, _dParams.hTokens, _dParams.tokens, _dParams.amounts, _dParams.deposits
        );

        //Perform Call
        _performCall(_refundee, payload, _gParams);
    }

    /// @inheritdoc IBranchBridgeAgent
    function callOutSigned(address payable _refundee, bytes calldata _params, GasParams calldata _gParams)
        external
        payable
        override
        lock
    {
        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(bytes1(0x04), msg.sender, depositNonce++, _params);

        //Perform Signed Call without deposit
        _performCall(_refundee, payload, _gParams);
    }

    /// @inheritdoc IBranchBridgeAgent
    function callOutSignedAndBridge(
        address payable _refundee,
        bytes calldata _params,
        DepositInput memory _dParams,
        GasParams calldata _gParams,
        bool _hasFallbackToggled
    ) external payable override lock {
        //Cache Deposit Nonce
        uint32 _depositNonce = depositNonce;

        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(
            _hasFallbackToggled ? bytes1(0x85) : bytes1(0x05),
            msg.sender,
            _depositNonce,
            _dParams.hToken,
            _dParams.token,
            _dParams.amount,
            _dParams.deposit,
            _params
        );

        //Create Deposit and Send Cross-Chain request
        _createDeposit(_depositNonce, _refundee, _dParams.hToken, _dParams.token, _dParams.amount, _dParams.deposit);

        //Perform Call
        _performCall(_refundee, payload, _gParams);
    }

    /// @inheritdoc IBranchBridgeAgent
    function callOutSignedAndBridgeMultiple(
        address payable _refundee,
        bytes calldata _params,
        DepositMultipleInput memory _dParams,
        GasParams calldata _gParams,
        bool _hasFallbackToggled
    ) external payable override lock {
        // Cache Deposit Nonce
        uint32 _depositNonce = depositNonce;

        // Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(
            _hasFallbackToggled ? bytes1(0x86) : bytes1(0x06),
            msg.sender,
            uint8(_dParams.hTokens.length),
            _depositNonce,
            _dParams.hTokens,
            _dParams.tokens,
            _dParams.amounts,
            _dParams.deposits,
            _params
        );

        // Create a Deposit and Send Cross-Chain request
        _createDepositMultiple(
            _depositNonce, _refundee, _dParams.hTokens, _dParams.tokens, _dParams.amounts, _dParams.deposits
        );

        //Perform Call
        _performCall(_refundee, payload, _gParams);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchBridgeAgent
    function retryDeposit(
        bool _isSigned,
        uint32 _depositNonce,
        bytes calldata _params,
        GasParams calldata _gParams,
        bool _hasFallbackToggled
    ) external payable override lock {
        // Get Settlement Reference
        Deposit storage deposit = getDeposit[_depositNonce];

        //Check if deposit belongs to message sender
        if (deposit.owner != msg.sender) revert NotDepositOwner();

        //Encode Data for cross-chain call.
        bytes memory payload;

        if (uint8(deposit.hTokens.length) == 1) {
            if (_isSigned) {
                //Pack new Data
                payload = abi.encodePacked(
                    _hasFallbackToggled ? bytes1(0x85) : bytes1(0x05),
                    msg.sender,
                    _depositNonce,
                    deposit.hTokens[0],
                    deposit.tokens[0],
                    deposit.amounts[0],
                    deposit.deposits[0],
                    _params
                );
            } else {
                payload = abi.encodePacked(
                    bytes1(0x02),
                    _depositNonce,
                    deposit.hTokens[0],
                    deposit.tokens[0],
                    deposit.amounts[0],
                    deposit.deposits[0],
                    _params
                );
            }
        } else if (uint8(deposit.hTokens.length) > 1) {
            if (_isSigned) {
                //Pack new Data
                payload = abi.encodePacked(
                    _hasFallbackToggled ? bytes1(0x86) : bytes1(0x06),
                    msg.sender,
                    uint8(deposit.hTokens.length),
                    _depositNonce,
                    deposit.hTokens,
                    deposit.tokens,
                    deposit.amounts,
                    deposit.deposits,
                    _params
                );
            } else {
                payload = abi.encodePacked(
                    bytes1(0x03),
                    uint8(deposit.hTokens.length),
                    _depositNonce,
                    deposit.hTokens,
                    deposit.tokens,
                    deposit.amounts,
                    deposit.deposits,
                    _params
                );
            }
        }

        // Check if payload is empty
        if (payload.length == 0) revert DepositRetryUnavailableUseCallout();

        // Ensure success Status
        deposit.status = STATUS_SUCCESS;

        // Perform Call
        _performCall(payable(msg.sender), payload, _gParams);
    }

    /// @inheritdoc IBranchBridgeAgent
    function retrieveDeposit(uint32 _depositNonce, GasParams calldata _gParams) external payable override lock {
        // Check if the deposit belongs to the message sender
        if (getDeposit[_depositNonce].owner != msg.sender) revert NotDepositOwner();

        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(bytes1(0x08), msg.sender, _depositNonce);

        //Update State and Perform Call
        _performCall(payable(msg.sender), payload, _gParams);
    }

    /// @inheritdoc IBranchBridgeAgent
    function redeemDeposit(uint32 _depositNonce) external override lock {
        // Get storage reference
        Deposit storage deposit = getDeposit[_depositNonce];

        // Check Deposit
        if (deposit.status == STATUS_SUCCESS) revert DepositRedeemUnavailable();
        if (deposit.owner == address(0)) revert DepositRedeemUnavailable();
        if (deposit.owner != msg.sender) revert NotDepositOwner();

        // Zero out owner
        deposit.owner = address(0);

        // Transfer token to depositor / user
        for (uint256 i = 0; i < deposit.tokens.length;) {
            _clearToken(msg.sender, deposit.hTokens[i], deposit.tokens[i], deposit.amounts[i], deposit.deposits[i]);

            unchecked {
                ++i;
            }
        }

        // Delete Failed Deposit Token Info
        delete getDeposit[_depositNonce];
    }

    /*///////////////////////////////////////////////////////////////
                    SETTLEMENT EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchBridgeAgent
    function retrySettlement(
        uint32 _settlementNonce,
        bytes calldata _params,
        GasParams[2] calldata _gParams,
        bool _hasFallbackToggled
    ) external payable virtual override lock {
        // Encode Retry Settlement Params
        bytes memory params = abi.encode(_settlementNonce, msg.sender, _params, _gParams[1]);

        // Prepare payload for cross-chain call.
        bytes memory payload = abi.encodePacked(_hasFallbackToggled ? bytes1(0x87) : bytes1(0x07), params);

        // Perform Call
        _performCall(payable(msg.sender), payload, _gParams[0]);
    }

    /*///////////////////////////////////////////////////////////////
                TOKEN MANAGEMENT EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchBridgeAgent
    function clearToken(address _recipient, address _hToken, address _token, uint256 _amount, uint256 _deposit)
        external
        override
        requiresAgentExecutor
    {
        _clearToken(_recipient, _hToken, _token, _amount, _deposit);
    }

    /// @inheritdoc IBranchBridgeAgent
    function clearTokens(bytes calldata _sParams, address _recipient)
        external
        override
        requiresAgentExecutor
        returns (SettlementMultipleParams memory)
    {
        // Parse Tokens Length
        uint8 numOfAssets = uint8(bytes1(_sParams[0]));

        // Parse Nonce
        uint32 nonce = uint32(bytes4(_sParams[PARAMS_START:PARAMS_TKN_START]));

        // Initialize Arrays
        address[] memory _hTokens = new address[](numOfAssets);
        address[] memory _tokens = new address[](numOfAssets);
        uint256[] memory _amounts = new uint256[](numOfAssets);
        uint256[] memory _deposits = new uint256[](numOfAssets);

        // Transfer the token to the recipient
        for (uint256 i = 0; i < numOfAssets;) {
            // Cache common offset
            uint256 currentIterationOffset = PARAMS_START + i;

            // Parse Params
            _hTokens[i] = address(
                uint160(
                    bytes20(
                        bytes32(
                            _sParams[
                                PARAMS_TKN_START + (PARAMS_ENTRY_SIZE * i) + ADDRESS_END_OFFSET:
                                    PARAMS_TKN_START + (PARAMS_ENTRY_SIZE * currentIterationOffset)
                            ]
                        )
                    )
                )
            );

            _tokens[i] = address(
                uint160(
                    bytes20(
                        bytes32(
                            _sParams[
                                PARAMS_TKN_START + PARAMS_ENTRY_SIZE * (i + numOfAssets) + ADDRESS_END_OFFSET:
                                    PARAMS_TKN_START + PARAMS_ENTRY_SIZE * (currentIterationOffset + numOfAssets)
                            ]
                        )
                    )
                )
            );

            _amounts[i] = uint256(
                bytes32(
                    _sParams[
                        PARAMS_TKN_START + PARAMS_AMT_OFFSET * numOfAssets + PARAMS_ENTRY_SIZE * i:
                            PARAMS_TKN_START + PARAMS_AMT_OFFSET * numOfAssets + PARAMS_ENTRY_SIZE * currentIterationOffset
                    ]
                )
            );

            _deposits[i] = uint256(
                bytes32(
                    _sParams[
                        PARAMS_TKN_START + PARAMS_DEPOSIT_OFFSET * numOfAssets + PARAMS_ENTRY_SIZE * i:
                            PARAMS_TKN_START + PARAMS_DEPOSIT_OFFSET * numOfAssets
                                + PARAMS_ENTRY_SIZE * currentIterationOffset
                    ]
                )
            );

            unchecked {
                ++i;
            }
        }

        IPort(localPortAddress).bridgeInMultiple(_recipient, _hTokens, _tokens, _amounts, _deposits);

        return SettlementMultipleParams(numOfAssets, _recipient, nonce, _hTokens, _tokens, _amounts, _deposits);
    }

    /*///////////////////////////////////////////////////////////////
                    LAYER ZERO EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ILayerZeroReceiver
    function lzReceive(uint16, bytes calldata _srcAddress, uint64, bytes calldata _payload) public override {
        address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(this.lzReceiveNonBlocking.selector, msg.sender, _srcAddress, _payload)
        );
    }

    /// @inheritdoc IBranchBridgeAgent
    function lzReceiveNonBlocking(address _endpoint, bytes calldata _srcAddress, bytes calldata _payload)
        public
        override
        requiresEndpoint(_endpoint, _srcAddress)
    {
        //Save Action Flag
        bytes1 flag = _payload[0] & 0x7F;

        // Save settlement nonce
        uint32 nonce;

        // DEPOSIT FLAG: 0 (No settlement)
        if (flag == 0x00) {
            // Get Settlement Nonce
            nonce = uint32(bytes4(_payload[PARAMS_START_SIGNED:PARAMS_TKN_START_SIGNED]));

            //Check if tx has already been executed
            if (executionState[nonce] != STATUS_READY) revert AlreadyExecutedTransaction();

            //Try to execute the remote request
            //Flag 0 - BranchBridgeAgentExecutor(bridgeAgentExecutorAddress).executeNoSettlement(localRouterAddress, _payload)
            _execute(
                nonce,
                abi.encodeWithSelector(
                    BranchBridgeAgentExecutor.executeNoSettlement.selector, localRouterAddress, _payload
                )
            );

            // DEPOSIT FLAG: 1 (Single Asset Settlement)
        } else if (flag == 0x01) {
            // Parse recipient
            address payable recipient = payable(address(uint160(bytes20(_payload[PARAMS_START:PARAMS_START_SIGNED]))));

            // Parse Settlement Nonce
            nonce = uint32(bytes4(_payload[PARAMS_START_SIGNED:PARAMS_TKN_START_SIGNED]));

            //Check if tx has already been executed
            if (executionState[nonce] != STATUS_READY) revert AlreadyExecutedTransaction();

            //Try to execute the remote request
            //Flag 1 - BranchBridgeAgentExecutor(bridgeAgentExecutorAddress).executeWithSettlement(recipient, localRouterAddress, _payload)
            _execute(
                _payload[0] == 0x81,
                nonce,
                recipient,
                abi.encodeWithSelector(
                    BranchBridgeAgentExecutor.executeWithSettlement.selector, recipient, localRouterAddress, _payload
                )
            );

            // DEPOSIT FLAG: 2 (Multiple Settlement)
        } else if (flag == 0x02) {
            // Parse recipient
            address payable recipient = payable(address(uint160(bytes20(_payload[PARAMS_START:PARAMS_START_SIGNED]))));

            // Parse deposit nonce
            nonce = uint32(bytes4(_payload[22:26]));

            //Check if tx has already been executed
            if (executionState[nonce] != STATUS_READY) revert AlreadyExecutedTransaction();

            //Try to execute remote request
            // Flag 2 - BranchBridgeAgentExecutor(bridgeAgentExecutorAddress).executeWithSettlementMultiple(recipient, localRouterAddress, _payload)
            _execute(
                _payload[0] == 0x82,
                nonce,
                recipient,
                abi.encodeWithSelector(
                    BranchBridgeAgentExecutor.executeWithSettlementMultiple.selector,
                    recipient,
                    localRouterAddress,
                    _payload
                )
            );

            //DEPOSIT FLAG: 3 (Retrieve Settlement)
        } else if (flag == 0x03) {
            // Parse recipient
            address payable recipient = payable(address(uint160(bytes20(_payload[PARAMS_START:PARAMS_START_SIGNED]))));

            //Get nonce
            nonce = uint32(bytes4(_payload[PARAMS_START_SIGNED:PARAMS_TKN_START_SIGNED]));

            //Check if settlement is in retrieve mode
            if (executionState[nonce] == STATUS_DONE) {
                revert AlreadyExecutedTransaction();
            } else {
                //Set settlement to retrieve mode, if not already set.
                if (executionState[nonce] == STATUS_READY) executionState[nonce] = STATUS_RETRIEVE;
                //Trigger fallback/Retry failed fallback
                _performFallbackCall(recipient, nonce);
            }

            //DEPOSIT FLAG: 4 (Fallback)
        } else if (flag == 0x04) {
            //Get nonce
            nonce = uint32(bytes4(_payload[PARAMS_START:PARAMS_TKN_START]));

            // Reopen Deposit for redemption
            getDeposit[nonce].status = STATUS_FAILED;

            // Emit Fallback Event
            emit LogFallback(nonce);

            // Return to prevent unnecessary logic/emits
            return;

            //Unrecognized Function Selector
        } else {
            revert UnknownFlag();
        }

        // Emit Execution Event
        emit LogExecute(nonce);
    }

    /*///////////////////////////////////////////////////////////////
                    SETTLEMENT EXECUTION INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function requests execution from Branch Bridge Agent Executor Contract.
     *   @param _settlementNonce Identifier for nonce being executed.
     *   @param _calldata Calldata to be executed by the Branch Bridge Agent Executor Contract.
     */
    function _execute(uint256 _settlementNonce, bytes memory _calldata) private {
        //Update tx state as executed
        executionState[_settlementNonce] = STATUS_DONE;

        //Try to execute the remote request
        (bool success,) = bridgeAgentExecutorAddress.call{value: address(this).balance}(_calldata);

        //  No fallback is requested revert allowing for settlement retry.
        if (!success) revert ExecutionFailure();
    }

    /**
     * @notice Internal function requests execution from Branch Bridge Agent Executor Contract.
     *   @param _hasFallbackToggled if true, fallback on execution failure is toggled on.
     *   @param _settlementNonce Identifier for nonce being executed.
     *   @param _refundee address to refund gas to in case of fallback being triggered.
     *   @param _calldata Calldata to be executed by the Branch Bridge Agent Executor Contract.
     */
    function _execute(bool _hasFallbackToggled, uint32 _settlementNonce, address _refundee, bytes memory _calldata)
        private
    {
        //Update tx state as executed
        executionState[_settlementNonce] = STATUS_DONE;

        //Try to execute the remote request
        (bool success,) = bridgeAgentExecutorAddress.call{value: address(this).balance}(_calldata);

        //Update tx state if execution failed
        if (!success) {
            //Read the fallback flag and perform the fallback call if necessary. If not, allow for retrying deposit.
            if (_hasFallbackToggled) {
                // Update tx state as retrieve only
                executionState[_settlementNonce] = STATUS_RETRIEVE;

                // Perform fallback call
                _performFallbackCall(payable(_refundee), _settlementNonce);
            } else {
                // If no fallback is requested revert allowing for settlement retry.
                revert ExecutionFailure();
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                    LAYER ZERO INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function performs the call to LayerZero messaging layer Endpoint for cross-chain messaging.
     *   @param _refundee address to refund excess gas to.
     *   @param _payload params for root bridge agent execution.
     *   @param _gParams LayerZero gas information. (_gasLimit,_remoteBranchExecutionGas,_nativeTokenRecipientOnDstChain)
     */
    function _performCall(address payable _refundee, bytes memory _payload, GasParams calldata _gParams)
        internal
        virtual
    {
        //Sends message to LayerZero messaging layer
        ILayerZeroEndpoint(lzEndpointAddress).send{value: msg.value}(
            rootChainId,
            rootBridgeAgentPath,
            _payload,
            payable(_refundee),
            address(0),
            abi.encodePacked(uint16(2), _gParams.gasLimit, _gParams.remoteBranchExecutionGas, rootBridgeAgentAddress)
        );
    }

    /**
     * @notice Internal function performs the call to Layerzero Endpoint Contract for cross-chain messaging.
     *   @param _refundee address to refund gas to.
     *   @param _settlementNonce root settlement nonce to fallback.
     */
    function _performFallbackCall(address payable _refundee, uint32 _settlementNonce) internal virtual {
        //Sends message to LayerZero messaging layer
        ILayerZeroEndpoint(lzEndpointAddress).send{value: address(this).balance}(
            rootChainId,
            rootBridgeAgentPath,
            abi.encodePacked(bytes1(0x09), _settlementNonce),
            _refundee,
            address(0),
            ""
        );
    }

    /*///////////////////////////////////////////////////////////////
                LOCAL USER DEPOSIT INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to move assets from branch chain to root omnichain environment.
     *         Naive assets are deposited and hTokens are bridgedOut.
     *   @param _depositNonce Identifier for user deposit.
     *   @param _refundee address to return excess gas deposited in `msg.value` to.
     *   @param _hToken Local Input hToken Address.
     *   @param _token Native/Underlying Token Address.
     *   @param _amount Amount of Local hTokens deposited for trade.
     *   @param _deposit Amount of native tokens deposited for trade.
     *
     */
    function _createDeposit(
        uint32 _depositNonce,
        address payable _refundee,
        address _hToken,
        address _token,
        uint256 _amount,
        uint256 _deposit
    ) internal {
        // Update Deposit Nonce
        depositNonce = _depositNonce + 1;

        // Deposit / Lock Tokens into Port
        IPort(localPortAddress).bridgeOut(msg.sender, _hToken, _token, _amount, _deposit);

        // Cast to Dynamic
        address[] memory addressArray = new address[](1);
        uint256[] memory uintArray = new uint256[](1);

        // Save deposit to storage
        Deposit storage deposit = getDeposit[_depositNonce];
        deposit.owner = _refundee;

        addressArray[0] = _hToken;
        deposit.hTokens = addressArray;

        addressArray[0] = _token;
        deposit.tokens = addressArray;

        uintArray[0] = _amount;
        deposit.amounts = uintArray;

        uintArray[0] = _deposit;
        deposit.deposits = uintArray;

        deposit.status = STATUS_SUCCESS;
    }

    /**
     * @dev Internal function to move assets from branch chain to root omnichain environment.
     *      Naive assets are deposited and hTokens are bridgedOut.
     *   @param _depositNonce Identifier for user deposit.
     *   @param _refundee address to return excess gas deposited in `msg.value` to.
     *   @param _hTokens Local Input hToken Address.
     *   @param _tokens Native/Underlying Token Address.
     *   @param _amounts Amount of Local hTokens deposited for trade.
     *   @param _deposits  Amount of native tokens deposited for trade.
     *
     */
    function _createDepositMultiple(
        uint32 _depositNonce,
        address payable _refundee,
        address[] memory _hTokens,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _deposits
    ) internal {
        // Validate Input
        if (_hTokens.length > MAX_TOKENS_LENGTH) revert InvalidInput();
        if (_hTokens.length != _tokens.length) revert InvalidInput();
        if (_tokens.length != _amounts.length) revert InvalidInput();
        if (_amounts.length != _deposits.length) revert InvalidInput();

        // Update Deposit Nonce
        depositNonce = _depositNonce + 1;

        // Deposit / Lock Tokens into Port
        IPort(localPortAddress).bridgeOutMultiple(msg.sender, _hTokens, _tokens, _amounts, _deposits);

        // Update State
        Deposit storage deposit = getDeposit[_depositNonce];
        deposit.owner = _refundee;
        deposit.hTokens = _hTokens;
        deposit.tokens = _tokens;
        deposit.amounts = _amounts;
        deposit.deposits = _deposits;
        deposit.status = STATUS_SUCCESS;
    }

    /*///////////////////////////////////////////////////////////////
                REMOTE USER DEPOSIT INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to request balance clearance from a Port to a given user.
     *     @param _recipient token receiver.
     *     @param _hToken  local hToken address to clear balance for.
     *     @param _token  native/underlying token address to clear balance for.
     *     @param _amount amounts of hToken to clear balance for.
     *     @param _deposit amount of native/underlying tokens to clear balance for.
     *
     */
    function _clearToken(address _recipient, address _hToken, address _token, uint256 _amount, uint256 _deposit)
        internal
    {
        if (_amount - _deposit > 0) {
            unchecked {
                IPort(localPortAddress).bridgeIn(_recipient, _hToken, _amount - _deposit);
            }
        }

        if (_deposit > 0) {
            IPort(localPortAddress).withdraw(_recipient, _token, _deposit);
        }
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

    /// @notice Modifier verifies the caller is the Layerzero Enpoint or Local Branch Bridge Agent.
    modifier requiresEndpoint(address _endpoint, bytes calldata _srcAddress) {
        _requiresEndpoint(_endpoint, _srcAddress);
        _;
    }

    /// @notice Internal function for caller verification. To be overwritten in `ArbitrumBranchBridgeAgent'.
    function _requiresEndpoint(address _endpoint, bytes calldata _srcAddress) internal view virtual {
        //Verify Endpoint
        if (msg.sender != address(this)) revert LayerZeroUnauthorizedEndpoint();
        if (_endpoint != lzEndpointAddress) revert LayerZeroUnauthorizedEndpoint();

        //Verify Remote Caller
        if (_srcAddress.length != 40) revert LayerZeroUnauthorizedCaller();
        if (rootBridgeAgentAddress != address(uint160(bytes20(_srcAddress[20:])))) revert LayerZeroUnauthorizedCaller();
    }

    /// @notice Modifier that verifies caller is Branch Bridge Agent's Router.
    modifier requiresRouter() {
        if (msg.sender != localRouterAddress) revert UnrecognizedRouter();
        _;
    }

    /// @notice Modifier that verifies caller is the Bridge Agent Executor.
    modifier requiresAgentExecutor() {
        if (msg.sender != bridgeAgentExecutorAddress) revert UnrecognizedBridgeAgentExecutor();
        _;
    }
}
