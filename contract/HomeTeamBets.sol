// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./InstilledInteroperability.sol";

contract HomeTeamBets {
    InstilledInteroperability public interoperability;
    IERC20 public usdcToken; // USDC contract
    address public owner;
    uint256 public totalRevenue; // 20% revenue pool

    enum BetType { Win, Lose, Tie } // Explicitly define Win, Lose, Tie

    struct Bet {
        address bettor;
        uint256 amount; // USDC amount bet
        BetType betType; // Win, Lose, or Tie
        bool overtime; // True = bet on overtime, False = no overtime
        uint256 timestamp;
    }

    struct Game {
        string homeTeam;
        string awayTeam;
        uint256 startTime; // Unix timestamp
        bool isActive; // True until game starts
        uint256 totalPool; // Total USDC bet
        bool completed; // True when game ends and results are set
        BetType result; // Win, Lose, or Tie for home team
        bool hadOvertime; // Game result
        mapping(address => Bet) bets; // One bet per user per game
        address[] bettors; // List of bettors
    }

    mapping(uint256 => Game) public games; // Game ID => Game data
    mapping(address => mapping(uint256 => bool)) public hasBet; // User => Game ID => Has bet?
    mapping(address => Bet[]) public transactionHistory; // User transaction history

    AggregatorV3Interface public oracle; // Chainlink oracle for game results
    uint256 public gameCount;

    event BetPlaced(address indexed bettor, uint256 gameId, uint256 amount, BetType betType, bool overtime, uint256 timestamp);
    event GameStarted(uint256 gameId, uint256 startTime);
    event GameCompleted(uint256 gameId, BetType result, bool hadOvertime);
    event WinningsDistributed(address indexed winner, uint256 gameId, uint256 amount);

    constructor(address _interoperability, address _usdcToken, address _oracle) {
        owner = msg.sender;
        interoperability = InstilledInteroperability(_interoperability);
        usdcToken = IERC20(_usdcToken); // USDC: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        oracle = AggregatorV3Interface(_oracle);
    }

    // Create a new game betting pool
    function createGame(string memory _homeTeam, string memory _awayTeam, uint256 _startTime) external {
        require(msg.sender == owner, "Only owner can create games");
        require(_startTime > block.timestamp, "Start time must be in the future");

        Game storage game = games[gameCount];
        game.homeTeam = _homeTeam;
        game.awayTeam = _awayTeam;
        game.startTime = _startTime;
        game.isActive = true;
        gameCount++;
    }

    // Place a bet (win, lose, or tie + overtime yes/no)
    function placeBet(uint256 _gameId, uint256 _amount, BetType _betType, bool _overtime) external {
        Game storage game = games[_gameId];
        require(game.isActive, "Betting closed or game not found");
        require(block.timestamp < game.startTime - 5 minutes, "Betting closes 5 mins before start");
        require(!hasBet[msg.sender][_gameId], "One bet per game allowed");
        require(_amount > 0, "Amount must be greater than 0");

        // Transfer USDC to contract
        require(usdcToken.transferFrom(msg.sender, address(this), _amount), "USDC transfer failed");

        // Record bet
        game.bets[msg.sender] = Bet(msg.sender, _amount, _betType, _overtime, block.timestamp);
        game.bettors.push(msg.sender);
        game.totalPool += _amount;
        hasBet[msg.sender][_gameId] = true;

        // Add to transaction history
        transactionHistory[msg.sender].push(Bet(msg.sender, _amount, _betType, _overtime, block.timestamp));

        emit BetPlaced(msg.sender, _gameId, _amount, _betType, _overtime, block.timestamp);
    }

    // Called when game starts (no more bets)
    function startGame(uint256 _gameId) external {
        Game storage game = games[_gameId];
        require(block.timestamp >= game.startTime, "Game not started yet");
        require(game.isActive, "Game already started or invalid");
        game.isActive = false;
        emit GameStarted(_gameId, game.startTime);
    }

    // Oracle updates game result (simplified for demo; use Chainlink in production)
    function completeGame(uint256 _gameId, BetType _result, bool _hadOvertime) external {
        require(msg.sender == owner, "Only owner can complete game"); // Replace with oracle in production
        Game storage game = games[_gameId];
        require(!game.isActive && !game.completed, "Game not started or already completed");

        game.completed = true;
        game.result = _result;
        game.hadOvertime = _hadOvertime;

        distributeWinnings(_gameId);
        emit GameCompleted(_gameId, _result, _hadOvertime);
    }

    // Distribute winnings pro-rata (80% to winners, 20% to revenue)
    function distributeWinnings(uint256 _gameId) internal {
        Game storage game = games[_gameId];
        uint256 revenueShare = (game.totalPool * 20) / 100;
        uint256 winnerPool = game.totalPool - revenueShare;
        totalRevenue += revenueShare;

        // Calculate total winning weight
        uint256 totalWinningWeight = 0;
        address[] memory winners = new address[](game.bettors.length);
        uint256 winnerCount = 0;

        for (uint256 i = 0; i < game.bettors.length; i++) {
            address bettor = game.bettors[i];
            Bet memory bet = game.bets[bettor];
            bool wonMain = bet.betType == game.result; // Match win, lose, or tie
            bool wonOvertime = bet.overtime == game.hadOvertime;

            if (wonMain && wonOvertime) {
                totalWinningWeight += bet.amount;
                winners[winnerCount] = bettor;
                winnerCount++;
            }
        }

        // Distribute winnings
        for (uint256 i = 0; i < winnerCount; i++) {
            address winner = winners[i];
            Bet memory bet = game.bets[winner];
            uint256 winnerShare = (bet.amount * winnerPool) / totalWinningWeight;
            interoperability.crossChainTransfer(1, 1, "USDC", winnerShare, winner);
            transactionHistory[winner].push(Bet(winner, winnerShare, bet.betType, bet.overtime, block.timestamp));
            emit WinningsDistributed(winner, _gameId, winnerShare);
        }
    }

    // Withdraw revenue (20%)
    function withdrawRevenue() external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 amount = totalRevenue;
        totalRevenue = 0;
        interoperability.crossChainTransfer(1, 1, "USDC", amount, interoperability.mediatorAccount());
    }

    // Get user's transaction history
    function getTransactionHistory(address user) external view returns (Bet[] memory) {
        return transactionHistory[user];
    }
}
