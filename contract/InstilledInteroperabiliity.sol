// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TheGoateToken.sol";

contract QuantumInstilledInteroperability {
    address public owner;
    TheGoateToken public goateToken;
    mapping(uint256 => mapping(string => address)) public tokenMap;
    mapping(string => string) public tradingAPIs;
    mapping(string => string) public sportsDataAPIs;
    mapping(address => mapping(string => uint256)) public userBalances; // User => Asset => Balance

    string[] public supportedAssets = [
        "USDC", "ZPE", "ZPW", "ZPP", "GySt", "GOATE", "ZGI", "SDM", "ZHV",
        "AQUA", "XLM", "yUSD", "yXLM", "yBTC", "WFM", "TTWO", "BBY", "SFM", "DOLE",
        "WMT", "AAPL", "T", "VZ"
    ];

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _goateToken) {
        owner = msg.sender;
        goateToken = TheGoateToken(_goateToken);
        // Initialize token mappings and APIs as before
    }

    function payWithAsset(
        uint256 fromChain,
        uint256 toChain,
        string memory tokenSymbol,
        uint256 amount,
        address recipient,
        string memory targetAsset
    ) external {
        require(isSupportedAsset(tokenSymbol), "Unsupported asset");
        require(userBalances[msg.sender][tokenSymbol] >= amount, "Insufficient balance");

        userBalances[msg.sender][tokenSymbol] -= amount;
        if (keccak256(bytes(tokenSymbol)) != keccak256(bytes(targetAsset))) {
            // Swap assets via USDMediator
            // (Placeholder for swap logic, integrated with USDMediator)
        }
        userBalances[recipient][targetAsset] += amount;

        IERC20(tokenMap[fromChain][targetAsset]).transferFrom(msg.sender, recipient, amount);
        emit CrossChainTransfer(fromChain, toChain, targetAsset, amount, recipient);
    }

    function isSupportedAsset(string memory asset) internal view returns (bool) {
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            if (keccak256(bytes(asset)) == keccak256(bytes(supportedAssets[i]))) {
                return true;
            }
        }
        return false;
    }

    function updateBalance(address user, string memory asset, uint256 amount, bool add) external onlyOwner {
        if (add) {
            userBalances[user][asset] += amount;
        } else {
            require(userBalances[user][asset] >= amount, "Insufficient balance");
            userBalances[user][asset] -= amount;
        }
    }

    event CrossChainTransfer(uint256 fromChain, uint256 toChain, string tokenSymbol, uint256 amount, address recipient);
}
