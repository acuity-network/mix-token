pragma solidity ^0.5.10;

import "mix-item-store/MixItemStoreRegistry.sol";
import "./MixTokenRegistry.sol";


interface MixTokenInterface {
    event Transfer(address indexed from, address indexed to, uint value);
    event Authorize(address indexed account, address indexed authorized);
    event Unauthorize(address indexed account, address indexed unauthorized);
    function transfer(address to, uint value) external returns (bool success);
    function transferFrom(address from, address to, uint value) external returns (bool success);
    function authorize(address account) external;
    function unauthorize(address account) external;
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function getAccountCount() external view returns (uint);
    function getAccounts() external view returns (address[] memory);
    function getAccountBalances() external view returns (address[] memory accounts, uint[] memory balances);
}


contract MixTokenBase is MixTokenInterface {

    struct AccountState {
        bool inUse;
        int128 balance;
    }

    mapping (address => AccountState) accountState;

    mapping (address => mapping (address => bool)) accountAuthorized;

    address[] accountList;

    string tokenSymbol;
    string tokenName;
    uint tokenDecimals;
    uint tokenSupply;

    modifier hasSufficientBalance(address account, uint value) {
        require (balanceOf(account) >= value, "Insufficient balance.");
        _;
    }

    modifier isAuthorized(address account) {
        require (accountAuthorized[account][msg.sender], "Not authorized.");
        _;
    }

    constructor(string memory symbol, string memory name, uint decimals, MixTokenRegistry registry, bytes32 itemId) public {
        tokenSymbol = symbol;
        tokenName = name;
        tokenDecimals = decimals;
        registry.register(itemId);
    }

    function _transfer(address from, address to, uint value) internal hasSufficientBalance(from, value) {
        // If value is 0 there is nothing to do.
        if (value == 0) {
            return;
        }
        // Add receiver to account list if they are not already on it.
        if (!accountState[to].inUse) {
            accountState[to].inUse = true;
            accountList.push(to);
        }
        // Update balances.
        accountState[from].balance -= int128(value);
        accountState[to].balance += int128(value);
        // Log the event.
        emit Transfer(from, to, value);
    }

    function transfer(address to, uint value) external returns (bool success) {
        // Transfer the tokens.
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external isAuthorized(from) returns (bool success) {
        // Transfer the tokens.
        _transfer(from, to, value);
        return true;
    }

    function authorize(address account) external {
        accountAuthorized[msg.sender][account] = true;
        emit Authorize(msg.sender, account);
    }

    function unauthorize(address account) external {
        delete accountAuthorized[msg.sender][account];
        emit Unauthorize(msg.sender, account);
    }

    function symbol() external view returns (string memory) {
        return tokenSymbol;
    }

    function name() external view returns (string memory) {
        return tokenName;
    }

    function decimals() external view returns (uint) {
        return tokenDecimals;
    }

    function totalSupply() external view returns (uint) {
        return tokenSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return uint(accountState[account].balance);
    }

    function getAccountCount() external view returns (uint) {
        return accountList.length;
    }

    function getAccounts() external view returns (address[] memory) {
        return accountList;
    }

    function getAccountBalances() external view returns (address[] memory accounts, uint[] memory balances) {
        uint count = accountList.length;
        accounts = accountList;
        balances = new uint[](count);

        for (uint i = 0; i < count; i++) {
            balances[i] = balanceOf(accounts[i]);
        }
    }

}
