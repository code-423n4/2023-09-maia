//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library ArbitrumBranchPortHelper {
    using ArbitrumBranchPortHelper for ArbitrumBranchPort;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _deploy(ArbitrumBranchPort, uint16 _rootChainId, RootPort _rootPort, address _owner)
        internal
        returns (ArbitrumBranchPort _arbitrumPort)
    {
        _arbitrumPort = new ArbitrumBranchPort(_rootChainId, address(_rootPort), _owner);

        _arbitrumPort.check_deploy(_rootChainId, _rootPort, _owner);
    }

    function check_deploy(ArbitrumBranchPort _arbitrumPort, uint256 _rootChainId, RootPort _rootPort, address _owner)
        internal
        view
    {
        _arbitrumPort.check_rootChainId(_rootChainId);
        _arbitrumPort.check_rootPort(_rootPort);
        _arbitrumPort.check_owner(_owner);
    }

    function check_rootChainId(ArbitrumBranchPort _arbitrumPort, uint256 _rootChainId) internal view {
        require(_arbitrumPort.localChainId() == _rootChainId, "Incorrect ArbitrumBranchPort Root Local Chain Id");
    }

    function check_rootPort(ArbitrumBranchPort _arbitrumPort, RootPort _rootPort) internal view {
        require(_arbitrumPort.rootPortAddress() == address(_rootPort), "Incorrect RootBridgeAgent RootPort");
    }

    function check_owner(ArbitrumBranchPort _arbitrumPort, address _owner) internal view {
        require(_arbitrumPort.owner() == _owner, "Incorrect ArbitrumBranchPort Owner");
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(
        ArbitrumBranchPort _arbitrumPort,
        ArbitrumCoreBranchRouter _arbitrumCoreBranchRouter,
        ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory
    ) internal {
        _arbitrumPort.initialize(address(_arbitrumCoreBranchRouter), address(_arbitrumBranchBridgeAgentFactory));

        _arbitrumPort.check_init(_arbitrumCoreBranchRouter, _arbitrumBranchBridgeAgentFactory);
    }

    function check_init(
        ArbitrumBranchPort _arbitrumPort,
        ArbitrumCoreBranchRouter _arbitrumCoreBranchRouter,
        ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory
    ) internal view {
        _arbitrumPort.check_arbitrumCoreBranchRouter(_arbitrumCoreBranchRouter);
        _arbitrumPort.check_arbitrumBranchBridgeAgentFactory(0, _arbitrumBranchBridgeAgentFactory);
        _arbitrumPort.check_isArbitrumBranchBridgeAgentFactory(_arbitrumBranchBridgeAgentFactory);
    }

    function check_arbitrumCoreBranchRouter(
        ArbitrumBranchPort _arbitrumPort,
        ArbitrumCoreBranchRouter _arbitrumCoreBranchRouter
    ) internal view {
        require(
            _arbitrumPort.coreBranchRouterAddress() == address(_arbitrumCoreBranchRouter),
            "Incorrect ArbitrumBranchPort ArbitrumCoreBranchRouter"
        );
    }

    function check_arbitrumBranchBridgeAgentFactory(
        ArbitrumBranchPort _arbitrumPort,
        uint256 index,
        ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory
    ) internal view {
        require(
            _arbitrumPort.bridgeAgentFactories(index) == address(_arbitrumBranchBridgeAgentFactory),
            "Incorrect ArbitrumBranchPort ArbitrumBranchBridgeAgentFactory index"
        );
    }

    function check_isArbitrumBranchBridgeAgentFactory(
        ArbitrumBranchPort _arbitrumPort,
        ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory
    ) internal view {
        require(
            _arbitrumPort.isBridgeAgentFactory(address(_arbitrumBranchBridgeAgentFactory)),
            "Incorrect ArbitrumBranchPort is ArbitrumBranchBridgeAgentFactory"
        );
    }
}
