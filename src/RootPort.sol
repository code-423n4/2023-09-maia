// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {IERC20hTokenRootFactory} from "./interfaces/IERC20hTokenRootFactory.sol";
import {IRootBridgeAgent as IBridgeAgent} from "./interfaces/IRootBridgeAgent.sol";
import {IRootPort, ICoreRootRouter, GasParams, VirtualAccount} from "./interfaces/IRootPort.sol";

import {ERC20hTokenRoot} from "./token/ERC20hTokenRoot.sol";

/// @title Root Port - Omnichain Token Management Contract
/// @author MaiaDAO
contract RootPort is Ownable, IRootPort {
    using SafeTransferLib for address;

    /*///////////////////////////////////////////////////////////////
                            SETUP STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice True if setup is still ongoing, false otherwise.
    bool internal _setup;

    /// @notice True if core setup is still ongoing, false otherwise.
    bool internal _setupCore;

    /*///////////////////////////////////////////////////////////////
                        ROOT PORT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Local Chain Id
    uint256 public immutable localChainId;

    /// @notice The address of local branch port responsible for handling local transactions.
    address public localBranchPortAddress;

    /// @notice The address of the core router in charge of adding new tokens to the system.
    address public coreRootRouterAddress;

    /// @notice The address of the core router in charge of adding new tokens to the system.
    address public coreRootBridgeAgentAddress;

    /*///////////////////////////////////////////////////////////////
                        VIRTUAL ACCOUNT
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping from user address to Virtual Account.
    mapping(address user => VirtualAccount account) public getUserAccount;

    /// @notice Holds the mapping from Virtual account to router address => bool.
    /// @notice Stores whether a router is approved to spend a virtual account.
    mapping(VirtualAccount acount => mapping(address router => bool allowed)) public isRouterApproved;

    /*///////////////////////////////////////////////////////////////
                        BRIDGE AGENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping from address to Bridge Agent.
    mapping(uint256 chainId => bool isActive) public isChainId;

    /// @notice Mapping from address to isBridgeAgent (bool).
    mapping(address bridgeAgent => bool isActive) public isBridgeAgent;

    /// @notice Bridge Agents deployed in root chain.
    address[] public bridgeAgents;

    /// @notice Mapping address Bridge Agent => address Bridge Agent Manager
    mapping(address bridgeAgent => address bridgeAgentManager) public getBridgeAgentManager;

    /*///////////////////////////////////////////////////////////////
                    BRIDGE AGENT FACTORIES
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping from Underlying Address to isUnderlying (bool).
    mapping(address bridgeAgentFactory => bool isActive) public isBridgeAgentFactory;

    /// @notice Bridge Agents deployed in root chain.
    address[] public bridgeAgentFactories;

    /*///////////////////////////////////////////////////////////////
                            hTOKENS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping with all global hTokens deployed in the system.
    mapping(address token => bool isGlobalToken) public isGlobalAddress;

    /// @notice ChainId -> Local Address -> Global Address
    mapping(address chainId => mapping(uint256 localAddress => address globalAddress)) public getGlobalTokenFromLocal;

    /// @notice ChainId -> Global Address -> Local Address
    mapping(address chainId => mapping(uint256 globalAddress => address localAddress)) public getLocalTokenFromGlobal;

    /// @notice ChainId -> Underlying Address -> Local Address
    mapping(address chainId => mapping(uint256 underlyingAddress => address localAddress)) public
        getLocalTokenFromUnderlying;

    /// @notice Mapping from Local Address to Underlying Address.
    mapping(address chainId => mapping(uint256 localAddress => address underlyingAddress)) public
        getUnderlyingTokenFromLocal;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Root Port.
     * @param _localChainId layer zero chain id of the local chain.
     */
    constructor(uint256 _localChainId) {
        localChainId = _localChainId;
        isChainId[_localChainId] = true;

        _initializeOwner(msg.sender);
        _setup = true;
        _setupCore = true;
    }

    /*///////////////////////////////////////////////////////////////
                    INITIALIZATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Function to initialize the Root Port.
     *   @param _bridgeAgentFactory The address of the Bridge Agent Factory.
     *   @param _coreRootRouter The address of the Core Root Router.
     */
    function initialize(address _bridgeAgentFactory, address _coreRootRouter) external onlyOwner {
        require(_bridgeAgentFactory != address(0), "Bridge Agent Factory cannot be 0 address.");
        require(_coreRootRouter != address(0), "Core Root Router cannot be 0 address.");
        require(_setup, "Setup ended.");
        _setup = false;

        isBridgeAgentFactory[_bridgeAgentFactory] = true;
        bridgeAgentFactories.push(_bridgeAgentFactory);

        coreRootRouterAddress = _coreRootRouter;
    }

    /**
     *  @notice Function to initialize the Root Chain Core Contracts in Port Storage.
     *   @param _coreRootBridgeAgent The address of the Core Root Bridge Agent.
     *   @param _coreLocalBranchBridgeAgent The address of the Core Arbitrum Branch Bridge Agent.
     *   @param _localBranchPortAddress The address of the Arbitrum Branch Port.
     */
    function initializeCore(
        address _coreRootBridgeAgent,
        address _coreLocalBranchBridgeAgent,
        address _localBranchPortAddress
    ) external onlyOwner {
        require(_coreRootBridgeAgent != address(0), "Core Root Bridge Agent cannot be 0 address.");
        require(_coreLocalBranchBridgeAgent != address(0), "Core Local Branch Bridge Agent cannot be 0 address.");
        require(_localBranchPortAddress != address(0), "Local Branch Port Address cannot be 0 address.");
        require(isBridgeAgent[_coreRootBridgeAgent], "Core Bridge Agent doesn't exist.");
        require(_setupCore, "Core Setup ended.");
        _setupCore = false;

        coreRootBridgeAgentAddress = _coreRootBridgeAgent;
        localBranchPortAddress = _localBranchPortAddress;
        IBridgeAgent(_coreRootBridgeAgent).syncBranchBridgeAgent(_coreLocalBranchBridgeAgent, localChainId);
        getBridgeAgentManager[_coreRootBridgeAgent] = owner();
    }

    /// @notice Function being overriden to prevent mistakenly renouncing ownership.
    function renounceOwnership() public payable override onlyOwner {
        revert("Cannot renounce ownership");
    }

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootPort
    function getLocalToken(address _localAddress, uint256 _srcChainId, uint256 _dstChainId)
        external
        view
        override
        returns (address)
    {
        return _getLocalToken(_localAddress, _srcChainId, _dstChainId);
    }

    /**
     * @notice View Function returns Local Token's Local Address on another chain.
     * @param _localAddress The address of the token in the local chain.
     * @param _srcChainId The chainId of the chain where the token is deployed.
     * @param _dstChainId The chainId of the chain for which the token address is requested.
     */
    function _getLocalToken(address _localAddress, uint256 _srcChainId, uint256 _dstChainId)
        internal
        view
        returns (address)
    {
        address globalAddress = getGlobalTokenFromLocal[_localAddress][_srcChainId];
        return getLocalTokenFromGlobal[globalAddress][_dstChainId];
    }

    /// @inheritdoc IRootPort
    function getUnderlyingTokenFromGlobal(address _globalAddress, uint256 _srcChainId)
        external
        view
        override
        returns (address)
    {
        address localAddress = getLocalTokenFromGlobal[_globalAddress][_srcChainId];
        return getUnderlyingTokenFromLocal[localAddress][_srcChainId];
    }

    /// @inheritdoc IRootPort
    function isGlobalToken(address _globalAddress, uint256 _srcChainId) external view override returns (bool) {
        return getLocalTokenFromGlobal[_globalAddress][_srcChainId] != address(0);
    }

    /// @inheritdoc IRootPort
    function isLocalToken(address _localAddress, uint256 _srcChainId) external view override returns (bool) {
        return getGlobalTokenFromLocal[_localAddress][_srcChainId] != address(0);
    }

    /// @inheritdoc IRootPort
    function isLocalToken(address _localAddress, uint256 _srcChainId, uint256 _dstChainId)
        external
        view
        returns (bool)
    {
        return _getLocalToken(_localAddress, _srcChainId, _dstChainId) != address(0);
    }

    /// @inheritdoc IRootPort
    function isUnderlyingToken(address _underlyingToken, uint256 _srcChainId) external view override returns (bool) {
        return getLocalTokenFromUnderlying[_underlyingToken][_srcChainId] != address(0);
    }

    /*///////////////////////////////////////////////////////////////
                        hTOKEN MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootPort
    function setAddresses(
        address _globalAddress,
        address _localAddress,
        address _underlyingAddress,
        uint256 _srcChainId
    ) external override requiresCoreRootRouter {
        if (_globalAddress == address(0)) revert InvalidGlobalAddress();
        if (_localAddress == address(0)) revert InvalidLocalAddress();
        if (_underlyingAddress == address(0)) revert InvalidUnderlyingAddress();

        isGlobalAddress[_globalAddress] = true;
        getGlobalTokenFromLocal[_localAddress][_srcChainId] = _globalAddress;
        getLocalTokenFromGlobal[_globalAddress][_srcChainId] = _localAddress;
        getLocalTokenFromUnderlying[_underlyingAddress][_srcChainId] = _localAddress;
        getUnderlyingTokenFromLocal[_localAddress][_srcChainId] = _underlyingAddress;

        emit LocalTokenAdded(_underlyingAddress, _localAddress, _globalAddress, _srcChainId);
    }

    /// @inheritdoc IRootPort
    function setLocalAddress(address _globalAddress, address _localAddress, uint256 _srcChainId)
        external
        override
        requiresCoreRootRouter
    {
        if (_localAddress == address(0)) revert InvalidLocalAddress();

        getGlobalTokenFromLocal[_localAddress][_srcChainId] = _globalAddress;
        getLocalTokenFromGlobal[_globalAddress][_srcChainId] = _localAddress;

        emit GlobalTokenAdded(_localAddress, _globalAddress, _srcChainId);
    }

    /*///////////////////////////////////////////////////////////////
                        hTOKEN ACCOUNTING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootPort
    function bridgeToRoot(address _recipient, address _hToken, uint256 _amount, uint256 _deposit, uint256 _srcChainId)
        external
        override
        requiresBridgeAgent
    {
        if (!isGlobalAddress[_hToken]) revert UnrecognizedToken();

        if (_amount - _deposit > 0) {
            unchecked {
                _hToken.safeTransfer(_recipient, _amount - _deposit);
            }
        }

        if (_deposit > 0) if (!ERC20hTokenRoot(_hToken).mint(_recipient, _deposit, _srcChainId)) revert UnableToMint();
    }

    /// @inheritdoc IRootPort
    function bridgeToRootFromLocalBranch(address _from, address _hToken, uint256 _amount)
        external
        override
        requiresLocalBranchPort
    {
        if (!isGlobalAddress[_hToken]) revert UnrecognizedToken();

        _hToken.safeTransferFrom(_from, address(this), _amount);
    }

    function bridgeToLocalBranchFromRoot(address _to, address _hToken, uint256 _amount)
        external
        override
        requiresLocalBranchPort
    {
        if (!isGlobalAddress[_hToken]) revert UnrecognizedToken();

        _hToken.safeTransfer(_to, _amount);
    }

    /// @inheritdoc IRootPort
    function burn(address _from, address _hToken, uint256 _amount, uint256 _srcChainId)
        external
        override
        requiresBridgeAgent
    {
        if (!isGlobalAddress[_hToken]) revert UnrecognizedToken();
        ERC20hTokenRoot(_hToken).burn(_from, _amount, _srcChainId);
    }

    /// @inheritdoc IRootPort
    function burnFromLocalBranch(address _from, address _hToken, uint256 _amount)
        external
        override
        requiresLocalBranchPort
    {
        if (!isGlobalAddress[_hToken]) revert UnrecognizedToken();

        ERC20hTokenRoot(_hToken).burn(_from, _amount, localChainId);
    }

    /// @inheritdoc IRootPort
    function mintToLocalBranch(address _to, address _hToken, uint256 _amount)
        external
        override
        requiresLocalBranchPort
    {
        if (!isGlobalAddress[_hToken]) revert UnrecognizedToken();
        if (!ERC20hTokenRoot(_hToken).mint(_to, _amount, localChainId)) revert UnableToMint();
    }

    /*///////////////////////////////////////////////////////////////
                    VIRTUAL ACCOUNT MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootPort
    function fetchVirtualAccount(address _user) external override returns (VirtualAccount account) {
        account = getUserAccount[_user];
        if (address(account) == address(0)) account = addVirtualAccount(_user);
    }

    /**
     * @notice Creates a new virtual account for a user.
     * @param _user address of the user to associate a virtual account with.
     */
    function addVirtualAccount(address _user) internal returns (VirtualAccount newAccount) {
        if (_user == address(0)) revert InvalidUserAddress();

        newAccount = new VirtualAccount{salt: keccak256(abi.encode(_user))}(_user, address(this));
        getUserAccount[_user] = newAccount;

        emit VirtualAccountCreated(_user, address(newAccount));
    }

    /// @inheritdoc IRootPort
    function toggleVirtualAccountApproved(VirtualAccount _userAccount, address _router)
        external
        override
        requiresBridgeAgent
    {
        isRouterApproved[_userAccount][_router] = !isRouterApproved[_userAccount][_router];
    }

    /*///////////////////////////////////////////////////////////////
                        BRIDGE AGENT ADDITION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootPort
    function addBridgeAgent(address _manager, address _bridgeAgent) external override requiresBridgeAgentFactory {
        if (isBridgeAgent[_bridgeAgent]) revert AlreadyAddedBridgeAgent();

        bridgeAgents.push(_bridgeAgent);
        getBridgeAgentManager[_bridgeAgent] = _manager;
        isBridgeAgent[_bridgeAgent] = true;

        emit BridgeAgentAdded(_bridgeAgent, _manager);
    }

    /// @inheritdoc IRootPort
    function syncBranchBridgeAgentWithRoot(
        address _newBranchBridgeAgent,
        address _rootBridgeAgent,
        uint256 _branchChainId
    ) external override requiresCoreRootRouter {
        if (IBridgeAgent(_rootBridgeAgent).getBranchBridgeAgent(_branchChainId) != address(0)) {
            revert AlreadyAddedBridgeAgent();
        }
        if (!IBridgeAgent(_rootBridgeAgent).isBranchBridgeAgentAllowed(_branchChainId)) {
            revert BridgeAgentNotAllowed();
        }
        IBridgeAgent(_rootBridgeAgent).syncBranchBridgeAgent(_newBranchBridgeAgent, _branchChainId);

        emit BridgeAgentSynced(_newBranchBridgeAgent, _rootBridgeAgent, _branchChainId);
    }

    /*///////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootPort
    function toggleBridgeAgent(address _bridgeAgent) external override onlyOwner {
        isBridgeAgent[_bridgeAgent] = !isBridgeAgent[_bridgeAgent];

        emit BridgeAgentToggled(_bridgeAgent);
    }

    /// @inheritdoc IRootPort
    function addBridgeAgentFactory(address _bridgeAgentFactory) external override onlyOwner {
        if (isBridgeAgentFactory[_bridgeAgentFactory]) revert AlreadyAddedBridgeAgentFactory();

        bridgeAgentFactories.push(_bridgeAgentFactory);
        isBridgeAgentFactory[_bridgeAgentFactory] = true;

        emit BridgeAgentFactoryAdded(_bridgeAgentFactory);
    }

    /// @inheritdoc IRootPort
    function toggleBridgeAgentFactory(address _bridgeAgentFactory) external override onlyOwner {
        isBridgeAgentFactory[_bridgeAgentFactory] = !isBridgeAgentFactory[_bridgeAgentFactory];

        emit BridgeAgentFactoryToggled(_bridgeAgentFactory);
    }

    /// @inheritdoc IRootPort
    function addNewChain(
        address _coreBranchBridgeAgentAddress,
        uint256 _chainId,
        string memory _wrappedGasTokenName,
        string memory _wrappedGasTokenSymbol,
        uint8 _wrappedGasTokenDecimals,
        address _newLocalBranchWrappedNativeTokenAddress,
        address _newUnderlyingBranchWrappedNativeTokenAddress
    ) external override onlyOwner {
        // Check if chain already added
        if (isChainId[_chainId]) revert AlreadyAddedChain();

        // Create new global token for new chain's wrapped native token
        address newGlobalToken = address(
            IERC20hTokenRootFactory(ICoreRootRouter(coreRootRouterAddress).hTokenFactoryAddress()).createToken(
                _wrappedGasTokenName, _wrappedGasTokenSymbol, _wrappedGasTokenDecimals
            )
        );

        // Sync new branch bridge agent with root core bridge agent
        IBridgeAgent(ICoreRootRouter(coreRootRouterAddress).bridgeAgentAddress()).syncBranchBridgeAgent(
            _coreBranchBridgeAgentAddress, _chainId
        );

        // Update State

        // 1. Add new chain to chainId mapping
        isChainId[_chainId] = true;
        // 2. Add new chain to global address mapping
        isGlobalAddress[newGlobalToken] = true;
        // 3. Add new branch local token to global token address mapping
        getGlobalTokenFromLocal[_newLocalBranchWrappedNativeTokenAddress][_chainId] = newGlobalToken;
        // 4. Add new global token to branch local token address mapping
        getLocalTokenFromGlobal[newGlobalToken][_chainId] = _newLocalBranchWrappedNativeTokenAddress;
        // 5. Add new branch underlying token to branch local token address mapping
        getLocalTokenFromUnderlying[_newUnderlyingBranchWrappedNativeTokenAddress][_chainId] =
            _newLocalBranchWrappedNativeTokenAddress;
        // 6. Add new branch local token to branch underlying token address mapping
        getUnderlyingTokenFromLocal[_newLocalBranchWrappedNativeTokenAddress][_chainId] =
            _newUnderlyingBranchWrappedNativeTokenAddress;

        emit NewChainAdded(_chainId);
    }

    /// @inheritdoc IRootPort
    function addEcosystemToken(address _ecoTokenGlobalAddress) external override onlyOwner {
        // Check if token already added
        if (isGlobalAddress[_ecoTokenGlobalAddress]) revert AlreadyAddedEcosystemToken();

        // Check if token is already a underlying token in current chain
        if (getUnderlyingTokenFromLocal[_ecoTokenGlobalAddress][localChainId] != address(0)) {
            revert AlreadyAddedEcosystemToken();
        }

        // Check if token is already a local branch token in current chain
        if (getLocalTokenFromUnderlying[_ecoTokenGlobalAddress][localChainId] != address(0)) {
            revert AlreadyAddedEcosystemToken();
        }

        // Update State
        // 1. Add new global token to global address mapping
        isGlobalAddress[_ecoTokenGlobalAddress] = true;
        // 2. Add new branch local token address to global token mapping
        getGlobalTokenFromLocal[_ecoTokenGlobalAddress][localChainId] = _ecoTokenGlobalAddress;
        // 3. Add new global token to branch local token address mapping
        getLocalTokenFromGlobal[_ecoTokenGlobalAddress][localChainId] = _ecoTokenGlobalAddress;

        emit EcosystemTokenAdded(_ecoTokenGlobalAddress);
    }

    /// @inheritdoc IRootPort
    function setCoreRootRouter(address _coreRootRouter, address _coreRootBridgeAgent) external override onlyOwner {
        if (_coreRootRouter == address(0)) revert InvalidCoreRootRouter();
        if (_coreRootBridgeAgent == address(0)) revert InvalidCoreRootBridgeAgent();

        coreRootRouterAddress = _coreRootRouter;
        coreRootBridgeAgentAddress = _coreRootBridgeAgent;
        getBridgeAgentManager[_coreRootBridgeAgent] = owner();

        emit CoreRootSet(_coreRootRouter, _coreRootBridgeAgent);
    }

    /// @inheritdoc IRootPort
    function setCoreBranchRouter(
        address _refundee,
        address _coreBranchRouter,
        address _coreBranchBridgeAgent,
        uint16 _dstChainId,
        GasParams calldata _gParams
    ) external payable override onlyOwner {
        if (_coreBranchRouter == address(0)) revert InvalidCoreBranchRouter();
        if (_coreBranchBridgeAgent == address(0)) revert InvalidCoreBrancBridgeAgent();

        ICoreRootRouter(coreRootRouterAddress).setCoreBranch{value: msg.value}(
            _refundee, _coreBranchRouter, _coreBranchBridgeAgent, _dstChainId, _gParams
        );

        emit CoreBranchSet(_coreBranchRouter, _coreBranchBridgeAgent, _dstChainId);
    }

    /// @inheritdoc IRootPort
    function syncNewCoreBranchRouter(address _coreBranchRouter, address _coreBranchBridgeAgent, uint16 _dstChainId)
        external
        override
        onlyOwner
    {
        if (_coreBranchRouter == address(0)) revert InvalidCoreBranchRouter();
        if (_coreBranchBridgeAgent == address(0)) revert InvalidCoreBrancBridgeAgent();

        IBridgeAgent(coreRootBridgeAgentAddress).syncBranchBridgeAgent(_coreBranchBridgeAgent, _dstChainId);

        emit CoreBranchSynced(_coreBranchRouter, _coreBranchBridgeAgent, _dstChainId);
    }

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Modifier that verifies msg sender is an active Bridge Agent Factory.
    modifier requiresBridgeAgentFactory() {
        if (!isBridgeAgentFactory[msg.sender]) revert UnrecognizedBridgeAgentFactory();
        _;
    }

    /// @notice Modifier that verifies msg sender is an active Bridge Agent.
    modifier requiresBridgeAgent() {
        if (!isBridgeAgent[msg.sender]) revert UnrecognizedBridgeAgent();
        _;
    }

    /// @notice Modifier that verifies msg sender is the Root Chain's Core Router.
    modifier requiresCoreRootRouter() {
        if (msg.sender != coreRootRouterAddress) revert UnrecognizedCoreRootRouter();
        _;
    }

    /// @notice Modifier that verifies msg sender is the Root Chain's Local Branch Port.
    modifier requiresLocalBranchPort() {
        if (msg.sender != localBranchPortAddress) revert UnrecognizedLocalBranchPort();
        _;
    }
}
