// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./USDMediator.sol";
import "./InstilledInteroperability.sol";

contract GoatePig is ERC20, Ownable {
    USDMediator public usdMediator;
    InstilledInteroperability public interoperability;
    address public cj03nes;
    address public goatePigReserve = 0xGoatePigReserve; // #!GoatePig
    IERC20 public piToken;

    constructor(address _usdMediator, address _interoperability, address _piToken, address _cj03nes, address initialOwner)
        ERC20("GoatePig", "GP")
        Ownable(initialOwner)
    {
        usdMediator = USDMediator(_usdMediator);
        interoperability = InstilledInteroperability(_interoperability);
        piToken = IERC20(_piToken);
        cj03nes = _cj03nes;
    }

    function buyPiToken(uint256 amount) external {
        require(msg.sender == cj03nes || msg.sender == address(interoperability) || msg.sender == address(usdMediator), "Unauthorized");
        uint256 cj03nesShare = (amount * 50) / 100;
        uint256 iiShare = (amount * 20) / 100;
        uint256 usdMediatorShare = (amount * 20) / 100;
        uint256 goatePigShare = (amount * 10) / 100;

        piToken.transferFrom(cj03nes, goatePigReserve, cj03nesShare);
        piToken.transferFrom(address(interoperability), goatePigReserve, iiShare);
        piToken.transferFrom(address(usdMediator), goatePigReserve, usdMediatorShare);
        piToken.transferFrom(goatePigReserve, goatePigReserve, goatePigShare);

        _mint(goatePigReserve, amount);
    }

    function switchToReserves() external {
        require(msg.sender == cj03nes || msg.sender == address(interoperability) || msg.sender == address(usdMediator), "Unauthorized");
        uint256 amount = balanceOf(goatePigReserve) / 4; // 25%
        _burn(goatePigReserve, amount);
        // Swap to reserve assets (handled by USDMediator/InstilledInteroperability)
        usdMediator.switchToReserves();
    }
}
