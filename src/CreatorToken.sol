pragma solidity ^0.5.11;

import "./ERC165.sol";
import "./MixToken.sol";


contract CreatorToken is ERC165, MixTokenInterface, MixTokenBase {

    uint public start;
    address public owner;
    uint public initialBalance;
    uint public dailyPayout;

    constructor(string memory symbol, string memory name, MixTokenRegistry tokenRegistry, bytes32 itemId, address _owner, uint _initialBalance, uint _dailyPayout) public
        MixTokenBase(symbol, name, tokenRegistry, itemId)
    {
        start = block.timestamp;
        accountState[_owner].inUse = true;
        accountList.push(_owner);
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
