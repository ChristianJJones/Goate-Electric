// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";
import "./GerastyxPropertyNFT.sol";
import "./AdWatch.sol";

contract GerastyxOpol is Ownable, VRFConsumerBase {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    GerastyxPropertyNFT public propertyNFT;
    AdWatch public adWatch;
    IERC20 public usdcToken;
    address public revenueRecipient;
    bytes32 internal keyHash;
    uint256 internal fee;

    // Game constants
    uint256 public constant BOARD_SIZE = 40;
    uint256 public constant MAX_PLAYERS = 8;
    uint256 public constant MIN_PLAYERS = 4;
    uint256 public constant TURN_TIMEOUT = 30 seconds;
    uint256 public constant AUTO_ROLL_COST = 1 * 10**6; // $1 in USDC
    uint256 public constant JAIL_POSITION = 10;

    // Game modes
    enum GameMode { Free, Civilian, Banker, Monopoly }
    mapping(GameMode => uint256) public entryFees; // In USDC (6 decimals)
    mapping(GameMode => uint256) public passGoRewards; // In USDC
    mapping(GameMode => uint256) public startingBalances; // In USDC

    // Board setup
    mapping(uint256 => uint256) public positionToProperty; // Board position => Property tokenId
    mapping(uint256 => bool) public isLuckyCardPosition;
    mapping(uint256 => bool) public isKarmaCardPosition;
    mapping(uint256 => uint256) public taxPositions; // Position => Tax amount (USDC)

    // Game state
    struct Player {
        address playerAddress;
        uint256 position; // Board position (0–39)
        uint256 balance; // In-game USDC balance
        bool isActive;
        uint256[] ownedProperties; // Token IDs of owned GerastyxPropertyNFTs
        uint256 luckyCards; // Number of LuckyCards
        uint256 karmaCards; // Number of KarmaCards
        bool hasGetOutOfJailCard;
        bool inJail;
        uint256 doubleRolls; // Consecutive doubles rolled
        bool autoRollEnabled;
        uint256 pieceId; // 0: Animal, 1: Clothing, 2: Food, 3: Emoji Rock-Boulder
        uint256 lastTurnTime; // Timestamp of last turn
    }

    struct Game {
        uint256 gameId;
        GameMode mode;
        address[] players;
        mapping(address => Player) playerData;
        uint256 currentPlayerIndex;
        bool isActive;
        bool canJoin;
        uint256 totalPool; // Total USDC in the game
        uint256 adScreenCounter; // Tracks turns for ad screens in Free mode
    }

    mapping(uint256 => Game) public games;
    mapping(bytes32 => uint256) public diceRequestToGameId;
    mapping(bytes32 => uint256) public coinRequestToGameId;
    mapping(address => bool) public hasPassedGo; // Tracks if player passed Go
    mapping(uint256 => uint256) public jailedPlayers; // Player => Remaining jail turns

    // Events for Unreal Engine
    event GameStarted(uint256 indexed gameId, GameMode mode, address[] players, string boardColor);
    event PlayerMoved(address indexed player, uint256 newPosition, uint256 diceRoll, bool movedLeft);
    event PropertyPurchased(address indexed player, uint256 tokenId, uint256 amount);
    event RentPaid(address indexed payer, address indexed receiver, uint256 amount);
    event LuckyCardDrawn(address indexed player, string action);
    event KarmaCardDrawn(address indexed player, string action);
    event PlayerJailed(address indexed player, uint256 turns);
    event PlayerFreed(address indexed player);
    event GameEnded(uint256 indexed gameId, address winner, uint256 winnings);
    event AdScreenTriggered(uint256 indexed gameId, uint256 turnCount);
    event AutoRollEnabled(address indexed player, uint256 gameId);

    constructor(
        address _usdMediator,
        address _interoperability,
        address _propertyNFT,
        address _adWatch,
        address _usdcToken,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        address initialOwner
    )
        Ownable(initialOwner)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        propertyNFT = GerastyxPropertyNFT(_propertyNFT);
        adWatch = AdWatch(_adWatch);
        usdcToken = IERC20(_usdcToken);
        revenueRecipient = initialOwner;
        keyHash = _keyHash;
        fee = _fee;

        // Initialize game modes
        entryFees[GameMode.Free] = 0;
        entryFees[GameMode.Civilian] = 5 * 10**6; // $5
        entryFees[GameMode.Banker] = 20 * 10**6; // $20
        entryFees[GameMode.Monopoly] = 100 * 10**6; // $100

        passGoRewards[GameMode.Free] = 0;
        passGoRewards[GameMode.Civilian] = 5 * 10**6; // $5
        passGoRewards[GameMode.Banker] = 20 * 10**6; // $20
        passGoRewards[GameMode.Monopoly] = 100 * 10**6; // $100

        startingBalances[GameMode.Free] = 250 * 10**6; // $250
        startingBalances[GameMode.Civilian] = 250 * 10**6; // $250
        startingBalances[GameMode.Banker] = 250 * 10**6; // $250
        startingBalances[GameMode.Monopoly] = 500 * 10**6; // $500

        // Initialize board (example positions)
        positionToProperty[1] = 1; // Duck Crossing
        positionToProperty[3] = 2; // Duck Coast
        // Add more properties (up to 30)
        isLuckyCardPosition[2] = true;
        isLuckyCardPosition[7] = true;
        isKarmaCardPosition[4] = true;
        isKarmaCardPosition[9] = true;
        taxPositions[12] = 2 * 10**6; // $2 tax
        taxPositions[28] = 5 * 10**6; // $5 tax
    }

    function startGame(address[] memory players, GameMode mode, uint256[] memory pieceIds) external onlyOwner {
        require(players.length >= MIN_PLAYERS && players.length <= MAX_PLAYERS, "Invalid player count");
        require(pieceIds.length == players.length, "Invalid piece IDs");
        for (uint256 i = 0; i < pieceIds.length; i++) {
            require(pieceIds[i] <= 3, "Invalid piece ID"); // 0: Animal, 1: Clothing, 2: Food, 3: Emoji Rock-Boulder
        }

        uint256 gameId = games.length;
        Game storage game = games[gameId];
        game.gameId = gameId;
        game.mode = mode;
        game.isActive = true;
        game.canJoin = true;
        game.players = players;
        game.currentPlayerIndex = 0;
        game.totalPool = entryFees[mode] * players.length;

        for (uint256 i = 0; i < players.length; i++) {
            if (mode == GameMode.Free) {
                adWatch.watchAd("GameEntry", players[i]);
            } else {
                require(usdcToken.transferFrom(players[i], address(this), entryFees[mode]), "Entry fee transfer failed");
            }
            game.playerData[players[i]] = Player({
                playerAddress: players[i],
                position: 0,
                balance: startingBalances[mode],
                isActive: true,
                ownedProperties: new uint256[](0),
                luckyCards: 0,
                karmaCards: 0,
                hasGetOutOfJailCard: false,
                inJail: false,
                doubleRolls: 0,
                autoRollEnabled: false,
                pieceId: pieceIds[i],
                lastTurnTime: block.timestamp
            });
        }

        emit GameStarted(gameId, mode, players, "BlackAndGold");
    }

    function enableAutoRoll(uint256 gameId) external {
        Game storage game = games[gameId];
        require(game.isActive, "Game not active");
        require(game.playerData[msg.sender].isActive, "Player not active");
        require(!game.playerData[msg.sender].autoRollEnabled, "Auto-roll already enabled");
        require(usdcToken.transferFrom(msg.sender, address(this), AUTO_ROLL_COST), "Auto-roll fee failed");
        game.playerData[msg.sender].autoRollEnabled = true;
        game.totalPool += AUTO_ROLL_COST;
        emit AutoRollEnabled(msg.sender, gameId);
    }

    function rollDiceAndCoin(uint256 gameId) external {
        Game storage game = games[gameId];
        require(game.isActive, "Game not active");
        require(msg.sender == game.players[game.currentPlayerIndex], "Not your turn");
        require(block.timestamp <= game.playerData[msg.sender].lastTurnTime + TURN_TIMEOUT, "Turn timeout");
        require(LINK.balanceOf(address(this)) >= fee * 2, "Insufficient LINK for VRF");

        // Request dice roll
        bytes32 diceRequestId = requestRandomness(keyHash, fee);
        diceRequestToGameId[diceRequestId] = gameId;

        // Request coin flip
        bytes32 coinRequestId = requestRandomness(keyHash, fee);
        coinRequestToGameId[coinRequestId] = gameId;
    }

    function autoRoll(uint256 gameId) external {
        Game storage game = games[gameId];
        address currentPlayer = game.players[game.currentPlayerIndex];
        require(game.isActive, "Game not active");
        require(game.playerData[currentPlayer].autoRollEnabled, "Auto-roll not enabled");
        require(block.timestamp >= game.playerData[currentPlayer].lastTurnTime + TURN_TIMEOUT - 5, "Too early for auto-roll");
        require(LINK.balanceOf(address(this)) >= fee * 2, "Insufficient LINK for VRF");

        // Request dice roll
        bytes32 diceRequestId = requestRandomness(keyHash, fee);
        diceRequestToGameId[diceRequestId] = gameId;

        // Request coin flip
        bytes32 coinRequestId = requestRandomness(keyHash, fee);
        coinRequestToGameId[coinRequestId] = gameId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 gameId = diceRequestToGameId[requestId] != 0 ? diceRequestToGameId[requestId] : coinRequestToGameId[requestId];
        Game storage game = games[gameId];
        require(game.isActive, "Game not active");

        address currentPlayer = game.players[game.currentPlayerIndex];
        Player storage player = game.playerData[currentPlayer];

        if (diceRequestToGameId[requestId] != 0) {
            // Handle dice roll
            uint256 dice1 = (randomness % 6) + 1;
            uint256 dice2 = ((randomness >> 128) % 6) + 1;
            uint256 diceRoll = dice1 + dice2;
            bool isDouble = dice1 == dice2;

            if (isDouble) {
                player.doubleRolls++;
                if (player.doubleRolls >= 3) {
                    sendToJail(gameId, currentPlayer);
                    return;
                }
            } else {
                player.doubleRolls = 0;
            }

            // Store dice roll for coin flip processing
            player.position = diceRoll; // Temporarily store dice roll
            emit PlayerMoved(currentPlayer, diceRoll, diceRoll, false); // Temporary event for UI
        } else if (coinRequestToGameId[requestId] != 0) {
            // Handle coin flip
            bool moveLeft = (randomness % 2) == 0; // 0: Left, 1: Right
            uint256 diceRoll = player.position; // Retrieve stored dice roll
            uint256 newPosition = calculateNewPosition(player.position, diceRoll, moveLeft);

            // Update position and process
            if (newPosition < player.position && hasPassedGo[currentPlayer]) {
                if (game.mode == GameMode.Free) {
                    adWatch.watchAd("PassGo", currentPlayer);
                } else {
                    player.balance += passGoRewards[game.mode];
                    game.totalPool += passGoRewards[game.mode];
                }
            }
            player.position = newPosition;
            emit PlayerMoved(currentPlayer, newPosition, diceRoll, moveLeft);

            // Process position
            processPosition(gameId, currentPlayer, newPosition);

            // Check if player can roll again
            if (player.doubleRolls > 0 && !player.inJail) {
                player.lastTurnTime = block.timestamp;
            } else {
                // Next player's turn
                game.currentPlayerIndex = (game.currentPlayerIndex + 1) % game.players.length;
                while (!game.playerData[game.players[game.currentPlayerIndex]].isActive) {
                    game.currentPlayerIndex = (game.currentPlayerIndex + 1) % game.players.length;
                }
                game.playerData[game.players[game.currentPlayerIndex]].lastTurnTime = block.timestamp;
            }

            // Trigger ad screen in Free mode
            if (game.mode == GameMode.Free) {
                game.adScreenCounter++;
                if (game.adScreenCounter % 3 == 0) {
                    emit AdScreenTriggered(gameId, game.adScreenCounter);
                }
            }

            // Update join status
            if (game.canJoin && game.adScreenCounter >= game.players.length) {
                game.canJoin = false;
            }

            // Check game end
            checkGameEnd(gameId);
        }
    }

    function calculateNewPosition(uint256 currentPosition, uint256 diceRoll, bool moveLeft) internal pure returns (uint256) {
        if (moveLeft) {
            return (currentPosition + BOARD_SIZE - diceRoll) % BOARD_SIZE;
        } else {
            return (currentPosition + diceRoll) % BOARD_SIZE;
        }
    }

    function processPosition(uint256 gameId, address player, uint256 position) internal {
        Game storage game = games[gameId];
        Player storage playerData = game.playerData[player];

        if (playerData.inJail) {
            handleJail(gameId, player);
            return;
        }

        if (positionToProperty[position] > 0) {
            uint256 tokenId = positionToProperty[position];
            address propertyOwner = propertyNFT.ownerOf(tokenId);
            if (propertyOwner == address(0) && hasPassedGo[player]) {
                // Unowned property, player can buy (handled via frontend options)
                // Options: "buy property", "roll dice" (if double), "pass turn"
            } else if (propertyOwner != player && propertyOwner != address(0)) {
                // Pay rent
                uint256 rent = propertyNFT.propertyValues(tokenId) / 10; // 10% of property value
                handleRentPayment(gameId, player, propertyOwner, rent, tokenId);
            }
        } else if (isLuckyCardPosition[position]) {
            drawLuckyCard(gameId, player);
        } else if (isKarmaCardPosition[position]) {
            drawKarmaCard(gameId, player);
        } else if (taxPositions[position] > 0) {
            if (game.mode == GameMode.Free) {
                adWatch.watchAd("Tax", player);
            } else {
                if (playerData.balance >= taxPositions[position]) {
                    playerData.balance -= taxPositions[position];
                    game.totalPool += taxPositions[position];
                } else {
                    handleBankruptcy(gameId, player, address(0), taxPositions[position]);
                }
            }
        }
    }

    function buyProperty(uint256 gameId, uint256 tokenId) external {
        Game storage game = games[gameId];
        require(game.isActive, "Game not active");
        require(hasPassedGo[msg.sender], "Must pass Go first");
        require(propertyNFT.ownerOf(tokenId) == address(0), "Property already owned");
        require(positionToProperty[game.playerData[msg.sender].position] == tokenId, "Not on property position");

        Player storage player = game.playerData[msg.sender];
        uint256 cost = game.mode == GameMode.Civilian ? 1 * 10**6 : propertyNFT.propertyValues(tokenId);
        if (game.mode == GameMode.Free) {
            adWatch.watchAd("BuyProperty", msg.sender);
        } else {
            require(player.balance >= cost, "Insufficient balance");
            player.balance -= cost;
            game.totalPool += cost;
        }

        if (game.mode == GameMode.Monopoly) {
            propertyNFT.mint(msg.sender, tokenId);
        } else {
            // In-game property (not NFT)
            player.ownedProperties.push(tokenId);
        }
        emit PropertyPurchased(msg.sender, tokenId, cost);
    }

    function handleRentPayment(uint256 gameId, address payer, address receiver, uint256 amount, uint256 tokenId) internal {
        Game storage game = games[gameId];
        Player storage payerData = game.playerData[payer];
        if (game.mode == GameMode.Free) {
            adWatch.watchAd("Rent", payer);
            emit RentPaid(payer, receiver, 0);
        } else if (payerData.balance >= amount) {
            payerData.balance -= amount;
            game.playerData[receiver].balance += (amount * 99) / 100;
            uint256 nftShare = amount / 100;
            game.totalPool += nftShare;
            emit RentPaid(payer, receiver, amount);
        } else {
            handleBankruptcy(gameId, payer, receiver, amount);
        }
    }

    function handleBankruptcy(uint256 gameId, address player, address owedTo, uint256 amountOwed) internal {
        Game storage game = games[gameId];
        Player storage playerData = game.playerData[player];
        uint256 totalValue = playerData.balance;

        // Sell in-game properties
        for (uint256 i = 0; i < playerData.ownedProperties.length; i++) {
            uint256 tokenId = playerData.ownedProperties[i];
            uint256 value = propertyNFT.propertyValues(tokenId) * 80 / 100; // 80% of value
            totalValue += value;
        }

        if (totalValue >= amountOwed) {
            // Pay owed amount
            if (owedTo != address(0)) {
                game.playerData[owedTo].balance += (amountOwed * 99) / 100;
                game.totalPool += amountOwed / 100;
            } else {
                game.totalPool += amountOwed;
            }
            playerData.balance = totalValue - amountOwed;
            // Clear properties
            delete playerData.ownedProperties;
        } else {
            // Full bankruptcy
            if (owedTo != address(0)) {
                game.playerData[owedTo].balance += (totalValue * 99) / 100;
                game.totalPool += totalValue / 100;
            } else {
                game.totalPool += totalValue;
            }
            playerData.balance = 0;
            delete playerData.ownedProperties;
            playerData.isActive = false;
            if (game.mode == GameMode.Free) {
                adWatch.watchAd("Bankruptcy", player);
            }
        }

        emit RentPaid(player, owedTo, totalValue);
    }

    function drawLuckyCard(uint256 gameId, address player) internal {
        Game storage game = games[gameId];
        Player storage playerData = game.playerData[player];
        // Random selection (simplified, could use VRF)
        uint256 action = block.timestamp % 8;
        if (action == 0) {
            // Get $1 from every player
            for (uint256 i = 0; i < game.players.length; i++) {
                if (game.playerData[game.players[i]].isActive && game.players[i] != player) {
                    if (game.mode == GameMode.Free) {
                        adWatch.watchAd("LuckyCard", game.players[i]);
                    } else {
                        game.playerData[game.players[i]].balance -= 1 * 10**6;
                        playerData.balance += 1 * 10**6;
                    }
                }
            }
            emit LuckyCardDrawn(player, "Get $1 from every player");
        } else if (action == 1) {
            // Extra roll
            playerData.doubleRolls = 1; // Allows another roll
            emit LuckyCardDrawn(player, "Extra roll");
        } else if (action == 2) {
            // Go to Go
            playerData.position = 0;
            if (game.mode != GameMode.Free) {
                playerData.balance += passGoRewards[game.mode];
                game.totalPool += passGoRewards[game.mode];
            } else {
                adWatch.watchAd("PassGo", player);
            }
            hasPassedGo[player] = true;
            emit LuckyCardDrawn(player, "Go to Go");
        } else if (action == 3) {
            // Pay $1 tax
            if (game.mode == GameMode.Free) {
                adWatch.watchAd("Tax", player);
            } else {
                playerData.balance -= 1 * 10**6;
                game.totalPool += 1 * 10**6;
            }
            emit LuckyCardDrawn(player, "Pay $1 tax");
        } else if (action == 4) {
            // Skip a player's turn
            uint256 targetIndex = (game.currentPlayerIndex + 1) % game.players.length;
            emit LuckyCardDrawn(player, "Skip a player's turn");
        } else if (action == 5) {
            // Send a player to jail
            uint256 targetIndex = (game.currentPlayerIndex + 1) % game.players.length;
            sendToJail(gameId, game.players[targetIndex]);
            emit LuckyCardDrawn(player, "Send a player to jail");
        } else if (action == 6) {
            // Pay $1 to bank
            if (game.mode == GameMode.Free) {
                adWatch.watchAd("Tax", player);
            } else {
                playerData.balance -= 1 * 10**6;
                game.totalPool += 1 * 10**6;
            }
            emit LuckyCardDrawn(player, "Pay $1 to bank");
        } else {
            // Get out of jail free card
            playerData.hasGetOutOfJailCard = true;
            emit LuckyCardDrawn(player, "Get out of jail free card");
        }
        playerData.luckyCards++;
    }

    function drawKarmaCard(uint256 gameId, address player) internal {
        Game storage game = games[gameId];
        Player storage playerData = game.playerData[player];
        // Random selection (simplified, could use VRF)
        uint256 action = block.timestamp % 5;
        if (action == 0) {
            // Go to Go
            playerData.position = 0;
            if (game.mode != GameMode.Free) {
                playerData.balance += passGoRewards[game.mode];
                game.totalPool += passGoRewards[game.mode];
            } else {
                adWatch.watchAd("PassGo", player);
            }
            hasPassedGo[player] = true;
            emit KarmaCardDrawn(player, "Go to Go");
        } else if (action == 1) {
            // Pay $1 to every player
            for (uint256 i = 0; i < game.players.length; i++) {
                if (game.playerData[game.players[i]].isActive && game.players[i] != player) {
                    if (game.mode == GameMode.Free) {
                        adWatch.watchAd("KarmaCard", player);
                    } else {
                        playerData.balance -= 1 * 10**6;
                        game.playerData[game.players[i]].balance += 1 * 10**6;
                    }
                }
            }
            emit KarmaCardDrawn(player, "Pay $1 to every player");
        } else if (action == 2) {
            // Pay $1 to bank
            if (game.mode == GameMode.Free) {
                adWatch.watchAd("Tax", player);
            } else {
                playerData.balance -= 1 * 10**6;
                game.totalPool += 1 * 10**6;
            }
            emit KarmaCardDrawn(player, "Pay $1 to bank");
        } else if (action == 3) {
            // Go to jail
            sendToJail(gameId, player);
            emit KarmaCardDrawn(player, "Go to jail");
        } else {
            // Get out of jail free card
            playerData.hasGetOutOfJailCard = true;
            emit KarmaCardDrawn(player, "Get out of jail free card");
        }
        playerData.karmaCards++;
    }

    function sendToJail(uint256 gameId, address player) internal {
        Game storage game = games[gameId];
        Player storage playerData = game.playerData[player];
        playerData.inJail = true;
        playerData.position = JAIL_POSITION;
        jailedPlayers[player] = 3; // 3 turns in jail
        playerData.doubleRolls = 0;
        emit PlayerJailed(player, 3);
    }

    function handleJail(uint256 gameId, address player) internal {
        Game storage game = games[gameId];
        Player storage playerData = game.playerData[player];
        if (playerData.hasGetOutOfJailCard) {
            playerData.hasGetOutOfJailCard = false;
            playerData.inJail = false;
            jailedPlayers[player] = 0;
            emit PlayerFreed(player);
        } else if (jailedPlayers[player] > 0) {
            jailedPlayers[player]--;
            if (jailedPlayers[player] == 0) {
                playerData.inJail = false;
                emit PlayerFreed(player);
            }
        }
    }

    function checkGameEnd(uint256 gameId) internal {
        Game storage game = games[gameId];
        uint256 activePlayers = 0;
        address lastActivePlayer;

        for (uint256 i = 0; i < game.players.length; i++) {
            if (game.playerData[game.players[i]].isActive) {
                activePlayers++;
                lastActivePlayer = game.players[i];
            }
        }

        if (activePlayers <= 1) {
            game.isActive = false;
            if (activePlayers == 1) {
                // Sell winner's properties
                Player storage winner = game.playerData[lastActivePlayer];
                uint256 totalWinnings = winner.balance;
                for (uint256 i = 0; i < winner.ownedProperties.length; i++) {
                    uint256 tokenId = winner.ownedProperties[i];
                    uint256 value = propertyNFT.propertyValues(tokenId) * 90 / 100; // 90% of value
                    totalWinnings += value;
                }
                uint256 revenueShare = totalWinnings / 10;
                totalWinnings -= revenueShare;
                usdMediator.transferUSD(lastActivePlayer, totalWinnings);
                usdMediator.transferUSD(revenueRecipient, revenueShare);
                emit GameEnded(gameId, lastActivePlayer, totalWinnings);
            } else {
                usdMediator.transferUSD(revenueRecipient, game.totalPool);
                emit GameEnded(gameId, address(0), 0);
            }
        }
    }

    function setRevenueRecipient(address _recipient) external onlyOwner {
        revenueRecipient = _recipient;
    }
}
