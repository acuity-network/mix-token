pragma solidity ^0.5.10;

import "mix-item-store/ItemStoreRegistry.sol";
import "./MixTokenRegistry.sol";


interface MixTokenInterface {
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    event Authorize(address indexed account, address indexed authorized);
    event Unauthorize(address indexed account, address indexed unauthorized);
    function transfer(address to, uint value) external;
    function transfer(address to, uint value, bytes calldata data) external;
    function transfer(address from, address to, uint value, bytes calldata data) external;
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
}


contract MixTokenReceiverInterface {

    /**
     * @return bytes4(keccak256("onMixTokenReceived(address,uint256,bytes)")) (0x3c8c71b0)
     */
    function onMixTokenReceived(address from, uint value, bytes calldata) external returns (bytes4);
}


contract MixTokenBase is MixTokenInterface {

    mapping (address => uint) accountBalance;

    mapping (address => mapping (address => bool)) accountAuthorized;

    string tokenSymbol;
    string tokenName;
    uint tokenDecimals;
    uint tokenSupply;

    modifier hasSufficientBalance(address account, uint value) {
        require (accountBalance[account] >= value, "Insufficient balance.");
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

    function _isContract(address account) internal view returns (bool) {
        uint length;
        assembly {
            length := extcodesize(account)
        }
        return length > 0;
    }

    function _transfer(address from, address to, uint value, bytes memory data) internal hasSufficientBalance(from, value) {
        // Update balances.
        accountBalance[from] -= value;
        accountBalance[to] += value;
        // Tell the receiver they received some tokens.
        if (_isContract(to)) {
            require (MixTokenReceiverInterface(to).onMixTokenReceived(from, value, data) == 0x3c8c71b0,
                "Receiving contract has not implemented receiving method."
            );
        }
        // Log the event.
        emit Transfer(from, to, value, data);
    }

    function transfer(address to, uint value) external {
        // Transfer the tokens.
        bytes memory empty;
        _transfer(msg.sender, to, value, empty);
    }

    function transfer(address to, uint value, bytes calldata data) external {
        // Transfer the tokens.
        _transfer(msg.sender, to, value, data);
    }

    function transfer(address from, address to, uint value, bytes calldata data) external isAuthorized(from) {
        // Transfer the tokens.
        _transfer(from, to, value, data);
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

    function balanceOf(address who) external view returns (uint) {
        return accountBalance[who];
    }

}
