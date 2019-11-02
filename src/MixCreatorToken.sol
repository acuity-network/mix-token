pragma solidity ^0.5.11;

import "./ERC165.sol";
import "./MixTokenBase.sol";


contract MixCreatorToken is ERC165, MixTokenOwnedInterface, MixTokenBase {

    uint public start;
    address public owner;
    uint public initialBalance;
    uint public dailyPayout;

    constructor(string memory symbol, string memory name, address _owner, uint _initialBalance, uint _dailyPayout) public
        MixTokenBase(symbol, name)
    {
        start = block.timestamp;
        owner = _owner;
        accountState[_owner].inUse = true;
        accountList.push(_owner);
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
