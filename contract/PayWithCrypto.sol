// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract PayWithCrypto is Ownable {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    mapping(address => mapping(string => bool)) public useForCardPayment;
    string[] public supportedAssets = [
        "ZPE", "ZPP", "ZPW", "ZHV", "GOATE", "GySt", "GP", "PI", "XLM", "BTC", "AQUA", "CRO"
    ];

    constructor(address _usdMediator, address _interoperability, address initialOwner) Ownable(initialOwner) {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        // USD is default and always enabled
    }

    function toggleCardPayment(string memory asset, bool enabled) external {
        require(isSupportedAsset(asset), "Unsupported asset");
        useForCardPayment[msg.sender][asset] = enabled;
    }

    function payWithCrypto(
        address user,
        uint256 amount,
        string memory paymentMethod // "swipe", "nfc", "manual", "goatepay"
    ) external {
        require(amount >= 0.01 * 10**6, "Minimum transaction amount is $0.01");
        uint256 totalBalance = interoperability.activeBalances[user]["USD"];
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            string memory asset = supportedAssets[i];
            if (useForCardPayment[user][asset]) {
                totalBalance += interoperability.convertAmount(asset, "USD", interoperability.activeBalances[user][asset]);
            }
        }

        require(totalBalance >= amount, "Insufficient balance");
        uint256 remaining = amount;
        if (interoperability.activeBalances[user]["USD"] >= remaining) {
            interoperability.activeBalances[user]["USD"] -= remaining;
            remaining = 0;
        } else {
            remaining -= interoperability.activeBalances[user]["USD"];
            interoperability.activeBalances[user]["USD"] = 0;
            for (uint256 i = 0; i < supportedAssets.length && remaining > 0; i++) {
                string memory asset = supportedAssets[i];
                if (useForCardPayment[user][asset]) {
                    uint256 assetAmount = interoperability.convertAmount("USD", asset, remaining);
                    if (interoperability.activeBalances[user][asset] >= assetAmount) {
                        interoperability.activeBalances[user][asset] -= assetAmount;
                        remaining = 0;
                    } else {
                        remaining -= interoperability.convertAmount(asset, "USD", interoperability.activeBalances[user][asset]);
                        interoperability.activeBalances[user][asset] = 0;
                    }
                }
            }
        }

        usdMediator.transferUSD(msg.sender, amount);
        emit PaymentProcessed(user, amount, paymentMethod);
    }

    function isSupportedAsset(string memory asset) internal view returns (bool) {
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            if (keccak256(bytes(asset)) == keccak256(bytes(supportedAssets[i]))) {
                return true;
            }
        }
        return false;
    }

    event PaymentProcessed(address indexed user, uint256 amount, string paymentMethod);
}
