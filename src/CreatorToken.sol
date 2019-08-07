pragma solidity ^0.5.10;

import "./MixToken.sol";


contract CreatorToken is MixTokenBase {

    uint public tokenStart;
    address public tokenOwner;
    uint public tokenPayout;

    constructor(string memory symbol, string memory name, uint decimals, uint payout, MixTokenRegistry tokenRegistry, bytes32 itemId) public
        MixTokenBase(symbol, name, decimals, tokenRegistry, itemId)
    {
        accountState[msg.sender].inUse = true;
        accountList.push(msg.sender);
        tokenStart = block.timestamp;
        tokenOwner = msg.sender;
        tokenPayout = payout;
    }

    function totalSupply() public view returns (uint) {
        return ((block.timestamp - tokenStart) * tokenPayout) / 1 days;
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
