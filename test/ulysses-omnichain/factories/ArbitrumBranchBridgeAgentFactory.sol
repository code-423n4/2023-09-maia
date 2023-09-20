// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IArbitrumBranchPort as IPort} from "../interfaces/IArbitrumBranchPort.sol";

import {ArbitrumBranchBridgeAgent, DeployArbitrumBranchBridgeAgent} from "../ArbitrumBranchBridgeAgent.sol";
import {BranchBridgeAgentFactory} from "./BranchBridgeAgentFactory.sol";

/**
 * @title  Arbitrum Branch Bridge Agent Factory Contract
 * @author MaiaDAO
 * @notice Factory contract for allowing permissionless deployment of
 *         new Arbitrum Branch Bridge Agents which are in charge of
 *         managing the deposit and withdrawal of assets between the
 *         branch chains and the omnichain environment.
 */
contract ArbitrumBranchBridgeAgentFactory is BranchBridgeAgentFactory {
    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Bridge Agent Factory Contract.
     *  @param _rootChainId Root Chain Layer Zero Id.
     *  @param _rootBridgeAgentFactoryAddress Root Bridge Agent Factory Address.
     *  @param _localCoreBranchRouterAddress Local Core Branch Router Address.
     *  @param _localPortAddress Local Branch Port Address.
     *  @param _owner Owner of the contract.
     */
    constructor(
        uint16 _rootChainId,
        address _rootBridgeAgentFactoryAddress,
        address _localCoreBranchRouterAddress,
        address _localPortAddress,
        address _owner
    )
        BranchBridgeAgentFactory(
            _rootChainId,
            _rootChainId,
            _rootBridgeAgentFactoryAddress,
            address(0),
            _localCoreBranchRouterAddress,
            _localPortAddress,
            _owner
        )
    {}

    /*///////////////////////////////////////////////////////////////
                             INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the Bridge Agent Factory Contract.
     * @param _coreRootBridgeAgent Address of the Core Root Bridge Agent.
     */
    function initialize(address _coreRootBridgeAgent) external override onlyOwner {
        require(_coreRootBridgeAgent != address(0), "Core Root Bridge Agent Address cannot be 0");

        address newCoreBridgeAgent = address(
            DeployArbitrumBranchBridgeAgent.deploy(
                rootChainId, _coreRootBridgeAgent, localCoreBranchRouterAddress, localPortAddress
            )
        );

        IPort(localPortAddress).addBridgeAgent(newCoreBridgeAgent);

        renounceOwnership();
    }

    /*///////////////////////////////////////////////////////////////
                BRIDGE AGENT FACTORY EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new bridge agent for a branch chain.
     * @param _newBranchRouterAddress Address of the new branch router.
     * @param _rootBridgeAgentAddress Address of the root bridge agent to connect to.
     */
    function createBridgeAgent(
        address _newBranchRouterAddress,
        address _rootBridgeAgentAddress,
        address _rootBridgeAgentFactoryAddress
    ) external virtual override returns (address newBridgeAgent) {
        require(
            msg.sender == localCoreBranchRouterAddress, "Only the Core Branch Router can create a new Bridge Agent."
        );
        require(
            _rootBridgeAgentFactoryAddress == rootBridgeAgentFactoryAddress,
            "Root Bridge Agent Factory Address does not match."
        );

        newBridgeAgent = address(
            DeployArbitrumBranchBridgeAgent.deploy(
                rootChainId, _rootBridgeAgentAddress, _newBranchRouterAddress, localPortAddress
            )
        );

        IPort(localPortAddress).addBridgeAgent(newBridgeAgent);
    }
}
