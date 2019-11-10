pragma solidity ^0.5.12;

import "./ERC165.sol";
import "./MixTokenBase.sol";


contract MixCreatorToken is ERC165, MixTokenInterface, MixTokenOwnedInterface, MixTokenBase {

    // MixTokenOwnedInterface
    address public owner;

    uint public start;
    uint public initialBalance;
    uint public dailyPayout;

    constructor(string memory symbol, string memory name, address _owner, uint _initialBalance, uint _dailyPayout) public
        MixTokenBase(symbol, name)
    {
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
            balance = uint(accountBalance[account] + int(totalSupply()));
        }
        else {
            balance = uint(accountBalance[account]);
        }
    }

    /**
     * @dev Interface identification is specified in ERC-165.
     * @param interfaceId The interface identifier, as specified in ERC-165.
     * @return true if the contract implements interfaceID.
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return (MixTokenBase.supportsInterface(interfaceId) ||
            interfaceId == 0x8da5cb5b ||        // MixTokenOwnedInterface
            interfaceId == 0xd6559ea1);         // MixCreatorToken
    }

}


contract MixCreatorTokenInterfaceId {

    function getInterfaceId() external view returns (bytes4) {
        MixCreatorToken i;
        return i.start.selector ^
            i.initialBalance.selector ^
            i.dailyPayout.selector;
    }

}
