// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRootBridgeAgentFactory} from "../interfaces/IRootBridgeAgentFactory.sol";
import {IRootPort} from "../interfaces/IRootPort.sol";

import {RootBridgeAgent} from "../RootBridgeAgent.sol";

/// @title Root Bridge Agent Factory Contract
/// @author MaiaDAO
contract RootBridgeAgentFactory is IRootBridgeAgentFactory {
    /// @notice Root Chain Id
    uint16 public immutable rootChainId;

    /// @notice Root Port Address
    address public immutable rootPortAddress;

    /// @notice Local Layerzero Enpoint Address
    address public immutable lzEndpointAddress;

    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Bridge Agent.
     *     @param _rootChainId Root Chain Layer Zero Id.
     *     @param _lzEndpointAddress Layer Zero Endpoint for cross-chain communication.
     *     @param _rootPortAddress Root Port Address.
     */
    constructor(uint16 _rootChainId, address _lzEndpointAddress, address _rootPortAddress) {
        require(_rootPortAddress != address(0), "Root Port Address cannot be 0");

        rootChainId = _rootChainId;
        lzEndpointAddress = _lzEndpointAddress;
        rootPortAddress = _rootPortAddress;
    }

    /*///////////////////////////////////////////////////////////////
                BRIDGE AGENT FACTORY EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new Root Bridge Agent.
     *   @param _newRootRouterAddress New Root Router Address.
     *   @return newBridgeAgent New Bridge Agent Address.
     */
    function createBridgeAgent(address _newRootRouterAddress) external returns (address newBridgeAgent) {
        newBridgeAgent = address(
            new RootBridgeAgent(
                rootChainId, 
                lzEndpointAddress, 
                rootPortAddress, 
                _newRootRouterAddress
            )
        );

        IRootPort(rootPortAddress).addBridgeAgent(msg.sender, newBridgeAgent);
    }
}
