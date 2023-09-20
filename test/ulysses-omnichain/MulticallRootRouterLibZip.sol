// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibZip} from "solady/utils/LibZip.sol";

import {MulticallRootRouter} from "./MulticallRootRouter.sol";

/**
 * @title  Multicall Root Router LibZip Contract
 * @author MaiaDAO
 * @notice Root Router implementation for interfacing with third-party dApps present in the Root Omnichain Environment.
 * @dev    Func IDs for calling these  functions through the messaging layer:
 *
 *         CROSS-CHAIN MESSAGING FUNCIDs
 *         -----------------------------
 *         FUNC ID      | FUNC NAME
 *         -------------+---------------
 *         0x01         | multicallNoOutput
 *         0x02         | multicallSingleOutput
 *         0x03         | multicallMultipleOutput
 *         0x04         | multicallSignedNoOutput
 *         0x05         | multicallSignedSingleOutput
 *         0x06         | multicallSignedMultipleOutput
 *
 */
contract MulticallRootRouterLibZip is MulticallRootRouter {
    using LibZip for bytes;

    constructor(uint256 _localChainId, address _localPortAddress, address _multicallAddress)
        MulticallRootRouter(_localChainId, _localPortAddress, _multicallAddress)
    {}

    /*///////////////////////////////////////////////////////////////
                            DECODING FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    function _decode(bytes calldata data) internal pure override returns (bytes memory) {
        return data.cdDecompress();
    }
}
