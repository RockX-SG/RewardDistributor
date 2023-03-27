pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract WeightedDistribution is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using Address for address;

    address[] private accounts;
    mapping(address => uint256) private accountWeights;
    uint256 private totalWeights;

    /**
     * @dev disable implementation init
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev make this contract eligible for receiving ethers
     */
    receive() external payable {}

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev set weight of an account
     */
    function setWeight(address account, uint256 weight) public onlyOwner {
        require(weight >= 0, "Weight must be non-negative");
        if (accountWeights[account] == 0) {
            accounts.push(account);
        } else {
            totalWeights -= accountWeights[account];
        }
        accountWeights[account] = weight;
        totalWeights += weight;
    }

    /**
     * @dev remove an account from distribution targets
     */
    function removeAccount(address account) public onlyOwner {
        require(accountWeights[account] > 0, "Account not found or weight is zero");
        totalWeights -= accountWeights[account];
        delete accountWeights[account];
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == account) {
                accounts[i] = accounts[accounts.length - 1];
                accounts.pop();
                break;
            }
        }
    }

    /**
     * @dev check accounts
     */
    function getAccounts() public view returns (address[] memory) {
        return accounts;
    }

    /**
     * @dev return weight for an account
     */
    function getWeight(address account) public view returns (uint256) {
        return accountWeights[account];
    }

    /**
     * @dev get total weight
     */
    function getTotalWeight() public view returns (uint256) {
        return totalWeights;
    }

    /**
     * @dev distribute ethers
     */
    function distribute() public {
        require(accounts.length > 0, "No accounts to distribute to");
        uint256 totalWeight = totalWeights;
        require(totalWeight > 0, "Total weight is zero");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract has no balance");
        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 amount = (contractBalance * accountWeights[accounts[i]]) / totalWeight;
            payable(accounts[i]).sendValue(amount);
        }
    }
}