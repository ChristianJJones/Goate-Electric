// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Spades is VRFConsumerBase {
    // Constants
    uint8 constant NUM_PLAYERS = 4;
    uint8 constant CARDS_PER_PLAYER = 13;
    uint8 constant TOTAL_CARDS = 52;
    uint256 constant BID_TIMEOUT = 30; // 30 seconds

    // Game state
    address[4] public players;
    uint8 public dealer;
    uint8 public leader;
    uint8 public currentPlayer;
    uint8[4] public tricksWon; // Tricks in current hand
    uint256 public teamAScore; // Team 0 & 2 (in wei, e.g., 4400000 = 4.4)
    uint256 public teamBScore; // Team 1 & 3
    uint8 public teamAStrikes;
    uint8 public teamBStrikes;
    uint8 public teamAReneges;
    uint8 public teamBReneges;
    bool public gameOver;
    mapping(uint8 => uint8[]) public hands;
    uint8[] public currentTrick;
    uint8 public suitLed;
    uint8[2] public teamBids; // Team A (0), Team B (1)
    mapping(uint8 => uint8) public playerBids; // Player index => bid
    uint256 public bidStartTime;
    uint8 public biddingPhase; // 0=dealer, 1=dealer's partner, 2=left, 3=left's partner
    bool public firstRound;

    // Betting
    uint256 public betAmount;
    address public revenueAddress;

    // Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    // Chainlink Oracle for Time
    AggregatorV3Interface internal timeFeed; // Hypothetical time oracle

    // Events
    event BidPlaced(uint8 indexed player, uint8 bid);
    event TrickWon(uint8 indexed winner, uint8 books);
    event GameEnded(address winnerTeam, uint256 winnings);

    // Constructor
    constructor(
        address[4] memory _players,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        address _timeFeed,
        address _revenueAddress
    ) VRFConsumerBase(_vrfCoordinator, _link) payable {
        players = _players;
        keyHash = _keyHash;
        fee = _fee;
        timeFeed = AggregatorV3Interface(_timeFeed);
        revenueAddress = _revenueAddress;
        betAmount = msg.value / 2; // Split between teams
        dealer = uint8(block.timestamp % 4);
        leader = (dealer + 1) % 4;
        currentPlayer = leader;
        firstRound = true;
        biddingPhase = 0;
    }

    // Start a new hand
    function startNewHand() public {
        require(!gameOver, "Game is over");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        requestRandomness(keyHash, fee);
    }

    // Fulfill randomness and deal cards
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomResult = randomness;
        uint8[52] memory deck;
        for (uint8 i = 0; i < 52; i++) deck[i] = i;
        for (uint8 i = 51; i > 0; i--) {
            uint8 j = uint8(uint256(keccak256(abi.encode(randomness, i))) % (i + 1));
            (deck[i], deck[j]) = (deck[j], deck[i]);
        }
        for (uint8 p = 0; p < 4; p++) {
            delete hands[p];
            for (uint8 c = 0; c < 13; c++) {
                hands[p].push(deck[p * 13 + c]);
            }
        }
        resetTrickState();
        bidStartTime = getCurrentTime();
        biddingPhase = 0;
        if (firstRound) {
            teamBids[0] = 4;
            teamBids[1] = 4;
            firstRound = false;
            currentPlayer = leader;
        }
    }

    // Place a bid
    function placeBid(uint8 bid) public {
        require(!firstRound, "First round has fixed bids");
        require(bid <= 13, "Bid must be 0-13");
        require(getCurrentTime() < bidStartTime + BID_TIMEOUT, "Bid timeout");
        require(msg.sender == players[currentBidder()], "Not your turn to bid");

        playerBids[currentBidder()] = bid;
        emit BidPlaced(currentBidder(), bid);

        if (biddingPhase == 0 || biddingPhase == 2) {
            biddingPhase++;
        } else {
            uint8 teamIndex = (currentBidder() % 2 == 0) ? 0 : 1;
            teamBids[teamIndex] = playerBids[currentBidder()] + playerBids[currentBidder() - 1];
            biddingPhase++;
        }

        if (biddingPhase == 4) {
            biddingPhase = 255; // Bidding done
            currentPlayer = leader;
        }
        bidStartTime = getCurrentTime();
    }

    // Play a card
    function playCard(uint8 card) public {
        require(msg.sender == players[currentPlayer], "Not your turn");
        require(biddingPhase == 255 || firstRound, "Bidding not complete");
        require(isValidPlay(card, currentPlayer), "Invalid play");

        bool reneged = checkRenege(card, currentPlayer);
        if (reneged) {
            uint8 team = (currentPlayer % 2 == 0) ? 0 : 1;
            if (team == 0) teamAReneges++;
            else teamBReneges++;
        }

        removeCardFromHand(currentPlayer, card);
        currentTrick.push(card);

        if (currentTrick.length == 1) suitLed = getSuit(card);
        currentPlayer = (currentPlayer + 1) % 4;

        if (currentTrick.length == 4) {
            resolveTrick();
        }
    }

    // Resolve a trick
    function resolveTrick() internal {
        uint8 winner = determineWinner(currentTrick, suitLed);
        tricksWon[winner]++;
        emit TrickWon(winner, tricksWon[winner]);
        leader = winner;
        currentPlayer = winner;

        if (tricksWon[0] + tricksWon[1] + tricksWon[2] + tricksWon[3] == 13) {
            resolveHand();
        } else {
            resetTrickState();
        }
    }

    // Resolve a hand
    function resolveHand() internal {
        uint8 teamATricks = tricksWon[0] + tricksWon[2];
        uint8 teamBTricks = tricksWon[1] + tricksWon[3];

        if (teamATricks >= teamBids[0]) {
            uint256 excess = teamATricks - teamBids[0];
            teamAScore += (teamBids[0] * 1 ether) + (excess * 1 ether / 10);
        } else {
            teamAStrikes++;
        }

        if (teamBTricks >= teamBids[1]) {
            uint256 excess = teamBTricks - teamBids[1];
            teamBScore += (teamBids[1] * 1 ether) + (excess * 1 ether / 10);
        } else {
            teamBStrikes++;
        }

        checkGameEnd();
        if (!gameOver) {
            dealer = (dealer + 1) % 4;
            leader = (dealer + 1) % 4;
            startNewHand();
        }
    }

    // Check game end conditions
    function checkGameEnd() internal {
        bool teamAWins = teamAScore >= 25 ether;
        bool teamBWins = teamBScore >= 25 ether;
        bool teamALoses = (teamAStrikes >= 3) || (teamAReneges >= 2) || 
                         (teamAStrikes >= 2 && teamAStrikes > tricksWon[0] + tricksWon[2]);
        bool teamBLoses = (teamBStrikes >= 3) || (teamBReneges >= 2) || 
                         (teamBStrikes >= 2 && teamBStrikes > tricksWon[1] + tricksWon[3]);

        if (teamAWins || teamBLoses) {
            gameOver = true;
            payable(players[0]).transfer(betAmount * 2);
            emit GameEnded(players[0], betAmount * 2);
        } else if (teamBWins || teamALoses) {
            gameOver = true;
            payable(players[1]).transfer(betAmount * 2);
            emit GameEnded(players[1], betAmount * 2);
        } else if (teamAReneges > 0 && teamBReneges > 0 && currentTrick.length == 4) {
            gameOver = true;
            payable(revenueAddress).transfer(betAmount * 2);
            emit GameEnded(address(0), 0);
        }
    }

    // Helper functions
    function getSuit(uint8 card) public pure returns (uint8) {
        if (card == 51) return 4; // Little Joker
        if (card == 52) return 4; // Big Joker
        return card / 13;
    }

    function getRank(uint8 card) public pure returns (uint8) {
        if (card == 51) return 13;
        if (card == 52) return 14;
        return card % 13;
    }

    function isValidPlay(uint8 card, uint8 player) public view returns (bool) {
        bool hasCard = false;
        for (uint8 i = 0; i < hands[player].length; i++) {
            if (hands[player][i] == card) {
                hasCard = true;
                break;
            }
        }
        if (!hasCard) return false;
        if (currentTrick.length == 0) return true;
        uint8 playerSuit = getSuit(card);
        if (playerSuit == suitLed) return true;
        for (uint8 i = 0; i < hands[player].length; i++) {
            if (getSuit(hands[player][i]) == suitLed) return false;
        }
        return true;
    }

    function checkRenege(uint8 card, uint8 player) internal view returns (bool) {
        if (currentTrick.length == 0 || getSuit(card) == suitLed) return false;
        for (uint8 i = 0; i < hands[player].length; i++) {
            if (getSuit(hands[player][i]) == suitLed && hands[player][i] != card) {
                return true;
            }
        }
        return false;
    }

    function removeCardFromHand(uint8 player, uint8 card) internal {
        for (uint8 i = 0; i < hands[player].length; i++) {
            if (hands[player][i] == card) {
                hands[player][i] = hands[player][hands[player].length - 1];
                hands[player].pop();
                break;
            }
        }
    }

    function determineWinner(uint8[] memory cards, uint8 suitLed) public pure returns (uint8) {
        uint8 maxIndex = 0;
        bool trumpPlayed = false;
        for (uint8 i = 0; i < 4; i++) {
            uint8 suit = getSuit(cards[i]);
            uint8 rank = getRank(cards[i]);
            if (suit == 4 || suit == 0) { // Joker or spade
                if (!trumpPlayed || compareCards(cards[i], cards[maxIndex]) > 0) {
                    maxIndex = i;
                    trumpPlayed = true;
                }
            } else if (!trumpPlayed && suit == suitLed) {
                if (rank > getRank(cards[maxIndex])) maxIndex = i;
            }
        }
        return maxIndex;
    }

    function compareCards(uint8 card1, uint8 card2) public pure returns (int8) {
        uint8 suit1 = getSuit(card1);
        uint8 suit2 = getSuit(card2);
        uint8 rank1 = getRank(card1);
        uint8 rank2 = getRank(card2);
        if (suit1 == 4 && suit2 != 4) return 1;
        if (suit2 == 4 && suit1 != 4) return -1;
        if (suit1 == 4 && suit2 == 4) return (rank1 > rank2) ? int8(1) : int8(-1);
        if (suit1 == 0 && suit2 != 0) return 1;
        if (suit2 == 0 && suit1 != 0) return -1;
        if (suit1 == 0 && suit2 == 0) return (rank1 > rank2) ? int8(1) : int8(-1);
        return (rank1 > rank2) ? int8(1) : int8(-1);
    }

    function resetTrickState() internal {
        delete currentTrick;
        suitLed = 255;
        for (uint8 p = 0; p < 4; p++) tricksWon[p] = 0;
    }

    function getCurrentTime() internal view returns (uint256) {
        (, int256 time, , ,) = timeFeed.latestRoundData();
        return uint256(time);
    }

    function currentBidder() internal view returns (uint8) {
        if (biddingPhase == 0) return dealer;
        if (biddingPhase == 1) return (dealer + 2) % 4;
        if (biddingPhase == 2) return (dealer + 1) % 4;
        return (dealer + 3) % 4;
    }
}
