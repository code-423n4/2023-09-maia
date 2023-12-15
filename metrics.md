
NB: This report has been created using [Solidity-Metrics](https://github.com/Consensys/solidity-metrics)
<sup>

# Solidity Metrics for Scoping for code-423n4 - 2023-09-maia

## Table of contents

- [Scope](#t-scope)
    - [Source Units in Scope](#t-source-Units-in-Scope)
    - [Out of Scope](#t-out-of-scope)
        - [Excluded Source Units](#t-out-of-scope-excluded-source-units)
        - [Duplicate Source Units](#t-out-of-scope-duplicate-source-units)
        - [Doppelganger Contracts](#t-out-of-scope-doppelganger-contracts)
- [Report Overview](#t-report)
    - [Risk Summary](#t-risk)
    - [Source Lines](#t-source-lines)
    - [Inline Documentation](#t-inline-documentation)
    - [Components](#t-components)
    - [Exposed Functions](#t-exposed-functions)
    - [StateVariables](#t-statevariables)
    - [Capabilities](#t-capabilities)
    - [Dependencies](#t-package-imports)
    - [Totals](#t-totals)

## <span id=t-scope>Scope</span>

This section lists files that are in scope for the metrics report.

- **Project:** `Scoping for code-423n4 - 2023-09-maia`
- **Included Files:** 
72
- **Excluded Files:** 
0
- **Project analysed:** `https://github.com/code-423n4/2023-09-maia` (`@main`)

### <span id=t-source-Units-in-Scope>Source Units in Scope</span>

Source Units Analyzed: **`72`**<br>
Source Units in Scope: **`72`** (**100%**)

| Type | File   | Logic Contracts | Interfaces | Lines | nLines | nSLOC | Comment Lines | Complex. Score | Capabilities |
| ---- | ------ | --------------- | ---------- | ----- | ------ | ----- | ------------- | -------------- | ------------ |
| 📝📚 | /src/ArbitrumBranchBridgeAgent.sol | 2 | **** | 129 | 126 | 53 | 58 | 53 | **<abbr title='Payable Functions'>💰</abbr><abbr title='create/create2'>🌀</abbr>** |
| 📝 | /src/ArbitrumBranchPort.sol | 1 | **** | 138 | 122 | 44 | 51 | 47 | **<abbr title='Unchecked Blocks'>Σ</abbr>** |
| 📝 | /src/ArbitrumCoreBranchRouter.sol | 1 | **** | 172 | 146 | 69 | 71 | 65 | **<abbr title='Payable Functions'>💰</abbr>** |
| 📝 | /src/BaseBranchRouter.sol | 1 | **** | 218 | 192 | 91 | 65 | 93 | **<abbr title='Payable Functions'>💰</abbr><abbr title='Unchecked Blocks'>Σ</abbr>** |
| 📝📚 | /src/BranchBridgeAgent.sol | 2 | **** | 957 | 863 | 459 | 257 | 415 | **<abbr title='Payable Functions'>💰</abbr><abbr title='create/create2'>🌀</abbr><abbr title='Unchecked Blocks'>Σ</abbr>** |
| 📝📚 | /src/BranchBridgeAgentExecutor.sol | 2 | **** | 129 | 121 | 53 | 53 | 72 | **<abbr title='Payable Functions'>💰</abbr><abbr title='create/create2'>🌀</abbr>** |
| 📝 | /src/BranchPort.sol | 1 | **** | 572 | 518 | 234 | 170 | 215 | **<abbr title='Payable Functions'>💰</abbr><abbr title='Unchecked Blocks'>Σ</abbr>** |
| 📝 | /src/CoreBranchRouter.sol | 1 | **** | 328 | 306 | 125 | 129 | 122 | **<abbr title='Payable Functions'>💰</abbr>** |
| 📝 | /src/CoreRootRouter.sol | 1 | **** | 531 | 441 | 180 | 192 | 224 | **<abbr title='Payable Functions'>💰</abbr>** |
| 📝 | /src/MulticallRootRouter.sol | 1 | **** | 607 | 571 | 287 | 203 | 200 | **<abbr title='Payable Functions'>💰</abbr><abbr title='Unchecked Blocks'>Σ</abbr>** |
| 📝 | /src/MulticallRootRouterLibZip.sol | 1 | **** | 40 | 40 | 12 | 22 | 5 | **** |
| 📝 | /src/RootBridgeAgent.sol | 1 | **** | 1238 | 1136 | 608 | 334 | 474 | **<abbr title='Payable Functions'>💰</abbr><abbr title='Unchecked Blocks'>Σ</abbr>** |
| 📝📚 | /src/RootBridgeAgentExecutor.sol | 2 | **** | 349 | 317 | 166 | 120 | 200 | **<abbr title='Payable Functions'>💰</abbr><abbr title='create/create2'>🌀</abbr><abbr title='Unchecked Blocks'>Σ</abbr>** |
| 📝 | /src/RootPort.sol | 1 | **** | 579 | 498 | 246 | 140 | 279 | **<abbr title='Payable Functions'>💰</abbr><abbr title='Uses Hash-Functions'>🧮</abbr><abbr title='Unchecked Blocks'>Σ</abbr>** |
| 📝 | /src/VirtualAccount.sol | 1 | **** | 168 | 158 | 84 | 39 | 95 | **<abbr title='Uses Assembly'>🖥</abbr><abbr title='Payable Functions'>💰</abbr><abbr title='Unchecked Blocks'>Σ</abbr>** |
| 📝 | /src/factories/ArbitrumBranchBridgeAgentFactory.sol | 1 | **** | 100 | 96 | 48 | 35 | 23 | **** |
| 📝 | /src/factories/BranchBridgeAgentFactory.sol | 1 | **** | 141 | 137 | 73 | 43 | 40 | **** |
| 📝 | /src/factories/ERC20hTokenBranchFactory.sol | 1 | **** | 116 | 112 | 47 | 42 | 71 | **<abbr title='create/create2'>🌀</abbr>** |
| 📝 | /src/factories/ERC20hTokenRootFactory.sol | 1 | **** | 104 | 100 | 43 | 42 | 39 | **<abbr title='create/create2'>🌀</abbr>** |
| 📝 | /src/factories/RootBridgeAgentFactory.sol | 1 | **** | 60 | 60 | 26 | 23 | 24 | **<abbr title='create/create2'>🌀</abbr>** |
| 📝 | /src/interfaces/BridgeAgentConstants.sol | 1 | **** | 58 | 58 | 23 | 11 | 21 | **** |
|  | /src/interfaces/BridgeAgentStructs.sol | **** | **** | 97 | 97 | 77 | 56 | **** | **** |
| 🔍 | /src/interfaces/IArbitrumBranchPort.sol | **** | 1 | 47 | 28 | 4 | 30 | 7 | **** |
| 🔍 | /src/interfaces/IBranchBridgeAgent.sol | **** | 1 | 356 | 96 | 14 | 231 | 69 | **<abbr title='Payable Functions'>💰</abbr>** |
| 🔍 | /src/interfaces/IBranchBridgeAgentFactory.sol | **** | 1 | 29 | 24 | 3 | 19 | 3 | **** |
| 🔍 | /src/interfaces/IBranchPort.sol | **** | 1 | 256 | 23 | 3 | 150 | 47 | **** |
| 🔍 | /src/interfaces/IBranchRouter.sol | **** | 1 | 116 | 27 | 11 | 68 | 39 | **<abbr title='Payable Functions'>💰</abbr>** |
| 🔍 | /src/interfaces/ICoreBranchRouter.sol | **** | 1 | 55 | 23 | 4 | 39 | 11 | **<abbr title='Payable Functions'>💰</abbr>** |
| 🔍 | /src/interfaces/IERC20hTokenBranch.sol | **** | 1 | 29 | 22 | 3 | 21 | 5 | **** |
| 🔍 | /src/interfaces/IERC20hTokenBranchFactory.sol | **** | 1 | 35 | 24 | 4 | 21 | 3 | **** |
| 🔍 | /src/interfaces/IERC20hTokenRoot.sol | **** | 1 | 58 | 19 | 3 | 40 | 11 | **** |
| 🔍 | /src/interfaces/IERC20hTokenRootFactory.sol | **** | 1 | 33 | 24 | 4 | 20 | 3 | **** |
| 🔍 | /src/interfaces/ILayerZeroEndpoint.sol | **** | 1 | 110 | 15 | 4 | 51 | 36 | **<abbr title='Payable Functions'>💰</abbr>** |
| 🔍 | /src/interfaces/ILayerZeroReceiver.sol | **** | 1 | 12 | 11 | 3 | 6 | 3 | **** |
| 🔍 | /src/interfaces/ILayerZeroUserApplicationConfig.sol | **** | 1 | 25 | 11 | 3 | 13 | 9 | **** |
| 🔍 | /src/interfaces/IMulticall2.sol | **** | 1 | 21 | 20 | 11 | 5 | 3 | **** |
| 🔍 | /src/interfaces/IPortStrategy.sol | **** | 1 | 30 | 23 | 3 | 20 | 3 | **** |
| 🔍 | /src/interfaces/IRootBridgeAgent.sol | **** | 1 | 378 | 104 | 13 | 241 | 54 | **<abbr title='Payable Functions'>💰</abbr>** |
| 🔍 | /src/interfaces/IRootBridgeAgentFactory.sol | **** | 1 | 17 | 16 | 3 | 11 | 3 | **** |
| 🔍 | /src/interfaces/IRootPort.sol | **** | 2 | 424 | 20 | 6 | 242 | 86 | **<abbr title='Payable Functions'>💰</abbr>** |
| 🔍 | /src/interfaces/IRootRouter.sol | **** | 1 | 99 | 25 | 4 | 61 | 36 | **<abbr title='Payable Functions'>💰</abbr>** |
| 🔍 | /src/interfaces/IVirtualAccount.sol | **** | 1 | 82 | 32 | 13 | 47 | 20 | **<abbr title='Payable Functions'>💰</abbr>** |
| 📝 | /src/token/ERC20hTokenBranch.sol | 1 | **** | 38 | 38 | 23 | 8 | 21 | **** |
| 📝 | /src/token/ERC20hTokenRoot.sol | 1 | **** | 73 | 73 | 32 | 30 | 28 | **** |
| 🎨 | /test/test-utils/fork/LzForkTest.t.sol | 1 | **** | 697 | 668 | 302 | 231 | 292 | **<abbr title='Uses Assembly'>🖥</abbr><abbr title='Uses Hash-Functions'>🧮</abbr>** |
| 🔍 | /test/test-utils/fork/interfaces/ILayerZeroEndpoint.sol | **** | 1 | 87 | 15 | 4 | 51 | 36 | **<abbr title='Payable Functions'>💰</abbr>** |
| 🔍 | /test/test-utils/fork/interfaces/ILayerZeroUserApplicationConfig.sol | **** | 1 | 25 | 11 | 3 | 13 | 9 | **** |
| 📝 | /test/ulysses-omnichain/ArbitrumBranchTest.t.sol | 1 | **** | 1008 | 902 | 556 | 119 | 957 | **<abbr title='Payable Functions'>💰</abbr><abbr title='Uses Hash-Functions'>🧮</abbr><abbr title='create/create2'>🌀</abbr>** |
| 📝 | /test/ulysses-omnichain/BranchBridgeAgentTest.t.sol | 1 | **** | 955 | 898 | 553 | 125 | 831 | **<abbr title='Payable Functions'>💰</abbr><abbr title='Uses Hash-Functions'>🧮</abbr><abbr title='create/create2'>🌀</abbr>** |
| 📝 | /test/ulysses-omnichain/CoreRootBridgeAgentTest.t.sol | 1 | **** | 555 | 418 | 233 | 60 | 522 | **<abbr title='create/create2'>🌀</abbr>** |
| 📝 | /test/ulysses-omnichain/MulticallRootBridgeAgentTest.t.sol | 1 | **** | 665 | 506 | 291 | 60 | 623 | **<abbr title='Uses Hash-Functions'>🧮</abbr><abbr title='create/create2'>🌀</abbr>** |
| 📝 | /test/ulysses-omnichain/MulticallRootRouterTest.t.sol | 1 | **** | 1444 | 994 | 579 | 149 | 1382 | **<abbr title='Uses Hash-Functions'>🧮</abbr><abbr title='create/create2'>🌀</abbr>** |
| 📝 | /test/ulysses-omnichain/MulticallRootRouterZippedTest.t.sol | 1 | **** | 20 | 20 | 14 | 1 | 17 | **<abbr title='create/create2'>🌀</abbr>** |
| 📝 | /test/ulysses-omnichain/RootBridgeAgentDecodeTest.t.sol | 1 | **** | 84 | 78 | 62 | 2 | 123 | **<abbr title='create/create2'>🌀</abbr>** |
| 📝 | /test/ulysses-omnichain/RootForkTest.t.sol | 2 | **** | 2958 | 2857 | 1659 | 444 | 1981 | **<abbr title='Payable Functions'>💰</abbr><abbr title='Initiates ETH Value Transfer'>📤</abbr><abbr title='Uses Hash-Functions'>🧮</abbr><abbr title='create/create2'>🌀</abbr>** |
| 📝 | /test/ulysses-omnichain/RootTest.t.sol | 2 | **** | 1814 | 1770 | 1057 | 253 | 1760 | **<abbr title='Payable Functions'>💰</abbr><abbr title='Uses Hash-Functions'>🧮</abbr><abbr title='create/create2'>🌀</abbr>** |
| 📚 | /test/ulysses-omnichain/helpers/ArbitrumBranchBridgeAgentFactoryHelper.t.sol | 1 | **** | 106 | 74 | 58 | 4 | 38 | **<abbr title='create/create2'>🌀</abbr>** |
| 📚 | /test/ulysses-omnichain/helpers/ArbitrumBranchPortHelper.t.sol | 1 | **** | 97 | 73 | 50 | 7 | 40 | **<abbr title='create/create2'>🌀</abbr>** |
| 📚 | /test/ulysses-omnichain/helpers/ArbitrumCoreBranchRouterHelper.t.sol | 1 | **** | 21 | 21 | 14 | 1 | 16 | **<abbr title='create/create2'>🌀</abbr>** |
| 📚 | /test/ulysses-omnichain/helpers/BaseBranchRouterHelper.t.sol | 1 | **** | 22 | 22 | 15 | 1 | 17 | **<abbr title='create/create2'>🌀</abbr>** |
| 📚 | /test/ulysses-omnichain/helpers/CoreRootRouterHelper.t.sol | 1 | **** | 91 | 71 | 52 | 4 | 43 | **<abbr title='create/create2'>🌀</abbr>** |
| 📚 | /test/ulysses-omnichain/helpers/ERC20hTokenRootFactoryHelper.t.sol | 1 | **** | 71 | 60 | 39 | 7 | 34 | **<abbr title='create/create2'>🌀</abbr>** |
|  | /test/ulysses-omnichain/helpers/ImportHelper.sol | **** | **** | 48 | 48 | 35 | 4 | **** | **** |
| 📚 | /test/ulysses-omnichain/helpers/MulticallRootRouterHelper.t.sol | 1 | **** | 88 | 70 | 51 | 4 | 41 | **<abbr title='create/create2'>🌀</abbr>** |
| 📚 | /test/ulysses-omnichain/helpers/RootBridgeAgentExecutorHelper.t.sol | 1 | **** | 29 | 23 | 14 | 4 | 5 | **** |
| 📚 | /test/ulysses-omnichain/helpers/RootBridgeAgentFactoryHelper.t.sol | 1 | **** | 85 | 71 | 50 | 7 | 37 | **<abbr title='create/create2'>🌀</abbr>** |
| 📚 | /test/ulysses-omnichain/helpers/RootBridgeAgentHelper.t.sol | 1 | **** | 54 | 47 | 32 | 4 | 21 | **** |
| 📚 | /test/ulysses-omnichain/helpers/RootForkHelper.t.sol | 1 | **** | 101 | 71 | 49 | 1 | 26 | **** |
| 📚 | /test/ulysses-omnichain/helpers/RootPortHelper.t.sol | 1 | **** | 107 | 91 | 60 | 10 | 50 | **<abbr title='create/create2'>🌀</abbr>** |
| 📝 | /test/ulysses-omnichain/mocks/MockRootBridgeAgent.t.sol | 1 | **** | 145 | 141 | 112 | 7 | 115 | **<abbr title='Unchecked Blocks'>Σ</abbr>** |
| 📝 | /test/ulysses-omnichain/mocks/Multicall2.sol | 1 | **** | 89 | 83 | 62 | 4 | 68 | **** |
| 📝 | /test/ulysses-omnichain/mocks/WETH9.sol | 1 | **** | 754 | 754 | 44 | 691 | 33 | **<abbr title='Payable Functions'>💰</abbr><abbr title='Initiates ETH Value Transfer'>📤</abbr>** |
| 📝📚🔍🎨 | **Totals** | **54** | **23** | **21374**  | **17770** | **9269** | **5798** | **12394** | **<abbr title='Uses Assembly'>🖥</abbr><abbr title='Payable Functions'>💰</abbr><abbr title='Initiates ETH Value Transfer'>📤</abbr><abbr title='Uses Hash-Functions'>🧮</abbr><abbr title='create/create2'>🌀</abbr><abbr title='Unchecked Blocks'>Σ</abbr>** |

##### <span>Legend</span>
<ul>
<li> <b>Lines</b>: total lines of the source unit </li>
<li> <b>nLines</b>: normalized lines of the source unit (e.g. normalizes functions spanning multiple lines) </li>
<li> <b>nSLOC</b>: normalized source lines of code (only source-code lines; no comments, no blank lines) </li>
<li> <b>Comment Lines</b>: lines containing single or block comments </li>
<li> <b>Complexity Score</b>: a custom complexity score derived from code statements that are known to introduce code complexity (branches, loops, calls, external interfaces, ...) </li>
</ul>

### <span id=t-out-of-scope>Out of Scope</span>

### <span id=t-out-of-scope-excluded-source-units>Excluded Source Units</span>
Source Units Excluded: **`0`**

| File |
| ---- |
| None |

## <span id=t-report>Report</span>

## Overview

The analysis finished with **`0`** errors and **`1`** duplicate files.





### <span style="font-weight: bold" id=t-inline-documentation>Inline Documentation</span>

- **Comment-to-Source Ratio:** On average there are`1.98` code lines per comment (lower=better).
- **ToDo's:** `11`

### <span style="font-weight: bold" id=t-components>Components</span>

| 📝Contracts   | 📚Libraries | 🔍Interfaces | 🎨Abstract |
| ------------- | ----------- | ------------ | ---------- |
| 37 | 16  | 23  | 1 |

### <span style="font-weight: bold" id=t-exposed-functions>Exposed Functions</span>

This section lists functions that are explicitly declared public or payable. Please note that getter methods for public stateVars are not included.

| 🌐Public   | 💰Payable |
| ---------- | --------- |
| 532 | 108  |

| External   | Internal | Private | Pure | View |
| ---------- | -------- | ------- | ---- | ---- |
| 336 | 634  | 24 | 13 | 171 |

### <span style="font-weight: bold" id=t-statevariables>StateVariables</span>

| Total      | 🌐Public  |
| ---------- | --------- |
| 501  | 142 |

### <span style="font-weight: bold" id=t-capabilities>Capabilities</span>

| Solidity Versions observed | 🧪 Experimental Features | 💰 Can Receive Funds | 🖥 Uses Assembly | 💣 Has Destroyable Contracts |
| -------------------------- | ------------------------ | -------------------- | ---------------- | ---------------------------- |
| `^0.8.0`<br/>`>=0.5.0`<br/>`>=0.8.0 <0.9.0`<br/>`^0.8.16`<br/>`>=0.4.22 <0.9` |  | `yes` | `yes` <br/>(5 asm blocks) | **** |

| 📤 Transfers ETH | ⚡ Low-Level Calls | 👥 DelegateCall | 🧮 Uses Hash Functions | 🔖 ECRecover | 🌀 New/Create/Create2 |
| ---------------- | ----------------- | --------------- | ---------------------- | ------------ | --------------------- |
| `yes` | **** | **** | `yes` | **** | `yes`<br>→ `NewContract:ArbitrumBranchBridgeAgent`<br/>→ `NewContract:BranchBridgeAgent`<br/>→ `NewContract:BranchBridgeAgentExecutor`<br/>→ `NewContract:RootBridgeAgentExecutor`<br/>→ `NewContract:ERC20hTokenBranch`<br/>→ `NewContract:ERC20hTokenRoot`<br/>→ `NewContract:RootBridgeAgent`<br/>→ `NewContract:WETH`<br/>→ `NewContract:Multicall2`<br/>→ `NewContract:RootPort`<br/>→ `NewContract:RootBridgeAgentFactory`<br/>→ `NewContract:CoreRootRouter`<br/>→ `NewContract:MulticallRootRouter`<br/>→ `NewContract:ERC20hTokenRootFactory`<br/>→ `NewContract:ArbitrumBranchPort`<br/>→ `NewContract:BaseBranchRouter`<br/>→ `NewContract:ArbitrumCoreBranchRouter`<br/>→ `NewContract:ArbitrumBranchBridgeAgentFactory`<br/>→ `NewContract:MockERC20`<br/>→ `NewContract:BranchPort`<br/>→ `NewContract:MulticallRootRouterLibZip`<br/>→ `NewContract:MockRootBridgeAgent`<br/>→ `NewContract:ERC20hTokenBranchFactory`<br/>→ `NewContract:CoreBranchRouter`<br/>→ `NewContract:BranchBridgeAgentFactory`<br/>→ `NewContract:MockPortStartegy`<br/>→ `NewContract:MockEndpoint` |

| ♻️ TryCatch | Σ Unchecked |
| ---------- | ----------- |
| **** | `yes` |

### <span style="font-weight: bold" id=t-package-imports>Dependencies / External Imports</span>

| Dependency / Import Path | Count  |
| ------------------------ | ------ |
| @omni/ArbitrumBranchBridgeAgent.sol | 1 |
| @omni/ArbitrumBranchPort.sol | 1 |
| @omni/ArbitrumCoreBranchRouter.sol | 1 |
| @omni/BaseBranchRouter.sol | 1 |
| @omni/BranchBridgeAgent.sol | 1 |
| @omni/BranchBridgeAgentExecutor.sol | 1 |
| @omni/BranchPort.sol | 1 |
| @omni/CoreBranchRouter.sol | 1 |
| @omni/CoreRootRouter.sol | 1 |
| @omni/MulticallRootRouter.sol | 2 |
| @omni/MulticallRootRouterLibZip.sol | 1 |
| @omni/RootBridgeAgent.sol | 2 |
| @omni/RootBridgeAgentExecutor.sol | 1 |
| @omni/RootPort.sol | 1 |
| @omni/factories/ArbitrumBranchBridgeAgentFactory.sol | 1 |
| @omni/factories/BranchBridgeAgentFactory.sol | 1 |
| @omni/factories/ERC20hTokenBranchFactory.sol | 1 |
| @omni/factories/ERC20hTokenRootFactory.sol | 1 |
| @omni/factories/RootBridgeAgentFactory.sol | 1 |
| @omni/interfaces/BridgeAgentConstants.sol | 1 |
| @omni/interfaces/IBranchBridgeAgent.sol | 1 |
| @omni/interfaces/IBranchRouter.sol | 1 |
| @omni/interfaces/ILayerZeroEndpoint.sol | 1 |
| @omni/interfaces/IRootBridgeAgent.sol | 2 |
| @omni/interfaces/IRootPort.sol | 1 |
| @omni/interfaces/IRootRouter.sol | 1 |
| @omni/token/ERC20hTokenBranch.sol | 1 |
| @omni/token/ERC20hTokenRoot.sol | 2 |
| @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol | 1 |
| @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol | 1 |
| @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol | 2 |
| forge-std/StdError.sol | 1 |
| forge-std/Test.sol | 2 |
| forge-std/console2.sol | 3 |
| lib/ExcessivelySafeCall.sol | 2 |
| solady/auth/Ownable.sol | 13 |
| solady/utils/LibString.sol | 1 |
| solady/utils/LibZip.sol | 2 |
| solady/utils/SafeCastLib.sol | 1 |
| solady/utils/SafeTransferLib.sol | 8 |
| solmate/test/utils/DSTestPlus.sol | 1 |
| solmate/test/utils/mocks/MockERC20.sol | 1 |
| solmate/tokens/ERC20.sol | 9 |
| solmate/tokens/ERC721.sol | 1 |


##### Contract Summary

```
Error: extraneous input 'depositNonce' expecting '=>' (87:20)
```
____

