pragma solidity ^0.5.10;

import "./MixToken.sol";


contract CreatorToken is MixTokenInterface, MixTokenBase {

    uint public start;
    address public owner;
    uint public initialBalance;
    uint public dailyPayout;

    constructor(string memory symbol, string memory name, uint _initialBalance, uint _dailyPayout, address _owner, MixTokenRegistry tokenRegistry, bytes32 itemId) public
        MixTokenBase(symbol, name, tokenRegistry, itemId)
    {
        accountState[_owner].inUse = true;
        accountList.push(_owner);
        start = block.timestamp;
        owner = _owner;
        initialBalance = _initialBalance;
        dailyPayout = _dailyPayout;
    }

    function totalSupply() public view returns (uint) {
        return initialBalance + ((block.timestamp - start) * dailyPayout) / 1 days;
    }

    function balanceOf(address account) public view returns (uint balance) {

        if (account == owner) {
            balance = uint(accountState[account].balance + int(totalSupply()));
        }
        else {
            balance = uint(accountState[account].balance);
        }
    }

}
