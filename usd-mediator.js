// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./InstilledInteroperability.sol";

contract USDMediator {
    InstilledInteroperability public interoperability;
    IERC20 public usdcToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public owner;

    mapping(string => string) public tradingAPIs;
    string[] public reserveAssets = [
        "WMT", "KMB", "MO", "WPC", "CSCO", "T", "BX", "AAPL", "CAT", "SPG",
        "LMT", "AVY", "MCD", "TGT", "TTWO", "DIS", "BAC", "BBY", "MGY", "NKE",
        "USD", "ZPE", "ZPW", "ZPP", "GySt", "XLM", "PI", "GerastyxOpolBank"
    ];

    event RevenueDistributed(uint256 amount, address cj03nes, address reserves, address mediator);

    constructor(address _interoperability) {
        owner = msg.sender;
        interoperability = InstilledInteroperability(_interoperability);
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
    }

    function buyStock(string memory stockSymbol, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(usdcToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        uint256 revenue = amount * 5 / 100;
        distributeRevenue(revenue);
    }

    function sellStock(string memory stockSymbol, uint256 amount, string memory toAsset, address recipient) external {
        uint256 usdAmount = amount;
        uint256 revenue = usdAmount * 5 / 100;
        distributeRevenue(revenue);
        uint256 netAmount = usdAmount - revenue;
        interoperability.crossChainTransfer(1, 1, toAsset, netAmount, recipient);
    }

    function transferUSD(address to, uint256 amount) external {
        require(msg.sender == address(scratchOffNFT) || msg.sender == owner, "Unauthorized");
        require(usdcToken.transfer(to, amount), "Transfer failed");
    }

    function swap(string memory fromAsset, string memory toAsset, uint256 amount, uint256 chainId) external {
        address fromToken = interoperability.tokenMap(chainId, fromAsset);
        address toToken = interoperability.tokenMap(chainId, toAsset);
        require(IERC20(fromToken).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        interoperability.crossChainTransfer(chainId, chainId, toAsset, amount, msg.sender);
    }

    function stakeDebt(address user, uint256 amount) external {
        uint256 perAsset = amount / reserveAssets.length;
        for (uint256 i = 0; i < reserveAssets.length; i++) {
            if (keccak256(abi.encodePacked(reserveAssets[i])) == keccak256(abi.encodePacked("USD"))) {
                usdcToken.transfer(address(this), perAsset);
            } else {
                buyStock(reserveAssets[i], perAsset);
            }
        }
    }

    function distributeRevenue(uint256 amount) internal {
        address cj03nes = 0xYourCj03nesAddress;
        address reserves = 0xYourReservesAddress;
        address mediator = 0xYourMediatorAddress;
        usdcToken.transfer(cj03nes, amount * 80 / 100);
        usdcToken.transfer(reserves, amount * 15 / 100);
        usdcToken.transfer(mediator, amount * 5 / 100);
        emit RevenueDistributed(amount, cj03nes, reserves, mediator);
    }

    function distributeStakingRevenue(uint256 amount) external {
        uint256 revenue = amount * 10 / 100;
        uint256 reserve = amount * 10 / 100;
        uint256 userShare = amount * 80 / 100;
        distributeRevenue(revenue);
        uint256 perReserve = reserve / reserveAssets.length;
        for (uint256 i = 0; i < reserveAssets.length; i++) {
            buyStock(reserveAssets[i], perReserve);
        }
    }

    function handleAdWatch(string memory adType, address user) external {
        // Placeholder: Off-chain ad revenue handled in usd-mediator.js
    }

    function handleGerastyxOpolTransaction(uint256 sessionId, uint256 amount, string memory type_) external {
        distributeRevenue(amount * 5 / 100);
    }

    function handleScratchOffPayment(string memory asset, uint256 amount, uint256 chainId) external {
        address tokenAddress = interoperability.tokenMap(chainId, asset);
        IERC20 token = IERC20(tokenAddress);
        uint256 half = amount / 2;
        require(token.transferFrom(msg.sender, address(this), half), "Mediator transfer failed");
        require(token.transfer(0xYourRevenueAddress, half), "Revenue transfer failed");
    }
}
