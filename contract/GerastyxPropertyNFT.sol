// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GerastyxPropertyNFT is ERC721, Ownable {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000;
    uint256 public tokenCounter;
    mapping(uint256 => uint256) public propertyValues; // USD value in wei

    constructor() ERC721("GerastyxPropertyNFT", "GPNFT") Ownable(msg.sender) {
        initializeProperties();
    }

    function initializeProperties() internal {
        propertyValues[1] = 100e18; // Duck Crossing
        propertyValues[2] = 110e18; // Duck Coast
        // Add all 25 properties with their USD values
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        require(tokenCounter < TOTAL_SUPPLY, "Max supply reached");
        _safeMint(to, tokenId);
        tokenCounter++;
    }

    function getPropertyValue(uint256 tokenId) external view returns (uint256) {
        return propertyValues[tokenId];
    }
}
