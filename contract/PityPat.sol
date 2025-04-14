// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./USDMediator.sol";

contract PityPat {
    USDMediator public mediator;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _mediator) {
        owner = msg.sender;
        mediator = USDMediator(_mediator);
    }

    function playGame(uint256 betAmount) external {
        require(mediator.usdcToken().transferFrom(msg.sender, address(mediator), betAmount), "Transfer failed");
        // Game logic here
    }
}
