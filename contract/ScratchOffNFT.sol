// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract ScratchOffNFT is ERC721, Ownable, VRFConsumerBase {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    uint256 public tokenCounter;
    bytes32 internal keyHash;
    uint256 internal fee;

    enum Mode { Pennies, Nickels, Dimes, Quarters, Dollars }
    uint256[] public costs = [
        1e6,   // $1.00 (Pennies)
        5e6,   // $5.00 (Nickels)
        10e6,  // $10.00 (Dimes)
        25e6,  // $25.00 (Quarters)
        100e6  // $100.00 (Dollars)
    ];

    uint256[9][5] public weights = [
        [10, 5, 5, 10, 10, 10, 10, 10, 30],  // Pennies
        [10, 10, 5, 10, 10, 10, 10, 10, 25], // Nickels
        [20, 10, 10, 10, 10, 10, 10, 10, 20], // Dimes
        [20, 10, 10, 10, 10, 15, 10, 10, 15], // Quarters
        [20, 15, 10, 10, 10, 15, 10, 10, 10]  // Dollars
    ];

    string[9] public symbols = [
        "lightning",
        "GoateElectric",
        "zeropointLogo",
        "zeropointWifiLogo",
        "zeropointPhoneServiceLogo",
        "greyStaxLogo",
        "luckCardLogo",
        "karmaCard",
        "gerastyxOpolLogo"
    ];

    struct ScratchCard {
        address owner;
        Mode mode;
        uint256[9] spots;
        bool revealed;
    }

    mapping(uint256 => ScratchCard) public scratchCards;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    mapping(bytes32 => uint256) public requestIdToSpot;

    event ScratchRequested(uint256 tokenId, address user, Mode mode);
    event SpotRevealed(uint256 tokenId, uint256 spot, string symbol);
    event PrizeAwarded(uint256 tokenId, uint256 prize);

    constructor(
        address _usdMediator,
        address _interoperability,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    )
        ERC721("ScratchOffNFT", "SONFT")
        Ownable(msg.sender)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        keyHash = _keyHash;
        fee = _fee;
    }

    function scratch(string memory asset, uint256 mode, uint256 chainId) external {
        require(mode <= uint256(Mode.Dollars), "Invalid mode");
        uint256 cost = costs[mode];
        address tokenAddress = interoperability.tokenMap(chainId, asset);
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), cost), "Transfer failed");

        uint256 half = cost / 2;
        require(token.transfer(address(usdMediator), half), "Mediator transfer failed");
        require(token.transfer(0xYourRevenueAddress, half), "Revenue transfer failed");

        uint256 tokenId = tokenCounter;
        _mint(msg.sender, tokenId);
        scratchCards[tokenId] = ScratchCard(msg.sender, Mode(mode), [0, 0, 0, 0, 0, 0, 0, 0, 0], false);
        tokenCounter++;

        for (uint256 spot = 0; spot < 9; spot++) {
            bytes32 requestId = requestRandomness(keyHash, fee);
            requestIdToTokenId[requestId] = tokenId;
            requestIdToSpot[requestId] = spot;
        }

        emit ScratchRequested(tokenId, msg.sender, Mode(mode));
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 tokenId = requestIdToTokenId[requestId];
        uint256 spot = requestIdToSpot[requestId];
        ScratchCard storage card = scratchCards[tokenId];
        Mode mode = card.mode;

        uint256 totalWeight = 100;
        uint256 randomValue = randomness % totalWeight;
        uint256 cumulativeWeight = 0;
        for (uint256 i = 0; i < 9; i++) {
            cumulativeWeight += weights[uint256(mode)][i];
            if (randomValue < cumulativeWeight) {
                card.spots[spot] = i;
                emit SpotRevealed(tokenId, spot, symbols[i]);
                break;
            }
        }

        bool allRevealed = true;
        for (uint256 i = 0; i < 9; i++) {
            if (card.spots[i] == 0 && i != spot) {
                allRevealed = false;
                break;
            }
        }

        if (allRevealed && !card.revealed) {
            card.revealed = true;
            uint256 gerastyxCount = 0;
            for (uint256 i = 0; i < 9; i++) {
                if (card.spots[i] == 8) {
                    gerastyxCount++;
                }
            }

            if (gerastyxCount >= 3) {
                uint256 prize = costs[uint256(mode)] * gerastyxCount;
                usdMediator.transferUSD(card.owner, prize);
                emit PrizeAwarded(tokenId, prize);
            }
        }
    }
}
