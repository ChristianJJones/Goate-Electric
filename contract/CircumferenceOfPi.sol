// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract CircumferenceOfPi is ERC20, Ownable {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    address public cj03nes;
    address public goatePigReserve = 0xGoatePigReserve;
    uint256 public constant MAX_SUPPLY = 250_000_000_000 * 10**18;
    bool public supplyUnlocked;

    constructor(address _usdMediator, address _interoperability, address _cj03nes, address initialOwner)
        ERC20("CircumferenceOfPi", "cP")
        Ownable(initialOwner)
    {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        cj03nes = _cj03nes;
    }

    function buyTokens(uint256 amount) external {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        usdMediator.transferUSD(address(this), amount);
        _mint(msg.sender, amount);
        if (totalSupply() >= MAX_SUPPLY) {
            supplyUnlocked = true;
        }
    }

    function stakeAsset(string memory asset, uint256 amount, uint256 durationDays) external {
        require(durationDays >= 30 && durationDays <= 365, "Invalid duration");
        interoperability.activeBalances[msg.sender][asset] -= amount;
        interoperability.stakingBalances[msg.sender][asset] += amount;

        uint256 dividends = calculateDividends(amount, durationDays);
        if (supplyUnlocked) {
            interoperability.activeBalances[msg.sender][asset] += dividends;
        } else {
            interoperability.activeBalances[msg.sender][asset] += dividends * 25 / 100;
            _mint(msg.sender, dividends * 25 / 100); // 25% in $cP
            uint256 revenueShare = dividends * 40 / 100;
            uint256 cj03nesShare = (revenueShare * 50) / 100;
            uint256 iiShare = (revenueShare * 20) / 100;
            uint256 usdMediatorShare = (revenueShare * 20) / 100;
            uint256 goatePigShare = (revenueShare * 10) / 100;
            usdMediator.transferUSD(cj03nes, cj03nesShare);
            usdMediator.transferUSD(address(interoperability), iiShare);
            usdMediator.transferUSD(address(usdMediator), usdMediatorShare);
            usdMediator.transferUSD(goatePigReserve, goatePigShare);
        }
    }

    function calculateDividends(uint256 amount, uint256 durationDays) internal pure returns (uint256) {
        uint256 apr = 10; // 10% APR (mock)
        return (amount * apr * durationDays) / (365 * 100);
    }
}
