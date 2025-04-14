// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Zeropoint is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Zeropoint", "ZPE") Ownable(initialOwner) {
        _mint(initialOwner, 1000000 * 10**3); // Initial supply: 1M $ZPE with 3 decimals
    }

    function decimals() public view virtual override returns (uint8) {
        return 3;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
