pragma solidity ^0.5.11;

import "mix-item-store/MixItemStoreRegistry.sol";
import "./MixTokenItemRegistry.sol";
import "./MixTokenInterface.sol";


contract MixTokenBase is MixTokenInterface {

    struct AccountState {
        bool inUse;
        int128 balance;
    }

    mapping (address => AccountState) accountState;

    mapping (address => mapping (address => bool)) accountAuthorized;

    address[] accountList;

    string public symbol;
    string public name;

    event Transfer(address indexed from, address indexed to, uint value);
    event Authorize(address indexed account, address indexed authorized);
    event Unauthorize(address indexed account, address indexed unauthorized);

    modifier hasSufficientBalance(address account, uint value) {
        require (balanceOf(account) >= value, "Insufficient balance.");
        _;
    }

    modifier isAuthorized(address account) {
        require (accountAuthorized[account][msg.sender], "Not authorized.");
        _;
    }

    constructor(string memory _symbol, string memory _name) public {
        symbol = _symbol;
        name = _name;
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
        success = true;
    }

    function transferFrom(address from, address to, uint value) external isAuthorized(from) returns (bool success) {
        // Transfer the tokens.
        _transfer(from, to, value);
        success = true;
    }

    function authorize(address account) external {
        accountAuthorized[msg.sender][account] = true;
        emit Authorize(msg.sender, account);
    }

    function unauthorize(address account) external {
        delete accountAuthorized[msg.sender][account];
        emit Unauthorize(msg.sender, account);
    }

    function decimals() external view returns (uint) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint) {
        return uint(accountState[account].balance);
    }

    function getAccountAuthorized(address account, address accountToCheck) external view returns (bool) {
        return accountAuthorized[account][accountToCheck];
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

    /**
     * @dev Interface identification is specified in ERC-165.
     * @param interfaceId The interface identifier, as specified in ERC-165.
     * @return true if the contract implements interfaceID.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return (interfaceId == 0x01ffc9a7 ||    // EIP165
            interfaceId == 0x23fb80f7);         // MixTokenInterface
    }

}
