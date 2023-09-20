// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @notice Call structure based off `Multicall2` contract for aggregating calls.
struct Call {
    address target;
    bytes callData;
}

/// @notice Payable call structure based off `Multicall3` contract for aggreagating calls with `msg.value`.
struct PayableCall {
    address target;
    bytes callData;
    uint256 value;
}

/**
 * @title  Virtual Account Contract
 * @author MaiaDAO
 * @notice A Virtual Account allows users to manage assets and perform interactions remotely while
 *         allowing dApps to keep encapsulated user balance for accounting purposes.
 * @dev    This contract is based off `Multicall2` and `Multicall3` contract, executes a set of `Call` or `PayableCall`
 *         objects if any of the performed calls is invalid the whole batch should revert.
 */
interface IVirtualAccount is IERC721Receiver {
    /**
     * @notice Returns the address of the user that owns the VirtualAccount.
     * @return The address of the user that owns the VirtualAccount.
     */
    function userAddress() external view returns (address);

    /**
     * @notice Returns the address of the local port.
     * @return The address of the local port.
     */
    function localPortAddress() external view returns (address);

    /**
     * @notice Withdraws native tokens from the VirtualAccount.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawNative(uint256 _amount) external;

    /**
     * @notice Withdraws ERC20 tokens from the VirtualAccount.
     * @param _token The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawERC20(address _token, uint256 _amount) external;

    /**
     * @notice Withdraws ERC721 tokens from the VirtualAccount.
     * @param _token The address of the ERC721 token to withdraw.
     * @param _tokenId The id of the token to withdraw.
     */
    function withdrawERC721(address _token, uint256 _tokenId) external;

    /**
     * @notice Aggregate calls ensuring each call is successful. Inspired by `Multicall2` contract.
     * @param callInput The call to make.
     * @return The return data of the call.
     */
    function call(Call[] calldata callInput) external returns (bytes[] memory);

    /**
     * @notice Aggregate calls with a msg value ensuring each call is successful. Inspired by `Multicall3` contract.
     * @param calls The calls to make.
     * @return The return data of the calls.
     * @dev Reverts if msg.value is less than the sum of the call values.
     */
    function payableCall(PayableCall[] calldata calls) external payable returns (bytes[] memory);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error CallFailed();

    error UnauthorizedCaller();
}
