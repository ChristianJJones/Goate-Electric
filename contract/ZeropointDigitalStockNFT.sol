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
        _mint(to, token
