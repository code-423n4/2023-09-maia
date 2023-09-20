//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library CoreRootRouterHelper {
    using CoreRootRouterHelper for CoreRootRouter;

    function _deploy(CoreRootRouter, uint16 _rootChainId, RootPort _rootPort)
        internal
        returns (CoreRootRouter _coreRootRouter)
    {
        _coreRootRouter = new CoreRootRouter(_rootChainId, address(_rootPort));

        _coreRootRouter.check_deploy(_rootChainId, _rootPort, address(this));
    }

    function check_deploy(CoreRootRouter _coreRootRouter, uint256 _rootChainId, RootPort _rootPort, address _owner)
        internal
        view
    {
        _coreRootRouter.check_rootChainId(_rootChainId);
        _coreRootRouter.check_rootPort(_rootPort);
        _coreRootRouter.check_owner(_owner);
    }

    function check_rootChainId(CoreRootRouter _coreRootRouter, uint256 _rootChainId) internal view {
        require(_coreRootRouter.rootChainId() == _rootChainId, "Incorrect CoreRootRouter Root Local Chain Id");
    }

    function check_rootPort(CoreRootRouter _coreRootRouter, RootPort _rootPort) internal view {
        require(_coreRootRouter.rootPortAddress() == address(_rootPort), "Incorrect CoreRootRouter RootPort");
    }

    function check_owner(CoreRootRouter _coreRootRouter, address _owner) internal view {
        require(_coreRootRouter.owner() == _owner, "Incorrect CoreRootRouter Owner");
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(
        CoreRootRouter _coreRootRouter,
        RootBridgeAgent _coreRootBridgeAgent,
        ERC20hTokenRootFactory _hTokenFactory
    ) internal {
        _coreRootRouter.initialize(address(_coreRootBridgeAgent), address(_hTokenFactory));

        _coreRootRouter.check_init(_coreRootBridgeAgent, _hTokenFactory);
    }

    function check_init(
        CoreRootRouter _coreRootRouter,
        RootBridgeAgent _coreRootBridgeAgent,
        ERC20hTokenRootFactory _hTokenFactory
    ) internal view {
        _coreRootRouter.check_coreRootBridgeAgent(_coreRootBridgeAgent);
        _coreRootRouter.check_coreRootBridgeAgentExecutor(
            RootBridgeAgentExecutor(_coreRootBridgeAgent.bridgeAgentExecutorAddress())
        );
        _coreRootRouter.check_hTokenFactory(_hTokenFactory);
    }

    function check_coreRootBridgeAgent(CoreRootRouter _coreRootRouter, RootBridgeAgent _coreRootBridgeAgent)
        internal
        view
    {
        require(
            _coreRootRouter.bridgeAgentAddress() == address(_coreRootBridgeAgent),
            "Incorrect CoreRootRouter bridgeAgentAddress"
        );
    }

    function check_coreRootBridgeAgentExecutor(
        CoreRootRouter _coreRootRouter,
        RootBridgeAgentExecutor _rootBridgeAgentExecutor
    ) internal view {
        require(
            _coreRootRouter.bridgeAgentExecutorAddress() == address(_rootBridgeAgentExecutor),
            "Incorrect CoreRootRouter bridgeAgentExecutorAddress"
        );
    }

    function check_hTokenFactory(CoreRootRouter _coreRootRouter, ERC20hTokenRootFactory _hTokenFactory) internal view {
        require(
            _coreRootRouter.hTokenFactoryAddress() == address(_hTokenFactory),
            "Incorrect CoreRootRouter hTokenFactoryAddress"
        );
    }
}
