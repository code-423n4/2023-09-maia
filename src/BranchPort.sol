// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IPortStrategy} from "./interfaces/IPortStrategy.sol";
import {IBranchPort} from "./interfaces/IBranchPort.sol";

import {ERC20hTokenBranch} from "./token/ERC20hTokenBranch.sol";

/// @title Branch Port - Omnichain Token Management Contract
/// @author MaiaDAO
contract BranchPort is Ownable, IBranchPort {
    using SafeTransferLib for address;

    /*///////////////////////////////////////////////////////////////
                        CORE ROUTER STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Local Core Branch Router Address.
    address public coreBranchRouterAddress;

    /*///////////////////////////////////////////////////////////////
                        BRIDGE AGENT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping from Underlying Address to isUnderlying (bool).
    mapping(address bridgeAgent => bool isActiveBridgeAgent) public isBridgeAgent;

    /// @notice Branch Routers deployed in branch chain.
    address[] public bridgeAgents;

    /*///////////////////////////////////////////////////////////////
                    BRIDGE AGENT FACTORIES STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping from Underlying Address to isUnderlying (bool).
    mapping(address bridgeAgentFactory => bool isActiveBridgeAgentFactory) public isBridgeAgentFactory;

    /// @notice Branch Routers deployed in branch chain.
    address[] public bridgeAgentFactories;

    /*///////////////////////////////////////////////////////////////
                        STRATEGY TOKENS STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping returns true if Strategy Token Address is active for usage in Port Strategies.
    mapping(address token => bool allowsStrategies) public isStrategyToken;

    /// @notice List of Tokens allowed for usage in Port Strategies.
    address[] public strategyTokens;

    /// @notice Mapping returns a given token's total debt incurred by Port Strategies.
    mapping(address token => uint256 debt) public getStrategyTokenDebt;

    /// @notice Mapping returns the minimum ratio of a given Strategy Token the Port should hold.
    mapping(address token => uint256 minimumReserveRatio) public getMinimumTokenReserveRatio;

    /*///////////////////////////////////////////////////////////////
                        PORT STRATEGIES STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping returns true if Port Strategy is allowed to manage a given Strategy Token.
    mapping(address strategy => mapping(address token => bool isActiveStrategy)) public isPortStrategy;

    /// @notice Port Strategy Addresses deployed in the current branch chain.
    address[] public portStrategies;

    /// @notice Mapping returns the amount of Strategy Token debt a given Port Strategy has.
    mapping(address strategy => mapping(address token => uint256 debt)) public getPortStrategyTokenDebt;

    /// @notice Mapping returns the last time a given Port Strategy managed a given Strategy Token.
    mapping(address strategy => mapping(address token => uint256 lastManaged)) public lastManaged;

    /// @notice Mapping returns the time limit a given Port Strategy must wait before managing a Strategy Token.
    mapping(address strategy => mapping(address token => uint256 dailyLimitAmount)) public strategyDailyLimitAmount;

    /// @notice Mapping returns the amount of a Strategy Token a given Port Strategy can manage.
    mapping(address strategy => mapping(address token => uint256 dailyLimitRemaining)) public
        strategyDailyLimitRemaining;

    /*///////////////////////////////////////////////////////////////
                            REENTRANCY STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Reentrancy lock guard state.
    uint256 internal _unlocked = 1;

    /*///////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant DIVISIONER = 1e4;
    uint256 internal constant MIN_RESERVE_RATIO = 3e3;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for the Branch Port Contract.
     *   @param _owner Address of the Owner.
     */
    constructor(address _owner) {
        require(_owner != address(0), "Owner is zero address");
        _initializeOwner(_owner);
    }

    /*///////////////////////////////////////////////////////////////
                        INITIALIZATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the Branch Port.
     *   @param _coreBranchRouter Address of the Core Branch Router.
     *   @param _bridgeAgentFactory Address of the Bridge Agent Factory.
     */
    function initialize(address _coreBranchRouter, address _bridgeAgentFactory) external virtual onlyOwner {
        require(coreBranchRouterAddress == address(0), "Contract already initialized");
        require(!isBridgeAgentFactory[_bridgeAgentFactory], "Contract already initialized");

        require(_coreBranchRouter != address(0), "CoreBranchRouter is zero address");
        require(_bridgeAgentFactory != address(0), "BridgeAgentFactory is zero address");

        coreBranchRouterAddress = _coreBranchRouter;
        isBridgeAgentFactory[_bridgeAgentFactory] = true;
        bridgeAgentFactories.push(_bridgeAgentFactory);
    }

    /// @notice Function being overrriden to prevent mistakenly renouncing ownership.
    function renounceOwnership() public payable override onlyOwner {
        revert("Cannot renounce ownership");
    }

    /*///////////////////////////////////////////////////////////////
                        PORT STRATEGY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchPort
    function manage(address _token, uint256 _amount) external override requiresPortStrategy(_token) {
        // Cache Strategy Token Global Debt
        uint256 _strategyTokenDebt = getStrategyTokenDebt[_token];

        // Check if request would surpass the tokens minimum reserves
        if (_amount > _excessReserves(_strategyTokenDebt, _token)) revert InsufficientReserves();

        // Check if request would surpass the Port Strategy's daily limit
        _checkTimeLimit(_token, _amount);

        // Update Strategy Token Global Debt
        getStrategyTokenDebt[_token] = _strategyTokenDebt + _amount;
        // Update Port Strategy Token Debt
        getPortStrategyTokenDebt[msg.sender][_token] += _amount;

        // Transfer tokens to Port Strategy for management
        _token.safeTransfer(msg.sender, _amount);

        // Emit DebtCreated event
        emit DebtCreated(msg.sender, _token, _amount);
    }

    /// @inheritdoc IBranchPort
    function replenishReserves(address _token, uint256 _amount) external override lock {
        // Update Port Strategy Token Debt. Will underflow if not enough debt to repay.
        getPortStrategyTokenDebt[msg.sender][_token] -= _amount;

        // Update Strategy Token Global Debt. Will underflow if not enough debt to repay.
        getStrategyTokenDebt[_token] -= _amount;

        // Get current balance of _token
        uint256 currBalance = ERC20(_token).balanceOf(address(this));

        // Withdraw tokens from startegy
        IPortStrategy(msg.sender).withdraw(address(this), _token, _amount);

        // Check if _token balance has increased by _amount
        require(ERC20(_token).balanceOf(address(this)) - currBalance == _amount, "Port Strategy Withdraw Failed");

        // Emit DebtRepaid event
        emit DebtRepaid(msg.sender, _token, _amount);
    }

    /// @inheritdoc IBranchPort
    function replenishReserves(address _strategy, address _token) external override lock {
        // Cache Strategy Token Global Debt
        uint256 strategyTokenDebt = getStrategyTokenDebt[_token];

        // Get current balance of _token
        uint256 currBalance = ERC20(_token).balanceOf(address(this));

        // Get reserves lacking
        uint256 reservesLacking = _reservesLacking(strategyTokenDebt, _token, currBalance);

        // Cache Port Strategy Token Debt
        uint256 portStrategyTokenDebt = getPortStrategyTokenDebt[_strategy][_token];

        // Calculate amount to withdraw. The lesser of reserves lacking or Strategy Token Global Debt.
        uint256 amountToWithdraw = portStrategyTokenDebt < reservesLacking ? portStrategyTokenDebt : reservesLacking;

        // Update Port Strategy Token Debt
        getPortStrategyTokenDebt[_strategy][_token] = portStrategyTokenDebt - amountToWithdraw;
        // Update Strategy Token Global Debt
        getStrategyTokenDebt[_token] = strategyTokenDebt - amountToWithdraw;

        // Withdraw tokens from startegy
        IPortStrategy(_strategy).withdraw(address(this), _token, amountToWithdraw);

        // Check if _token balance has increased by _amount
        require(
            ERC20(_token).balanceOf(address(this)) - currBalance == amountToWithdraw, "Port Strategy Withdraw Failed"
        );

        // Emit DebtRepaid event
        emit DebtRepaid(_strategy, _token, amountToWithdraw);
    }

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchPort
    function withdraw(address _recipient, address _underlyingAddress, uint256 _deposit)
        public
        virtual
        override
        lock
        requiresBridgeAgent
    {
        _underlyingAddress.safeTransfer(_recipient, _deposit);
    }

    /// @inheritdoc IBranchPort
    function bridgeIn(address _recipient, address _localAddress, uint256 _amount)
        external
        override
        requiresBridgeAgent
    {
        _bridgeIn(_recipient, _localAddress, _amount);
    }

    /// @inheritdoc IBranchPort
    function bridgeInMultiple(
        address _recipient,
        address[] memory _localAddresses,
        address[] memory _underlyingAddresses,
        uint256[] memory _amounts,
        uint256[] memory _deposits
    ) external override requiresBridgeAgent {
        // Cache Length
        uint256 length = _localAddresses.length;

        // Loop through token inputs
        for (uint256 i = 0; i < length;) {
            // Check if hTokens are being bridged in
            if (_amounts[i] - _deposits[i] > 0) {
                unchecked {
                    _bridgeIn(_recipient, _localAddresses[i], _amounts[i] - _deposits[i]);
                }
            }

            // Check if underlying tokens are being cleared
            if (_deposits[i] > 0) {
                withdraw(_recipient, _underlyingAddresses[i], _deposits[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IBranchPort
    function bridgeOut(
        address _depositor,
        address _localAddress,
        address _underlyingAddress,
        uint256 _amount,
        uint256 _deposit
    ) external override lock requiresBridgeAgent {
        _bridgeOut(_depositor, _localAddress, _underlyingAddress, _amount, _deposit);
    }

    /// @inheritdoc IBranchPort
    function bridgeOutMultiple(
        address _depositor,
        address[] memory _localAddresses,
        address[] memory _underlyingAddresses,
        uint256[] memory _amounts,
        uint256[] memory _deposits
    ) external override lock requiresBridgeAgent {
        // Cache Length
        uint256 length = _localAddresses.length;

        // Sanity Check input arrays
        if (length > 255) revert InvalidInputArrays();
        if (length != _underlyingAddresses.length) revert InvalidInputArrays();
        if (_underlyingAddresses.length != _amounts.length) revert InvalidInputArrays();
        if (_amounts.length != _deposits.length) revert InvalidInputArrays();

        // Loop through token inputs and bridge out
        for (uint256 i = 0; i < length;) {
            _bridgeOut(_depositor, _localAddresses[i], _underlyingAddresses[i], _amounts[i], _deposits[i]);

            unchecked {
                i++;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                    BRIDGE AGENT FACTORIES FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchPort
    function addBridgeAgent(address _bridgeAgent) external override requiresBridgeAgentFactory {
        if (isBridgeAgent[_bridgeAgent]) revert AlreadyAddedBridgeAgent();

        isBridgeAgent[_bridgeAgent] = true;
        bridgeAgents.push(_bridgeAgent);
    }

    /*///////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchPort
    function setCoreRouter(address _newCoreRouter) external override requiresCoreRouter {
        require(coreBranchRouterAddress != address(0), "CoreRouter address is zero");
        require(_newCoreRouter != address(0), "New CoreRouter address is zero");
        coreBranchRouterAddress = _newCoreRouter;
    }

    /// @inheritdoc IBranchPort
    function addBridgeAgentFactory(address _newBridgeAgentFactory) external override requiresCoreRouter {
        if (isBridgeAgentFactory[_newBridgeAgentFactory]) revert AlreadyAddedBridgeAgentFactory();

        isBridgeAgentFactory[_newBridgeAgentFactory] = true;
        bridgeAgentFactories.push(_newBridgeAgentFactory);

        emit BridgeAgentFactoryAdded(_newBridgeAgentFactory);
    }

    /// @inheritdoc IBranchPort
    function toggleBridgeAgentFactory(address _newBridgeAgentFactory) external override requiresCoreRouter {
        isBridgeAgentFactory[_newBridgeAgentFactory] = !isBridgeAgentFactory[_newBridgeAgentFactory];

        emit BridgeAgentFactoryToggled(_newBridgeAgentFactory);
    }

    /// @inheritdoc IBranchPort
    function toggleBridgeAgent(address _bridgeAgent) external override requiresCoreRouter {
        isBridgeAgent[_bridgeAgent] = !isBridgeAgent[_bridgeAgent];

        emit BridgeAgentToggled(_bridgeAgent);
    }

    /// @inheritdoc IBranchPort
    function addStrategyToken(address _token, uint256 _minimumReservesRatio) external override requiresCoreRouter {
        if (_minimumReservesRatio >= DIVISIONER || _minimumReservesRatio < MIN_RESERVE_RATIO) {
            revert InvalidMinimumReservesRatio();
        }

        strategyTokens.push(_token);
        getMinimumTokenReserveRatio[_token] = _minimumReservesRatio;
        isStrategyToken[_token] = true;

        emit StrategyTokenAdded(_token, _minimumReservesRatio);
    }

    /// @inheritdoc IBranchPort
    function toggleStrategyToken(address _token) external override requiresCoreRouter {
        isStrategyToken[_token] = !isStrategyToken[_token];

        emit StrategyTokenToggled(_token);
    }

    /// @inheritdoc IBranchPort
    function addPortStrategy(address _portStrategy, address _token, uint256 _dailyManagementLimit)
        external
        override
        requiresCoreRouter
    {
        if (!isStrategyToken[_token]) revert UnrecognizedStrategyToken();
        portStrategies.push(_portStrategy);
        strategyDailyLimitAmount[_portStrategy][_token] = _dailyManagementLimit;
        isPortStrategy[_portStrategy][_token] = true;

        emit PortStrategyAdded(_portStrategy, _token, _dailyManagementLimit);
    }

    /// @inheritdoc IBranchPort
    function togglePortStrategy(address _portStrategy, address _token) external override requiresCoreRouter {
        isPortStrategy[_portStrategy][_token] = !isPortStrategy[_portStrategy][_token];

        emit PortStrategyToggled(_portStrategy, _token);
    }

    /// @inheritdoc IBranchPort
    function updatePortStrategy(address _portStrategy, address _token, uint256 _dailyManagementLimit)
        external
        override
        requiresCoreRouter
    {
        strategyDailyLimitAmount[_portStrategy][_token] = _dailyManagementLimit;

        emit PortStrategyUpdated(_portStrategy, _token, _dailyManagementLimit);
    }

    /// @inheritdoc IBranchPort
    function setCoreBranchRouter(address _coreBranchRouter, address _coreBranchBridgeAgent)
        external
        override
        requiresCoreRouter
    {
        coreBranchRouterAddress = _coreBranchRouter;
        isBridgeAgent[_coreBranchBridgeAgent] = true;
        bridgeAgents.push(_coreBranchBridgeAgent);

        emit CoreBranchSet(_coreBranchRouter, _coreBranchBridgeAgent);
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns amount of Strategy Tokens
     *   @param _token Address of a given Strategy Token.
     *   @return uint256 excess reserves
     */
    function _excessReserves(uint256 _strategyTokenDebt, address _token) internal view returns (uint256) {
        uint256 currBalance = ERC20(_token).balanceOf(address(this));
        uint256 minReserves = _minimumReserves(_strategyTokenDebt, currBalance, _token);

        unchecked {
            return currBalance > minReserves ? currBalance - minReserves : 0;
        }
    }

    /**
     * @notice Returns amount of Strategy Tokens needed to reach minimum reserves
     *   @param _token Address of a given Strategy Token.
     *   @return uint256 excess reserves
     */
    function _reservesLacking(uint256 _strategyTokenDebt, address _token, uint256 currBalance)
        internal
        view
        returns (uint256)
    {
        uint256 minReserves = _minimumReserves(_strategyTokenDebt, currBalance, _token);

        unchecked {
            return currBalance < minReserves ? minReserves - currBalance : 0;
        }
    }

    /**
     * @notice Internal function to return the minimum amount of reserves of a given Strategy Token the Port should hold.
     *   @param _strategyTokenDebt Total token debt incurred by Port Strategies.
     *   @param _currBalance Current balance of a given Strategy Token.
     *   @param _token Address of a given Strategy Token.
     *   @return uint256 minimum reserves
     */
    function _minimumReserves(uint256 _strategyTokenDebt, uint256 _currBalance, address _token)
        internal
        view
        returns (uint256)
    {
        return ((_currBalance + _strategyTokenDebt) * getMinimumTokenReserveRatio[_token]) / DIVISIONER;
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to check if a Port Strategy has reached its daily management limit.
     *   @param _token address being managed.
     *   @param _amount of token being requested.
     */
    function _checkTimeLimit(address _token, uint256 _amount) internal {
        uint256 dailyLimit = strategyDailyLimitRemaining[msg.sender][_token];
        if (block.timestamp - lastManaged[msg.sender][_token] >= 1 days) {
            dailyLimit = strategyDailyLimitAmount[msg.sender][_token];
            unchecked {
                lastManaged[msg.sender][_token] = (block.timestamp / 1 days) * 1 days;
            }
        }
        strategyDailyLimitRemaining[msg.sender][_token] = dailyLimit - _amount;
    }

    /**
     * @notice Internal function to bridge in hTokens.
     *   @param _recipient address of the recipient.
     *   @param _localAddress address of the hToken.
     *   @param _amount amount of hTokens to bridge in.
     */
    function _bridgeIn(address _recipient, address _localAddress, uint256 _amount) internal virtual {
        ERC20hTokenBranch(_localAddress).mint(_recipient, _amount);
    }

    /**
     * @notice Internal function to bridge out hTokens and underlying tokens.
     *   @param _depositor address of the depositor.
     *   @param _localAddress address of the hToken.
     *   @param _underlyingAddress address of the underlying token.
     *   @param _amount total amount of tokens to bridge out.
     *   @param _deposit amount of underlying tokens to bridge out.
     */
    function _bridgeOut(
        address _depositor,
        address _localAddress,
        address _underlyingAddress,
        uint256 _amount,
        uint256 _deposit
    ) internal virtual {
        // Cache hToken amount out
        uint256 _hTokenAmount = _amount - _deposit;

        // Check if hTokens are being bridged out
        if (_hTokenAmount > 0) {
            _localAddress.safeTransferFrom(_depositor, address(this), _hTokenAmount);
            ERC20hTokenBranch(_localAddress).burn(_hTokenAmount);
        }

        // Check if underlying tokens are being bridged out
        if (_deposit > 0) {
            _underlyingAddress.safeTransferFrom(_depositor, address(this), _deposit);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Modifier that verifies msg sender is the Branch Chain's Core Root Router.
    modifier requiresCoreRouter() {
        if (msg.sender != coreBranchRouterAddress) revert UnrecognizedCore();
        _;
    }

    /// @notice Modifier that verifies msg sender is an active Bridge Agent.
    modifier requiresBridgeAgent() {
        if (!isBridgeAgent[msg.sender]) revert UnrecognizedBridgeAgent();
        _;
    }

    /// @notice Modifier that verifies msg sender is an active Bridge Agent Factory.
    modifier requiresBridgeAgentFactory() {
        if (!isBridgeAgentFactory[msg.sender]) revert UnrecognizedBridgeAgentFactory();
        _;
    }

    /// @notice Modifier that require msg sender to be an active Port Strategy
    modifier requiresPortStrategy(address _token) {
        if (!isStrategyToken[_token]) revert UnrecognizedStrategyToken();
        if (!isPortStrategy[msg.sender][_token]) revert UnrecognizedPortStrategy();
        _;
    }

    /// @notice Modifier for a simple re-entrancy check.
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }
}
