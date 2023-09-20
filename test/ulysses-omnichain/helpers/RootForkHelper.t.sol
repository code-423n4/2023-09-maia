//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

import {ArbitrumBranchBridgeAgentFactoryHelper} from "./ArbitrumBranchBridgeAgentFactoryHelper.t.sol";
import {ArbitrumBranchPortHelper} from "./ArbitrumBranchPortHelper.t.sol";
import {ArbitrumCoreBranchRouterHelper} from "./ArbitrumCoreBranchRouterHelper.t.sol";
import {BaseBranchRouterHelper} from "./BaseBranchRouterHelper.t.sol";
import {CoreRootRouterHelper} from "./CoreRootRouterHelper.t.sol";
import {ERC20hTokenRootFactoryHelper} from "./ERC20hTokenRootFactoryHelper.t.sol";
import {MulticallRootRouterHelper} from "./MulticallRootRouterHelper.t.sol";
import {RootBridgeAgentFactoryHelper} from "./RootBridgeAgentFactoryHelper.t.sol";
import {RootPortHelper} from "./RootPortHelper.t.sol";

library RootForkHelper {
    using ArbitrumBranchBridgeAgentFactoryHelper for ArbitrumBranchBridgeAgentFactory;
    using ArbitrumBranchPortHelper for ArbitrumBranchPort;
    using ArbitrumCoreBranchRouterHelper for ArbitrumCoreBranchRouter;
    using BaseBranchRouterHelper for BaseBranchRouter;
    using ERC20hTokenRootFactoryHelper for ERC20hTokenRootFactory;
    using MulticallRootRouterHelper for MulticallRootRouter;
    using RootBridgeAgentFactoryHelper for RootBridgeAgentFactory;
    using RootPortHelper for RootPort;
    using CoreRootRouterHelper for CoreRootRouter;

    function _deployRoot(uint16 _rootChainId, address _lzEndpointAddress, address _multicallAddress)
        internal
        returns (
            RootPort _rootPort,
            RootBridgeAgentFactory _rootBridgeAgentFactory,
            ERC20hTokenRootFactory _hTokenRootFactory,
            CoreRootRouter _coreRootRouter,
            MulticallRootRouter _rootMulticallRouter
        )
    {
        _rootPort = _rootPort._deploy(_rootChainId);

        _rootBridgeAgentFactory = _rootBridgeAgentFactory._deploy(_rootChainId, _lzEndpointAddress, _rootPort);

        _hTokenRootFactory = _hTokenRootFactory._deploy(_rootChainId, _rootPort);

        _coreRootRouter = _coreRootRouter._deploy(_rootChainId, _rootPort);

        _rootMulticallRouter = _rootMulticallRouter._deploy(_rootChainId, _rootPort, _multicallAddress);
    }

    function _initRoot(
        RootPort _rootPort,
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        ERC20hTokenRootFactory _hTokenRootFactory,
        CoreRootRouter _coreRootRouter,
        MulticallRootRouter _rootMulticallRouter
    ) internal returns (RootBridgeAgent _coreRootBridgeAgent, RootBridgeAgent _multicallRootBridgeAgent) {
        _rootPort._init(_rootBridgeAgentFactory, _coreRootRouter);

        _hTokenRootFactory._init(_coreRootRouter);

        _coreRootBridgeAgent = _rootBridgeAgentFactory._createRootBridgeAgent(address(_coreRootRouter));

        _multicallRootBridgeAgent = _rootBridgeAgentFactory._createRootBridgeAgent(address(_rootMulticallRouter));

        _coreRootRouter._init(_coreRootBridgeAgent, _hTokenRootFactory);

        _rootMulticallRouter._init(_multicallRootBridgeAgent);
    }

    function _deployLocalBranch(
        uint16 _rootChainId,
        RootPort _rootPort,
        address _owner,
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        RootBridgeAgent _coreRootBridgeAgent
    )
        internal
        returns (
            ArbitrumBranchPort _arbitrumPort,
            BaseBranchRouter _arbitrumMulticallRouter,
            ArbitrumCoreBranchRouter _arbitrumCoreBranchRouter,
            ArbitrumBranchBridgeAgentFactory _arbitrumBranchBridgeAgentFactory,
            ArbitrumBranchBridgeAgent _arbitrumCoreBranchBridgeAgent
        )
    {
        _arbitrumPort = _arbitrumPort._deploy(_rootChainId, _rootPort, _owner);

        _arbitrumMulticallRouter = _arbitrumMulticallRouter._deploy();

        _arbitrumCoreBranchRouter = _arbitrumCoreBranchRouter._deploy();

        _arbitrumBranchBridgeAgentFactory = _arbitrumBranchBridgeAgentFactory._deploy(
            _rootChainId, _rootBridgeAgentFactory, _arbitrumCoreBranchRouter, _arbitrumPort, _owner
        );

        _arbitrumPort._init(_arbitrumCoreBranchRouter, _arbitrumBranchBridgeAgentFactory);

        _arbitrumBranchBridgeAgentFactory.initialize(address(_coreRootBridgeAgent));
        _arbitrumCoreBranchBridgeAgent = ArbitrumBranchBridgeAgent(payable(_arbitrumPort.bridgeAgents(0)));

        _arbitrumCoreBranchRouter.initialize(address(_arbitrumCoreBranchBridgeAgent));
    }
}
