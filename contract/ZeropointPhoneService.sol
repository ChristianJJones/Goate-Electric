// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZeropointPhone is ERC20, Ownable {
    uint256 public constant SUBSCRIPTION_COST = 100; // 1 $ZPP = 100 units (2 decimals), $5
    uint256 public constant SUBSCRIPTION_DURATION = 30 days;
    mapping(address => uint256) public lastSubscriptionTime;
    address public revenueRecipient;

    constructor(address initialOwner) ERC20("ZeropointPhone", "ZPP") Ownable(initialOwner) {
        _mint(initialOwner, 1000000 * 10**2); // 1M $ZPP
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    function setRevenueRecipient(address recipient) external onlyOwner {
        revenueRecipient = recipient;
    }

    function subscribe() external {
        require(balanceOf(msg.sender) >= SUBSCRIPTION_COST, "Insufficient $ZPP balance");
        require(revenueRecipient != address(0), "Revenue recipient not set");
        _transfer(msg.sender, revenueRecipient, SUBSCRIPTION_COST);
        lastSubscriptionTime[msg.sender] = block.timestamp + SUBSCRIPTION_DURATION;
    }

    function isSubscribed(address user) public view returns (bool) {
        return lastSubscriptionTime[user] > block.timestamp;
    }
}
