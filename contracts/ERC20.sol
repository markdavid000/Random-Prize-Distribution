//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Token is ERC20, Ownable {
    constructor(address _initialAddress, string memory _tokenName, string memory _symbol)
        ERC20(_tokenName, _symbol)
        Ownable(_initialAddress)
    {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
}