// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract ZeropointDigitalStockNFT is ERC721, Ownable {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    uint256 public tokenCounter;
    mapping(uint256 => string) public stockSymbols;
    mapping(uint256 => uint256) public totalInvested;
    mapping(uint256 => mapping(address => uint256)) public userInvestments;
    mapping(uint256 => uint256) public dividendPool;

    event StockPurchased(uint256 tokenId, address buyer, uint256 amount);
    event StockSold(uint256 tokenId, address seller, uint256 amount);
    event DividendDistributed(uint256 tokenId, uint256 amount);

    constructor(address _usdMediator, address _interoperability) ERC721("ZeropointDigitalStockNFT", "ZDSNFT") Ownable(msg.sender) {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
    }

    function mintStock(address to, string memory stockSymbol) external onlyOwner {
        uint256 tokenId = tokenCounter;
        _mint(to, tokenId);
        stockSymbols[tokenId] = stockSymbol;
        tokenCounter++;
    }

    function buyStock(uint256 tokenId, uint256 amount, uint256 chainId) external {
        require(_exists(tokenId), "Stock does not exist");
        require(amount >= 1e6, "Minimum $1 USD");

        IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        require(usdc.transferFrom(msg.sender, address(usdMediator), amount), "Transfer failed");
        usdMediator.buyStock(stockSymbols[tokenId], amount);

        if (balanceOf(msg.sender) == 0 || ownerOf(tokenId) != msg.sender) {
            _safeTransfer(address(this), msg.sender, tokenId, "");
        }
        totalInvested[tokenId] += amount;
        userInvestments[tokenId][msg.sender] += amount;

        if (chainId != block.chainid) {
            interoperability.crossChainTransfer(block.chainid, chainId, "ZDSNFT", amount, msg.sender);
        }

        emit StockPurchased(tokenId, msg.sender, amount);
    }

    function sellStock(uint256 tokenId, uint256 amount, string memory toAsset, uint256 chainId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        uint256 userInvestment = userInvestments[tokenId][msg.sender];
        require(amount <= userInvestment, "Insufficient balance");

        uint256 proRata = (userInvestment * 1e18) / totalInvested[tokenId];
        uint256 saleAmount = (proRata * amount) / 1e18;

        usdMediator.sellStock(stockSymbols[tokenId], saleAmount, toAsset, msg.sender);

        totalInvested[tokenId] -= saleAmount;
        userInvestments[tokenId][msg.sender] -= saleAmount;
        if (userInvestments[tokenId][msg.sender] == 0) {
            _safeTransfer(msg.sender, address(this), tokenId, "");
        }

        emit StockSold(tokenId, msg.sender, saleAmount);
    }

    function distributeDividends(uint256 tokenId, uint256 amount) external onlyOwner {
        dividendPool[tokenId] += amount;
        for (uint256 i = 0; i < balanceOf(msg.sender); i++) {
            address holder = ownerOf(tokenId);
            uint256 proRata = (userInvestments[tokenId][holder] * 1e18) / totalInvested[tokenId];
            uint256 dividend = (proRata * amount) / 1e18;
            usdMediator.transferUSD(holder, dividend);
            emit DividendDistributed(tokenId, dividend);
        }
    }
}
