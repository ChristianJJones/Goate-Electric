pragma solidity ^0.8.20;

import { consumeZeropoint, transfer, transactionLog } from "./Zeropoint.sol";
import { consumeZeropointWifi, zeropointWifiConsumedToDevice, transfer, transactionLog } from  "./ZeropointWifi.sol";
import { connectDevice , deviceConnected, deviceInformation, accountBalances } from "./Util.sol";

// chain to device
mapping(chain) => mapping(device => mapping(deviceInformation) ) => deviceConnected;

//chain to Zeropoint to device
mapping(chain => mapping(uint256 Zeropoint) => mapping(device => mapping(deviceInformation) ) => zeropointConsumedToDevice;

//chain to ZeropointWifi to device
mapping(chain => mapping(uint256 ZeropointWifi) => mapping(device => mapping(deviceInformation) ) => zeropointwifiConsumedToDevice;


contract DeviceConnect (public virtual view returns) {

msg.sender(connectDevice) = get("modelName", " productName", "serialNumber", "IMEI", "batteryStatus", "batteryLevel", "batteryCapacity", "ipAddress", "phoneWifiMACAddress", "phoneNumber", "Wi-Fi", "APN", "MCC", "MNC", "APN Type", "APN Protocol", "APN roaming protocol", "Turn APN On/Off", "Mobile Network Operator Value", "Bluetooth Tethering" );
modelName = mapping(Settings < About Phone < Model Name) then return "string";
productName = mapping(Settings < About Phone < Product Name ) then return "string";
serialNumber = mapping(Settings < About Phone < Serial Number) then return uint256(number);
IMEI = mapping(Settings < About Phone < IMEI) then return uint256(number);
batteryStatus = mapping(Settings < About Phone < Battery Information < Battery Status) then return "string";
batteryLevel = mapping(Settings < About Phone < Battery Level) then return uint256(number[percent]);
batteryCapacity = mapping(Settings < About Phone < Battery Capacity) then return uint256(number);
ipAddress = mapping(Settings < About Phone < Status Information < IP Address) then return "string" && uint256(number);
phoneWifiMACAddress = mapping(Settings < About Phone < Status Information < Phone Wi-Fi MAC Address) then return "string" && uint256(number);
phoneNumber = mapping(Settings < About Phone < Phone Number) then return uint256(number);
Wi-Fi = mapping(Settings < Connections < Wi-Fi < Current network) then return "string &| uint256(number);
APN = mapping(Settings < Connections < Mobile Networks < Access Point Names < Edit Access Point < APN) then return "string";
MCC = mapping(Settings < Connections < Mobile Networks < Access Point Names < Edit Access Point < MCC) then return 3 digit uint256(number);
MNC = mapping(Settings < Connections < Mobile Networks < Access Point Names < Edit Access Point < MNC) then return 3 digit uint256(number);
APN Type = mapping(Settings < Connections < Mobile Networks < Access Point Names < Edit Access Point < APN Type) then return "string";
APN Protocol = mapping(Settings < Connections < Mobile Networks < Access Point Names < Edit Access Point < APN Protocol) then return "string" && uint256(number);
APN roaming protocol = mapping(Settings < Connections < Mobile Networks < Access Point Names < Edit Access Point < APN roaming protocol) then return "string" && uint256(number);
Turn APN On/Off= mapping(Settings < Connections < Mobile Networks < Access Point Names < Edit Access Point < Turn APN On/Off) then return "string", require(Turn APN On/Off) == On;
Mobile Network Operator Value = mapping(Settings < Connections < Mobile Networks < Access Point Names < Edit Access Point < Mobile virtual network operator value) then return "string";
Bluetooth Tethering = mapping(Settings < Connections < Mobile Hotspot and Tethering < Bluetooth tethering) then return ( on || off); 
deviceInformation = ("modelName", " productName", "serialNumber", "IMEI", "batteryStatus", "batteryLevel", "batteryCapacity", "ipAddress", "phoneWifiMACAddress", "phoneNumber", "Wi-Fi", "APN", "MCC", "MNC", "APN Type", "APN Protocol", "APN roaming protocol", "Turn APN On/Off", "Mobile Network Operator Value", "Bluetooth Tethering");
if msg.sender(connectDevice) != get("modelName", " productName", "serialNumber", "IMEI", "batteryStatus", "batteryLevel", "batteryCapacity", "ipAddress", "phoneWifiMACAddress", "phoneNumber", "Wi-Fi", "APN", "MCC", "MNC", "APN Type", "APN Protocol", "APN roaming protocol", "Turn APN On/Off", "Mobile Network Operator Value", "Bluetooth Tethering" ) then return error && revert,
else if msg.sender(connectDevice) == get("modelName", " productName", "serialNumber", "IMEI", "batteryStatus", "batteryLevel", "batteryCapacity", "ipAddress", "phoneWifiMACAddress", "phoneNumber", "Wi-Fi", "APN", "MCC", "MNC", "APN Type", "APN Protocol", "APN roaming protocol", "Turn APN On/Off", "Mobile Network Operator Value", "Bluetooth Tethering") then return deviceConnected; 

}
