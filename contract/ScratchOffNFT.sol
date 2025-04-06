// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./USDMediator.sol";

contract ScratchOffNFT is ERC721, Ownable, VRFConsumerBase {
    USDMediator public usdMediator;
    uint256 public tokenCounter;
    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(uint256 => address) public requestIdToSender;
    mapping(uint256 => uint256) public tokenToPrize;

    enum Mode { Pennies, Nickels, Dimes, Quarters, Dollars }
    uint256[] public prizePools = [
        0.01 ether, // Pennies
        0.05 ether, // Nickels
        0.10 ether, // Dimes
        0.25 ether, // Quarters
        1.00 ether  // Dollars
    ];

    event ScratchRequested(uint256 tokenId, address user, Mode mode);
    event PrizeRevealed(uint256 tokenId, uint256 prize);

    constructor(address _usdMediator, address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee)
        ERC721("ScratchOffNFT", "SONFT")
        Ownable(msg.sender)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        usdMediator = USDMediator(_usdMediator);
        keyHash = _keyHash;
        fee = _fee;
    }

    function scratch(uint256 mode) external {
        require(mode <= uint256(Mode.Dollars), "Invalid mode");
        uint256 amount = prizePools[mode];
        IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        require(usdc.transferFrom(msg.sender, address(usdMediator), amount), "Transfer failed");

        uint256 tokenId = tokenCounter;
        _mint(msg.sender, tokenId);
        tokenCounter++;

        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIdToSender[uint256(requestId)] = msg.sender;

        emit ScratchRequested(tokenId, msg.sender, Mode(mode));
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        address user = requestIdToSender[uint256(requestId)];
        uint256 tokenId = tokenCounter - 1; // Last minted token
        uint256 prizeIndex = randomness % 5; // 0-4 for prize pool
        uint256 prize = prizePools[prizeIndex];
        tokenToPrize[tokenId] = prize;

        usdMediator.transferUSD(user, prize);
        emit PrizeRevealed(tokenId, prize);
    }
}
