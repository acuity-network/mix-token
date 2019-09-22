pragma solidity ^0.5.11;

import "./MixTokenInterface.sol";


/**
 * @title MixTokenBurn
 * @author Jonathan Brown <jbrown@mix-blockchain.org>
 * @dev Enable accounts to burn its tokens.
 */
contract MixTokenBurn {

    /**
     * Mapping of account to mapping of token to quantity burned.
     */
    mapping (address => mapping(address => uint)) accountTokenBurned;

    /**
     * @dev Tokens have been burned.
     * @param account Address of the account burning its tokens.
     * @param token Address of the token's contract.
     * @param amount Amount of tokens burned.
     */
    event BurnTokens(address indexed account, MixTokenInterface indexed token, uint amount);

    /**
     * @dev Burn senders tokens.
     * @param token Address of the token's contract.
     * @param amount Amount of tokens burned.
     */
    function burnTokens(MixTokenInterface token, uint amount) external {
        // Transfer the tokens to this contract.
        // Wrap with require() in case the token contract returns false on error instead of throwing.
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
        // Update the record of tokens burned.
        accountTokenBurned[msg.sender][address(token)] += amount;
        // Emit the event.
        emit BurnTokens(msg.sender, token, amount);
    }

    /**
     * @dev Get the amount of tokens an account has burned.
     * @param account Address of the account.
     * @param token Address of the token contract.
     * @return Amount of these tokens that this account has burned.
     */
    function getTokensBurned(address account, MixTokenInterface token) external view returns (uint) {
        return accountTokenBurned[account][address(token)];
    }

    /**
     * @dev Get the amount of multiple tokens an account has burned.
     * @param account Address of the account.
     * @param tokens Addresses of the token contracts.
     * @return burned Amount of these tokens that account has burned.
     */
    function getTokensBurnedMultiple(address account, MixTokenInterface[] calldata tokens) external view returns (uint[] memory burned) {
        // Get number of tokens.
        uint count = tokens.length;
        // Allocate return array.
        burned = new uint[](count);
        // Populate return array.
        for (uint i = 0; i < count; i++) {
            burned[i] = accountTokenBurned[account][address(tokens[i])];
        }
    }

}
