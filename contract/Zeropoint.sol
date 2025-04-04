// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Zeropoint ($ZPE) token for Goate Electric's wireless charging utility
contract Zeropoint is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Zeropoint", "ZPE") Ownable(initialOwner) {
        _mint(initialOwner, 1000000 * 10**3); // Initial supply: 1M $ZPE with 3 decimals
    }

    // Override decimals to 3, reflecting $ZPE's precision (pegged to $0.10)
    function decimals() public view virtual override returns (uint8) {
        return 3;
    }

    // Mint new $ZPE tokens (restricted to owner, e.g., Goate Electric admin)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Burn $ZPE tokens (users can burn their own tokens)
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
