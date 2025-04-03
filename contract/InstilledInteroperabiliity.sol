pragma solidity ^8.0;

import ZeropointContractAddress from "./Zeropoint.sol";

contract InstilledInteroperability ={

VerifiedBlockchain ={

[1. ethereumBlockchain ] {
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
    Zeropoint = [
        tokenAssetName = Zeropoint;
        tokenAssetDecimal = 3;
        tokenAssetSymbol = ZPE;
        tokenAssetContractAddress = ZeropointContractAddress;

],
        
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
    Zeropoint = [
        tokenAssetName = Zeropoint;
        tokenAssetDecimal = 3;
        tokenAssetSymbol = ZPE;
        tokenAssetContractAddress = ZeropointContractAddress;
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
    Zeropoint = [
        tokenAssetName = Zeropoint;
        tokenAssetDecimal = 3;
        tokenAssetSymbol = ZPE;
        tokenAssetContractAddress = ZeropointContractAddress;
    }    } 
}



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



// instilled interoperability node








}














return default InstilledInteroperability;
