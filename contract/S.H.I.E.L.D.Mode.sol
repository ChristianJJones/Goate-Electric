// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ValidationPortal.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract SHIELDMode is ERC20, Ownable {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    ValidationPortal public validationPortal;
    uint256 public constant SHOT_COST = 1 * 10**18; // $1 in $SDM

    mapping(address => uint256) public shotsFired;
    event ShotFired(address user, uint256 timestamp);

    constructor(address _usdMediator, address _interoperability, address _validationPortal) 
        ERC20("SHIELDMode", "SDM") Ownable(msg.sender) {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        validationPortal = ValidationPortal(_validationPortal);
        _mint(msg.sender, 1000000 * 10**18);
        _mint(msg.sender, 1 * 10**18); // Free shot
    }

    function useSDM() external {
        require(balanceOf(msg.sender) >= SHOT_COST, "Insufficient $SDM");
        _burn(msg.sender, SHOT_COST);
        shotsFired[msg.sender]++;
        emit ShotFired(msg.sender, block.timestamp);
        if (shotsFired[msg.sender] >= 5) {
            validationPortal.createTask(ValidationPortal.TaskType.IcerIncident, "SDM Incident");
        }
    }
}
