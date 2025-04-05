// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./InstilledInteroperability.sol";

contract TheLambduckCard {
    InstilledInteroperability public interoperability;
    uint256 public constant DAILY_SPENDING_LIMIT = 10_000_000_000 * 10**18;

    struct User {
        string firstName;
        string lastName;
        bytes32 cardNumberHash;
        uint256[3] cvc;
        uint256 balance; // USDC balance
    }
    mapping(address => User) public users;
    mapping(bytes32 => address) public cardNumberToUser;

    constructor(address _interoperability) {
        interoperability = InstilledInteroperability(_interoperability);
    }

    function registerUser(string memory firstName, string memory lastName) external {
        require(bytes(users[msg.sender].firstName).length == 0, "User already registered");
        uint256[3] memory cvc = [
            uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, 1))) % 1000,
            uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, 2))) % 1000,
            uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, 3))) % 1000
        ];
        bytes32 cardNumberHash = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        users[msg.sender] = User(firstName, lastName, cardNumberHash, cvc, 0);
        cardNumberToUser[cardNumberHash] = msg.sender;
    }

    modifier onlyVerifiedToken(uint256 chainId, string memory tokenSymbol) {
        (, , , address tokenAddress, ,) = interoperability.verifiedTokenAssets(chainId, tokenSymbol);
        require(tokenAddress != address(0), "Asset not available");
        _;
    }

    function buyWithCard(address merchant, uint256 amount, uint256 chainId, string memory tokenSymbol) 
        external onlyVerifiedToken(chainId, tokenSymbol) {
        require(users[msg.sender].balance >= amount, "Insufficient balance");
        require(amount <= DAILY_SPENDING_LIMIT, "Exceeds daily limit");
        users[msg.sender].balance -= amount;
        interoperability.crossChainTransfer(chainId, chainId, tokenSymbol, amount, merchant);
    }

    function withdrawToCard(uint256 amount, uint256 chainId, string memory tokenSymbol) 
        external onlyVerifiedToken(chainId, tokenSymbol) {
        users[msg.sender].balance += amount;
        interoperability.crossChainTransfer(chainId, chainId, tokenSymbol, amount, address(this));
    }

    function withdrawFromCard(address recipient, uint256 amount, uint256 chainId, string memory tokenSymbol) 
        external onlyVerifiedToken(chainId, tokenSymbol) {
        require(users[msg.sender].balance >= amount, "Insufficient balance");
        users[msg.sender].balance -= amount;
        interoperability.crossChainTransfer(chainId, chainId, tokenSymbol, amount, recipient);
    }
}
