// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract War is VRFConsumerBase {
    // Constants
    uint8 constant MIN_PLAYERS = 4;
    uint8 constant MAX_PLAYERS = 8;
    uint8 constant TOTAL_CARDS = 52;

    // Game state
    address[] public players;            // List of player addresses
    uint8 public numPlayers;             // Number of players in the session
    uint8 public firstDealer;            // Index of the first player to receive a card
    mapping(address => uint8[]) public hands;  // Each player's hand of cards
    uint8[] public currentRoundCards;    // Cards played in the current round
    uint256 public randomResult;         // Randomness from Chainlink VRF
    bool public gameOver;                // Tracks if the game has ended
    address public winner;               // Winner of the game

    // Chainlink VRF configuration
    bytes32 internal keyHash;
    uint256 internal fee;

    // Events for Unreal Engine integration
    event RoundWinner(address winner, uint8 cardsWon);
    event GameEnded(address winner);

    // Constructor: Initialize players and Chainlink VRF
    constructor(
        address[] memory _players,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        require(_players.length >= MIN_PLAYERS && _players.length <= MAX_PLAYERS, "Invalid number of players");
        players = _players;
        numPlayers = uint8(_players.length);
        keyHash = _keyHash;
        fee = _fee;
        gameOver = false;
    }

    // Start the game by requesting randomness from Chainlink
    function startGame() public {
        require(!gameOver, "Game is over");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK for VRF");
        requestRandomness(keyHash, fee);
    }

    // Chainlink callback: Use randomness to shuffle and deal cards
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomResult = randomness;

        // Randomly select the first player to receive a card
        firstDealer = uint8(randomness % numPlayers);

        // Initialize the deck (0-51 representing 52 cards)
        uint8[52] memory deck;
        for (uint8 i = 0; i < TOTAL_CARDS; i++) {
            deck[i] = i;
        }

        // Shuffle the deck using Fisher-Yates algorithm
        for (uint8 i = 51; i > 0; i--) {
            uint8 j = uint8(uint256(keccak256(abi.encode(randomness, i))) % (i + 1));
            (deck[i], deck[j]) = (deck[j], deck[i]);
        }

        // Deal cards counterclockwise starting from firstDealer
        uint8 currentPlayer = firstDealer;
        for (uint8 i = 0; i < TOTAL_CARDS; i++) {
            hands[players[currentPlayer]].push(deck[i]);
            currentPlayer = (currentPlayer + numPlayers - 1) % numPlayers; // Counterclockwise
        }
    }

    // Play a round of War
    function playRound() public {
        require(!gameOver, "Game is over");
        require(currentRoundCards.length == 0, "Round already in progress");

        // Each player plays their top card
        for (uint8 i = 0; i < numPlayers; i++) {
            address player = players[i];
            require(hands[player].length > 0, "Player has no cards");
            uint8 card = hands[player][0];
            removeCardFromHand(player, 0);
            currentRoundCards.push(card);
        }

        // Find the highest card and determine the winner(s)
        uint8 highestRank = 0;
        uint8[] memory winners;
        for (uint8 i = 0; i < numPlayers; i++) {
            uint8 rank = getRank(currentRoundCards[i]);
            if (rank > highestRank) {
                highestRank = rank;
                delete winners;
                winners = new uint8[](1);
                winners[0] = i;
            } else if (rank == highestRank) {
                winners.push(i);
            }
        }

        if (winners.length == 1) {
            // Single winner takes all cards
            address roundWinner = players[winners[0]];
            for (uint8 i = 0; i < numPlayers; i++) {
                hands[roundWinner].push(currentRoundCards[i]);
            }
            emit RoundWinner(roundWinner, numPlayers);
        } else {
            // Tie: Trigger a simplified war
            startWar(winners);
        }

        // Clear the round cards
        delete currentRoundCards;

        // Check if the game is over
        for (uint8 i = 0; i < numPlayers; i++) {
            if (hands[players[i]].length == TOTAL_CARDS) {
                gameOver = true;
                winner = players[i];
                emit GameEnded(winner);
                break;
            }
        }
    }

    // Simplified war resolution (random winner for brevity)
    function startWar(uint8[] memory tiedPlayers) internal {
        // In a full implementation, tied players would play additional cards
        // Here, we randomly select a winner among tied players
        uint8 randomIndex = uint8(uint256(keccak256(abi.encode(randomResult, block.timestamp))) % tiedPlayers.length);
        address warWinner = players[tiedPlayers[randomIndex]];
        for (uint8 i = 0; i < numPlayers; i++) {
            hands[warWinner].push(currentRoundCards[i]);
        }
        emit RoundWinner(warWinner, numPlayers);
    }

    // Helper: Get card rank (0=2, ..., 11=King, 12=Ace)
    function getRank(uint8 card) public pure returns (uint8) {
        return card % 13;
    }

    // Helper: Remove a card from a player's hand
    function removeCardFromHand(address player, uint8 index) internal {
        uint8[] storage hand = hands[player];
        require(index < hand.length, "Invalid card index");
        for (uint8 i = index; i < hand.length - 1; i++) {
            hand[i] = hand[i + 1];
        }
        hand.pop();
    }
}
