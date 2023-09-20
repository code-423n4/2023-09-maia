//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

import {RootBridgeAgentExecutorHelper} from "./RootBridgeAgentExecutorHelper.t.sol";

library RootBridgeAgentHelper {
    using RootBridgeAgentExecutorHelper for RootBridgeAgentExecutor;
    using RootBridgeAgentHelper for RootBridgeAgent;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function check_deploy(
        RootBridgeAgent _bridgeAgent,
        address _factoryAddress,
        uint256 _rootChainId,
        address _lzEndpointAddress,
        RootPort _rootPort,
        address _routerAddress
    ) internal view {
        _bridgeAgent.check_factoryAddress(_factoryAddress);
        _bridgeAgent.check_rootChainId(_rootChainId);
        _bridgeAgent.check_lzEndpointAddress(_lzEndpointAddress);
        _bridgeAgent.check_rootPort(_rootPort);
        _bridgeAgent.check_routerAddress(_routerAddress);

        RootBridgeAgentExecutor(_bridgeAgent.bridgeAgentExecutorAddress()).check_deploy(_bridgeAgent);
    }

    function check_factoryAddress(RootBridgeAgent _bridgeAgent, address _factoryAddress) internal view {
        require(_bridgeAgent.factoryAddress() == _factoryAddress, "Incorrect RootBridgeAgent Owner");
    }

    function check_rootChainId(RootBridgeAgent _bridgeAgent, uint256 _rootChainId) internal view {
        require(_bridgeAgent.localChainId() == _rootChainId, "Incorrect RootBridgeAgent Root Local Chain Id");
    }

    function check_lzEndpointAddress(RootBridgeAgent _bridgeAgent, address _lzEndpointAddress) internal view {
        require(_bridgeAgent.lzEndpointAddress() == _lzEndpointAddress, "Incorrect RootBridgeAgent lzEndpointAddress");
    }

    function check_rootPort(RootBridgeAgent _bridgeAgent, RootPort _rootPort) internal view {
        require(_bridgeAgent.localPortAddress() == address(_rootPort), "Incorrect RootBridgeAgent RootPort");
    }

    function check_routerAddress(RootBridgeAgent _bridgeAgent, address _routerAddress) internal view {
        require(
            _bridgeAgent.localRouterAddress() == address(_routerAddress), "Incorrect RootBridgeAgent Router Address"
        );
    }
}
