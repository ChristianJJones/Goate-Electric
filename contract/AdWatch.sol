// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./InstilledInteroperability.sol";

contract AdWatch {
    InstilledInteroperability public interoperability;
    IERC20 public usdcToken; // USDC contract
    address public owner;
    uint256 public totalRevenue; // 20% revenue in USDC

    struct AdTransaction {
        address viewer;
        uint256 timestamp;
        uint256 payout; // 80% in USDC
        string adType; // "Google", "Pi", "YouTube"
    }

    mapping(address => AdTransaction[]) public transactionHistory;

    event AdWatched(address indexed viewer, uint256 payout, string adType, uint256 timestamp);
    event RevenueDistributed(address indexed viewer, uint256 viewerShare, uint256 revenueShare);

    constructor(address _interoperability, address _usdcToken) {
        owner = msg.sender;
        interoperability = InstilledInteroperability(_interoperability);
        usdcToken = IERC20(_usdcToken); // USDC address: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    }

    function watchAd(string memory adType, uint256 amount) external {
        require(amount > 0, "No payment received for ad view");

        // Transfer USDC from mediator (off-chain revenue source) to this contract
        require(usdcToken.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");

        // Calculate shares: 80% to viewer, 20% to revenue
        uint256 viewerShare = (amount * 80) / 100;
        uint256 revenueShare = amount - viewerShare;

        // Update total revenue
        totalRevenue += revenueShare;

        // Record transaction
        AdTransaction memory newTransaction = AdTransaction({
            viewer: msg.sender,
            timestamp: block.timestamp,
            payout: viewerShare,
            adType: adType
        });
        transactionHistory[msg.sender].push(newTransaction);

        // Send 80% to the viewer via crossChainTransfer
        interoperability.crossChainTransfer(1, 1, "USDC", viewerShare, msg.sender);

        // Emit events
        emit AdWatched(msg.sender, viewerShare, adType, block.timestamp);
        emit RevenueDistributed(msg.sender, viewerShare, revenueShare);
    }

    // Withdraw accumulated revenue (20%) to mediator account
    function withdrawRevenue() external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 amount = totalRevenue;
        totalRevenue = 0;
        interoperability.crossChainTransfer(1, 1, "USDC", amount, interoperability.mediatorAccount());
    }

    // Get a user's transaction history
    function getTransactionHistory(address user) external view returns (AdTransaction[] memory) {
        return transactionHistory[user];
    }
}
