// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TheGoateToken is ERC20, Ownable {
    struct UserActivity {
        uint256 adsWatched;
        uint256 energyConsumed;
        uint256 validations;
        uint256 stakedAmount;
        uint256 wifiConsumed;
        uint256 digitalStockHeld;
        uint256 betsMade;
        uint256 gerastyxOpolPlayed;
        uint256 lotteryTicketsBought;
        uint256 gamesPlayed;
    }

    mapping(address => UserActivity) public userActivities;
    mapping(address => uint256) public creditScores;

    event ActivityRecorded(address indexed user, string activity, uint256 value);

    constructor() ERC20("The Goate Token", "GOATE") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10**18);
    }

    function recordActivity(address user, string memory activity, uint256 value) external onlyOwner {
        UserActivity storage ua = userActivities[user];
        if (keccak256(bytes(activity)) == keccak256(bytes("adsWatched"))) ua.adsWatched += value;
        else if (keccak256(bytes(activity)) == keccak256(bytes("energyConsumed"))) ua.energyConsumed += value;
        else if (keccak256(bytes(activity)) == keccak256(bytes("validations"))) ua.validations += value;
        else if (keccak256(bytes(activity)) == keccak256(bytes("stakedAmount"))) ua.stakedAmount += value;
        else if (keccak256(bytes(activity)) == keccak256(bytes("wifiConsumed"))) ua.wifiConsumed += value;
        else if (keccak256(bytes(activity)) == keccak256(bytes("digitalStockHeld"))) ua.digitalStockHeld += value;
        else if (keccak256(bytes(activity)) == keccak256(bytes("betsMade"))) ua.betsMade += value;
        else if (keccak256(bytes(activity)) == keccak256(bytes("gerastyxOpolPlayed"))) ua.gerastyxOpolPlayed += value;
        else if (keccak256(bytes(activity)) == keccak256(bytes("lotteryTicketsBought"))) ua.lotteryTicketsBought += value;
        else if (keccak256(bytes(activity)) == keccak256(bytes("gamesPlayed"))) ua.gamesPlayed += value;
        emit ActivityRecorded(user, activity, value);
        updateCreditScore(user);
    }

    function updateCreditScore(address user) internal {
        UserActivity memory ua = userActivities[user];
        uint256 score = (ua.adsWatched * 10) + (ua.stakedAmount / 1e18 * 50) + (ua.energyConsumed / 1e3 * 20);
        creditScores[user] = score > 1000 ? 1000 : score; // Cap at 1000
    }
}
