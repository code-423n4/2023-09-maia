//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library RootPortHelper {
    using RootPortHelper for RootPort;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _deploy(RootPort, uint16 _rootChainId) internal returns (RootPort _rootPort) {
        _rootPort = new RootPort(_rootChainId);

        _rootPort.check_deploy(_rootChainId);
    }

    function check_deploy(RootPort _rootPort, uint256 _rootChainId) internal view {
        _rootPort.check_rootChainId(_rootChainId);
        _rootPort.check_isChainId(_rootChainId);
        _rootPort.check_owner(address(this));
    }

    function check_rootChainId(RootPort _rootPort, uint256 _rootChainId) internal view {
        require(_rootPort.localChainId() == _rootChainId, "Incorrect RootPort Root Local Chain Id");
    }

    function check_isChainId(RootPort _rootPort, uint256 _rootChainId) internal view {
        require(_rootPort.isChainId(_rootChainId), "Incorrect RootPort is Chain Id");
    }

    function check_owner(RootPort _rootPort, address _owner) internal view {
        require(_rootPort.owner() == _owner, "Incorrect RootPort Owner");
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(RootPort _rootPort, RootBridgeAgentFactory _rootBridgeAgentFactory, CoreRootRouter _coreRootRouter)
        internal
    {
        _rootPort.initialize(address(_rootBridgeAgentFactory), address(_coreRootRouter));

        _rootPort.check_init(_rootBridgeAgentFactory, _coreRootRouter);
    }

    function check_init(
        RootPort _rootPort,
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        CoreRootRouter _coreRootRouter
    ) internal view {
        _rootPort.check_rootBridgeAgentFactory(0, _rootBridgeAgentFactory);
        _rootPort.check_isBridgeAgentFactory(_rootBridgeAgentFactory);
        _rootPort.check_coreRootRouter(_coreRootRouter);
    }

    function check_rootBridgeAgentFactory(
        RootPort _rootPort,
        uint256 index,
        RootBridgeAgentFactory _rootBridgeAgentFactory
    ) internal view {
        require(
            _rootPort.bridgeAgentFactories(index) == address(_rootBridgeAgentFactory),
            "Incorrect RootPort RootBridgeAgentFactory"
        );
    }

    function check_isBridgeAgentFactory(RootPort _rootPort, RootBridgeAgentFactory _rootBridgeAgentFactory)
        internal
        view
    {
        require(
            _rootPort.isBridgeAgentFactory(address(_rootBridgeAgentFactory)),
            "Incorrect RootPort RootBridgeAgentFactory"
        );
    }

    function check_coreRootRouter(RootPort _rootPort, CoreRootRouter _coreRootRouter) internal view {
        require(_rootPort.coreRootRouterAddress() == address(_coreRootRouter), "Incorrect RootPort CoreRootRouter");
    }

    /*//////////////////////////////////////////////////////////////
                        ADD BRIDGE AGENT HELPERS
    //////////////////////////////////////////////////////////////*/

    function check_addBridgeAgent(RootPort _rootPort, RootBridgeAgent _bridgeAgent, address _manager) internal view {
        _rootPort.check_isBridgeAgent(_bridgeAgent);
        _rootPort.check_bridgeAgentManager(_bridgeAgent, _manager);
    }

    function check_isBridgeAgent(RootPort _rootPort, RootBridgeAgent _bridgeAgent) internal view {
        require(_rootPort.isBridgeAgent(address(_bridgeAgent)), "Incorrect RootPort BridgeAgent");
    }

    function check_bridgeAgentManager(RootPort _rootPort, RootBridgeAgent _bridgeAgent, address _manager)
        internal
        view
    {
        require(_rootPort.getBridgeAgentManager(address(_bridgeAgent)) == _manager, "Incorrect RootPort BridgeAgent");
    }

    function check_bridgeAgents(RootPort _rootPort, uint256 index, RootBridgeAgent _bridgeAgent) internal view {
        require(_rootPort.bridgeAgents(index) == address(_bridgeAgent), "Incorrect RootPort BridgeAgent");
    }
}
