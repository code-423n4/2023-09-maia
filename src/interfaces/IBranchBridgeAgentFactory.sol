// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title  Branch Bridge Agent Factory Contract
 * @author MaiaDAO
 * @notice Factory contract for allowing permissionless deployment of
 *         new Branch Bridge Agents which are in charge of managing the
 *         deposit and withdrawal of assets between the branch chains
 *         and the omnichain environment.
 */
interface IBranchBridgeAgentFactory {
    /*///////////////////////////////////////////////////////////////
                        BRIDGE AGENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new Branch Bridge Agent.
     * @param newRootRouterAddress New Root Router Address.
     * @param rootBridgeAgentAddress Root Bridge Agent Address.
     * @param _rootBridgeAgentFactoryAddress Root Bridge Agent Factory Address.
     * @return newBridgeAgent New Bridge Agent Address.
     */
    function createBridgeAgent(
        address newRootRouterAddress,
        address rootBridgeAgentAddress,
        address _rootBridgeAgentFactoryAddress
    ) external returns (address newBridgeAgent);
}
