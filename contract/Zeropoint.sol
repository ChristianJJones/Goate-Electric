// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Zeropoint is ERC20, Ownable {
    constructor() ERC20("Zeropoint", "ZPE") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    // Provide energy and reward with $ZPE
    function provideEnergy(address user, uint256 amount) external onlyOwner {
        _mint(user, amount);
    }

    // Consume energy by burning $ZPE
    function consumeEnergy(address user, uint256 amount) external {
        require(balanceOf(user) >= amount, "Insufficient $ZPE");
        _burn(user, amount);
    }
}
