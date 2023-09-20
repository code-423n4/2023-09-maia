// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";

import {DeployBranchBridgeAgent} from "../BranchBridgeAgent.sol";

import {IBranchPort as IPort} from "../interfaces/IBranchPort.sol";
import {IBranchBridgeAgentFactory} from "../interfaces/IBranchBridgeAgentFactory.sol";

/**
 * @title Branch Bridge Agent Factory Contract
 * @author MaiaDAO
 * @notice Factory contract for allowing permissionless deployment of
 *         new Branch Bridge Agents which are in charge of
 *         managing the deposit and withdrawal of assets between the
 *         branch chains and the omnichain environment.
 */
contract BranchBridgeAgentFactory is Ownable, IBranchBridgeAgentFactory {
    /// @notice Local Chain Id.
    uint16 public immutable localChainId;

    /// @notice Root Chain Id.
    uint16 public immutable rootChainId;

    /// @notice Root Bridge Agent Factory Address.
    address public immutable rootBridgeAgentFactoryAddress;

    /// @notice Local Core Branch Router Address.
    address public immutable localCoreBranchRouterAddress;

    /// @notice Root Port Address.
    address public immutable localPortAddress;

    /// @notice Local Layer Zero Endpoint for cross-chain communication.
    address public immutable lzEndpointAddress;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Bridge Agent.
     *     @param _localChainId Local Chain Layer Zero Id.
     *     @param _rootChainId Root Chain Layer Zero Id.
     *     @param _rootBridgeAgentFactoryAddress Root Bridge Agent Factory Address.
     *     @param _lzEndpointAddress Layer Zero Endpoint for cross-chain communication.
     *     @param _localCoreBranchRouterAddress Local Core Branch Router Address.
     *     @param _localPortAddress Local Branch Port Address.
     *     @param _owner Owner of the contract.
     */
    constructor(
        uint16 _localChainId,
        uint16 _rootChainId,
        address _rootBridgeAgentFactoryAddress,
        address _lzEndpointAddress,
        address _localCoreBranchRouterAddress,
        address _localPortAddress,
        address _owner
    ) {
        require(_rootBridgeAgentFactoryAddress != address(0), "Root Bridge Agent Factory Address cannot be 0");
        require(
            _lzEndpointAddress != address(0) || _rootChainId == _localChainId,
            "Layerzero Endpoint Address cannot be the zero address."
        );
        require(_localCoreBranchRouterAddress != address(0), "Core Branch Router Address cannot be 0");
        require(_localPortAddress != address(0), "Port Address cannot be 0");
        require(_owner != address(0), "Owner cannot be 0");

        localChainId = _localChainId;
        rootChainId = _rootChainId;
        rootBridgeAgentFactoryAddress = _rootBridgeAgentFactoryAddress;
        lzEndpointAddress = _lzEndpointAddress;
        localCoreBranchRouterAddress = _localCoreBranchRouterAddress;
        localPortAddress = _localPortAddress;
        _initializeOwner(_owner);
    }

    /*///////////////////////////////////////////////////////////////
                            INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to initialize the contract.
     * @param _coreRootBridgeAgent Address of the Root Chain's Core Root Bridge Agent.
     */
    function initialize(address _coreRootBridgeAgent) external virtual onlyOwner {
        require(_coreRootBridgeAgent != address(0), "Core Root Bridge Agent cannot be 0");

        address newCoreBridgeAgent = address(
            DeployBranchBridgeAgent.deploy(
                rootChainId,
                localChainId,
                _coreRootBridgeAgent,
                lzEndpointAddress,
                localCoreBranchRouterAddress,
                localPortAddress
            )
        );

        IPort(localPortAddress).addBridgeAgent(newCoreBridgeAgent);

        renounceOwnership();
    }

    /*///////////////////////////////////////////////////////////////
                BRIDGE AGENT FACTORY EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new bridge agent for a new branch chain.
     * @param _newBranchRouterAddress Address of the new branch router.
     * @param _rootBridgeAgentAddress Address of the root bridge agent to connect to.
     */
    function createBridgeAgent(
        address _newBranchRouterAddress,
        address _rootBridgeAgentAddress,
        address _rootBridgeAgentFactoryAddress
    ) external virtual returns (address newBridgeAgent) {
        require(
            msg.sender == localCoreBranchRouterAddress, "Only the Core Branch Router can create a new Bridge Agent."
        );
        require(
            _rootBridgeAgentFactoryAddress == rootBridgeAgentFactoryAddress,
            "Root Bridge Agent Factory Address does not match."
        );

        newBridgeAgent = address(
            DeployBranchBridgeAgent.deploy(
                rootChainId,
                localChainId,
                _rootBridgeAgentAddress,
                lzEndpointAddress,
                _newBranchRouterAddress,
                localPortAddress
            )
        );

        IPort(localPortAddress).addBridgeAgent(newBridgeAgent);
    }
}
