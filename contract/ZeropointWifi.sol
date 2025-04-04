// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ZeropointWifi ($ZPW) token for Goate Electric's unlimited WiFi subscription
contract ZeropointWifi is ERC20, Ownable {
    constructor(address initialOwner) ERC20("ZeropointWifi", "ZPW") Ownable(initialOwner) {
        _mint(initialOwner, 1000000 * 10**2); // Initial supply: 1M $ZPW with 2 decimals
    }

    // Override decimals to 2, reflecting $ZPW's precision (pegged to $5)
    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    // Mint new $ZPW tokens (restricted to owner, e.g., Goate Electric admin)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Burn $ZPW tokens (users can burn their own tokens)
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
