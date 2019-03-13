pragma solidity ^0.5.4;

import "mix-item-store/item_store_registry.sol";


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
    function getItemId() external view returns (bytes32);
    function balanceOf(address who) external view returns (uint);
}


contract MixTokenReceiverInterface {

    /**
     * @return bytes4(keccak256("receiveMixToken(address,uint,bytes)"))
     */
    function receiveMixToken(address from, uint value, bytes calldata data) external returns (bytes4);
}


contract MixTokenReceiverBase is MixTokenReceiverInterface {

    /**
     * @return bytes4(keccak256("receiveMixToken(address,uint,bytes)"))
     */
    function receiveMixToken(address, uint, bytes calldata) external returns (bytes4) {
        return 0xf2e0ed8f;
    }
}


contract MixTokenBase is MixTokenInterface {

    mapping (address => uint) accountBalance;

    mapping (address => mapping (address => bool)) accountAuthorized;

    string tokenSymbol;
    string tokenName;
    uint tokenDecimals;
    uint tokenSupply;
    bytes32 tokenItemId;

    modifier hasSufficientBalance(address account, uint value) {
        require (accountBalance[account] >= value, "Insufficient balance.");
        _;
    }

    modifier isAuthorized(address account) {
        require (accountAuthorized[account][msg.sender], "Not authorized.");
        _;
    }

    constructor(string memory symbol, string memory name, uint decimals, ItemStoreRegistry itemStoreRegistry, bytes32 itemId) public {
        ItemStoreInterface itemStore = itemStoreRegistry.getItemStore(itemId);
        require(itemStore.getEnforceRevisions(itemId), "Item does not enforce revisions.");
        require(!itemStore.getRetractable(itemId), "Item is retractable.");
        require(!itemStore.getTransferable(itemId), "Item is transferable.");
        require(itemStore.getOwner(itemId) == msg.sender, "Item is not owned by token owner.");

        tokenSymbol = symbol;
        tokenName = name;
        tokenDecimals = decimals;
        tokenItemId = itemId;
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
            require (MixTokenReceiverInterface(to).receiveMixToken(from, value, data) == 0xf2e0ed8f,
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

    function getItemId() external view returns (bytes32) {
        return tokenItemId;
    }

    function balanceOf(address who) external view returns (uint) {
        return accountBalance[who];
    }

}
