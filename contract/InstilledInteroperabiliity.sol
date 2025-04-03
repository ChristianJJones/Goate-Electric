contract InstilledInteroperability ={

VerifiedBlockchain ={

    [1. ethereumBlockchain ],={
        chainName = Ethereum;
        chainId =  1;
        chainRpcUrl1 = https://eth.llamarpc.com ;
        chainRpcUrl2 = https://eth.blockrazor.xyz ;
        chainRpcUrl3 = https://ethereum-rpc.publicnode.com ;
        chainRpcUrl4 = https://eth-pokt.nodies.app ;
        chainRpcUrl5 = https://eth.meowrpc.com ;
        chainCurrency=  ETH;
        returns Ethereum Mainnet;


        ethVerifiedTokenAssets ={


    USD Tether = [
            tokenAssetName = United States Dollar Tether;
            tokenAssetDecimal =  6;
            tokenAssetSymbol = USDT;
            tokenAssetContractAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;],

    USD Coin  = [
        tokenAssetName = United States Dollar Coin;
        tokenAssetDecimal =  6;
        tokenAssetSymbol = USDC;
        tokenAssetContractAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; ],  
        
    Wrapped Ethereum  = [
        tokenAssetName = Wrapped Ethereum;
        tokenAssetDecimal =  18;
        tokenAssetSymbol = wETH;
        tokenAssetContractAddress =  0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; ],
        
    Binance  = [
        tokenAssetName = Binance;
        tokenAssetDecimal = 18; 
        tokenAssetSymbol = BNB;
        tokenAssetContractAddress = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52; ],
        
    Matic  = [
        tokenAssetName = Matic Token ;
        tokenAssetDecimal = 18; 
        tokenAssetSymbol = MATIC;
        tokenAssetContractAddress = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;        ],
        
    Chainlink  = [
        tokenAssetName = Chainlink;
        tokenAssetDecimal =  18;
        tokenAssetSymbol = LINK;
        tokenAssetContractAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA; ]     }
    }





    [2. binanceBlockchain ], ={
        chainName = BNB Smart Chain Mainnet ;
        chainId = 56 ;
        chainRpcUrl1 = https://rpc.ankr.com/bsc ;
        chainRpcUrl2 = https://binance.llamarpc.com ;
        chainRpcUrl3 = https://bsc-pokt.nodies.app ;
        chainRpcUrl4 = https://bsc.drpc.org ;
        chainRpcUrl5 = https://bsc.blockrazor.xyz ;
        chainCurrency=  BNB ;
        returns BNB Smart Chain Mainnet;

        bnbVerifiedTokenAssets ={

    USD Tether = [
            tokenAssetName = United States Dollar Tether;
            tokenAssetDecimal =  6;
            tokenAssetSymbol = USDT;
            tokenAssetContractAddress = 0x55d398326f99059fF775485246999027B3197955; ],

    USD Coin  = [
        tokenAssetName = United States Dollar Coin;
        tokenAssetDecimal =  6;
        tokenAssetSymbol = USDC;
        tokenAssetContractAddress =  0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; ],  
        
     Ethereum  = [
        tokenAssetName =  Ethereum;
        tokenAssetDecimal =  18;
        tokenAssetSymbol = ETH;
        tokenAssetContractAddress =  0x2170Ed0880ac9A755fd29B2688956BD959F933F8; ],
        
    Wrapped Binance  = [
        tokenAssetName = Wrapped Binance;
        tokenAssetDecimal = 18; 
        tokenAssetSymbol = wBNB;
        tokenAssetContractAddress =  0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; ],
        
    Matic  = [
        tokenAssetName = Matic Token ;
        tokenAssetDecimal = 18; 
        tokenAssetSymbol = MATIC;
        tokenAssetContractAddress =  0xCC42724C6683B7E57334c4E856f4c9965ED682bD;        ],
        
    Chainlink  = [
        tokenAssetName = Chainlink;
        tokenAssetDecimal =  18;
        tokenAssetSymbol = LINK;
        tokenAssetContractAddress =  0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD; ]

        }
    }





    [3. polygonBlockchain ] ={
        chainName = Polygon Mainnet;
        chainId = 137 ;
        chainRpcUrl1 =  https://polygon.llamarpc.com ;
        chainRpcUrl2 =  https://rpc.ankr.com/polygon ;
        chainRpcUrl3 =  https://polygon-pokt.nodies.app ;
        chainRpcUrl4 =  wss://polygon-bor-rpc.publicnode.com ;
        chainRpcUrl5 =  https://rpc-mainnet.matic.quiknode.pro ;
        chainCurrency =  POL;
        returns Polygon Mainnet;

        polVerifiedTokenAssets ={


    USD Tether = [
            tokenAssetName = United States Dollar Tether;
            tokenAssetDecimal =  6;
            tokenAssetSymbol = USDT;
            tokenAssetContractAddress = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; ],

    USD Coin  = [
        tokenAssetName = United States Dollar Coin;
        tokenAssetDecimal =  6;
        tokenAssetSymbol = USDC;
        tokenAssetContractAddress = 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359; ],  
        
    Wrapped Ethereum  = [
        tokenAssetName = Wrapped Ethereum;
        tokenAssetDecimal =  18;
        tokenAssetSymbol = wETH;
        tokenAssetContractAddress =  0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619; ],
        
    Binance  = [
        tokenAssetName = Binance;
        tokenAssetDecimal = 18; 
        tokenAssetSymbol = BNB;
        tokenAssetContractAddress = 0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3; ],
        
    Wrapped Matic  = [
        tokenAssetName = Wrapped Matic Token ;
        tokenAssetDecimal = 18; 
        tokenAssetSymbol = wMATIC;
        tokenAssetContractAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;        ],
        
    Chainlink  = [
        tokenAssetName = Chainlink;
        tokenAssetDecimal =  18;
        tokenAssetSymbol = LINK;
        tokenAssetContractAddress =  0xb0897686c545045aFc77CF20eC7A532E3120E0F1; ]


          
    }    }    }



// declaring chains => tokens
mapping(ethereumBlockchain => uint256) ethVerifiedTokenAsset;
mapping(binanceBlockchain => uint256)  bnbVerifiedTokenAsset;
mapping(polygonBlockchain => uint256)  polyVerifiedTokenAsset;



//eth tokens => bnb tokens
if ethVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) == bnbVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) then return crossChainTransfer,
else if ethVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) != bnbVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) then return crossChainSwap;
// eth tokens => polygon tokens
if ethVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) == polyVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) then return crossChainTransfer,
else if ethVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) != polyVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) then return crossChainSwap;


// bnb token => eth tokens
if bnbVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) == ethVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) then return crossChainTransfer,
else if bnbVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) != ethVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) then return crossChainSwap;
//bnb => polygon tokens
if bnbVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) == polyVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) then return crossChainTransfer,
else if bnbVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) != polyVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) then return crossChainSwap;


 //polygon tokens => eth token
 if polyVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) == ethVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) then return crossChainTransfer,
 else if polyVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) != ethVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) then return crossChainSwap;   
//polygon tokens => bnb tokens
if polyVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) == bnbVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) then return crossChainTransfer,
else if polyVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) != bnbVerifiedTokenAsset(tokenAssetName, tokenAssetDecimal, tokenAssetSymbol) then return crossChainSwap;
}


return default InstilledInteroperability;
