// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract InstilledInteroperability {
    uint256 constant ETHEREUM_CHAIN = 1;
    uint256 constant BINANCE_CHAIN = 2;
    uint256 constant POLYGON_CHAIN = 3;
    uint256 constant STELLAR_CHAIN = 4;
    uint256 constant SOLANA_CHAIN = 5;
    uint256 constant CRONOS_CHAIN = 6;
    uint256 constant BITCOIN_CHAIN = 7;

    address public mediatorAccount;
    IERC20 public usdToken;
    AggregatorV3Interface public priceFeed;
    struct MediatorBalance { uint256 totalUSD; uint256 publicUSD; int256 capitalOrDebt; }
    MediatorBalance public mediatorBalance;

    struct TokenAsset { string name; string symbol; uint8 decimals; address tokenAddress; uint256 chainId; string explorer; }
    struct Blockchain { string name; uint256 chainId; string[] rpcUrls; string currency; string explorer; }
    struct Node { address nodeAddress; uint256 chainId; bool active; }

    mapping(uint256 => Blockchain) public verifiedBlockchains;
    mapping(uint256 => mapping(string => TokenAsset)) public verifiedTokenAssets;
    mapping(address => Node) public networkNodes;
    address[] public nodeAddresses;
    address[] public cj03nesAccounts;
    uint256 public reserve;

    event CrossChainTransfer(uint256 fromChain, uint256 toChain, string tokenSymbol, uint256 amount, address recipient);
    event NodeAdded(address nodeAddress, uint256 chainId);
    event RewardsDistributed(uint256 total, uint256 cj03nes, uint256 mediator, uint256 reserve);

    constructor(address _mediatorAccount, address _usdToken, address _priceFeed) {
        mediatorAccount = _mediatorAccount;
        usdToken = IERC20(_usdToken);
        priceFeed = AggregatorV3Interface(_priceFeed);

        // Populate verifiedBlockchains and verifiedTokenAssets as in your original (omitted for brevity)
        // Example for Ethereum:
        verifiedBlockchains[ETHEREUM_CHAIN] = Blockchain("Ethereum", 1, new string[](1), "ETH", "https://etherscan.io");
        verifiedBlockchains[ETHEREUM_CHAIN].rpcUrls[0] = "https://eth.llamarpc.com";
        verifiedTokenAssets[ETHEREUM_CHAIN]["USDC"] = TokenAsset("USD Coin", "USDC", 6, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 1, "https://etherscan.io");
        verifiedTokenAssets[ETHEREUM_CHAIN]["ZPE"] = TokenAsset("Zeropoint", "ZPE", 3, 0xYourZPEAddress, 1, "https://etherscan.io");
        verifiedTokenAssets[ETHEREUM_CHAIN]["ZPW"] = TokenAsset("ZeropointWifi", "ZPW", 2, 0xYourZPWAddress, 1, "https://etherscan.io");
        verifiedTokenAssets[ETHEREUM_CHAIN]["ZPP"] = TokenAsset("ZeropointPhone", "ZPP", 2, 0xYourZPPAddress, 1, "https://etherscan.io");
    }

    function addNode(address nodeAddress, uint256 chainId) external {
        require(verifiedBlockchains[chainId].chainId != 0, "Chain not supported");
        networkNodes[nodeAddress] = Node(nodeAddress, chainId, true);
        nodeAddresses.push(nodeAddress);
        emit NodeAdded(nodeAddress, chainId);
    }

    function setCj03nesAccounts(address[] memory accounts) external {
        require(msg.sender == mediatorAccount, "Only mediator");
        cj03nesAccounts = accounts;
    }

    function distributeRewards() external payable {
        uint256 amount = msg.value;
        uint256 cj03nesShare = (amount * 80) / 100;
        uint256 mediatorShare = (amount * 5) / 100;
        uint256 reserveShare = (amount * 15) / 100;
        uint256 perCj03nes = cj03nesAccounts.length > 0 ? cj03nesShare / cj03nesAccounts.length : 0;

        for (uint256 i = 0; i < cj03nesAccounts.length; i++) payable(cj03nesAccounts[i]).transfer(perCj03nes);
        payable(mediatorAccount).transfer(mediatorShare);
        reserve += reserveShare;

        emit RewardsDistributed(amount, cj03nesShare, mediatorShare, reserveShare);
    }

    function crossChainTransfer(uint256 fromChain, uint256 toChain, string memory tokenSymbol, uint256 amount, address recipient) external payable {
        TokenAsset memory token = verifiedTokenAssets[fromChain][tokenSymbol];
        require(token.chainId != 0, "Token not supported");
        if (fromChain != STELLAR_CHAIN && fromChain != SOLANA_CHAIN && fromChain != BITCOIN_CHAIN) {
            IERC20(token.tokenAddress).transferFrom(msg.sender, mediatorAccount, amount);
        }
        emit CrossChainTransfer(fromChain, toChain, tokenSymbol, amount, recipient);
    }
}
