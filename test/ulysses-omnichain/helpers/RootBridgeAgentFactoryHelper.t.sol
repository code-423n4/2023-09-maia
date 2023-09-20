//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

import {RootBridgeAgentHelper} from "./RootBridgeAgentHelper.t.sol";
import {RootPortHelper} from "./RootPortHelper.t.sol";

library RootBridgeAgentFactoryHelper {
    using RootBridgeAgentFactoryHelper for RootBridgeAgentFactory;
    using RootBridgeAgentHelper for RootBridgeAgent;
    using RootPortHelper for RootPort;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _deploy(RootBridgeAgentFactory, uint16 _rootChainId, address _lzEndpointAddress, RootPort _rootPort)
        internal
        returns (RootBridgeAgentFactory _rootBridgeAgentFactory)
    {
        _rootBridgeAgentFactory = new RootBridgeAgentFactory(
            _rootChainId,
            _lzEndpointAddress,
            address(_rootPort)
        );

        _rootBridgeAgentFactory.check_deploy(_rootChainId, _lzEndpointAddress, _rootPort);
    }

    function check_deploy(
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        uint256 _rootChainId,
        address _lzEndpointAddress,
        RootPort _rootPort
    ) internal view {
        _rootBridgeAgentFactory.check_rootChainId(_rootChainId);
        _rootBridgeAgentFactory.check_lzEndpointAddress(_lzEndpointAddress);
        _rootBridgeAgentFactory.check_rootPort(_rootPort);
    }

    function check_rootChainId(RootBridgeAgentFactory _rootBridgeAgentFactory, uint256 _rootChainId) internal view {
        require(
            _rootBridgeAgentFactory.rootChainId() == _rootChainId,
            "Incorrect RootBridgeAgentFactory Root Local Chain Id"
        );
    }

    function check_lzEndpointAddress(RootBridgeAgentFactory _rootBridgeAgentFactory, address _lzEndpointAddress)
        internal
        view
    {
        require(
            _rootBridgeAgentFactory.lzEndpointAddress() == _lzEndpointAddress,
            "Incorrect RootBridgeAgentFactory lzEndpointAddress"
        );
    }

    function check_rootPort(RootBridgeAgentFactory _rootBridgeAgentFactory, RootPort _rootPort) internal view {
        require(
            _rootBridgeAgentFactory.rootPortAddress() == address(_rootPort), "Incorrect RootBridgeAgentFactory RootPort"
        );
    }

    /*//////////////////////////////////////////////////////////////
                    CREATE ROOT BRIDGE AGENT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _createRootBridgeAgent(RootBridgeAgentFactory _rootBridgeAgentFactory, address _routerAddress)
        internal
        returns (RootBridgeAgent _rootBridgeAgent)
    {
        _rootBridgeAgent = RootBridgeAgent(payable(_rootBridgeAgentFactory.createBridgeAgent(_routerAddress)));

        RootPort(_rootBridgeAgentFactory.rootPortAddress()).check_addBridgeAgent(_rootBridgeAgent, address(this));

        _rootBridgeAgent.check_deploy(
            address(_rootBridgeAgentFactory),
            _rootBridgeAgentFactory.rootChainId(),
            _rootBridgeAgentFactory.lzEndpointAddress(),
            RootPort(_rootBridgeAgentFactory.rootPortAddress()),
            _routerAddress
        );
    }
}
