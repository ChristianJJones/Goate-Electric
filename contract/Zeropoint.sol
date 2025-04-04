// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Zeropoint is ERC20, ERC20Burnable, Ownable {
    uint256 public constant PRICE_PER_ZPE = 0.10 * 10**18; // $0.10 in wei (assuming 18 decimals for USD)
    
    // Track USD balances (assuming a separate USD stablecoin integration)
    mapping(address => uint256) public usdBalance;
    mapping(address => uint256) public zeropointConsumedToDevice;

    constructor(address initialOwner) 
        ERC20("Zeropoint", "ZPE") 
        Ownable(initialOwner) 
    {
        _mint(initialOwner, 1_000_000_000 * 10**decimals()); // 1 billion ZPE with 3 decimals
    }

    function decimals() public view virtual override returns (uint8) {
        return 3; // ZPE has 3 decimals as per your design
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function buyZeropoint(uint256 usdAmount) external {
        require(usdBalance[msg.sender] >= usdAmount, "Insufficient USD balance");
        uint256 zpeAmount = (usdAmount * 10**decimals()) / PRICE_PER_ZPE; // Convert USD to ZPE
        usdBalance[msg.sender] -= usdAmount;
        usdBalance[owner()] += usdAmount; // Transfer USD to owner
        _mint(msg.sender, zpeAmount);
        emit TransactionLog(msg.sender, "Buy", usdAmount, zpeAmount);
    }

    function sellZeropoint(uint256 zpeAmount) external {
        require(balanceOf(msg.sender) >= zpeAmount, "Insufficient ZPE balance");
        uint256 usdAmount = (zpeAmount * PRICE_PER_ZPE) / 10**decimals();
        require(usdBalance[owner()] >= usdAmount, "Owner lacks USD to pay");
        _burn(msg.sender, zpeAmount);
        usdBalance[msg.sender] += usdAmount;
        usdBalance[owner()] -= usdAmount;
        emit TransactionLog(msg.sender, "Sell", usdAmount, zpeAmount);
    }

    function consumeZeropoint(uint256 amount, address device) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient ZPE balance");
        require(amount > 0, "Amount must be greater than 0");
        _burn(msg.sender, amount);
        zeropointConsumedToDevice[device] += amount;
        emit TransactionLog(msg.sender, "Consume", 0, amount);
    }

    function transferZeropoint(address to, uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient ZPE balance");
        _transfer(msg.sender, to, amount);
        emit TransactionLog(msg.sender, "Transfer", 0, amount);
    }

    // Placeholder for USD deposit (integrate with a stablecoin in practice)
    function depositUSD(uint256 amount) external onlyOwner {
        usdBalance[msg.sender] += amount;
    }

    event TransactionLog(address indexed user, string action, uint256 usdAmount, uint256 zpeAmount);
}
