// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract GerastyxOpol {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    address public owner;
    IERC20 public usdcToken;

    constructor(address _usdMediator, address _interoperability, address _usdcToken) {
        owner = msg.sender;
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        usdcToken = IERC20(_usdcToken);
    }

    // Game logic to be implemented
}
