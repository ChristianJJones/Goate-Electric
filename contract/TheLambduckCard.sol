// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TheLambduckCard is Ownable {
    struct Card {
        string cardNumber;
        string expirationDate;
        string cvc;
        string nftDesign;
    }

    mapping(address => Card) public userCards;
    string[] public nftDesigns = [
        "Goat1", "Goat2", "Duck1", "Duck2", "Sheep1", "Sheep2", "Lightning1", "Lightning2",
        "DollarSign1", "DollarSign2", "PlainBlack1", "PlainBlack2", "PlainWhite1", "PlainWhite2",
        "Goat3", "Goat4", "Duck3", "Duck4", "Sheep3", "Sheep4"
    ];

    constructor(address initialOwner) Ownable(initialOwner) {}

    function generateCard(address user, uint256 designIndex) external {
        require(designIndex < nftDesigns.length, "Invalid design index");
        string memory cardNumber = generateCardNumber(user);
        string memory expirationDate = "12/28"; // Mock
        string memory cvc = generateCVC(user);
        userCards[user] = Card(cardNumber, expirationDate, cvc, nftDesigns[designIndex]);
    }

    function generateCardNumber(address user) internal view returns (string memory) {
        bytes32 hash = keccak256(abi.encodePacked(user, block.timestamp));
        return string(abi.encodePacked("4", uint256(hash) % 10**15)); // ISO 20022 compliant (mock)
    }

    function generateCVC(address user) internal view returns (string memory) {
        bytes32 hash = keccak256(abi.encodePacked(user, block.timestamp));
        return string(abi.encodePacked(uint256(hash) % 1000)); // 3-digit CVC
    }
}
