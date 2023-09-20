//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library ArbitrumBranchBridgeAgentFactoryHelper {
    using ArbitrumBranchBridgeAgentFactoryHelper for ArbitrumBranchBridgeAgentFactory;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _deploy(
        ArbitrumBranchBridgeAgentFactory,
        uint16 _rootChainId,
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        ArbitrumCoreBranchRouter _arbitrumCoreBranchRouter,
        ArbitrumBranchPort _arbitrumPort,
        address _owner
    ) internal returns (ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory) {
        _arbitrumBranchBridgeAgentFactory = new ArbitrumBranchBridgeAgentFactory(
            _rootChainId,
            address(_rootBridgeAgentFactory),
            address(_arbitrumCoreBranchRouter),
            address(_arbitrumPort),
            _owner
        );

        _arbitrumBranchBridgeAgentFactory.check_deploy(
            _rootChainId, _rootBridgeAgentFactory, _arbitrumCoreBranchRouter, _arbitrumPort, _owner
        );
    }

    function check_deploy(
        ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory,
        uint16 _rootChainId,
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        ArbitrumCoreBranchRouter _arbitrumCoreBranchRouter,
        ArbitrumBranchPort _arbitrumPort,
        address _owner
    ) internal view {
        _arbitrumBranchBridgeAgentFactory.check_rootChainId(_rootChainId);
        _arbitrumBranchBridgeAgentFactory.check_rootBridgeAgentFactory(_rootBridgeAgentFactory);
        _arbitrumBranchBridgeAgentFactory.check_lzEndpointAddress(address(0));
        _arbitrumBranchBridgeAgentFactory.check_arbitrumCoreBranchRouter(_arbitrumCoreBranchRouter);
        _arbitrumBranchBridgeAgentFactory.check_arbitrumPort(_arbitrumPort);
        _arbitrumBranchBridgeAgentFactory.check_owner(_owner);
    }

    function check_rootChainId(ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory, uint256 _rootChainId)
        internal
        view
    {
        require(
            _arbitrumBranchBridgeAgentFactory.localChainId() == _rootChainId,
            "Incorrect ArbitrumBranchBridgeAgentFactory Root Local Chain Id"
        );
    }

    function check_rootBridgeAgentFactory(
        ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory,
        RootBridgeAgentFactory _rootBridgeAgentFactory
    ) internal view {
        require(
            _arbitrumBranchBridgeAgentFactory.rootBridgeAgentFactoryAddress() == address(_rootBridgeAgentFactory),
            "Incorrect ArbitrumBranchBridgeAgentFactory RootBridgeAgentFactory"
        );
    }

    function check_lzEndpointAddress(
        ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory,
        address _lzEndpointAddress
    ) internal view {
        require(
            _arbitrumBranchBridgeAgentFactory.lzEndpointAddress() == _lzEndpointAddress,
            "Incorrect ArbitrumBranchBridgeAgentFactory lzEndpointAddress"
        );
    }

    function check_arbitrumCoreBranchRouter(
        ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory,
        ArbitrumCoreBranchRouter _arbitrumCoreBranchRouter
    ) internal view {
        require(
            _arbitrumBranchBridgeAgentFactory.localCoreBranchRouterAddress() == address(_arbitrumCoreBranchRouter),
            "Incorrect ArbitrumBranchBridgeAgentFactory ArbitrumCoreBranchRouter"
        );
    }

    function check_arbitrumPort(
        ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory,
        ArbitrumBranchPort _arbitrumPort
    ) internal view {
        require(
            _arbitrumBranchBridgeAgentFactory.localPortAddress() == address(_arbitrumPort),
            "Incorrect ArbitrumBranchBridgeAgentFactory ArbitrumBranchPort"
        );
    }

    function check_owner(ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory, address _owner)
        internal
        view
    {
        require(_arbitrumBranchBridgeAgentFactory.owner() == _owner, "Incorrect ArbitrumBranchBridgeAgentFactory Owner");
    }
}
