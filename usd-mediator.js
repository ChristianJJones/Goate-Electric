// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./InstilledInteroperability.sol";

contract USDMediator is Ownable {
    InstilledInteroperability public interoperability;
    IERC20 public usdcToken;
    address public revenueRecipient;
    address public goatePigReserve = 0xGoatePigReserve; // #!GoatePig
    mapping(string => uint256) public reserveBalances;
    mapping(address => mapping(string => uint256)) public activeBalances;
    mapping(address => mapping(string => uint256)) public stakingBalances;
    string[] public reserveAssets = [
        "AQUA", "yXLM", "yBTC", "yUSD", "XLM", "USDC", "WFM", "SFM", "UNFI", "BBY",
        "TTWO", "SGDM", "GDX", "RGLD", "PRU", "GOLD", "SQ", "MSTR", "CORZ", "BITF",
        "NEM", "HMY", "HYMC", "SHW", "SLR", "ABAT", "BHP", "CLF", "CRTM", "LAC",
        "USGO", "DLR", "O", "ESS", "SPG", "EQR", "WPC", "MORN", "BX", "AHR", "WMT",
        "ZPE", "ZPP", "ZPW", "ZHV", "GOATE", "GySt", "SD", "GP", "VVS", "CRO"
    ];

    constructor(address _usdcToken, address _interoperability, address initialOwner) Ownable(initialOwner) {
        usdcToken = IERC20(_usdcToken);
        interoperability = InstilledInteroperability(_interoperability);
        revenueRecipient = initialOwner;
    }

    function transferUSD(address recipient, uint256 amount) external {
        require(amount >= 0.01 * 10**6, "Minimum transaction amount is $0.01");
        require(usdcToken.transferFrom(msg.sender, recipient, amount), "USDC transfer failed");
        emit USDTransferred(recipient, amount);
    }

    function quantumSwap(string memory fromAsset, string memory toAsset, uint256 amount, address sender, address recipient) external {
        require(isReserveAsset(fromAsset) && isReserveAsset(toAsset), "Unsupported asset");
        require(activeBalances[sender][fromAsset] >= amount, "Insufficient balance");
        activeBalances[sender][fromAsset] -= amount;
        uint256 convertedAmount = interoperability.convertAmount(fromAsset, toAsset, amount);
        activeBalances[recipient][toAsset] += convertedAmount;
        emit QuantumSwap(sender, recipient, fromAsset, toAsset, amount, convertedAmount);
    }

    function switchToReserves() external {
        require(msg.sender == owner || msg.sender == address(this), "Unauthorized");
        for (uint256 i = 0; i < reserveAssets.length; i++) {
            string memory asset = reserveAssets[i];
            uint256 amount = activeBalances[address(this)][asset] / 4; // 25%
            activeBalances[address(this)][asset] -= amount;
            reserveBalances[address(this)][asset] += amount;
        }
    }

    function isReserveAsset(string memory asset) internal view returns (bool) {
        for (uint256 i = 0; i < reserveAssets.length; i++) {
            if (keccak256(bytes(asset)) == keccak256(bytes(reserveAssets[i]))) {
                return true;
            }
        }
        return false;
    }

    event USDTransferred(address indexed recipient, uint256 amount);
    event QuantumSwap(address indexed sender, address indexed recipient, string fromAsset, string toAsset, uint256 amount, uint256 convertedAmount);
}
