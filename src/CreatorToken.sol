pragma solidity ^0.5.10;

import "./MixToken.sol";


contract CreatorToken is MixTokenBase {

    uint public tokenStart;
    address public tokenOwner;
    uint public tokenInitialBalance;
    uint public tokenDailyPayout;

    constructor(string memory symbol, string memory name, uint decimals, uint initialBalance, uint dailyPayout, address owner, MixTokenRegistry tokenRegistry, bytes32 itemId) public
        MixTokenBase(symbol, name, decimals, tokenRegistry, itemId)
    {
        accountState[owner].inUse = true;
        accountList.push(owner);
        tokenStart = block.timestamp;
        tokenOwner = owner;
        tokenInitialBalance = initialBalance;
        tokenDailyPayout = dailyPayout;
    }

    function totalSupply() public view returns (uint) {
        return tokenInitialBalance + ((block.timestamp - tokenStart) * tokenDailyPayout) / 1 days;
    }

    function balanceOf(address account) public view returns (uint balance) {

        if (account == tokenOwner) {
            balance = uint(accountState[account].balance + int(totalSupply()));
        }
        else {
            balance = uint(accountState[account].balance);
        }
    }

}
