//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

//TEST
import {LzForkTest} from "../../test-utils/fork/LzForkTest.t.sol";

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {stdError} from "forge-std/StdError.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

//COMPONENTS
import {ILayerZeroEndpoint} from "@omni/interfaces/ILayerZeroEndpoint.sol";
import {IBranchRouter} from "@omni/interfaces/IBranchRouter.sol";

import {RootPort} from "@omni/RootPort.sol";
import {ArbitrumBranchPort} from "@omni/ArbitrumBranchPort.sol";
import {BranchPort} from "@omni/BranchPort.sol";

import {RootBridgeAgent} from "@omni/RootBridgeAgent.sol";
import {RootBridgeAgentExecutor} from "@omni/RootBridgeAgentExecutor.sol";
import {BranchBridgeAgent} from "@omni/BranchBridgeAgent.sol";
import {BranchBridgeAgentExecutor} from "@omni/BranchBridgeAgentExecutor.sol";
import {ArbitrumBranchBridgeAgent} from "@omni/ArbitrumBranchBridgeAgent.sol";

import {BaseBranchRouter} from "@omni/BaseBranchRouter.sol";
import {MulticallRootRouter} from "@omni/MulticallRootRouter.sol";
import {CoreRootRouter} from "@omni/CoreRootRouter.sol";
import {CoreBranchRouter} from "@omni/CoreBranchRouter.sol";
import {ArbitrumCoreBranchRouter} from "@omni/ArbitrumCoreBranchRouter.sol";

import {ERC20hTokenBranch} from "@omni/token/ERC20hTokenBranch.sol";
import {ERC20hTokenRoot} from "@omni/token/ERC20hTokenRoot.sol";
import {ERC20hTokenRootFactory} from "@omni/factories/ERC20hTokenRootFactory.sol";
import {ERC20hTokenBranchFactory} from "@omni/factories/ERC20hTokenBranchFactory.sol";
import {RootBridgeAgentFactory} from "@omni/factories/RootBridgeAgentFactory.sol";
import {BranchBridgeAgentFactory} from "@omni/factories/BranchBridgeAgentFactory.sol";
import {ArbitrumBranchBridgeAgentFactory} from "@omni/factories/ArbitrumBranchBridgeAgentFactory.sol";

//UTILS
import {BridgeAgentConstants} from "@omni/interfaces/BridgeAgentConstants.sol";
import {Deposit, DepositMultipleInput, DepositInput} from "@omni/interfaces/IBranchBridgeAgent.sol";
import {Settlement, GasParams} from "@omni/interfaces/IRootBridgeAgent.sol";

import {MockRootBridgeAgent, DepositParams, DepositMultipleParams} from "../mocks/MockRootBridgeAgent.t.sol";
import {WETH9 as WETH} from "../mocks/WETH9.sol";
import {Multicall2} from "../mocks/Multicall2.sol";
