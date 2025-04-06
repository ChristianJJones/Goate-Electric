// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract Lending {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    address public owner;
    string public plaidAPI = "https://api.plaid.com";

    uint256 public borrowPool;
    mapping(address => uint256) public loans;
    mapping(address => uint256) public loanDueDates;
    mapping(address => uint256) public creditScores;

    string[] public stockList = [
        "WMT", "KMB", "MO", "WPC", "CSCO", "T", "BX", "AAPL", "CAT", "SPG",
        "LMT", "AVY", "MCD", "TGT", "TTWO", "DIS", "BAC", "BBY", "MGY", "NKE"
    ];

    event Lent(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);

    constructor(address _usdMediator, address _interoperability) {
        owner = msg.sender;
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
    }

    function lend(uint256 amount) external {
        require(amount >= 1e6, "Minimum $1 USD");
        IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        require(usdc.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint256 perStock = amount / 20;
        for (uint256 i = 0; i < stockList.length; i++) {
            usdMediator.buyStock(stockList[i], perStock);
        }
        borrowPool += amount;
        emit Lent(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        uint256 creditScore = getCreditScore(msg.sender);
        uint256 ecosystemSize = 1000; // Placeholder
        uint256 maxLoan = (creditScore * borrowPool) / (1000 * ecosystemSize);
        require(amount <= maxLoan, "Exceeds loan limit");
        require(loans[msg.sender] == 0, "Existing loan pending");
        require(borrowPool >= amount, "Insufficient pool");

        borrowPool -= amount;
        loans[msg.sender] = amount;
        loanDueDates[msg.sender] = block.timestamp + 30 days;
        usdMediator.transferUSD(msg.sender, amount);
        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        require(loans[msg.sender] >= amount, "Invalid amount");
        IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        require(usdc.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        loans[msg.sender] -= amount;
        borrowPool += amount;
        if (loans[msg.sender] == 0) loanDueDates[msg.sender] = 0;
        emit Repaid(msg.sender, amount);
    }

    function handleDefault(address user) external {
        require(loanDueDates[user] != 0 && block.timestamp > loanDueDates[user], "Not defaulted");
        uint256 debt = loans[user];
        usdMediator.stakeDebt(user, debt);
        loans[user] = 0;
        loanDueDates[user] = 0;
    }

    function getCreditScore(address user) internal returns (uint256) {
        if (creditScores[user] == 0) {
            creditScores[user] = 700; // Default, updated off-chain via Plaid
        }
        return creditScores[user];
    }
}
