// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract PayWithCrypto is Ownable {
    USDMediator public usdMediator;
    QuantumInstilledInteroperability public interoperability;
    string[] public supportedAssets;
    mapping(address => mapping(string => bool)) public useForCardPayment;

    event PaymentProcessed(address indexed user, uint256 amount, string paymentMethod);

    constructor(address _usdMediator, address _interoperability) {
        usdMediator = USDMediator(_usdMediator);
        interoperability = QuantumInstilledInteroperability(_interoperability);
        supportedAssets = ['USD', 'PI', 'ZPE', 'ZPP', 'ZPW', 'ZHV', 'GOATE', 'GySt', 'SD', 'ZGI', 'GP', 'zS'];
    }

    function payWithCrypto(
        address user,
        uint256 amount,
        string memory paymentMethod,
        string memory pinOrPassword
    ) external {
        require(amount >= 0.01 * 10**6, "Minimum transaction amount is $0.01");
        require(verifyCredentials(user, pinOrPassword), "Invalid credentials");

        require(isAuthorizedRecipient(msg.sender, user), "Unauthorized recipient");

        uint256 totalBalance = interoperability.activeBalances(user, "USD");
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            string memory asset = supportedAssets[i];
            if (useForCardPayment[user][asset]) {
                totalBalance += interoperability.convertAmount(asset, "USD", interoperability.activeBalances(user, asset));
            }
        }

        require(totalBalance >= amount, "Insufficient balance");
        uint256 remaining = amount;
        if (interoperability.activeBalances(user, "USD") >= remaining) {
            interoperability.activeBalances(user, "USD") -= remaining;
            remaining = 0;
        } else {
            remaining -= interoperability.activeBalances(user, "USD");
            interoperability.activeBalances(user, "USD") = 0;
            for (uint256 i = 0; i < supportedAssets.length && remaining > 0; i++) {
                string memory asset = supportedAssets[i];
                if (useForCardPayment[user][asset]) {
                    uint256 assetAmount = interoperability.convertAmount("USD", asset, remaining);
                    if (interoperability.activeBalances(user, asset) >= assetAmount) {
                        interoperability.activeBalances(user, asset) -= assetAmount;
                        remaining = 0;
                    } else {
                        remaining -= interoperability.convertAmount(asset, "USD", interoperability.activeBalances(user, asset));
                        interoperability.activeBalances(user, asset) = 0;
                    }
                }
            }
        }

        usdMediator.transferUSD(msg.sender, amount);
        emit PaymentProcessed(user, amount, paymentMethod);
    }

    function verifyCredentials(address user, string memory pinOrPassword) internal view returns (bool) {
        return true; // Replace with actual pin/password check
    }

    function isAuthorizedRecipient(address recipient, address user) internal view returns (bool) {
        return recipient != address(0);
    }
}
