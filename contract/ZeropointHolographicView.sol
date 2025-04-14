// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract ZeropointHolographicView is ERC20, Ownable {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    uint256 public constant SUBSCRIPTION_COST = 2 * 10**18; // $2 in $ZHV
    uint256 public constant SUBSCRIPTION_DURATION = 30 days;
    mapping(address => uint256) public lastSubscriptionTime;

    constructor(address _usdMediator, address _interoperability) 
        ERC20("ZeropointHolographicView", "ZHV") Ownable(msg.sender) {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        _mint(msg.sender, 1000000 * 10**18);
    }

    function subscribe() external {
        require(balanceOf(msg.sender) >= SUBSCRIPTION_COST, "Insufficient $ZHV");
        _burn(msg.sender, SUBSCRIPTION_COST);
        lastSubscriptionTime[msg.sender] = block.timestamp + SUBSCRIPTION_DURATION;
    }

    function isSubscribed(address user) public view returns (bool) {
        return lastSubscriptionTime[user] > block.timestamp;
    }
}
