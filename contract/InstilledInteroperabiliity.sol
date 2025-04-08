// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TheGoateToken.sol";

contract InstilledInteroperability {
    address public owner;
    TheGoateToken public goateToken;
    mapping(uint256 => mapping(string => address)) public tokenMap;
    mapping(string => string) public tradingAPIs;
    mapping(string => string) public sportsDataAPIs;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _goateToken) {
        owner = msg.sender;
        goateToken = TheGoateToken(_goateToken);
        // Token mappings from provided version
        tokenMap[1]["USDC"] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // Ethereum USDC
        tokenMap[1]["ZPE"] = 0xYourZPEAddress; // Placeholder
        tokenMap[1]["ZPW"] = 0xYourZPWAddress; // Placeholder
        tokenMap[1]["ZPP"] = 0xYourZPPAddress; // Placeholder
        tokenMap[1]["GySt"] = 0xYourGreyStaxAddress; // Placeholder
        tokenMap[512]["XLM"] = 0xYourStellarXLMAddress; // Placeholder
        tokenMap[1]["GOATE"] = _goateToken; // Added Goate Token
        // Trading APIs from provided version
        tradingAPIs["Alpaca"] = "https://api.alpaca.markets";
        tradingAPIs["Tradier"] = "https://api.tradier.com";
        tradingAPIs["SnapTrade"] = "https://api.snaptrade.com";
        tradingAPIs["ETrade"] = "https://api.etrade.com";
        tradingAPIs["TradeStation"] = "https://api.tradestation.com";
        tradingAPIs["Questrade"] = "https://api.questrade.com";
        tradingAPIs["Stellar"] = "https://horizon.stellar.org";
        tradingAPIs["Aquarius"] = "https://api.aquariusdex.com";
        tradingAPIs["MoonPay"] = "https://api.moonpay.com";
        tradingAPIs["1inch"] = "https://api.1inch.exchange/v5.0";
        tradingAPIs["Uniswap"] = "https://api.uniswap.org/v1";
        tradingAPIs["PancakeSwap"] = "https://api.pancakeswap.info/api/v2";
        tradingAPIs["OKX"] = "https://www.okx.com/api/v5";
        tradingAPIs["SushiSwap"] = "https://api.sushiswap.org/v1";
        // Sports Data APIs
        sportsDataAPIs["ESPN"] = "https://api.espn.com";
        sportsDataAPIs["SportsRadar"] = "https://api.sportsradar.com";
    }

    // Add or update a token in the map
    function setToken(uint256 chainId, string memory symbol, address tokenAddress) external onlyOwner {
        tokenMap[chainId][symbol] = tokenAddress;
    }

    // Get sports data API endpoint
    function getSportsDataAPI(string memory apiName) external view returns (string memory) {
        return sportsDataAPIs[apiName];
    }

    // Cross-chain transfer from provided version
    function crossChainTransfer(uint256 fromChain, uint256 toChain, string memory tokenSymbol, uint256 amount, address recipient) external {
        IERC20(tokenMap[fromChain][tokenSymbol]).transferFrom(msg.sender, address(this), amount);
        emit CrossChainTransfer(fromChain, toChain, tokenSymbol, amount, recipient);
    }

    // Mediator account from provided version
    function mediatorAccount() external view returns (address) {
        return 0xYourMediatorAccount; // Placeholder
    }

    event CrossChainTransfer(uint256 fromChain, uint256 toChain, string tokenSymbol, uint256 amount, address recipient);
}
