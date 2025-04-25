// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract GoateStaking is Ownable {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    address public cj03nes;
    address public goatePigReserve = 0xGoatePigReserve;

    struct Stake {
        address user;
        string asset;
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        uint256 usdValue;
        bool active;
        uint256[] nftIds; // For GerastyxPropertyNFT
    }

    mapping(uint256 => Stake) public stakes;
    uint256 public stakeCounter;
    mapping(string => string[]) public stakingAssets;

    constructor(address _usdMediator, address _interoperability, address _cj03nes, address initialOwner)
        Ownable(initialOwner)
    {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        cj03nes = _cj03nes;
        initializeStakingAssets();
    }

    function initializeStakingAssets() internal {
        stakingAssets["USD"] = ["yXLM", "yBTC", "yUSD"];
        stakingAssets["PI"] = ["WFM", "WMT", "SFM"];
        stakingAssets["ZPE"] = ["DLR", "O", "BITF"];
        stakingAssets["ZPP"] = ["VZ", "T", "DIS"];
        stakingAssets["ZPW"] = ["yXLM", "yBTC", "yUSD"];
        stakingAssets["ZHV"] = ["XLM", "yXLM", "GDX"];
        stakingAssets["GySt"] = ["yUSD", "SHW", "USGO"];
        stakingAssets["GOATE"] = ["yXLM", "yBTC", "yUSD"];
        stakingAssets["GP"] = ["yXLM", "AQUA", "yUSD"];
        stakingAssets["SD"] = ["yXLM", "AQUA", "yUSD"];
        stakingAssets["GerastyxPropertyNFT"] = ["yXLM", "yBTC", "yUSD"];
    }

    function stakeAsset(string memory asset, uint256 amount, uint256 durationDays, uint256[] memory nftIds) external {
        require(durationDays >= 30 && durationDays <= 365, "Invalid duration");
        uint256 stakeId = stakeCounter++;
        uint256 duration = durationDays * 1 days;

        interoperability.activeBalances[msg.sender][asset] -= amount;
        interoperability.stakingBalances[msg.sender][asset] += amount / 2;

        uint256 swapAmount = amount / 2;
        string[] memory designatedAssets = stakingAssets[asset];
        for (uint256 i = 0; i < designatedAssets.length; i++) {
            interoperability.quantumSwap(1, 1, asset, designatedAssets[i], swapAmount / designatedAssets.length, msg.sender, address(this));
        }

        uint256 usdValue = interoperability.convertAmount(asset, "USD", amount);
        stakes[stakeId] = Stake(msg.sender, asset, amount, block.timestamp, duration, usdValue, true, nftIds);
        emit Staked(stakeId, msg.sender, asset, amount, duration);
    }

    function calculateAPR(string memory asset, uint256 amount) public view returns (uint256) {
        uint256 apr = 10; // 10% APR (mock)
        uint256 monthlyReturn = (amount * apr) / (12 * 100);
        uint256 revenueDeduction = (monthlyReturn * 25) / 100; // 25% to revenue
        return (monthlyReturn - revenueDeduction) * 100 / amount; // Adjusted APR
    }

    event Staked(uint256 indexed stakeId, address indexed user, string asset, uint256 amount, uint256 duration);
}
