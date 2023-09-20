// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IArbitrumBranchPort as IArbPort} from "./interfaces/IArbitrumBranchPort.sol";
import {IRootBridgeAgent} from "./interfaces/IRootBridgeAgent.sol";
import {GasParams, IBranchBridgeAgent} from "./interfaces/IBranchBridgeAgent.sol";

import {BranchBridgeAgent} from "./BranchBridgeAgent.sol";

library DeployArbitrumBranchBridgeAgent {
    function deploy(uint16 _localChainId, address _daoAddress, address _localRouterAddress, address _localPortAddress)
        external
        returns (ArbitrumBranchBridgeAgent)
    {
        return new ArbitrumBranchBridgeAgent(
            _localChainId,
            _daoAddress,
            _localRouterAddress,
            _localPortAddress
        );
    }
}

/**
 * @title  Arbitrum Branch Bridge Agent Contract.
 * @author MaiaDAO
 * @notice This contract is used for interfacing with Users/Routers acting as a middleman
 *         to access LayerZero cross-chain messaging and Port communication for asset management
 *         connecting Arbitrum Branch Chain contracts and the root omnichain environment.
 */
contract ArbitrumBranchBridgeAgent is BranchBridgeAgent {
    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Arbitrum Branch Bridge Agent.
     *  @param _localChainId Local Chain Layer Zero Id.
     *  @param _rootBridgeAgentAddress Root Bridge Agent Address.
     *  @param _localRouterAddress Local Core Branch Router Address.
     *  @param _localPortAddress Local Branch Port Address.
     */
    constructor(
        uint16 _localChainId,
        address _rootBridgeAgentAddress,
        address _localRouterAddress,
        address _localPortAddress
    )
        BranchBridgeAgent(
            _localChainId,
            _localChainId,
            _rootBridgeAgentAddress,
            address(0),
            _localRouterAddress,
            _localPortAddress
        )
    {}

    /*///////////////////////////////////////////////////////////////
                        USER EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to deposit a single asset to the local Port.
     *   @param underlyingAddress address of the underlying asset to be deposited.
     *   @param amount amount to be deposited.
     *
     */
    function depositToPort(address underlyingAddress, uint256 amount) external payable lock {
        IArbPort(localPortAddress).depositToPort(msg.sender, msg.sender, underlyingAddress, amount);
    }

    /**
     * @notice Function to withdraw a single asset to the local Port.
     *   @param localAddress local hToken to be withdrawn.
     *   @param amount amount to be withdrawn.
     *
     */
    function withdrawFromPort(address localAddress, uint256 amount) external payable lock {
        IArbPort(localPortAddress).withdrawFromPort(msg.sender, msg.sender, localAddress, amount);
    }

    /*///////////////////////////////////////////////////////////////
                    SETTLEMENT EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchBridgeAgent
    /// @dev This functionality should be accessed from Root environment
    function retrySettlement(uint32, bytes calldata, GasParams[2] calldata, bool) external payable override lock {}

    /*///////////////////////////////////////////////////////////////
                    LAYER ZERO INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function performs the call to LayerZero messaging layer Endpoint for cross-chain messaging.
     *   @param _calldata params for root bridge agent execution.
     */
    function _performCall(address payable, bytes memory _calldata, GasParams calldata) internal override {
        // Cache Root Bridge Agent Address
        address _rootBridgeAgentAddress = rootBridgeAgentAddress;
        // Send Gas to Root Bridge Agent
        _rootBridgeAgentAddress.call{value: msg.value}("");
        // Execute locally
        IRootBridgeAgent(_rootBridgeAgentAddress).lzReceive(rootChainId, "", 0, _calldata);
    }

    /**
     * @notice Internal function performs the call to Layerzero Endpoint Contract for cross-chain messaging.
     *   @param _settlementNonce root settlement nonce to fallback.
     */
    function _performFallbackCall(address payable, uint32 _settlementNonce) internal override {
        //Sends message to Root Bridge Agent
        IRootBridgeAgent(rootBridgeAgentAddress).lzReceive(
            rootChainId, "", 0, abi.encodePacked(bytes1(0x09), _settlementNonce)
        );
    }

    /*///////////////////////////////////////////////////////////////
                        MODIFIER INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Verifies the caller is the Root Bridge Agent.
    /// @dev Internal function used in modifier to reduce contract bytesize.
    function _requiresEndpoint(address _endpoint, bytes calldata) internal view override {
        if (msg.sender != address(this)) revert LayerZeroUnauthorizedEndpoint();
        if (_endpoint != rootBridgeAgentAddress) revert LayerZeroUnauthorizedEndpoint();
    }
}
