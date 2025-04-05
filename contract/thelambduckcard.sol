pragma solidity ^0.8;

import "instilledInteroperability.sol";

contract debitCard {

// KYC / AML & SettingsInfo
first name + last name : string;
user[address] : string;
keccak256[card number] : hex num;
card number[cvc] :  [ (random num1), (random num2)], (random num3) ]= (000 : 999);
address[card balance] = random uint256 num;
__________________________________________
// Card Settings & Error Handling

// select ecosystem accepted assets & tokens
require(verifiedTokenAssets);
if (uint256) !verifiedTokenAsset then return error("Asset is not available in the ecosystem at this time");

// map errors & send them to the right spot
if msg.sender[address] receive (uint256 vefifiedTokenAsset["Ethereum", "USDT"]) to pi[address] , then push[balance] += usdt[address];

// withdraw & spending limits

daily withdraw limit inUSD = $250,000;
daily withdraw limit inPi =  $250,000 ÷ $314,159.26 = twoHundredAndFiftyThousandDollarsInPi;

type of withdraw limit transactions = {

// pi to fiat
1. [ pi[uint256 balance] => fiat[uint256 balance]  ];

// pi to other crypto
2. [ pi[uint256 balance] => crypto[uint256 balance]  ];
}

daily spending limit inUSD = $100,000,000
daily spending limit inPi = $100,000,000 ÷ $314,159.26 = oneHundredMillionDollarsInPi;

type of spending limit transactions = {

// p2p
1. [  card[balance] transferTo msg.recipient[balance];

// pi to fiat
2. [ card[balance] withdrawFromATM fiat[balance];

// pi for goods & services
3. [ card[balance] transferTo merchant[balance];

// pi for crypto
4. [ card[balance] transferTo crypto[balance];

}

__________________________________________

function buyWithCard (msg.sender address, address merchant,uint256 amountSpending) {}

function withdrawToCard ( msg.sender address, card address, uint256 amountAddingFromWalletToCard) {}

function withdrawFromCard ( card address, msg.sender address, uint256 amountAddingFromCardToWallet) {}

function connectToBank ( card address, bankCredentials, cardToBankConnection) {}

function addMoneyFromExternalBankToCard ( bankCredentials, card address, amountAddingFromBankToCard ) {}

function addMoneyFromCardToExternalBank ( cardAddress, bankCredentials, amountAddingFromCardToExternalBank ) {}

function getCreditScore ( bankCredentials, loanOptions, creditScore) {}



