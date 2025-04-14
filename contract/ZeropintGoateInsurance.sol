// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ValidationPortal.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract ZeropointGoateInsurance is ERC20, Ownable {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    ValidationPortal public validationPortal;
    uint256 public constant SUBSCRIPTION_COST = 6 * 10**18; // $6 in $ZGI
    uint256 public constant SUBSCRIPTION_DURATION = 30 days;

    struct InsuredDevice {
        string deviceId;
        bool isInsured;
        uint256 expiry;
    }

    mapping(address => InsuredDevice[]) public insuredDevices;

    constructor(address _usdMediator, address _interoperability, address _validationPortal) 
        ERC20("ZeropointGoateInsurance", "ZGI") Ownable(msg.sender) {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        validationPortal = ValidationPortal(_validationPortal);
        _mint(msg.sender, 1000000 * 10**18);
    }

    function subscribe(string memory deviceId, uint256 amount) external {
        require(amount >= SUBSCRIPTION_COST, "Insufficient $ZGI");
        _burn(msg.sender, SUBSCRIPTION_COST);
        insuredDevices[msg.sender].push(InsuredDevice(deviceId, true, block.timestamp + SUBSCRIPTION_DURATION));
    }

    function makeClaim(string memory deviceId, string memory claimData, uint256 amount) external {
        bool isInsured = false;
        for (uint i = 0; i < insuredDevices[msg.sender].length; i++) {
            if (keccak256(bytes(insuredDevices[msg.sender][i].deviceId)) == keccak256(bytes(deviceId)) &&
                insuredDevices[msg.sender][i].isInsured && insuredDevices[msg.sender][i].expiry > block.timestamp) {
                isInsured = true;
                break;
            }
        }
        require(isInsured, "Device not insured");
        validationPortal.createTask(ValidationPortal.TaskType.InsuranceClaim, claimData);
    }

    function getInsuredDevices(address user) external view returns (InsuredDevice[] memory) {
        return insuredDevices[user];
    }
}
