//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import {LibZip} from "solady/utils/LibZip.sol";

import {MulticallRootRouter} from "@omni/MulticallRootRouter.sol";
import {MulticallRootRouterLibZip} from "@omni/MulticallRootRouterLibZip.sol";

import {MulticallRootRouterTest} from "./MulticallRootRouterTest.t.sol";

contract MulticallRootRouterZipTest is MulticallRootRouterTest {
    function setNewMulticallRootRouter() internal override {
        rootMulticallRouter =
            MulticallRootRouter(new MulticallRootRouterLibZip(rootChainId, address(rootPort), multicallAddress));
    }

    function encodeCalls(bytes memory data) internal pure override returns (bytes memory) {
        return LibZip.cdCompress(data);
    }
}
