// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./InstilledInteroperability.sol";

contract AdWatch {
    InstilledInteroperability public interoperability;
    IERC20 public usdcToken;
    address public owner;
    uint256 public totalRevenue;

    struct AdTransaction {
        address viewer;
        uint256 timestamp;
        uint256 payout;
        string adType;
    }

    mapping(address => AdTransaction[]) public transactionHistory;

    event AdWatched(address indexed viewer, uint256 payout, string adType, uint256 timestamp);
    event RevenueDistributed(address indexed viewer, uint256 viewerShare, uint256 revenueShare);

    constructor(address _interoperability, address _usdcToken) {
        owner = msg.sender;
        interoperability = InstilledInteroperability(_interoperability);
        usdcToken = IERC20(_usdcToken);
    }

    function watchAd(string memory adType, uint256 amount) external {
        require(amount > 0, "No payment received for ad view");
        require(usdcToken.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");

        uint256 viewerShare = (amount * 80) / 100;
        uint256 revenueShare = amount - viewerShare;
        totalRevenue += revenueShare;

        AdTransaction memory newTransaction = AdTransaction({
            viewer: msg.sender,
            timestamp: block.timestamp,
            payout: viewerShare,
            adType: adType
        });
        transactionHistory[msg.sender].push(newTransaction);

        interoperability.crossChainTransfer(1, 1, "USDC", viewerShare, msg.sender);

        emit AdWatched(msg.sender, viewerShare, adType, block.timestamp);
        emit RevenueDistributed(msg.sender, viewerShare, revenueShare);
    }

    function withdrawRevenue() external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 amount = totalRevenue;
        totalRevenue = 0;
        interoperability.crossChainTransfer(1, 1, "USDC", amount, interoperability.mediatorAccount());
    }

    function getTransactionHistory(address user) external view returns (AdTransaction[] memory) {
        return transactionHistory[user];
    }
}
