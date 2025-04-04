pragma solidity ^0.8.20;

import "./openzeppelin/ERC20.sol";
import "./openzeppelin/ERC20Burnable.sol";
import "./openzeppelin/Ownable.sol";
import { connectDevice, deviceConnected, deviceInformation, batteryLevel } from "./DeviceConnect.sol";
import { onlyOwner } from "../.env";
import { buyZeropoint, sellZeropoint, consumeZeropoint, transfer, transactionLog, privateOwner1, privateOwner2 } from "./Util.sol";

mapping(chain => mapping(uint256 Zeropoint) => mapping(device => mapping(deviceInformation) ) => zeropointConsumedToDevice;

contract Zeropoint is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("Zeropoint", "ZPE")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 1000000000 * 3 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
      require(onlyOwner);
        _mint(to, amount);
    }

    function buyZeropoint( msg.sender who, uint256 USD(amount) usingToBuy, uint256 Zeropoint(amount) zeropointBought ) {  
      require(msg.sender[USDbalance]);
      require(msg.sender[ZeropointBalance]);
      require(privateOwner[USDbalance2]);
msg.sender(buyZeropoint) = msg.sender(USDbalance) - uint256( amountUSDBuyingZeropointWith);
if msg.sender(USDbalance) < uint256( amount USD) then return error,
else if msg.sender(USDbalance) >= uint256( amount USD) then return swapUSDToZeropoint;
swapUSDToZeropoint = msg.sender(uint256[amountUSDBuyingZeropointWith]) % zeropointPriceInUSD;
zeropointPriceInUSD = $0.10USD;
if msg.sender(uint256[amountUSDBuyingZeropointWith]) = $5USD; then $5USD % $0.10 = 50 Zeropoint;
50 Zeropoint = uint256(amountZeropointBought);
msg.sender(USDbalance) - msg.sender(amountUSDBuyingZeropointWith) = msg.sender(USDbalance);
msg.sender(ZeropointBalance) + msg.sender(amountZeropointBought) = msg.sender(ZeropointBalance);
privateOwner(USDbalance2) + msg.sender(amountUSDBuyingZeropointWith) = privateOwner(USDbalance2);
         _buyZeropoint( who, usingToBuy, zeropointBought);


}

    function sellZeropoint( msg.sender who, uint256 Zeropoint(amount) zeropointSold, uint256 USD(amount) usdReturned ) {
      require(msg.sender[USDbalance]);
      require(msg.sender[ZeropointBalance]);
      require(privateOwner[USDbalance2]);
msg.sender(sellZeropoint) = msg.sender(ZeropointBalance) - uint256( amountZeropointSelling);
if msg.sender(ZeropointBalance) < uint256(amountZeropointSelling) then return error,
else if msg.sender(USDbalance) >= uint256(amountZeropointSelling) then return swapZeropointToUSD;
swapZeropointToUSD = msg.sender(amountZeropointSelling) * zeropointPriceInUSD;
zeropointPriceInUSD = $0.10USD;
if msg.sender(uint256[amountZeropointSelling]) = 50 Zeropoint; then 50 Zeropoint * $0.10 = $5 USD;
$5 USD = uint256(amountZeropointSoldInUSD);
msg.sender(ZeropointBalance) - msg.sender(amountZeropointSelling) = msg.sender(ZeropointBalance);
msg.sender(USDbalance) + msg.sender(amountZeropointSoldInUSD) = msg.sender(USDbalance);
privateOwner(USDbalance2) - msg.sender(amountZeropointSoldInUSD) = privateOwner(USDbalance2); 
         _sellZeropoint(who, zeropointSold, usdReturned);

}

   function consumeZeropoint( address from, uint256 amount, deviceConnected batteryLevel deviceTo) public msg.sender {
      require(msg.sender[USDbalance]);
      require(msg.sender[ZeropointBalance]);
      require(deviceConnected);
      require(deviceConnected[deviceInformation]);
      require(deviceConnected[batteryLevel]);
      require(ERC20Burnable);
      require(privateOwner[USDbalance2]);
      require(privateOwner[USDbalance1]);
msg.sender(consumeZeropoint) = msg.sender(uint256[amountZeropointToConsume]) + msg.sender(deviceConnected);
if msg.sender(ZeropointBalance) < amountZeropointToConsume then return error,
else if msg.sender(ZeropointBalance) >= amountZeropointToConsume then return msg.sender(deviceConnected[ batteryLevel + amountZeropointToConsume]);
if msg.sender(deviceConnected[ baterryLevel]) > 98% then return error , " Battery Percentage is too high.",
else if msg.sender(deviceConnected[ baterryLevel]) < 98% then consumeZeropoint returns ZeropointConsumed;
msg.sender(deviceConnected[ batteryLevel + amountZeropointToConsume]) = deviceConnected(balance);
deviceConnected(balance) !> 98%;
msg.sender(amountZeropointToConsume) * $0.10USD = msg.sender(amountZeropointToConsumeInUSD);
privateOwner(USDbalance2) - msg.sender(amountZeropointToConsumeInUSD) = privateOwner(USDbalance2) ;
privateOwner(USDbalance1) + msg.sender(amountZeropointToConsumeInUSD) = privateOwner(USDbalance1) ;  
                               _consumeZeropoint(from, amount, deviceTo);

}

function transferZeropoint( address from, uint256 Zeropoint(amount), address to) public msg.sender {
require(msg.sender == profileLoggedInto);
require(msg.sender[ZeropointBalance]);
require(recipient[ZeropointBalance]);
msg.sender(transfer) = uint256( amountZeropointToBeTransferred) + recipient;
recipient = username || emailAddress || phoneNumber;
if msg.sender( ZeropointBalance ) < ( amountZeropointToBeTransferred) then return error,
else if msg.sender( ZeropointBalance ) >= ( amountZeropointToBeTransferred) then ( amountZeropointToBeTransferred) returns ( amountZeropointTransferred);
msg.sender( ZeropointBalance ) - msg.sender( amountZeropointTransferred ) = msg.sender( ZeropointBalance );
recipient( ZeropointBalance ) + msg.sender( amountZeropointTransferred ) = recipient( ZeropointBalance );  
                               _transfer(from, amount, to)


}


}

