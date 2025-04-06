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
        mapping(uint256 => uint256) propertiesOwned;
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
        uint256 pausedTime;
    }

    mapping(uint256 => GameSession) public sessions;
    uint256 public sessionCount;
    mapping(bytes32 => uint256) public requestIdToSession;

    uint256 public constant BOARD_SIZE = 40;
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
        uint256[] memory row1 = new uint256[](BOARD_SIZE / 2);
        uint256[] memory row2 = new uint256[](BOARD_SIZE / 2);
        row1[0] = uint256(SpaceType.GO); row2[0] = uint256(SpaceType.JAIL);
        row1[5] = uint256(SpaceType.PROPERTY); row2[5] = uint256(SpaceType.PROPERTY);
    }

    function startSession(GameMode mode, uint256 entryFee) external payable {
        require(sessions[sessionCount].isActive == false, "Session already active");
        if (mode == GameMode.FreePlay) {
            require(msg.value == 0, "Free play requires ad watch");
            usdMediator.handleAdWatch("GameStart", msg.sender);
        } else {
            uint256 requiredFee = mode == GameMode.Reasonable ? 1e6 : mode == GameMode.Gambling ? 5e6 : 20e6;
            require(usdcToken.transferFrom(msg.sender, address(this), requiredFee), "Payment failed");
            usdMediator.handleGerastyxOpolTransaction(sessionCount, requiredFee, "EntryFee");
        }

        GameSession storage session = sessions[sessionCount];
        session.mode = mode;
        session.players.push(msg.sender);
        session.startTime = block.timestamp;
        session.isActive = true;
        session.boardRow1 = new uint256[](BOARD_SIZE / 2);
        session.boardRow2 = new uint256[](BOARD_SIZE / 2);
        emit SessionStarted(sessionCount, mode);
        sessionCount++;
    }

    function joinSession(uint256 sessionId) external payable {
        GameSession storage session = sessions[sessionId];
        require(session.isActive && session.players.length < 8, "Session full or inactive");
        require(block.timestamp < session.startTime + TURN_DURATION, "Too late to join");
        if (session.mode == GameMode.FreePlay) {
            usdMediator.handleAdWatch("GameStart", msg.sender);
        } else {
            uint256 requiredFee = session.mode == GameMode.Reasonable ? 1e6 : session.mode == GameMode.Gambling ? 5e6 : 20e6;
            require(usdcToken.transferFrom(msg.sender, address(this), requiredFee), "Payment failed");
            usdMediator.handleGerastyxOpolTransaction(sessionId, requiredFee, "EntryFee");
        }
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
        requestIdToSession[requestId] = sessionId + 1e18;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 sessionId = requestIdToSession[requestId];
        GameSession storage session = sessions[sessionId % 1e18];
        Player storage player = session.playerData[msg.sender];
        
    }
}
