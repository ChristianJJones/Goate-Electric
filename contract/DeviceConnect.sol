// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

// DeviceConnect manages Goate Electric device connections (Zeropoint and ZeropointWifi modems)
contract DeviceConnect is Ownable {
    struct Device {
        string deviceId;    // Unique identifier (e.g., serial number or IMEI)
        address owner;      // Device owner’s wallet address
        bool isActive;      // Connection status
        uint256 chainId;    // Blockchain network (1-7)
    }

    // Mapping of device IDs to their details
    mapping(string => Device) public devices;
    // Mapping of user addresses to their list of device IDs
    mapping(address => string[]) public userDevices;

    event DeviceConnected(string deviceId, address owner, uint256 chainId);
    event DeviceDisconnected(string deviceId, address owner);

    constructor(address initialOwner) Ownable(initialOwner) {}

    // Connect a device to a specific chain (e.g., Ethereum, Bitcoin)
    function connectDevice(string memory deviceId, uint256 chainId) external {
        require(devices[deviceId].owner == address(0) || devices[deviceId].owner == msg.sender, "Device already owned");
        require(chainId >= 1 && chainId <= 7, "Invalid chain ID"); // Supports chains 1-7

        devices[deviceId] = Device(deviceId, msg.sender, true, chainId);
        userDevices[msg.sender].push(deviceId);
        emit DeviceConnected(deviceId, msg.sender, chainId);
    }

    // Disconnect a device (only by owner)
    function disconnectDevice(string memory deviceId) external {
        require(devices[deviceId].owner == msg.sender, "Not device owner");
        devices[deviceId].isActive = false;
        emit DeviceDisconnected(deviceId, msg.sender);
    }

    // Get all devices owned by a user
    function getUserDevices(address user) external view returns (string[] memory) {
        return userDevices[user];
    }
}
