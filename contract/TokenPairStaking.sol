// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract TokenPairStaking is Ownable {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    address public cj03nes;
    address public goatePigReserve = 0xGoatePigReserve;

    struct Stake {
        address user;
        string asset1;
        string asset2;
        uint256 amount1;
        uint256 amount2;
        uint256 startTime;
        uint256 duration;
        uint256 usdValue;
        bool active;
    }

    mapping(uint256 => Stake) public stakes;
    uint256 public stakeCounter;
    mapping(string => mapping(string => string[])) public stakingPairs;

    constructor(address _usdMediator, address _interoperability, address _cj03nes, address initialOwner)
        Ownable(initialOwner)
    {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        cj03nes = _cj03nes;
        initializePairs();
    }

    function initializePairs() internal {
        stakingPairs["DOGE"]["SHIB"] = ["AQUA", "yXLM", "yUSD"];
        stakingPairs["TON"]["PI"] = ["WFM", "WMT", "SFM"];
        stakingPairs["GP"]["GySt"] = ["yXLM", "yBTC", "yUSD"];
        stakingPairs["VVS"]["CRO"] = ["XLM", "yXLM", "GDX"];
        stakingPairs["XLM"]["BTC"] = ["yXLM", "yBTC", "yUSD"];
        stakingPairs["USD"]["GOATE"] = ["yXLM", "yBTC", "yUSD"];
        stakingPairs["PYUSD"]["ZPE"] = ["yXLM", "yBTC", "yUSD"];
        // Add more pairs for GerastyxPropertyNFT
    }

    function stakeTokens(
        string memory asset1,
        string memory asset2,
        uint256 amount1,
        uint256 amount2,
        uint256 durationDays
    ) external {
        require(durationDays >= 30 && durationDays <= 365, "Invalid duration");
        uint256 stakeId = stakeCounter++;
        uint256 duration = durationDays * 1 days;

        interoperability.activeBalances[msg.sender][asset1] -= amount1;
        interoperability.activeBalances[msg.sender][asset2] -= amount2;
        interoperability.stakingBalances[msg.sender][asset1] += amount1 / 2;
        interoperability.stakingBalances[msg.sender][asset2] += amount2 / 2;

        uint256 swapAmount1 = amount1 / 2;
        uint256 swapAmount2 = amount2 / 2;
        string[] memory designatedAssets = stakingPairs[asset1][asset2];
        for (uint256 i = 0; i < designatedAssets.length; i++) {
            interoperability.quantumSwap(1, 1, asset1, designatedAssets[i], swapAmount1 / designatedAssets.length, msg.sender, address(this));
            interoperability.quantumSwap(1, 1, asset2, designatedAssets[i], swapAmount2 / designatedAssets.length, msg.sender, address(this));
        }

        uint256 usdValue = calculateUSDValue(asset1, asset2, amount1, amount2);
        stakes[stakeId] = Stake(msg.sender, asset1, asset2, amount1, amount2, block.timestamp, duration, usdValue, true);
        emit Staked(stakeId, msg.sender, asset1, asset2, amount1, amount2, duration);
    }

    function calculateUSDValue(string memory asset1, string memory asset2, uint256 amount1, uint256 amount2) internal view returns (uint256) {
        uint256 price1 = interoperability.assetPrices[asset1].aggregatedPrice;
        uint256 price2 = interoperability.assetPrices[asset2].aggregatedPrice;
        return (amount1 * price1 + amount2 * price2) / 10**6;
    }

    function withdrawStake(uint256 stakeId) external {
        Stake storage stake = stakes[stakeId];
        require(stake.user == msg.sender, "Not staker");
        require(stake.active, "Stake not active");
        require(block.timestamp >= stake.startTime + stake.duration, "Stake not matured");

        stake.active = false;
        interoperability.activeBalances[msg.sender][stake.asset1] += stake.amount1 / 2;
        interoperability.activeBalances[msg.sender][stake.asset2] += stake.amount2 / 2;

        string[] memory designatedAssets = stakingPairs[stake.asset1][stake.asset2];
        for (uint256 i = 0; i < designatedAssets.length; i++) {
            uint256 amount = interoperability.stakingBalances[msg.sender][designatedAssets[i]];
            interoperability.quantumSwap(1, 1, designatedAssets[i], stake.asset1, amount / 2, address(this), msg.sender);
            interoperability.quantumSwap(1, 1, designatedAssets[i], stake.asset2, amount / 2, address(this), msg.sender);
        }

        uint256 dividends = calculateDividends(stakeId);
        distributeDividends(stake.user, stake.asset1, stake.asset2, dividends);
    }

    function calculateDividends(uint256 stakeId) internal view returns (uint256) {
        Stake storage stake = stakes[stakeId];
        uint256 apr = 10; // 10% APR (mock)
        uint256 usdValue = stake.usdValue;
        uint256 durationInDays = stake.duration / 1 days;
        return (usdValue * apr * durationInDays) / (365 * 100);
    }

    function distributeDividends(address user, string memory asset1, string memory asset2, uint256 amount) internal {
        uint256 userShare1 = (amount * 25) / 100;
        uint256 userShare2 = (amount * 25) / 100;
        uint256 designatedShare = (amount * 25) / 100;
        uint256 revenueShare = (amount * 25) / 100;

        interoperability.activeBalances[user][asset1] += userShare1;
        interoperability.activeBalances[user][asset2] += userShare2;
        // Swap designated share to asset1/asset2 (mocked)
        interoperability.activeBalances[user][asset1] += designatedShare / 2;
        interoperability.activeBalances[user][asset2] += designatedShare / 2;

        uint256 cj03nesShare = (revenueShare * 50) / 100;
        uint256 iiShare = (revenueShare * 20) / 100;
        uint256 usdMediatorShare = (revenueShare * 20) / 100;
        uint256 goatePigShare = (revenueShare * 10) / 100;
        usdMediator.transferUSD(cj03nes, cj03nesShare);
        usdMediator.transferUSD(address(interoperability), iiShare);
        usdMediator.transferUSD(address(usdMediator), usdMediatorShare);
        usdMediator.transferUSD(goatePigReserve, goatePigShare);
    }

    event Staked(uint256 indexed stakeId, address indexed user, string asset1, string asset2, uint256 amount1, uint256 amount2, uint256 duration);
}
