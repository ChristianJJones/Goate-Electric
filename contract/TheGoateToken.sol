// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TheGoateToken is ERC20, Ownable {
    mapping(address => uint256) public userPrices; // Custom price per user
    mapping(address => uint256) public achievements; // Track user achievements

    event Airdrop(address indexed recipient, uint256 amount);

    constructor() ERC20("The Goate Token", "GOATE") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10**18); // Initial supply: 1M tokens
    }

    // Set custom price for a user
    function setUserPrice(address user, uint256 price) external onlyOwner {
        userPrices[user] = price;
    }

    // Get user's custom price
    function getUserPrice(address user) external view returns (uint256) {
        return userPrices[user] > 0 ? userPrices[user] : 1 * 10**18; // Default price: 1 token
    }

    // Record an achievement and airdrop tokens
    function recordAchievement(address user, uint256 achievementPoints) external onlyOwner {
        achievements[user] += achievementPoints;
        uint256 airdropAmount = achievementPoints * 10 * 10**18; // 10 tokens per point
        _mint(user, airdropAmount);
        emit Airdrop(user, airdropAmount);
    }

    // Override transfer to respect custom pricing (optional logic)
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return super.transfer(recipient, amount);
    }
}
