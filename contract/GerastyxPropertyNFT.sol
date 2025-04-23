// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract GerastyxPropertyNFT is ERC721, Ownable {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    uint256 public constant TOTAL_PROPERTIES = 30;
    uint256 public constant TOKENS_PER_PROPERTY = 1_000_000_000;
    uint256 public tokenCounter;

    mapping(uint256 => uint256) public propertyValues; // Token ID => Value in USDC
    mapping(uint256 => uint256) public propertyMarketCaps; // Token ID => Market cap
    mapping(address => uint256[]) public userDecks; // User's selected deck (max 15 NFTs)
    mapping(uint256 => mapping(string => uint256)) public assetAllocations; // Token ID => Asset => Amount

    string[] public supportedAssets = [
        "AQUA", "XLM", "yUSD", "yXLM", "yBTC", "WFM", "TTWO", "BBY", "SFM", "DOLE"
    ];

    event PropertyMinted(uint256 tokenId, address owner, uint256 value);
    event DeckUpdated(address owner, uint256[] tokenIds);
    event RevenueDistributed(uint256 tokenId, uint256 amount, string asset);

    constructor(address _usdMediator, address _interoperability, address initialOwner)
        ERC721("GerastyxPropertyNFT", "GPNFT")
        Ownable(initialOwner)
    {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        initializeProperties();
    }

    function initializeProperties() internal {
        propertyValues[1] = 100 * 10**6; // Duck Crossing
        propertyValues[2] = 110 * 10**6; // Duck Coast
        // Initialize remaining 28 properties with values
        for (uint256 i = 3; i <= TOTAL_PROPERTIES; i++) {
            propertyValues[i] = 100 * 10**6 + (i - 1) * 10 * 10**6;
        }
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        require(tokenId <= TOTAL_PROPERTIES * TOKENS_PER_PROPERTY, "Exceeds total supply");
        _safeMint(to, tokenId);
        tokenCounter++;
        emit PropertyMinted(tokenId, to, propertyValues[tokenId]);
    }

    function buyPropertyNFT(address buyer, uint256 tokenId, uint256 amount) external {
        require(tokenId <= TOTAL_PROPERTIES, "Invalid property");
        require(amount >= propertyValues[tokenId], "Insufficient payment");
        require(tokenCounter < TOTAL_PROPERTIES * TOKENS_PER_PROPERTY, "Max supply reached");

        // Allocate payment across supported assets
        uint256 perAsset = amount / supportedAssets.length;
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            assetAllocations[tokenId][supportedAssets[i]] += perAsset;
            usdMediator.buyStock(supportedAssets[i], perAsset);
        }

        _safeMint(buyer, tokenId);
        tokenCounter++;
        propertyMarketCaps[tokenId] += amount;
        emit PropertyMinted(tokenId, buyer, amount);
    }

    function sellPropertyNFT(address seller, uint256 tokenId, bool isAuction) external {
        require(ownerOf(tokenId) == seller, "Not owner");
        uint256 value = propertyValues[tokenId];
        uint256 payout = isAuction ? (value * 80) / 100 : value;

        // Sell underlying assets
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            uint256 assetAmount = assetAllocations[tokenId][supportedAssets[i]];
            usdMediator.sellStock(supportedAssets[i], assetAmount, "USDC", seller);
            assetAllocations[tokenId][supportedAssets[i]] = 0;
        }

        if (isAuction) {
            uint256 mediatorShare = value / 10;
            usdMediator.transferUSD(address(interoperability), mediatorShare / 2);
            usdMediator.transferUSD(address(usdMediator), mediatorShare / 2);
        }

        _burn(tokenId);
        propertyMarketCaps[tokenId] -= value;
    }

    function distributeDividends(uint256 tokenId, uint256 amount) external onlyOwner {
        uint256 revenueShare = (amount * 50) / 100;
        uint256 nftShare = (amount * 30) / 100;
        uint256 userShare = (amount * 20) / 100;

        // Revenue distribution
        usdMediator.transferUSD(0xCj03nesRevenueAddress, revenueShare / 2);
        usdMediator.transferUSD(address(interoperability), revenueShare / 4);
        usdMediator.transferUSD(address(usdMediator), revenueShare / 4);

        // NFT share (1% to each of 30 properties)
        for (uint256 i = 1; i <= TOTAL_PROPERTIES; i++) {
            propertyMarketCaps[i] += nftShare / TOTAL_PROPERTIES;
        }

        // User share (split across GOATE, GySt, BTC, USD)
        address owner = ownerOf(tokenId);
        usdMediator.transferUSD(owner, userShare / 4); // USD
        interoperability.crossChainTransfer(1, 1, "GOATE", userShare / 4, owner);
        interoperability.crossChainTransfer(1, 1, "GySt", userShare / 4, owner);
        interoperability.crossChainTransfer(1, 1, "BTC", userShare / 4, owner);

        emit RevenueDistributed(tokenId, amount, "USDC");
    }

    function updateDeck(uint256[] memory tokenIds) external {
        require(tokenIds.length <= 15, "Deck cannot exceed 15 NFTs");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Not owner of NFT");
        }
        userDecks[msg.sender] = tokenIds;
        emit DeckUpdated(msg.sender, tokenIds);
    }
}
