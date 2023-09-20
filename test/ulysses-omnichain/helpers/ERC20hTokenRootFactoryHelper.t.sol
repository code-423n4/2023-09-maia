//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library ERC20hTokenRootFactoryHelper {
    using ERC20hTokenRootFactoryHelper for ERC20hTokenRootFactory;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function _deploy(ERC20hTokenRootFactory, uint16 _rootChainId, RootPort _rootPort)
        internal
        returns (ERC20hTokenRootFactory _hTokenRootFactory)
    {
        _hTokenRootFactory = new ERC20hTokenRootFactory(_rootChainId, address(_rootPort));

        _hTokenRootFactory.check_deploy(_rootChainId, _rootPort, address(this));
    }

    function check_deploy(
        ERC20hTokenRootFactory _hTokenRootFactory,
        uint256 _rootChainId,
        RootPort _rootPort,
        address _owner
    ) internal view {
        _hTokenRootFactory.check_rootChainId(_rootChainId);
        _hTokenRootFactory.check_rootPort(_rootPort);
        _hTokenRootFactory.check_owner(_owner);
    }

    function check_rootChainId(ERC20hTokenRootFactory _hTokenRootFactory, uint256 _rootChainId) internal view {
        require(
            _hTokenRootFactory.localChainId() == _rootChainId, "Incorrect ERC20hTokenRootFactory Root Local Chain Id"
        );
    }

    function check_rootPort(ERC20hTokenRootFactory _hTokenRootFactory, RootPort _rootPort) internal view {
        require(_hTokenRootFactory.rootPortAddress() == address(_rootPort), "Incorrect ERC20hTokenRootFactory RootPort");
    }

    function check_owner(ERC20hTokenRootFactory _hTokenRootFactory, address _owner) internal view {
        require(_hTokenRootFactory.owner() == _owner, "Incorrect ERC20hTokenRootFactory Owner");
    }

    /*//////////////////////////////////////////////////////////////
                            INIT HELPERS
    //////////////////////////////////////////////////////////////*/

    function _init(ERC20hTokenRootFactory _hTokenRootFactory, CoreRootRouter _coreRootRouter) internal {
        _hTokenRootFactory.initialize(address(_coreRootRouter));

        _hTokenRootFactory.check_init(_coreRootRouter);
    }

    function check_init(ERC20hTokenRootFactory _hTokenRootFactory, CoreRootRouter _coreRootRouter) internal view {
        _hTokenRootFactory.check_coreRootRouter(_coreRootRouter);
        _hTokenRootFactory.check_owner(address(0));
    }

    function check_coreRootRouter(ERC20hTokenRootFactory _hTokenRootFactory, CoreRootRouter _coreRootRouter)
        internal
        view
    {
        require(
            _hTokenRootFactory.coreRootRouterAddress() == address(_coreRootRouter),
            "Incorrect ERC20hTokenRootFactory CoreRootRouter"
        );
    }
}
