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
        // Token mappings
        tokenMap[1]["USDC"] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        tokenMap[1]["ZPE"] = 0xYourZPEAddress;
        tokenMap[1]["ZPW"] = 0xYourZPWAddress;
        tokenMap[1]["ZPP"] = 0xYourZPPAddress;
        tokenMap[1]["GySt"] = 0xYourGreyStaxAddress;
        tokenMap[512]["XLM"] = 0xYourStellarXLMAddress;
        tokenMap[1]["GOATE"] = _goateToken;
        // Trading APIs
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

    function setToken(uint256 chainId, string memory symbol, address tokenAddress) external onlyOwner {
        tokenMap[chainId][symbol] = tokenAddress;
    }

    function getSportsDataAPI(string memory apiName) external view returns (string memory) {
        return sportsDataAPIs[apiName];
    }

    function crossChainTransfer(uint256 fromChain, uint256 toChain, string memory tokenSymbol, uint256 amount, address recipient) external {
        IERC20(tokenMap[fromChain][tokenSymbol]).transferFrom(msg.sender, address(this), amount);
        emit CrossChainTransfer(fromChain, toChain, tokenSymbol, amount, recipient);
    }

    function mediatorAccount() external view returns (address) {
        return 0xYourMediatorAccount;
    }

    event CrossChainTransfer(uint256 fromChain, uint256 toChain, string tokenSymbol, uint256 amount, address recipient);
}
