// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IBranchRouter} from "./interfaces/IBranchRouter.sol";

import {
    IBranchBridgeAgent as IBridgeAgent,
    GasParams,
    Deposit,
    DepositInput,
    DepositParams,
    DepositMultipleInput,
    DepositMultipleParams,
    SettlementParams,
    SettlementMultipleParams
} from "./interfaces/IBranchBridgeAgent.sol";

/// @title Base Branch Router Contract
/// @author MaiaDAO
contract BaseBranchRouter is IBranchRouter, Ownable {
    using SafeTransferLib for address;

    /*///////////////////////////////////////////////////////////////
                    BASE BRANCH ROUTER STATE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchRouter
    address public localPortAddress;

    /// @inheritdoc IBranchRouter
    address public override localBridgeAgentAddress;

    /// @inheritdoc IBranchRouter
    address public override bridgeAgentExecutorAddress;

    /// @notice Re-entrancy lock modifier state.
    uint256 internal _unlocked = 1;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _initializeOwner(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                    INITIALIZATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the Base Branch Router.
     * @param _localBridgeAgentAddress The address of the local Bridge Agent.
     */
    function initialize(address _localBridgeAgentAddress) external onlyOwner {
        require(_localBridgeAgentAddress != address(0), "Bridge Agent address cannot be 0");
        localBridgeAgentAddress = _localBridgeAgentAddress;
        localPortAddress = IBridgeAgent(_localBridgeAgentAddress).localPortAddress();
        bridgeAgentExecutorAddress = IBridgeAgent(_localBridgeAgentAddress).bridgeAgentExecutorAddress();
        
        renounceOwnership();
    }

    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchRouter
    function getDepositEntry(uint32 _depositNonce) external view override returns (Deposit memory) {
        return IBridgeAgent(localBridgeAgentAddress).getDepositEntry(_depositNonce);
    }

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchRouter
    function callOut(bytes calldata _params, GasParams calldata _gParams) external payable override lock {
        IBridgeAgent(localBridgeAgentAddress).callOut{value: msg.value}(payable(msg.sender), _params, _gParams);
    }

    /// @inheritdoc IBranchRouter
    function callOutAndBridge(bytes calldata _params, DepositInput calldata _dParams, GasParams calldata _gParams)
        external
        payable
        override
        lock
    {
        //Transfer tokens to this contract.
        _transferAndApproveToken(_dParams.hToken, _dParams.token, _dParams.amount, _dParams.deposit);

        //Perform call to bridge agent.
        IBridgeAgent(localBridgeAgentAddress).callOutAndBridge{value: msg.value}(
            payable(msg.sender), _params, _dParams, _gParams
        );
    }

    /// @inheritdoc IBranchRouter
    function callOutAndBridgeMultiple(
        bytes calldata _params,
        DepositMultipleInput calldata _dParams,
        GasParams calldata _gParams
    ) external payable override lock {
        //Transfer tokens to this contract.
        _transferAndApproveMultipleTokens(_dParams.hTokens, _dParams.tokens, _dParams.amounts, _dParams.deposits);

        //Perform call to bridge agent.
        IBridgeAgent(localBridgeAgentAddress).callOutAndBridgeMultiple{value: msg.value}(
            payable(msg.sender), _params, _dParams, _gParams
        );
    }

    /*///////////////////////////////////////////////////////////////
                BRIDGE AGENT EXECUTOR EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchRouter
    function executeNoSettlement(bytes calldata) external payable virtual override requiresAgentExecutor {
        revert UnrecognizedFunctionId();
    }

    /// @inheritdoc IBranchRouter
    function executeSettlement(bytes calldata, SettlementParams memory)
        external
        payable
        virtual
        override
        requiresAgentExecutor
    {
        revert UnrecognizedFunctionId();
    }

    /// @inheritdoc IBranchRouter
    function executeSettlementMultiple(bytes calldata, SettlementMultipleParams memory)
        external
        payable
        virtual
        override
        requiresAgentExecutor
    {
        revert UnrecognizedFunctionId();
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to transfer token into a contract.
     *   @param _hToken The address of the hToken.
     *   @param _token The address of the token.
     *   @param _amount The amount of the hToken.
     *   @param _deposit The amount of the token.
     */
    function _transferAndApproveToken(address _hToken, address _token, uint256 _amount, uint256 _deposit) internal {
        // Cache local port address
        address _localPortAddress = localPortAddress;

        // Check if the local branch tokens are being spent
        if (_amount - _deposit > 0) {
            unchecked {
                _hToken.safeTransferFrom(msg.sender, address(this), _amount - _deposit);
                ERC20(_hToken).approve(_localPortAddress, _amount - _deposit);
            }
        }

        // Check if the underlying tokens are being spent
        if (_deposit > 0) {
            _token.safeTransferFrom(msg.sender, address(this), _deposit);
            ERC20(_token).approve(_localPortAddress, _deposit);
        }
    }

    /**
     * @notice Internal function to transfer multiple tokens into a contract.
     *   @param _hTokens The addresses of the hTokens.
     *   @param _tokens The addresses of the tokens.
     *   @param _amounts The amounts of the hTokens.
     *   @param _deposits The amounts of the tokens.
     */
    function _transferAndApproveMultipleTokens(
        address[] memory _hTokens,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _deposits
    ) internal {
        for (uint256 i = 0; i < _hTokens.length;) {
            _transferAndApproveToken(_hTokens[i], _tokens[i], _amounts[i], _deposits[i]);

            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Modifier that verifies msg sender is the Bridge Agent Executor.
    modifier requiresAgentExecutor() {
        if (msg.sender != bridgeAgentExecutorAddress) revert UnrecognizedBridgeAgentExecutor();
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
