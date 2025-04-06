// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract GoateStaking {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    address public owner;

    struct Stake {
        address user;
        string asset;
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        bool active;
    }

    mapping(address => Stake[]) public stakes;
    mapping(address => uint256) public totalStaked;

    string[] public stockList = [
        "WMT", "KMB", "MO", "WPC", "CSCO", "T", "BX", "AAPL", "CAT", "SPG",
        "LMT", "AVY", "MCD", "TGT", "TTWO", "DIS", "BAC", "BBY", "MGY", "NKE"
    ];

    event Staked(address indexed user, string asset, uint256 amount, uint256 duration);
    event Unstaked(address indexed user, string asset, uint256 amount);

    constructor(address _usdMediator, address _interoperability) {
        owner = msg.sender;
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
    }

    function stake(string memory asset, uint256 amount, uint256 duration) external {
        require(amount >= 1e6, "Minimum $1 USD");
        IERC20 token = IERC20(interoperability.tokenMap(block.chainid, asset));
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint256 perStock = amount / 20;
        for (uint256 i = 0; i < stockList.length; i++) {
            usdMediator.buyStock(stockList[i], perStock);
        }

        stakes[msg.sender].push(Stake(msg.sender, asset, amount, block.timestamp, duration, true));
        totalStaked[msg.sender] += amount;

        emit Staked(msg.sender, asset, amount, duration);
    }

    function unstake(uint256 stakeId) external {
        Stake storage stake = stakes[msg.sender][stakeId];
        require(stake.active, "Stake not active");
        require(block.timestamp >= stake.startTime + stake.duration, "Stake not matured");

        uint256 perStock = stake.amount / 20;
        for (uint256 i = 0; i < stockList.length; i++) {
            usdMediator.sellStock(stockList[i], perStock, stake.asset, msg.sender);
        }

        stake.active = false;
        totalStaked[msg.sender] -= stake.amount;

        emit Unstaked(msg.sender, stake.asset, stake.amount);
    }
}
