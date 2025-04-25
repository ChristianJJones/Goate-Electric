// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract GhostGoate is Ownable {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    address public cj03nes;
    address public goatePigReserve = 0xGoatePigReserve;

    struct DeviceLocation {
        address user;
        string latitude;
        string longitude;
        uint256 timestamp;
    }

    mapping(uint256 => DeviceLocation) public deviceLocations;
    uint256 public locationCounter;
    mapping(address => uint256) public nodeRewards;
    mapping(string => uint256) public assetConsumptionRevenue;

    constructor(address _usdMediator, address _interoperability, address _cj03nes, address initialOwner)
        Ownable(initialOwner)
    {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        cj03nes = _cj03nes;
    }

    function updateDeviceLocation(address user, string memory latitude, string memory longitude) external {
        require(msg.sender == cj03nes, "Unauthorized");
        deviceLocations[locationCounter] = DeviceLocation(user, latitude, longitude, block.timestamp);
        locationCounter++;
    }

    function getBalances() external view returns (uint256 cj03nesBalance, uint256 iiBalance, uint256 usdMediatorBalance, uint256 goatePigBalance) {
        require(msg.sender == cj03nes, "Unauthorized");
        cj03nesBalance = interoperability.activeBalances[cj03nes]["USD"];
        iiBalance = interoperability.activeBalances[address(interoperability)]["USD"];
        usdMediatorBalance = interoperability.activeBalances[address(usdMediator)]["USD"];
        goatePigBalance = interoperability.activeBalances[goatePigReserve]["USD"];
    }
}
