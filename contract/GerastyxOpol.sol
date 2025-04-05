// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./InstilledInteroperability.sol";
import "./GerastyxPropertyNFT.sol";
import "./GreyStax.sol";
import "./USDMediator.sol";

contract GerastyxOpol is VRFConsumerBase {
    InstilledInteroperability public interoperability;
    GerastyxPropertyNFT public propertyNFT;
    GreyStax public greyStax;
    USDMediator public usdMediator;
    IERC20 public usdcToken;
    address public owner;

    enum GameMode { FreePlay, Reasonable, Gambling, Rich }
    enum SpaceType { GO, JAIL, HIDEOUT, GO_TO_JAIL, BLANK, PROPERTY, LUCK, KARMA }

    struct Player {
        address playerAddress;
        uint256 positionRow1;
        uint256 positionRow2;
        uint256 balance;
        bool hasCompletedLap;
        uint256 jailedTurns;
        mapping(uint256 => uint256) propertiesOwned; // propertyId => houseCount (5 = hotel)
        uint256[] luckCards;
        uint256[] karmaCards;
    }

    struct GameSession {
        GameMode mode;
        address[] players;
        mapping(address => Player) playerData;
        uint256 startTime;
        uint256 currentTurn;
        bool isActive;
        uint256[] boardRow1;
        uint256[] boardRow2;
    }

    mapping(uint256 => GameSession) public sessions;
    uint256 public sessionCount;
    mapping(bytes32 => uint256) public requestIdToSession;

    uint256 public constant BOARD_SIZE = 40; // Example: 20 spaces per row
    uint256 public constant TURN_DURATION = 15 seconds;
    uint256 public constant SESSION_DURATION = 60 minutes;

    bytes32 internal keyHash;
    uint256 internal fee;

    event DiceRolled(address player, uint256 sessionId, uint256 roll);
    event CoinFlipped(address player, uint256 sessionId, bool isHeads);
    event PropertyBought(address player, uint256 sessionId, uint256 propertyId);
    event SessionStarted(uint256 sessionId, GameMode mode);
    event SessionEnded(uint256 sessionId, address winner);

    constructor(
        address _interoperability,
        address _propertyNFT,
        address _greyStax,
        address _usdMediator,
        address _usdcToken,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        owner = msg.sender;
        interoperability = InstilledInteroperability(_interoperability);
        propertyNFT = GerastyxPropertyNFT(_propertyNFT);
        greyStax = GreyStax(_greyStax);
        usdMediator = USDMediator(_usdMediator);
        usdcToken = IERC20(_usdcToken);
        keyHash = _keyHash;
        fee = _fee;
        initializeBoard();
    }

    function initializeBoard() internal {
        // Define board layout (example)
        uint256[] memory row1 = new uint256[](BOARD_SIZE / 2);
        uint256[] memory row2 = new uint256[](BOARD_SIZE / 2);
        row1[0] = uint256(SpaceType.GO); row2[0] = uint256(SpaceType.JAIL);
        // Add properties, luck/karma cards, etc., based on your layout
        // This is a simplified example; expand as needed
    }

    function startSession(GameMode mode, uint256 entryFee) external payable {
        require(sessions[sessionCount].isActive == false, "Session already active");
        if (mode == GameMode.FreePlay) {
            require(msg.value == 0, "Free play requires ad watch");
            // Trigger ad watch logic via USDMediator
            usdMediator.handleAdWatch("GameStart", msg.sender);
        } else {
            uint256 requiredFee = mode == GameMode.Reasonable ? 1e6 : mode == GameMode.Gambling ? 5e6 : 20e6; // USDC in 6 decimals
            require(usdcToken.transferFrom(msg.sender, address(this), requiredFee), "Payment failed");
            usdMediator.distributeRevenue(requiredFee);
        }

        GameSession storage session = sessions[sessionCount];
        session.mode = mode;
        session.players.push(msg.sender);
        session.startTime = block.timestamp;
        session.isActive = true;
        emit SessionStarted(sessionCount, mode);
        sessionCount++;
    }

    function joinSession(uint256 sessionId) external payable {
        GameSession storage session = sessions[sessionId];
        require(session.isActive && session.players.length < 8, "Session full or inactive");
        require(block.timestamp < session.startTime + TURN_DURATION, "Too late to join");
        // Same payment logic as startSession
        session.players.push(msg.sender);
    }

    function rollDice(uint256 sessionId) external {
        GameSession storage session = sessions[sessionId];
        require(session.isActive && session.players[session.currentTurn] == msg.sender, "Not your turn");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIdToSession[requestId] = sessionId;
    }

    function flipCoin(uint256 sessionId) external {
        GameSession storage session = sessions[sessionId];
        require(session.isActive && session.players[session.currentTurn] == msg.sender, "Not your turn");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIdToSession[requestId] = sessionId + 1e18; // Offset to distinguish from dice
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 sessionId = requestIdToSession[requestId];
        GameSession storage session = sessions[sessionId % 1e18];
        Player storage player = session.playerData[msg.sender];
        
        if (sessionId < 1e18) { // Dice roll
            uint256 roll = (randomness % 6) + 1;
            movePlayer(sessionId, roll);
            emit DiceRolled(msg.sender, sessionId, roll);
        } else { // Coin flip
            bool isHeads = randomness % 2 == 0; // Heads (left) or Tails (right)
            player.positionRow1 = isHeads ? player.positionRow1 : player.positionRow2;
            emit CoinFlipped(msg.sender, sessionId % 1e18, isHeads);
        }
        nextTurn(sessionId);
    }

    function movePlayer(uint256 sessionId, uint256 steps) internal {
        GameSession storage session = sessions[sessionId];
        Player storage player = session.playerData[msg.sender];
        uint256 newPos = (player.positionRow1 + steps) % (BOARD_SIZE / 2);
        if (newPos < player.positionRow1) {
            player.hasCompletedLap = true;
            uint256 paycheck = session.mode == GameMode.FreePlay ? 0 : session.mode == GameMode.Reasonable ? 5e6 : session.mode == GameMode.Gambling ? 20e6 : 100e6;
            greyStax.mint(msg.sender, paycheck);
        }
        player.positionRow1 = newPos;
        handleSpace(sessionId, newPos);
    }

    function handleSpace(uint256 sessionId, uint256 position) internal {
        GameSession storage session = sessions[sessionId];
        SpaceType space = SpaceType(session.boardRow1[position]);
        if (space == SpaceType.PROPERTY) {
            uint256 propertyId = position; // Simplified mapping
            if (propertyNFT.ownerOf(propertyId) != address(0) && propertyNFT.ownerOf(propertyId) != msg.sender) {
                uint256 rent = calculateRent(sessionId, propertyId);
                payRent(sessionId, propertyId, rent);
            }
        } // Add logic for other space types
    }

    function buyProperty(uint256 sessionId, uint256 propertyId) external {
        GameSession storage session = sessions[sessionId];
        Player storage player = session.playerData[msg.sender];
        require(player.hasCompletedLap, "Complete a lap first");
        uint256 price = getPropertyPrice(session.mode, propertyId);
        if (session.mode == GameMode.FreePlay) {
            usdMediator.handleAdWatch("PropertyPurchase", msg.sender);
        } else {
            require(greyStax.transferFrom(msg.sender, address(this), price), "Payment failed");
            usdMediator.distributeRevenue(price);
        }
        propertyNFT.safeTransferFrom(address(this), msg.sender, propertyId);
        player.propertiesOwned[propertyId] = 0;
        emit PropertyBought(msg.sender, sessionId, propertyId);
    }

    function calculateRent(uint256 sessionId, uint256 propertyId) internal view returns (uint256) {
        GameSession storage session = sessions[sessionId];
        uint256 basePrice = getPropertyPrice(session.mode, propertyId);
        uint256 houseCount = sessions[sessionId].playerData[propertyNFT.ownerOf(propertyId)].propertiesOwned[propertyId];
        return houseCount == 5 ? basePrice / 2 : basePrice / 10 + (houseCount * basePrice / 20);
    }

    function payRent(uint256 sessionId, uint256 propertyId, uint256 rent) internal {
        Player storage player = sessions[sessionId].playerData[msg.sender];
        address owner = propertyNFT.ownerOf(propertyId);
        require(greyStax.transferFrom(msg.sender, owner, rent), "Rent payment failed");
        usdMediator.distributeRevenue(rent);
    }

    function getPropertyPrice(GameMode mode, uint256 propertyId) internal pure returns (uint256) {
        // Implement pricing logic based on mode and propertyId
        // Example: return mode == GameMode.Reasonable ? 1e6 : mode == GameMode.Gambling ? 10e6 : 50e6;
    }

    function nextTurn(uint256 sessionId) internal {
        GameSession storage session = sessions[sessionId];
        session.currentTurn = (session.currentTurn + 1) % session.players.length;
        if (block.timestamp > session.startTime + SESSION_DURATION) {
            endSession(sessionId);
        }
    }

    function endSession(uint256 sessionId) internal {
        GameSession storage session = sessions[sessionId];
        session.isActive = false;
        address winner = session.players[0]; // Simplified; determine actual winner
        uint256 appraisal = calculateAppraisal(sessionId, winner);
        uint256 payout = session.mode == GameMode.FreePlay ? 0 : session.mode == GameMode.Reasonable ? 1e6 : session.mode == GameMode.Gambling ? 10e6 : 25e6;
        greyStax.mint(winner, appraisal + payout);
        emit SessionEnded(sessionId, winner);
    }

    function calculateAppraisal(uint256 sessionId, address player) internal returns (uint256) {
        // Sum up value of properties, houses, hotels, cards
        return 0; // Placeholder
    }
}
