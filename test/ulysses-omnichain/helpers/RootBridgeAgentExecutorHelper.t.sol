//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library RootBridgeAgentExecutorHelper {
    using RootBridgeAgentExecutorHelper for RootBridgeAgentExecutor;

    /*//////////////////////////////////////////////////////////////
                            DEPLOY HELPERS
    //////////////////////////////////////////////////////////////*/

    function check_deploy(RootBridgeAgentExecutor _rootBridgeAgentExecutor, RootBridgeAgent _bridgeAgent)
        internal
        view
    {
        _rootBridgeAgentExecutor.check_bridgeAgent(_bridgeAgent);
    }

    function check_bridgeAgent(RootBridgeAgentExecutor _rootBridgeAgentExecutor, RootBridgeAgent _bridgeAgent)
        internal
        view
    {
        require(
            _rootBridgeAgentExecutor.owner() == address(_bridgeAgent),
            "Incorrect RootBridgeAgentExecutor Root Bridge Agent"
        );
    }
}
