// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IERC20hTokenRootFactory as IFactory} from "./interfaces/IERC20hTokenRootFactory.sol";
import {IRootRouter} from "./interfaces/IRootRouter.sol";
import {
    DepositParams,
    DepositMultipleParams,
    GasParams,
    IRootBridgeAgent as IBridgeAgent
} from "./interfaces/IRootBridgeAgent.sol";
import {IRootPort as IPort} from "./interfaces/IRootPort.sol";

/**
 * 2
 * @title  Core Root Router Contract
 * @author MaiaDAO
 * @notice Core Root Router implementation for Root Environment deployment.
 *         This contract is responsible for permissionlessly adding new
 *         tokens or Bridge Agents to the system as well as key governance
 *         enabled system functions (i.e. `toggleBranchBridgeAgentFactory`).
 * @dev    Func IDs for calling these functions through messaging layer:
 *
 *         CROSS-CHAIN MESSAGING FUNCIDs
 *         -----------------------------
 *         FUNC ID      | FUNC NAME
 *         -------------+---------------
 *         0x01         | addGlobalToken
 *         0x02         | addLocalToken
 *         0x03         | setLocalToken
 *         0x04         | syncBranchBridgeAgent
 *
 */
contract CoreRootRouter is IRootRouter, Ownable {
    /*///////////////////////////////////////////////////////////////
                    CORE ROOT ROUTER STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Boolean to indicate if the contract is in set up mode.
    bool internal _setup;

    /// @notice Root Chain Layer Zero Identifier.
    uint256 public immutable rootChainId;

    /// @notice Address for Local Port Address where funds deposited from this chain are kept
    ///         managed and supplied to different Port Strategies.
    address public immutable rootPortAddress;

    /// @notice Bridge Agent to manage remote execution and cross-chain assets.
    address payable public bridgeAgentAddress;

    /// @notice Bridge Agent Executor Address.
    address public bridgeAgentExecutorAddress;

    /// @notice ERC20 hToken Root Factory Address.
    address public hTokenFactoryAddress;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Core Root Router.
     * @param _rootChainId layer zero root chain id.
     * @param _rootPortAddress address of the Root Port.
     */
    constructor(uint256 _rootChainId, address _rootPortAddress) {
        rootChainId = _rootChainId;
        rootPortAddress = _rootPortAddress;

        _initializeOwner(msg.sender);
        _setup = true;
    }

    /*///////////////////////////////////////////////////////////////
                    INITIALIZATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize(address _bridgeAgentAddress, address _hTokenFactory) external onlyOwner {
        require(_setup, "Contract is already initialized");
        _setup = false;
        bridgeAgentAddress = payable(_bridgeAgentAddress);
        bridgeAgentExecutorAddress = IBridgeAgent(_bridgeAgentAddress).bridgeAgentExecutorAddress();
        hTokenFactoryAddress = _hTokenFactory;
    }

    /*///////////////////////////////////////////////////////////////
                    BRIDGE AGENT MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Add a new Chain (Branch Bridge Agent and respective Router) to a Root Bridge Agent.
     * @param _branchBridgeAgentFactory Address of the branch Bridge Agent Factory.
     * @param _newBranchRouter Address of the new branch router.
     * @param _refundee Address of the excess gas receiver.
     * @param _dstChainId Chain Id of the branch chain where the new Bridge Agent will be deployed.
     * @param _gParams Gas parameters for remote execution.
     */
    function addBranchToBridgeAgent(
        address _rootBridgeAgent,
        address _branchBridgeAgentFactory,
        address _newBranchRouter,
        address _refundee,
        uint16 _dstChainId,
        GasParams[2] calldata _gParams
    ) external payable {
        // Check if msg.sender is the Bridge Agent Manager
        if (msg.sender != IPort(rootPortAddress).getBridgeAgentManager(_rootBridgeAgent)) {
            revert UnauthorizedCallerNotManager();
        }

        // Check if valid chain
        if (!IPort(rootPortAddress).isChainId(_dstChainId)) revert InvalidChainId();

        // Check if chain already added to bridge agent
        if (IBridgeAgent(_rootBridgeAgent).getBranchBridgeAgent(_dstChainId) != address(0)) revert InvalidChainId();

        // Check if Branch Bridge Agent is allowed by Root Bridge Agent
        if (!IBridgeAgent(_rootBridgeAgent).isBranchBridgeAgentAllowed(_dstChainId)) revert UnauthorizedChainId();

        // Encode CallData
        bytes memory params = abi.encode(
            _newBranchRouter,
            _branchBridgeAgentFactory,
            _rootBridgeAgent,
            IBridgeAgent(_rootBridgeAgent).factoryAddress(),
            _refundee,
            _gParams[1]
        );

        // Pack funcId into data
        bytes memory payload = abi.encodePacked(bytes1(0x02), params);

        //Add new global token to branch chain
        IBridgeAgent(bridgeAgentAddress).callOut{value: msg.value}(
            payable(_refundee), _refundee, _dstChainId, payload, _gParams[0]
        );
    }

    /*///////////////////////////////////////////////////////////////
                GOVERNANCE / ADMIN EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Add or Remove a Branch Bridge Agent Factory.
     * @param _rootBridgeAgentFactory Address of the root Bridge Agent Factory.
     * @param _branchBridgeAgentFactory Address of the branch Bridge Agent Factory.
     * @param _refundee Receiver of any leftover execution gas upon reaching the destination network.
     * @param _dstChainId Chain Id of the branch chain where the new Bridge Agent will be deployed.
     * @param _gParams Gas parameters for remote execution.
     */
    function toggleBranchBridgeAgentFactory(
        address _rootBridgeAgentFactory,
        address _branchBridgeAgentFactory,
        address _refundee,
        uint16 _dstChainId,
        GasParams calldata _gParams
    ) external payable onlyOwner {
        if (!IPort(rootPortAddress).isBridgeAgentFactory(_rootBridgeAgentFactory)) {
            revert UnrecognizedBridgeAgentFactory();
        }

        // Encode CallData
        bytes memory params = abi.encode(_branchBridgeAgentFactory);

        // Pack funcId into data
        bytes memory payload = abi.encodePacked(bytes1(0x03), params);

        //Add new global token to branch chain
        IBridgeAgent(bridgeAgentAddress).callOut{value: msg.value}(
            payable(_refundee), _refundee, _dstChainId, payload, _gParams
        );
    }

    /**
     * @notice Remove a Branch Bridge Agent.
     * @param _branchBridgeAgent Address of the Branch Bridge Agent to be updated.
     * @param _refundee Receiver of any leftover execution gas upon reaching destination network.
     * @param _dstChainId Chain Id of the branch chain where the new Bridge Agent will be deployed.
     * @param _gParams Gas parameters for remote execution.
     */
    function removeBranchBridgeAgent(
        address _branchBridgeAgent,
        address _refundee,
        uint16 _dstChainId,
        GasParams calldata _gParams
    ) external payable onlyOwner {
        //Encode CallData
        bytes memory params = abi.encode(_branchBridgeAgent);

        // Pack funcId into data
        bytes memory payload = abi.encodePacked(bytes1(0x04), params);

        //Add new global token to branch chain
        IBridgeAgent(bridgeAgentAddress).callOut{value: msg.value}(
            payable(_refundee), _refundee, _dstChainId, payload, _gParams
        );
    }

    /**
     * @notice Add or Remove a Strategy Token.
     * @param _underlyingToken Address of the underlying token to be added for use in Branch strategies.
     * @param _minimumReservesRatio Minimum Branch Port reserves ratio for the underlying token.
     * @param _refundee Receiver of any leftover execution gas upon reaching destination network.
     * @param _dstChainId Chain Id of the branch chain where the new Bridge Agent will be deployed.
     * @param _gParams Gas parameters for remote execution.
     */
    function manageStrategyToken(
        address _underlyingToken,
        uint256 _minimumReservesRatio,
        address _refundee,
        uint16 _dstChainId,
        GasParams calldata _gParams
    ) external payable onlyOwner {
        // Encode CallData
        bytes memory params = abi.encode(_underlyingToken, _minimumReservesRatio);

        // Pack funcId into data
        bytes memory payload = abi.encodePacked(bytes1(0x05), params);

        //Add new global token to branch chain
        IBridgeAgent(bridgeAgentAddress).callOut{value: msg.value}(
            payable(_refundee), _refundee, _dstChainId, payload, _gParams
        );
    }

    /**
     * @notice Add, Remove or update a Port Strategy.
     * @param _portStrategy Address of the Port Strategy to be added for use in Branch strategies.
     * @param _underlyingToken Address of the underlying token to be added for use in Branch strategies.
     * @param _dailyManagementLimit Daily management limit of the given token for the Port Strategy.
     * @param _isUpdateDailyLimit Boolean to safely indicate if the Port Strategy is being updated and not deactivated.
     * @param _refundee Receiver of any leftover execution gas upon reaching destination network.
     * @param _dstChainId Chain Id of the branch chain where the new Bridge Agent will be deployed.
     * @param _gParams Gas parameters for remote execution.
     */
    function managePortStrategy(
        address _portStrategy,
        address _underlyingToken,
        uint256 _dailyManagementLimit,
        bool _isUpdateDailyLimit,
        address _refundee,
        uint16 _dstChainId,
        GasParams calldata _gParams
    ) external payable onlyOwner {
        // Encode CallData
        bytes memory params = abi.encode(_portStrategy, _underlyingToken, _dailyManagementLimit, _isUpdateDailyLimit);

        // Pack funcId into data
        bytes memory payload = abi.encodePacked(bytes1(0x06), params);

        //Add new global token to branch chain
        IBridgeAgent(bridgeAgentAddress).callOut{value: msg.value}(
            payable(_refundee), _refundee, _dstChainId, payload, _gParams
        );
    }

    /**
     * @notice Set the Core Branch Router and Bridge Agent.
     * @param _refundee Receiver of any leftover execution gas upon reaching destination network.
     * @param _coreBranchRouter Address of the Core Branch Router.
     * @param _coreBranchBridgeAgent Address of the Core Branch Bridge Agent.
     * @param _dstChainId Chain Id of the branch chain where the new Bridge Agent will be deployed.
     * @param _gParams Gas parameters for remote execution.
     */
    function setCoreBranch(
        address _refundee,
        address _coreBranchRouter,
        address _coreBranchBridgeAgent,
        uint16 _dstChainId,
        GasParams calldata _gParams
    ) external payable {
        // Check caller is root port
        require(msg.sender == rootPortAddress, "Only root port can call");

        // Encode CallData
        bytes memory params = abi.encode(_coreBranchRouter, _coreBranchBridgeAgent);

        // Pack funcId into data
        bytes memory payload = abi.encodePacked(bytes1(0x07), params);

        //Add new global token to branch chain
        IBridgeAgent(bridgeAgentAddress).callOut{value: msg.value}(
            payable(_refundee), _refundee, _dstChainId, payload, _gParams
        );
    }

    /*///////////////////////////////////////////////////////////////
                        LAYERZERO FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootRouter
    function executeResponse(bytes calldata _encodedData, uint16 _srcChainId)
        external
        payable
        override
        requiresExecutor
    {
        // Parse funcId
        bytes1 funcId = _encodedData[0];

        ///  FUNC ID: 2 (_addLocalToken)
        if (funcId == 0x02) {
            (address underlyingAddress, address localAddress, string memory name, string memory symbol, uint8 decimals)
            = abi.decode(_encodedData[1:], (address, address, string, string, uint8));

            _addLocalToken(underlyingAddress, localAddress, name, symbol, decimals, _srcChainId);

            /// FUNC ID: 3 (_setLocalToken)
        } else if (funcId == 0x03) {
            (address globalAddress, address localAddress) = abi.decode(_encodedData[1:], (address, address));

            _setLocalToken(globalAddress, localAddress, _srcChainId);

            /// FUNC ID: 4 (_syncBranchBridgeAgent)
        } else if (funcId == 0x04) {
            (address newBranchBridgeAgent, address rootBridgeAgent) = abi.decode(_encodedData[1:], (address, address));

            _syncBranchBridgeAgent(newBranchBridgeAgent, rootBridgeAgent, _srcChainId);

            /// Unrecognized Function Selector
        } else {
            revert UnrecognizedFunctionId();
        }
    }

    /// @inheritdoc IRootRouter
    function execute(bytes calldata _encodedData, uint16) external payable override requiresExecutor {
        // Parse funcId
        bytes1 funcId = _encodedData[0];

        /// FUNC ID: 1 (_addGlobalToken)
        if (funcId == 0x01) {
            (address refundee, address globalAddress, uint16 dstChainId, GasParams[2] memory gasParams) =
                abi.decode(_encodedData[1:], (address, address, uint16, GasParams[2]));

            _addGlobalToken(refundee, globalAddress, dstChainId, gasParams);

            /// Unrecognized Function Selector
        } else {
            revert UnrecognizedFunctionId();
        }
    }

    /// @inheritdoc IRootRouter
    function executeDepositSingle(bytes memory, DepositParams memory, uint16)
        external
        payable
        override
        requiresExecutor
    {
        revert();
    }

    /// @inheritdoc IRootRouter
    function executeDepositMultiple(bytes calldata, DepositMultipleParams memory, uint16)
        external
        payable
        override
        requiresExecutor
    {
        revert();
    }

    /// @inheritdoc IRootRouter
    function executeSigned(bytes memory, address, uint16) external payable override requiresExecutor {
        revert();
    }

    /// @inheritdoc IRootRouter
    function executeSignedDepositSingle(bytes memory, DepositParams memory, address, uint16)
        external
        payable
        override
        requiresExecutor
    {
        revert();
    }

    /// @inheritdoc IRootRouter
    function executeSignedDepositMultiple(bytes memory, DepositMultipleParams memory, address, uint16)
        external
        payable
        override
        requiresExecutor
    {
        revert();
    }

    /*///////////////////////////////////////////////////////////////
                    TOKEN MANAGEMENT INTERNAL FUNCTIONS
    ////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to add a global token to a specific chain. Must be called from a branch.
     *   @param _refundee Address of the excess gas receiver.
     *   @param _globalAddress global token to be added.
     *   @param _dstChainId chain to which the Global Token will be added.
     *   @param _gParams Gas parameters for remote execution.
     *
     */
    function _addGlobalToken(
        address _refundee,
        address _globalAddress,
        uint16 _dstChainId,
        GasParams[2] memory _gParams
    ) internal {
        if (_dstChainId == rootChainId) revert InvalidChainId();

        if (!IPort(rootPortAddress).isGlobalAddress(_globalAddress)) {
            revert UnrecognizedGlobalToken();
        }

        // Verify that it does not exist
        if (IPort(rootPortAddress).isGlobalToken(_globalAddress, _dstChainId)) {
            revert TokenAlreadyAdded();
        }

        // Encode CallData
        bytes memory params = abi.encode(
            _globalAddress,
            ERC20(_globalAddress).name(),
            ERC20(_globalAddress).symbol(),
            ERC20(_globalAddress).decimals(),
            _refundee,
            _gParams[1]
        );

        // Pack funcId into data
        bytes memory payload = abi.encodePacked(bytes1(0x01), params);

        //Add new global token to branch chain
        IBridgeAgent(bridgeAgentAddress).callOut{value: msg.value}(
            payable(_refundee), _refundee, _dstChainId, payload, _gParams[0]
        );
    }

    /**
     * @notice Function to add a new local to the global environment. Called from branch chain.
     *   @param _underlyingAddress the token's underlying/native chain address.
     *   @param _localAddress the token's address.
     *   @param _name the token's name.
     *   @param _symbol the token's symbol.
     *   @param _decimals the token's decimals.
     *   @param _srcChainId the token's origin chain Id.
     *
     */
    function _addLocalToken(
        address _underlyingAddress,
        address _localAddress,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint16 _srcChainId
    ) internal {
        // Verify if the underlying address is already known by the branch or root chain
        if (IPort(rootPortAddress).isGlobalAddress(_underlyingAddress)) revert TokenAlreadyAdded();
        if (IPort(rootPortAddress).isLocalToken(_underlyingAddress, _srcChainId)) revert TokenAlreadyAdded();
        if (IPort(rootPortAddress).isUnderlyingToken(_underlyingAddress, _srcChainId)) revert TokenAlreadyAdded();

        //Create a new global token
        address newToken = address(IFactory(hTokenFactoryAddress).createToken(_name, _symbol, _decimals));

        // Update Registry
        IPort(rootPortAddress).setAddresses(
            newToken, (_srcChainId == rootChainId) ? newToken : _localAddress, _underlyingAddress, _srcChainId
        );
    }

    /**
     * @notice Internal function to set the local token on a specific chain for a global token.
     *   @param _globalAddress global token to be updated.
     *   @param _localAddress local token to be added.
     *   @param _dstChainId local token's chain.
     *
     */
    function _setLocalToken(address _globalAddress, address _localAddress, uint16 _dstChainId) internal {
        // Verify if the token already added
        if (IPort(rootPortAddress).isLocalToken(_localAddress, _dstChainId)) revert TokenAlreadyAdded();

        // Set the global token's new branch chain address
        IPort(rootPortAddress).setLocalAddress(_globalAddress, _localAddress, _dstChainId);
    }

    /*///////////////////////////////////////////////////////////////
                BRIDGE AGENT MANAGEMENT INTERNAL FUNCTIONS
    ////////////////////////////////////////////////////////////*/

    /**
     * @dev Internal function sync a Root Bridge Agent with a newly created BRanch Bridge Agent.
     *   @param _newBranchBridgeAgent new branch bridge agent address
     *   @param _rootBridgeAgent new branch bridge agent address
     *   @param _srcChainId branch chain id.
     *
     */
    function _syncBranchBridgeAgent(address _newBranchBridgeAgent, address _rootBridgeAgent, uint256 _srcChainId)
        internal
    {
        IPort(rootPortAddress).syncBranchBridgeAgentWithRoot(_newBranchBridgeAgent, _rootBridgeAgent, _srcChainId);
    }

    /*///////////////////////////////////////////////////////////////
                             MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Modifier verifies the caller is the Bridge Agent Executor.
    modifier requiresExecutor() {
        if (msg.sender != bridgeAgentExecutorAddress) revert UnrecognizedBridgeAgentExecutor();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    error InvalidChainId();

    error UnauthorizedChainId();

    error UnauthorizedCallerNotManager();

    error TokenAlreadyAdded();

    error UnrecognizedGlobalToken();

    error UnrecognizedBridgeAgentFactory();
}
