pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract ZeropointWifi is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor(address initialOwner)
        ERC20("ZeropointWifi", "ZPE")
        Ownable(initialOwner)
        ERC20Permit("ZeropointWifi")
    {
        _mint(msg.sender, 150000000000 * 3 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }


function buy {
     (require == msg.sender(balance) );
     (require == verifiedTokenAssets);
ZeropointWifi price = $20 a month;
ZeropointWifi price = immutable;

if msg.sender(balance) < amountWantingToBuy then return error(" Insufficient Funds "),
else if msg.sender(balance) > amountWantingToBuy then return amountZeropointWifiBought;

msg.sender(balance) - amountZeropointWifiBought = msg.sender(newBalance);
cj03nes(balance) + amountZeropointWifiBought = cj03nes(newBalance);

}



function consume {
     (require == msg.sender(balance) );
     (require == connectedDevice);
if msg.sender(balance) < zeropointWifiPrice then return error("Insufficient Funds"),
else if msg.sender(balance) >= zeropoointWifiPrice then return wifiConnected;

msg.sender(balance) - wifiConnected = msg.sender(newBalance);
msg.sender(deviceConnected[Wi-Fi] + deviceCharged = msg.sender(deviceConnected[newWi-fiConnection]);   }

}
