pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract WeightedDistribution is OwnableUpgradeable {

    address[] private accounts;
    mapping(address => uint256) private accountWeights;
    uint256 private totalWeights;

    function initialize() public initializer {
        __Ownable_init();
    }

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

    function adjustWeight(address account, uint256 newWeight) public onlyOwner {
        require(newWeight >= 0, "Weight must be non-negative");
        totalWeights -= accountWeights[account];
        accountWeights[account] = newWeight;
        totalWeights += newWeight;
    }

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

    function getAccounts() public view returns (address[] memory) {
        return accounts;
    }

    function getWeight(address account) public view returns (uint256) {
        return accountWeights[account];
    }

    function getTotalWeight() public view returns (uint256) {
        return totalWeights;
    }

    function distribute() public {
        require(accounts.length > 0, "No accounts to distribute to");
        uint256 totalWeight = totalWeights;
        require(totalWeight > 0, "Total weight is zero");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract has no balance");
        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 amount = (contractBalance * accountWeights[accounts[i]]) / totalWeight;
            (bool success,) = payable(accounts[i]).call{value: amount}("");
            require(success, "Transfer failed.");
        }
    }

    receive() external payable {}

}