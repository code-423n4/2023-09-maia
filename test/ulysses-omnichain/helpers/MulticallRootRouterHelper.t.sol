//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library MulticallRootRouterHelper {
    using MulticallRootRouterHelper for MulticallRootRouter;

    function _deploy(MulticallRootRouter, uint16 _rootChainId, RootPort _rootPort, address _multicallAddress)
        internal
        returns (MulticallRootRouter _rootMulticallRouter)
    {
        _rootMulticallRouter = new MulticallRootRouter(_rootChainId, address(_rootPort), _multicallAddress);

        _rootMulticallRouter.check_deploy(_rootChainId, _rootPort, address(this), _multicallAddress);
    }

    function check_deploy(
        MulticallRootRouter _rootMulticallRouter,
        uint256 _rootChainId,
        RootPort _rootPort,
        address _owner,
        address _multicallAddress
    ) internal view {
        _rootMulticallRouter.check_rootChainId(_rootChainId);
        _rootMulticallRouter.check_rootPort(_rootPort);
        _rootMulticallRouter.check_owner(_owner);
        _rootMulticallRouter.check_multicallAddress(_multicallAddress);
    }

    function check_rootChainId(MulticallRootRouter _rootMulticallRouter, uint256 _rootChainId) internal view {
        require(
            _rootMulticallRouter.localChainId() == _rootChainId, "Incorrect MulticallRootRouter Root Local Chain Id"
        );
    }

    function check_rootPort(MulticallRootRouter _rootMulticallRouter, RootPort _rootPort) internal view {
        require(_rootMulticallRouter.localPortAddress() == address(_rootPort), "Incorrect MulticallRootRouter RootPort");
    }

    function check_owner(MulticallRootRouter _rootMulticallRouter, address _owner) internal view {
        require(_rootMulticallRouter.owner() == _owner, "Incorrect MulticallRootRouter Owner");
    }

    function check_multicallAddress(MulticallRootRouter _rootMulticallRouter, address _multicallAddress)
        internal
        view
    {
        require(_rootMulticallRouter.multicallAddress() == _multicallAddress, "Incorrect MulticallRootRouter Owner");
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(MulticallRootRouter _rootMulticallRouter, RootBridgeAgent _coreRootBridgeAgent) internal {
        _rootMulticallRouter.initialize(address(_coreRootBridgeAgent));

        _rootMulticallRouter.check_init(_coreRootBridgeAgent);
    }

    function check_init(MulticallRootRouter _rootMulticallRouter, RootBridgeAgent _coreRootBridgeAgent) internal view {
        _rootMulticallRouter.check_coreRootBridgeAgent(_coreRootBridgeAgent);
        _rootMulticallRouter.check_coreRootBridgeAgentExecutor(
            RootBridgeAgentExecutor(_coreRootBridgeAgent.bridgeAgentExecutorAddress())
        );
    }

    function check_coreRootBridgeAgent(MulticallRootRouter _rootMulticallRouter, RootBridgeAgent _coreRootBridgeAgent)
        internal
        view
    {
        require(
            _rootMulticallRouter.bridgeAgentAddress() == address(_coreRootBridgeAgent),
            "Incorrect MulticallRootRouter bridgeAgentAddress"
        );
    }

    function check_coreRootBridgeAgentExecutor(
        MulticallRootRouter _rootMulticallRouter,
        RootBridgeAgentExecutor _rootBridgeAgentExecutor
    ) internal view {
        require(
            _rootMulticallRouter.bridgeAgentExecutorAddress() == address(_rootBridgeAgentExecutor),
            "Incorrect MulticallRootRouter bridgeAgentExecutorAddress"
        );
    }
}
