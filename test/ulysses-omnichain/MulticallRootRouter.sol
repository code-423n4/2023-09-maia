// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {IMulticall2 as IMulticall} from "./interfaces/IMulticall2.sol";
import {
    GasParams,
    IRootBridgeAgent as IBridgeAgent,
    SettlementInput,
    SettlementMultipleInput
} from "./interfaces/IRootBridgeAgent.sol";
import {IRootRouter, DepositParams, DepositMultipleParams} from "./interfaces/IRootRouter.sol";
import {IVirtualAccount, Call} from "./interfaces/IVirtualAccount.sol";

struct OutputParams {
    // Address to receive the output assets.
    address recipient;
    // Address of the output hToken.
    address outputToken;
    // Amount of output hTokens to send.
    uint256 amountOut;
    // Amount of output underlying token to send.
    uint256 depositOut;
}

struct OutputMultipleParams {
    // Address to receive the output assets.
    address recipient;
    // Addresses of the output hTokens.
    address[] outputTokens;
    // Amounts of output hTokens to send.
    uint256[] amountsOut;
    // Amounts of output underlying tokens to send.
    uint256[] depositsOut;
}

/**
 * @title  Multicall Root Router Contract
 * @author MaiaDAO
 * @notice Root Router implementation for interfacing with third-party dApps present in the Root Omnichain Environment.
 * @dev    Func IDs for calling these  functions through messaging layer:
 *
 *         CROSS-CHAIN MESSAGING FUNCIDs
 *         -----------------------------
 *         FUNC ID      | FUNC NAME
 *         -------------+---------------
 *         0x01         | multicallNoOutput
 *         0x02         | multicallSingleOutput
 *         0x03         | multicallMultipleOutput
 *         0x04         | multicallSignedNoOutput
 *         0x05         | multicallSignedSingleOutput
 *         0x06         | multicallSignedMultipleOutput
 *
 */
contract MulticallRootRouter is IRootRouter, Ownable {
    using SafeTransferLib for address;

    /*///////////////////////////////////////////////////////////////
                    MULTICALL ROOT ROUTER STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Root Chain Layer Zero Identifier.
    uint256 public immutable localChainId;

    /// @notice Address for Local Port Address where assets are stored and managed.
    address public immutable localPortAddress;

    /// @notice Root Chain Multicall Address.
    address public immutable multicallAddress;

    /// @notice Bridge Agent to manage communications and cross-chain assets.
    address payable public bridgeAgentAddress;

    /// @notice Bridge Agent Executor Address.
    address public bridgeAgentExecutorAddress;

    /// @notice Re-entrancy lock modifier state.
    uint256 internal _unlocked = 1;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Multicall Root Router.
     * @param _localChainId local layer zero chain id.
     * @param _localPortAddress address of the root Port.
     * @param _multicallAddress address of the Multicall contract.
     */
    constructor(uint256 _localChainId, address _localPortAddress, address _multicallAddress) {
        require(_localPortAddress != address(0), "Local Port Address cannot be 0");
        require(_multicallAddress != address(0), "Multicall Address cannot be 0");

        localChainId = _localChainId;
        localPortAddress = _localPortAddress;
        multicallAddress = _multicallAddress;
        _initializeOwner(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                        INITIALIZATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Initializes the Multicall Root Router.
     * @param _bridgeAgentAddress The address of the Bridge Agent.
     */
    function initialize(address _bridgeAgentAddress) external onlyOwner {
        require(_bridgeAgentAddress != address(0), "Bridge Agent Address cannot be 0");

        bridgeAgentAddress = payable(_bridgeAgentAddress);
        bridgeAgentExecutorAddress = IBridgeAgent(_bridgeAgentAddress).bridgeAgentExecutorAddress();
        renounceOwnership();
    }

    /*///////////////////////////////////////////////////////////////
                        LAYERZERO FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRootRouter
    /// @dev This function will revert when called.
    function executeResponse(bytes memory, uint16) external payable override {
        revert();
    }

    /**
     *  @inheritdoc IRootRouter
     *  @dev FuncIDs
     *
     *  FUNC ID      | FUNC NAME
     *  0x01         |  multicallNoOutput
     *  0x02         |  multicallSingleOutput
     *  0x03         |  multicallMultipleOutput
     *
     */
    function execute(bytes calldata encodedData, uint16) external payable override lock requiresExecutor {
        // Parse funcId
        bytes1 funcId = encodedData[0];

        /// FUNC ID: 1 (multicallNoOutput)
        if (funcId == 0x01) {
            // Decode Params
            (IMulticall.Call[] memory callData) = abi.decode(_decode(encodedData[1:]), (IMulticall.Call[]));

            // Perform Calls
            _multicall(callData);

            /// FUNC ID: 2 (multicallSingleOutput)
        } else if (funcId == 0x02) {
            // Decode Params
            (
                IMulticall.Call[] memory callData,
                OutputParams memory outputParams,
                uint16 dstChainId,
                GasParams memory gasParams
            ) = abi.decode(_decode(encodedData[1:]), (IMulticall.Call[], OutputParams, uint16, GasParams));

            // Perform Calls
            _multicall(callData);

            // Bridge Out assets
            _approveAndCallOut(
                outputParams.recipient,
                outputParams.recipient,
                outputParams.outputToken,
                outputParams.amountOut,
                outputParams.depositOut,
                dstChainId,
                gasParams
            );

            /// FUNC ID: 3 (multicallMultipleOutput)
        } else if (funcId == 0x03) {
            // Decode Params
            (
                IMulticall.Call[] memory callData,
                OutputMultipleParams memory outputParams,
                uint16 dstChainId,
                GasParams memory gasParams
            ) = abi.decode(_decode(encodedData[1:]), (IMulticall.Call[], OutputMultipleParams, uint16, GasParams));

            // Perform Calls
            _multicall(callData);

            // Bridge Out assets
            _approveMultipleAndCallOut(
                outputParams.recipient,
                outputParams.recipient,
                outputParams.outputTokens,
                outputParams.amountsOut,
                outputParams.depositsOut,
                dstChainId,
                gasParams
            );
            /// UNRECOGNIZED FUNC ID
        } else {
            revert UnrecognizedFunctionId();
        }
    }

    ///@inheritdoc IRootRouter
    function executeDepositSingle(bytes calldata, DepositParams calldata, uint16) external payable override {
        revert();
    }

    ///@inheritdoc IRootRouter

    function executeDepositMultiple(bytes calldata, DepositMultipleParams calldata, uint16) external payable {
        revert();
    }

    /**
     *  @inheritdoc IRootRouter
     *  @dev FuncIDs
     *
     *  FUNC ID      | FUNC NAME
     *  0x01         |  multicallNoOutput
     *  0x02         |  multicallSingleOutput
     *  0x03         |  multicallMultipleOutput
     *
     */
    function executeSigned(bytes calldata encodedData, address userAccount, uint16)
        external
        payable
        override
        lock
        requiresExecutor
    {
        // Parse funcId
        bytes1 funcId = encodedData[0];

        /// FUNC ID: 1 (multicallNoOutput)
        if (funcId == 0x01) {
            // Decode Params
            Call[] memory calls = abi.decode(_decode(encodedData[1:]), (Call[]));

            // Make requested calls
            IVirtualAccount(userAccount).call(calls);

            /// FUNC ID: 2 (multicallSingleOutput)
        } else if (funcId == 0x02) {
            // Decode Params
            (Call[] memory calls, OutputParams memory outputParams, uint16 dstChainId, GasParams memory gasParams) =
                abi.decode(_decode(encodedData[1:]), (Call[], OutputParams, uint16, GasParams));

            // Make requested calls
            IVirtualAccount(userAccount).call(calls);

            // Withdraw assets from Virtual Account
            IVirtualAccount(userAccount).withdrawERC20(outputParams.outputToken, outputParams.amountOut);

            // Bridge Out assets
            _approveAndCallOut(
                IVirtualAccount(userAccount).userAddress(),
                outputParams.recipient,
                outputParams.outputToken,
                outputParams.amountOut,
                outputParams.depositOut,
                dstChainId,
                gasParams
            );

            /// FUNC ID: 3 (multicallMultipleOutput)
        } else if (funcId == 0x03) {
            // Decode Params
            (
                Call[] memory calls,
                OutputMultipleParams memory outputParams,
                uint16 dstChainId,
                GasParams memory gasParams
            ) = abi.decode(_decode(encodedData[1:]), (Call[], OutputMultipleParams, uint16, GasParams));

            // Make requested calls
            IVirtualAccount(userAccount).call(calls);

            // Withdraw assets from Virtual Account
            for (uint256 i = 0; i < outputParams.outputTokens.length;) {
                IVirtualAccount(userAccount).withdrawERC20(outputParams.outputTokens[i], outputParams.amountsOut[i]);

                unchecked {
                    ++i;
                }
            }

            // Bridge Out assets
            _approveMultipleAndCallOut(
                IVirtualAccount(userAccount).userAddress(),
                outputParams.recipient,
                outputParams.outputTokens,
                outputParams.amountsOut,
                outputParams.depositsOut,
                dstChainId,
                gasParams
            );
            /// UNRECOGNIZED FUNC ID
        } else {
            revert UnrecognizedFunctionId();
        }
    }

    /**
     *  @inheritdoc IRootRouter
     *  @dev FuncIDs
     *
     *  FUNC ID      | FUNC NAME
     *  0x01         |  multicallNoOutput
     *  0x02         |  multicallSingleOutput
     *  0x03         |  multicallMultipleOutput
     *
     */
    function executeSignedDepositSingle(bytes calldata encodedData, DepositParams calldata, address userAccount, uint16)
        external
        payable
        override
        requiresExecutor
        lock
    {
        // Parse funcId
        bytes1 funcId = encodedData[0];

        /// FUNC ID: 1 (multicallNoOutput)
        if (funcId == 0x01) {
            // Decode Params
            Call[] memory calls = abi.decode(_decode(encodedData[1:]), (Call[]));

            // Make requested calls
            IVirtualAccount(userAccount).call(calls);

            /// FUNC ID: 2 (multicallSingleOutput)
        } else if (funcId == 0x02) {
            // Decode Params
            (Call[] memory calls, OutputParams memory outputParams, uint16 dstChainId, GasParams memory gasParams) =
                abi.decode(_decode(encodedData[1:]), (Call[], OutputParams, uint16, GasParams));

            // Make requested calls
            IVirtualAccount(userAccount).call(calls);

            // Withdraw assets from Virtual Account
            IVirtualAccount(userAccount).withdrawERC20(outputParams.outputToken, outputParams.amountOut);

            // Bridge Out assets
            _approveAndCallOut(
                IVirtualAccount(userAccount).userAddress(),
                outputParams.recipient,
                outputParams.outputToken,
                outputParams.amountOut,
                outputParams.depositOut,
                dstChainId,
                gasParams
            );

            /// FUNC ID: 3 (multicallMultipleOutput)
        } else if (funcId == 0x03) {
            // Decode Params
            (
                Call[] memory calls,
                OutputMultipleParams memory outputParams,
                uint16 dstChainId,
                GasParams memory gasParams
            ) = abi.decode(_decode(encodedData[1:]), (Call[], OutputMultipleParams, uint16, GasParams));

            // Make requested calls
            IVirtualAccount(userAccount).call(calls);

            // Withdraw assets from Virtual Account
            for (uint256 i = 0; i < outputParams.outputTokens.length;) {
                IVirtualAccount(userAccount).withdrawERC20(outputParams.outputTokens[i], outputParams.amountsOut[i]);

                unchecked {
                    ++i;
                }
            }

            // Bridge Out assets
            _approveMultipleAndCallOut(
                IVirtualAccount(userAccount).userAddress(),
                outputParams.recipient,
                outputParams.outputTokens,
                outputParams.amountsOut,
                outputParams.depositsOut,
                dstChainId,
                gasParams
            );
            /// UNRECOGNIZED FUNC ID
        } else {
            revert UnrecognizedFunctionId();
        }
    }

    /**
     *  @inheritdoc IRootRouter
     *  @dev FuncIDs
     *
     *  FUNC ID      | FUNC NAME
     *  0x01         |  multicallNoOutput
     *  0x02         |  multicallSingleOutput
     *  0x03         |  multicallMultipleOutput
     *
     */
    function executeSignedDepositMultiple(
        bytes calldata encodedData,
        DepositMultipleParams calldata,
        address userAccount,
        uint16
    ) external payable override requiresExecutor lock {
        // Parse funcId
        bytes1 funcId = encodedData[0];

        /// FUNC ID: 1 (multicallNoOutput)
        if (funcId == 0x01) {
            // Decode Params
            Call[] memory calls = abi.decode(_decode(encodedData[1:]), (Call[]));

            // Make requested calls
            IVirtualAccount(userAccount).call(calls);

            /// FUNC ID: 2 (multicallSingleOutput)
        } else if (funcId == 0x02) {
            // Decode Params
            (Call[] memory calls, OutputParams memory outputParams, uint16 dstChainId, GasParams memory gasParams) =
                abi.decode(_decode(encodedData[1:]), (Call[], OutputParams, uint16, GasParams));

            // Make requested calls
            IVirtualAccount(userAccount).call(calls);

            // Withdraw assets from Virtual Account
            IVirtualAccount(userAccount).withdrawERC20(outputParams.outputToken, outputParams.amountOut);

            // Bridge Out assets
            _approveAndCallOut(
                IVirtualAccount(userAccount).userAddress(),
                outputParams.recipient,
                outputParams.outputToken,
                outputParams.amountOut,
                outputParams.depositOut,
                dstChainId,
                gasParams
            );

            /// FUNC ID: 3 (multicallMultipleOutput)
        } else if (funcId == 0x03) {
            // Decode Params
            (
                Call[] memory calls,
                OutputMultipleParams memory outputParams,
                uint16 dstChainId,
                GasParams memory gasParams
            ) = abi.decode(_decode(encodedData[1:]), (Call[], OutputMultipleParams, uint16, GasParams));

            // Make requested calls
            IVirtualAccount(userAccount).call(calls);

            // Withdraw assets from Virtual Account
            for (uint256 i = 0; i < outputParams.outputTokens.length;) {
                IVirtualAccount(userAccount).withdrawERC20(outputParams.outputTokens[i], outputParams.amountsOut[i]);

                unchecked {
                    ++i;
                }
            }

            // Bridge Out assets
            _approveMultipleAndCallOut(
                IVirtualAccount(userAccount).userAddress(),
                outputParams.recipient,
                outputParams.outputTokens,
                outputParams.amountsOut,
                outputParams.depositsOut,
                dstChainId,
                gasParams
            );
            /// UNRECOGNIZED FUNC ID
        } else {
            revert UnrecognizedFunctionId();
        }
    }

    /*///////////////////////////////////////////////////////////////
                        MULTICALL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     *   @notice Function to perform a set of actions on the omnichain environment without using the user's Virtual Acccount.
     *   @param calls to be executed.
     *
     */
    function _multicall(IMulticall.Call[] memory calls)
        internal
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        // Make requested calls
        (blockNumber, returnData) = IMulticall(multicallAddress).aggregate(calls);
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL HOOKS
    ////////////////////////////////////////////////////////////*/
    /**
     *  @notice Function to call 'clearToken' on the Root Port.
     *  @param refundee settlement owner adn excess gas receiver.
     *  @param recipient Address to receive the output hTokens.
     *  @param outputToken Address of the output hToken.
     *  @param amountOut Amount of output hTokens to send.
     *  @param depositOut Amount of output hTokens to deposit.
     *  @param dstChainId Chain Id of the destination chain.
     */
    function _approveAndCallOut(
        address refundee,
        address recipient,
        address outputToken,
        uint256 amountOut,
        uint256 depositOut,
        uint16 dstChainId,
        GasParams memory gasParams
    ) internal virtual {
        // Save bridge agent address to memory
        address _bridgeAgentAddress = bridgeAgentAddress;

        // Approve Root Port to spend/send output hTokens.
        outputToken.safeApprove(_bridgeAgentAddress, amountOut);

        //Move output hTokens from Root to Branch and call 'clearToken'.
        IBridgeAgent(_bridgeAgentAddress).callOutAndBridge{value: msg.value}(
            payable(refundee),
            recipient,
            dstChainId,
            "",
            SettlementInput(outputToken, amountOut, depositOut),
            gasParams,
            true
        );
    }

    /**
     *  @notice Function to approve token spend before Bridge Agent interaction to Bridge Out of omnichain environment.
     *  @param refundee settlement owner adn excess gas receiver.
     *  @param recipient Address to receive the output tokens.
     *  @param outputTokens Addresses of the output hTokens.
     *  @param amountsOut Total amount of tokens to send.
     *  @param depositsOut Amounts of tokens to withdraw from the destination port.
     *
     */
    function _approveMultipleAndCallOut(
        address refundee,
        address recipient,
        address[] memory outputTokens,
        uint256[] memory amountsOut,
        uint256[] memory depositsOut,
        uint16 dstChainId,
        GasParams memory gasParams
    ) internal virtual {
        // Save bridge agent address to memory
        address _bridgeAgentAddress = bridgeAgentAddress;

        // For each output token
        for (uint256 i = 0; i < outputTokens.length;) {
            // Approve Root Port to spend output hTokens.
            outputTokens[i].safeApprove(_bridgeAgentAddress, amountsOut[i]);
            unchecked {
                ++i;
            }
        }

        //Move output hTokens from Root to Branch and call 'clearTokens'.
        IBridgeAgent(_bridgeAgentAddress).callOutAndBridgeMultiple{value: msg.value}(
            payable(refundee),
            recipient,
            dstChainId,
            "",
            SettlementMultipleInput(outputTokens, amountsOut, depositsOut),
            gasParams,
            true
        );
    }

    /*///////////////////////////////////////////////////////////////
                            DECODING FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    function _decode(bytes calldata data) internal pure virtual returns (bytes memory) {
        return data;
    }

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    ////////////////////////////////////////////////////////////*/

    /// @notice Modifier for a simple re-entrancy check.
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    /// @notice Modifier verifies the caller is the Bridge Agent Executor.
    modifier requiresExecutor() {
        _requiresExecutor();
        _;
    }

    /// @notice Verifies the caller is the Bridge Agent Executor. Internal function used in modifier to reduce contract bytesize.
    function _requiresExecutor() internal view {
        if (msg.sender != bridgeAgentExecutorAddress) revert UnrecognizedBridgeAgentExecutor();
    }
}
