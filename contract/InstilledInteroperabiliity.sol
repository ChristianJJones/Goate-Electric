// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// InstilledInteroperability powers Goate Electric’s cross-chain ecosystem
contract InstilledInteroperability {
    // Chain IDs for Goate Electric’s supported networks
    uint256 constant ETHEREUM_CHAIN = 1;
    uint256 constant BINANCE_CHAIN = 2;
    uint256 constant POLYGON_CHAIN = 3;
    uint256 constant STELLAR_CHAIN = 4;
    uint256 constant SOLANA_CHAIN = 5;
    uint256 constant CRONOS_CHAIN = 6;
    uint256 constant BITCOIN_CHAIN = 7;

    // Mediator and USD token configuration
    address public mediatorAccount;           // Goate Electric’s mediator wallet
    IERC20 public usdToken;                   // USDC contract address
    AggregatorV3Interface public priceFeed;   // Chainlink price feed (e.g., ETH/USD)

    // Mediator balance tracking
    struct MediatorBalance {
        uint256 totalUSD;      // Total USD held by mediator
        uint256 publicUSD;     // Publicly available USD
        int256 capitalOrDebt;  // Capital surplus or debt
    }
    MediatorBalance public mediatorBalance;

    // Token asset definition
    struct TokenAsset {
        string tokenAssetName;
        string tokenAssetSymbol;
        uint8 tokenAssetDecimal;
        address tokenAssetContractAddress;
        uint256 chainId;
        string chainExplorerUrl;
    }

    // Blockchain definition
    struct Blockchain {
        string chainName;
        uint256 chainId;
        string[] chainRpcUrls;
        string chainCurrency;
        string chainExplorerUrl;
    }

    // Node network definition
    struct Node {
        address nodeAddress;
        uint256 chainId;
        bool active;
    }

    // Mappings for Goate Electric’s ecosystem
    mapping(uint256 => Blockchain) public verifiedBlockchains;
    mapping(uint256 => mapping(string => TokenAsset)) public verifiedTokenAssets;
    mapping(bytes32 => bool) public usedSignatures;
    mapping(address => Node) public networkNodes;
    address[] public nodeAddresses;

    // Reward distribution for Goate Electric mining
    address[] public cj03nesAccounts;  // Accounts receiving 80% of rewards
    uint256 public reserve;            // 15% reserve pool

    // Events for tracking Goate Electric operations
    event CrossChainTransfer(uint256 fromChain, uint256 toChain, string tokenSymbol, uint256 amount, address recipient);
    event GhostTransfer(address from, address to, string tokenSymbol, uint256 amount);
    event MediatorUpdate(uint256 totalUSD, uint256 publicUSD, int256 capitalOrDebt);
    event NodeAdded(address nodeAddress, uint256 chainId);
    event RewardsDistributed(uint256 totalAmount, uint256 cj03nesShare, uint256 mediatorShare, uint256 reserveShare);

    constructor(address _mediatorAccount, address _usdToken, address _priceFeed) {
        mediatorAccount = _mediatorAccount;
        usdToken = IERC20(_usdToken);
        priceFeed = AggregatorV3Interface(_priceFeed);

        // Ethereum
        verifiedBlockchains[ETHEREUM_CHAIN] = Blockchain("Ethereum", 1, new string[](1), "ETH", "https://etherscan.io");
        verifiedBlockchains[ETHEREUM_CHAIN].chainRpcUrls[0] = "https://eth.llamarpc.com";
        verifiedTokenAssets[ETHEREUM_CHAIN]["USDC"] = TokenAsset("United States Dollar Coin", "USDC", 6, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 1, "https://etherscan.io");
        verifiedTokenAssets[ETHEREUM_CHAIN]["ZPE"] = TokenAsset("Zeropoint", "ZPE", 3, 0xYourZPEAddress, 1, "https://etherscan.io");
        verifiedTokenAssets[ETHEREUM_CHAIN]["ZPW"] = TokenAsset("ZeropointWifi", "ZPW", 2, 0xYourZPWAddress, 1, "https://etherscan.io");
        verifiedTokenAssets[ETHEREUM_CHAIN]["ETH"] = TokenAsset("Ethereum", "ETH", 18, address(0), 1, "https://etherscan.io");
        verifiedTokenAssets[ETHEREUM_CHAIN]["LINK"] = TokenAsset("Chainlink", "LINK", 18, 0x514910771AF9Ca656af840dff83E8264EcF986CA, 1, "https://etherscan.io");
        verifiedTokenAssets[ETHEREUM_CHAIN]["ARB"] = TokenAsset("Arbitrum", "ARB", 18, 0x912CE59144191C1204E64559FE8253a0e49E6548, 1, "https://etherscan.io");
        verifiedTokenAssets[ETHEREUM_CHAIN]["BTC"] = TokenAsset("Wrapped Bitcoin", "WBTC", 8, 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, 1, "https://etherscan.io");
        verifiedTokenAssets[ETHEREUM_CHAIN]["BNB"] = TokenAsset("Binance Coin (BEP2)", "BNB", 18, 0xB8c77482e45F1F44dE1745F52C74426C631bDD52, 1, "https://etherscan.io");

        // Binance Smart Chain
        verifiedBlockchains[BINANCE_CHAIN] = Blockchain("BNB Smart Chain", 2, new string[](1), "BNB", "https://bscscan.com");
        verifiedBlockchains[BINANCE_CHAIN].chainRpcUrls[0] = "https://rpc.ankr.com/bsc";
        verifiedTokenAssets[BINANCE_CHAIN]["USDC"] = TokenAsset("United States Dollar Coin", "USDC", 6, 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d, 2, "https://bscscan.com");
        verifiedTokenAssets[BINANCE_CHAIN]["ZPE"] = TokenAsset("Zeropoint", "ZPE", 3, 0xYourZPEAddressBSC, 2, "https://bscscan.com");
        verifiedTokenAssets[BINANCE_CHAIN]["ZPW"] = TokenAsset("ZeropointWifi", "ZPW", 2, 0xYourZPWAddressBSC, 2, "https://bscscan.com");
        verifiedTokenAssets[BINANCE_CHAIN]["BNB"] = TokenAsset("Binance Coin", "BNB", 18, address(0), 2, "https://bscscan.com");
        verifiedTokenAssets[BINANCE_CHAIN]["BTC"] = TokenAsset("Bitcoin BEP2", "BTCB", 18, 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c, 2, "https://bscscan.com");

        // Polygon
        verifiedBlockchains[POLYGON_CHAIN] = Blockchain("Polygon", 3, new string[](1), "MATIC", "https://polygonscan.com");
        verifiedBlockchains[POLYGON_CHAIN].chainRpcUrls[0] = "https://polygon.llamarpc.com";
        verifiedTokenAssets[POLYGON_CHAIN]["USDC"] = TokenAsset("United States Dollar Coin", "USDC", 6, 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359, 3, "https://polygonscan.com");
        verifiedTokenAssets[POLYGON_CHAIN]["ZPE"] = TokenAsset("Zeropoint", "ZPE", 3, 0xYourZPEAddressPolygon, 3, "https://polygonscan.com");
        verifiedTokenAssets[POLYGON_CHAIN]["ZPW"] = TokenAsset("ZeropointWifi", "ZPW", 2, 0xYourZPWAddressPolygon, 3, "https://polygonscan.com");

        // Stellar
        verifiedBlockchains[STELLAR_CHAIN] = Blockchain("Stellar Mainnet", 4, new string[](1), "XLM", "https://stellar.expert/explorer/public");
        verifiedBlockchains[STELLAR_CHAIN].chainRpcUrls[0] = "https://horizon.stellar.org";
        verifiedTokenAssets[STELLAR_CHAIN]["USDC"] = TokenAsset("United States Dollar Coin", "USDC", 7, address(0), 4, "https://stellar.expert/explorer/public");
        verifiedTokenAssets[STELLAR_CHAIN]["ZPE"] = TokenAsset("Zeropoint", "ZPE", 3, address(0), 4, "https://stellar.expert/explorer/public");
        verifiedTokenAssets[STELLAR_CHAIN]["ZPW"] = TokenAsset("ZeropointWifi", "ZPW", 2, address(0), 4, "https://stellar.expert/explorer/public");
        verifiedTokenAssets[STELLAR_CHAIN]["XLM"] = TokenAsset("Stellar Lumens", "XLM", 7, address(0), 4, "https://stellar.expert/explorer/public");
        verifiedTokenAssets[STELLAR_CHAIN]["BTC"] = TokenAsset("Bitcoin (Anchored)", "BTC", 7, address(0), 4, "https://stellar.expert/explorer/public");

        // Solana
        verifiedBlockchains[SOLANA_CHAIN] = Blockchain("Solana Mainnet", 5, new string[](1), "SOL", "https://solscan.io");
        verifiedBlockchains[SOLANA_CHAIN].chainRpcUrls[0] = "https://api.mainnet-beta.solana.com";
        verifiedTokenAssets[SOLANA_CHAIN]["USDC"] = TokenAsset("United States Dollar Coin", "USDC", 6, address(0), 5, "https://solscan.io");
        verifiedTokenAssets[SOLANA_CHAIN]["ZPE"] = TokenAsset("Zeropoint", "ZPE", 3, address(0), 5, "https://solscan.io");
        verifiedTokenAssets[SOLANA_CHAIN]["ZPW"] = TokenAsset("ZeropointWifi", "ZPW", 2, address(0), 5, "https://solscan.io");
        verifiedTokenAssets[SOLANA_CHAIN]["SOL"] = TokenAsset("Solana", "SOL", 9, address(0), 5, "https://solscan.io");
        verifiedTokenAssets[SOLANA_CHAIN]["BTC"] = TokenAsset("Wrapped Bitcoin", "WBTC", 6, address(0), 5, "https://solscan.io");

        // Cronos
        verifiedBlockchains[CRONOS_CHAIN] = Blockchain("Cronos Mainnet", 6, new string[](1), "CRO", "https://cronoscan.com");
        verifiedBlockchains[CRONOS_CHAIN].chainRpcUrls[0] = "https://evm.cronos.org";
        verifiedTokenAssets[CRONOS_CHAIN]["USDC"] = TokenAsset("United States Dollar Coin", "USDC", 6, 0x66c0dD67fB6b0f25B417aA81304D4627dE96a392, 6, "https://cronoscan.com");
        verifiedTokenAssets[CRONOS_CHAIN]["ZPE"] = TokenAsset("Zeropoint", "ZPE", 3, 0xYourZPEAddressCronos, 6, "https://cronoscan.com");
        verifiedTokenAssets[CRONOS_CHAIN]["ZPW"] = TokenAsset("ZeropointWifi", "ZPW", 2, 0xYourZPWAddressCronos, 6, "https://cronoscan.com");
        verifiedTokenAssets[CRONOS_CHAIN]["CRO"] = TokenAsset("Cronos", "CRO", 18, 0x5C7F8A570d578ed84E63fdFA7b1eE72dEae1AE23, 6, "https://cronoscan.com");

        // Bitcoin
        verifiedBlockchains[BITCOIN_CHAIN] = Blockchain("Bitcoin Mainnet", 7, new string[](1), "BTC", "https://blockchain.info");
        verifiedBlockchains[BITCOIN_CHAIN].chainRpcUrls[0] = "https://bitcoin-mainnet-rpc.example.com";
        verifiedTokenAssets[BITCOIN_CHAIN]["BTC"] = TokenAsset("Bitcoin", "BTC", 8, address(0), 7, "https://blockchain.info");
        verifiedTokenAssets[BITCOIN_CHAIN]["BTC-LN"] = TokenAsset("Bitcoin Lightning", "BTC-LN", 8, address(0), 7, "https://1ml.com");
    }

    // Add a node to Goate Electric’s network
    function addNode(address nodeAddress, uint256 chainId) external {
        require(verifiedBlockchains[chainId].chainId != 0, "Chain not supported");
        require(!networkNodes[nodeAddress].active, "Node already added");
        networkNodes[nodeAddress] = Node(nodeAddress, chainId, true);
        nodeAddresses.push(nodeAddress);
        emit NodeAdded(nodeAddress, chainId);
    }

    // Set cj03nes accounts for reward distribution
    function setCj03nesAccounts(address[] memory accounts) external {
        require(msg.sender == mediatorAccount, "Only mediator can set");
        require(accounts.length <= 5, "Max 5 accounts");
        cj03nesAccounts = accounts;
    }

    // Distribute mining rewards (80% cj03nes, 5% mediator, 15% reserve)
    function distributeRewards() external payable {
        uint256 amount = msg.value;
        uint256 cj03nesShare = (amount * 80) / 100;
        uint256 mediatorShare = (amount * 5) / 100;
        uint256 reserveShare = (amount * 15) / 100;
        uint256 perCj03nes = cj03nesAccounts.length > 0 ? cj03nesShare / cj03nesAccounts.length : 0;

        for (uint256 i = 0; i < cj03nesAccounts.length; i++) {
            payable(cj03nesAccounts[i]).transfer(perCj03nes);
        }
        payable(mediatorAccount).transfer(mediatorShare);
        reserve += reserveShare;

        emit RewardsDistributed(amount, cj03nesShare, mediatorShare, reserveShare);
    }

    // Perform a cross-chain transfer for Goate Electric assets
    function crossChainTransfer(
        uint256 fromChain,
        uint256 toChain,
        string memory tokenSymbol,
        uint256 amount,
        address recipient
    ) external payable {
        TokenAsset memory token = verifiedTokenAssets[fromChain][tokenSymbol];
        require(token.chainId != 0, "Token not supported");

        if (fromChain != STELLAR_CHAIN && fromChain != SOLANA_CHAIN && fromChain != BITCOIN_CHAIN) {
            IERC20(token.tokenAssetContractAddress).transferFrom(msg.sender, mediatorAccount, amount);
        }
        updateMediatorBalance(amount, true);
        emit CrossChainTransfer(fromChain, toChain, tokenSymbol, amount, recipient);
    }

    // Ghost transfer (off-chain signed transaction)
    function ghostTransfer(string memory tokenSymbol, uint256 amount, address recipient, bytes memory signature) external {
        TokenAsset memory token = verifiedTokenAssets[block.chainid][tokenSymbol];
        bytes32 message = keccak256(abi.encodePacked(tokenSymbol, amount, recipient, block.chainid));
        require(!usedSignatures[message], "Signature already used");
        require(verifySignature(message, signature, msg.sender), "Invalid signature");
        usedSignatures[message] = true;
        emit GhostTransfer(msg.sender, recipient, tokenSymbol, amount);
    }

    function verifySignature(bytes32 message, bytes memory signature, address signer) internal pure returns (bool) {
        bytes32 r; bytes32 s; uint8 v;
        assembly { r := mload(add(signature, 32)) s := mload(add(signature, 64)) v := byte(0, mload(add(signature, 96))) }
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message)), v, r, s) == signer;
    }

    // Internal function to update mediator balance
    function updateMediatorBalance(uint256 amount, bool isDeposit) internal {
        if (isDeposit) {
            mediatorBalance.totalUSD += amount;
            mediatorBalance.publicUSD += (amount * 95) / 100;
            mediatorBalance.capitalOrDebt = int256(mediatorBalance.totalUSD) - int256(mediatorBalance.publicUSD);
        } else {
            require(mediatorBalance.publicUSD >= amount, "Insufficient public USD");
            mediatorBalance.totalUSD -= amount;
            mediatorBalance.publicUSD -= amount;
            mediatorBalance.capitalOrDebt = int256(mediatorBalance.totalUSD) - int256(mediatorBalance.publicUSD);
        }
        emit MediatorUpdate(mediatorBalance.totalUSD, mediatorBalance.publicUSD, mediatorBalance.capitalOrDebt);
    }

    // Withdraw from mediator (restricted to mediator account)
    function withdrawFromMediator(uint256 amount, string memory tokenSymbol, address recipient) external {
        require(msg.sender == mediatorAccount, "Only mediator can withdraw");
        updateMediatorBalance(amount, false);
        TokenAsset memory token = verifiedTokenAssets[block.chainid][tokenSymbol];
        if (token.tokenAssetContractAddress != address(0)) {
            IERC20(token.tokenAssetContractAddress).transfer(recipient, amount);
        }
    }
}
