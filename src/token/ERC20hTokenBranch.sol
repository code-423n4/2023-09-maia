// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IERC20hTokenBranch} from "../interfaces/IERC20hTokenBranch.sol";

/// @title ERC20 hToken Branch Contract
/// @author MaiaDAO
contract ERC20hTokenBranch is ERC20, Ownable, IERC20hTokenBranch {
    constructor(
        string memory chainName,
        string memory chainSymbol,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _owner
    ) ERC20(string(string.concat(chainName, _name)), string(string.concat(chainSymbol, _symbol)), _decimals) {
        _initializeOwner(_owner);
    }

    /*///////////////////////////////////////////////////////////////
                        ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC20hTokenBranch
    function mint(address account, uint256 amount) external override onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    /// @inheritdoc IERC20hTokenBranch
    function burn(uint256 amount) public override onlyOwner {
        _burn(msg.sender, amount);
    }
}
