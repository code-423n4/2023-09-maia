//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./ImportHelper.sol";

library BaseBranchRouterHelper {
    using BaseBranchRouterHelper for BaseBranchRouter;

    function _deploy(BaseBranchRouter) internal returns (BaseBranchRouter _multicallRouter) {
        _multicallRouter = new BaseBranchRouter();

        _multicallRouter.check_deploy(address(this));
    }

    function check_deploy(BaseBranchRouter _multicallRouter, address _owner) internal view {
        _multicallRouter.check_owner(_owner);
    }

    function check_owner(BaseBranchRouter _multicallRouter, address _owner) internal view {
        require(_multicallRouter.owner() == _owner, "Incorrect BaseBranchRouter Owner");
    }
}
