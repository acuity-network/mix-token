pragma solidity ^0.5.4;


interface ERC223 {
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    function transfer(address to, uint value) external;
    function transfer(address to, uint value, bytes calldata data) external;
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
}


interface ERC223Receiver {
    function tokenFallback(address from, uint value, bytes calldata data) external;
}


contract ERC223Abstract is ERC223 {

    mapping (address => uint) balances;

    string public symbol;
    string public name;
    uint public decimals;

    modifier hasSufficientBalance(uint value) {
        require (balances[msg.sender] >= value, "Insufficient balance.");
        _;
    }

    function _transfer(address to, uint value) internal hasSufficientBalance(value) {
        balances[msg.sender] -= value;
        balances[to] += value;
    }

    function isContract(address account) internal view returns (bool) {
        uint length;
        assembly {
            length := extcodesize(account)
        }
        return length > 0;
    }

    function transfer(address to, uint value) external {
        bytes memory empty;
        // Transfer the tokens.
        _transfer(to, value);
        // Tell the receiver they received some tokens.
        if (isContract(to)) {
            ERC223Receiver receiver = ERC223Receiver(to);
            receiver.tokenFallback(msg.sender, value, empty);
        }
        // Log the event.
        emit Transfer(msg.sender, to, value, empty);
    }

    function transfer(address to, uint value, bytes calldata data) external {
        // Transfer the tokens.
        _transfer(to, value);
        // Tell the receiver they received some tokens.
        if (isContract(to)) {
            ERC223Receiver receiver = ERC223Receiver(to);
            receiver.tokenFallback(msg.sender, value, data);
        }
        // Log the event.
        emit Transfer(msg.sender, to, value, data);
    }

    function balanceOf(address who) external view returns (uint) {
        return balances[who];
    }

}
