// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "solady/auth/Ownable.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IERC20hTokenRoot} from "../interfaces/IERC20hTokenRoot.sol";

/// @title ERC20 hToken Contract
/// @author MaiaDAO
contract ERC20hTokenRoot is ERC20, Ownable, IERC20hTokenRoot {
    /// @inheritdoc IERC20hTokenRoot
    uint16 public immutable override localChainId;

    /// @inheritdoc IERC20hTokenRoot
    address public immutable override factoryAddress;

    /// @inheritdoc IERC20hTokenRoot
    mapping(uint256 chainId => uint256 balance) public override getTokenBalance;

    /**
     * @notice Constructor for the ERC20hTokenRoot Contract.
     *     @param _localChainId Local Network Identifier.
     *     @param _factoryAddress Address of the Factory Contract.
     *     @param _rootPortAddress Address of the Root Port Contract.
     *     @param _name Name of the Token.
     *     @param _symbol Symbol of the Token.
     *     @param _decimals Decimals of the Token.
     */
    constructor(
        uint16 _localChainId,
        address _factoryAddress,
        address _rootPortAddress,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(string(string.concat(_name)), string(string.concat(_symbol)), _decimals) {
        require(_rootPortAddress != address(0), "Root Port Address cannot be 0");
        require(_factoryAddress != address(0), "Factory Address cannot be 0");

        localChainId = _localChainId;
        factoryAddress = _factoryAddress;
        _initializeOwner(_rootPortAddress);
    }

    /*///////////////////////////////////////////////////////////////
                        ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints new tokens and updates the total supply for the given chain.
     * @param to Address to mint tokens to.
     * @param amount Amount of tokens to mint.
     * @param chainId Chain Id of the chain to mint tokens to.
     */
    function mint(address to, uint256 amount, uint256 chainId) external onlyOwner returns (bool) {
        getTokenBalance[chainId] += amount;
        _mint(to, amount);
        return true;
    }

    /**
     * @notice Burns new tokens and updates the total supply for the given chain.
     * @param from Address to burn tokens from.
     * @param amount Amount of tokens to burn.
     * @param chainId Chain Id of the chain to burn tokens to.
     */
    function burn(address from, uint256 amount, uint256 chainId) external onlyOwner {
        getTokenBalance[chainId] -= amount;
        _burn(from, amount);
    }
}
