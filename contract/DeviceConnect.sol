// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./InstilledInteroperability.sol";

contract DeviceConnect is Ownable {
    InstilledInteroperability public interoperability;
    uint256 public constant FREE_MODALS = 5;
    uint256 public constant MODAL_COST = 1 * 10**6; // $1 in USDC (6 decimals)
    address public revenueRecipient;

    struct Device {
        string deviceId;
        bool isActive;
        uint256 modalCount;
    }
    mapping(address => Device[]) public userDevices;
    mapping(string => bool) public deviceExists;

    constructor(address _interoperability, address initialOwner) Ownable(initialOwner) {
        interoperability = InstilledInteroperability(_interoperability);
    }

    function setRevenueRecipient(address recipient) external onlyOwner {
        revenueRecipient = recipient;
    }

    function addDevice(string memory deviceId) external {
        require(!deviceExists[deviceId], "Device already exists");
        userDevices[msg.sender].push(Device(deviceId, true, 0));
        deviceExists[deviceId] = true;
    }

    function disconnectDevice(string memory deviceId) external {
        Device[] storage devices = userDevices[msg.sender];
        for (uint256 i = 0; i < devices.length; i++) {
            if (keccak256(bytes(devices[i].deviceId)) == keccak256(bytes(deviceId)) && devices[i].isActive) {
                devices[i].isActive = false;
                return;
            }
        }
        revert("Device not found or already disconnected");
    }

    function useModal(string memory deviceId) external {
        Device[] storage devices = userDevices[msg.sender];
        for (uint256 i = 0; i < devices.length; i++) {
            if (keccak256(bytes(devices[i].deviceId)) == keccak256(bytes(deviceId)) && devices[i].isActive) {
                if (devices[i].modalCount < FREE_MODALS) {
                    devices[i].modalCount++;
                } else {
                    require(revenueRecipient != address(0), "Revenue recipient not set");
                    interoperability.crossChainTransfer(1, 1, "USDC", MODAL_COST, revenueRecipient);
                    devices[i].modalCount++;
                }
                return;
            }
        }
        revert("Active device not found");
    }

    function getUserDevices(address user) external view returns (Device[] memory) {
        return userDevices[user];
    }

    function isDeviceActive(string memory deviceId) external view returns (bool) {
        Device[] memory devices = userDevices[msg.sender];
        for (uint256 i = 0; i < devices.length; i++) {
            if (keccak256(bytes(devices[i].deviceId)) == keccak256(bytes(deviceId))) {
                return devices[i].isActive;
            }
        }
        return false;
    }
}
