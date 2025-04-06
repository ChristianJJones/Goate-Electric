// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./InstilledInteroperability.sol";
import "./GerastyxPropertyNFT.sol";
import "./GreyStax.sol";
import "./USDMediator.sol";

contract GerastyxOpol is VRFConsumerBase {
    USDMediator public usdMediator;
    GreyStax public greyStax;
    GerastyxPropertyNFT public propertyNFT;
    uint256 public sessionCount;
    bytes32 internal keyHash;
    uint256 internal fee;

    struct Session {
        address[] players;
        uint256 mode;
        mapping(address => uint256) positions;
        mapping(address => uint256) balances;
        bool active;
    }

    mapping(uint256 => Session) public sessions;
    mapping(bytes32 => uint256) public requestIdToSession;

    event SessionStarted(uint256 sessionId, uint256 mode);
    event DiceRolled(uint256 sessionId, address player, uint256 result);

    constructor(
        address _usdMediator,
        address _greyStax,
        address _propertyNFT,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        usdMediator = USDMediator(_usdMediator);
        greyStax = GreyStax(_greyStax);
        propertyNFT = GerastyxPropertyNFT(_propertyNFT);
        keyHash = _keyHash;
        fee = _fee;
    }

    function startSession(uint256 mode, uint256 amount) external {
        require(mode <= 3, "Invalid mode");
        if (mode > 0) {
            IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
            require(usdc.transferFrom(msg.sender, address(usdMediator), amount), "Transfer failed");
            usdMediator.handleGerastyxOpolTransaction(sessionCount, amount, "start");
        }

        Session storage session = sessions[sessionCount];
        session.players.push(msg.sender);
        session.mode = mode;
        session.balances[msg.sender] = mode == 0 ? 1500e18 : mode == 1 ? 1500e6 : mode == 2 ? 5000e6 : 20000e6;
        session.active = true;

        emit SessionStarted(sessionCount, mode);
        sessionCount++;
    }

    function rollDice(uint256 sessionId) external {
        Session storage session = sessions[sessionId];
        require(session.active, "Session not active");
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIdToSession[requestId] = sessionId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 sessionId = requestIdToSession[requestId];
        Session storage session = sessions[sessionId];
        address player = session.players[session.players.length - 1];
        uint256 result = (randomness % 6) + 1 + (randomness % 6) + 1;
        session.positions[player] = (session.positions[player] + result) % 40;
        emit DiceRolled(sessionId, player, result);
    }
}
