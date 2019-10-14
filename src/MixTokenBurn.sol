pragma solidity ^0.5.11;

import "mix-item-dag/MixItemDagOneParent.sol";
import "./MixTokenInterface.sol";
import "./MixTokenRegistry.sol";


/**
 * @title MixTokenBurn
 * @author Jonathan Brown <jbrown@mix-blockchain.org>
 * @dev Enable accounts to burn their tokens.
 */
contract MixTokenBurn {

    struct AccountBurnedLinked {
        address prev;
        address next;
        uint amount;
    }

    /**
     * Mapping of account to list of tokens that it has burned.
     */
    mapping (address => address[]) accountTokensBurnedList;

    /**
     * Mapping of token to account that has burned the most of that token.
     */
    mapping (address => address) tokenAccountBurnedMost;

    /**
     * Mapping of token to account that has burned the least of that token.
     */
    mapping (address => address) tokenAccountBurnedLeast;

    /**
     * Mapping of token to mapping of account to AccountBurnedLinked.
     */
    mapping (address => mapping (address => AccountBurnedLinked)) tokenAccountBurned;

    /**
     * Mapping of token to total burned.
     */
    mapping (address => uint) tokenBurnedTotal;

    /**
     * Mapping of account to list of itemIds that it has burned the token for.
     */
    mapping (address => bytes32[]) accountItemsBurnedList;

    /**
     * Mapping of itemId to account that has burned the most tokens for that item.
     */
    mapping (bytes32 => address) itemAccountBurnedMost;

    /**
     * Mapping of itemId to account that has burned the least tokens for that item.
     */
    mapping (bytes32 => address) itemAccountBurnedLeast;

    /**
     * Mapping of itemId to mapping of account to quantity of tokens burned for the item.
     */
    mapping (bytes32 => mapping (address => AccountBurnedLinked)) itemAccountBurned;

    /**
     * Mapping of item to total burned for the item.
     */
    mapping (bytes32 => uint) itemBurnedTotal;

    MixTokenRegistry tokenRegistry;
    MixItemDagOneParent tokenItems;

    /**
     * @dev Tokens have been burned.
     * @param token Address of the token's contract.
     * @param itemId Item the token was burned for, or 0 for none.
     * @param account Address of the account burning its tokens.
     * @param amount Amount of tokens burned.
     */
    event BurnTokens(MixTokenInterface indexed token, bytes32 indexed itemId, address indexed account, uint amount);

    /**
     * @dev Revert if amount is zero.
     */
    modifier nonZero(uint amount) {
        require (amount != 0);
        _;
    }

    /**
     * @dev Revert if an item is not listed by token.
     * @param token Token that must list the item.
     * @param itemId Item that must be listed.
     */
    modifier tokenListsItem(MixTokenInterface token, bytes32 itemId) {
        require (tokenRegistry.getItemId(address(token)) == tokenItems.getParentId(itemId), "Token does not list item.");
        _;
    }

    /**
     * @param _tokenRegistry Address of the MixTokenRegistry contract.
     */
    constructor(MixTokenRegistry _tokenRegistry, MixItemDagOneParent _tokenItems) public {
        // Store the address of the MixItemStoreRegistry contract.
        tokenRegistry = _tokenRegistry;
        tokenItems = _tokenItems;
    }

    function _burnTokens(address token, uint amount, address prev, address next) internal {
        // Get accountBurned mapping.
        mapping (address => AccountBurnedLinked) storage accountBurned = tokenAccountBurned[token];
        // Update list of tokens burned by this account.
        if (accountBurned[msg.sender].amount == 0) {
            accountTokensBurnedList[msg.sender].push(token);
        }
        // Update total burned for this token.
        tokenBurnedTotal[token] += amount;
        // Get total burned by sender for this token.
        uint total = accountBurned[msg.sender].amount + amount;
        accountBurned[msg.sender].amount = total;
        // Check new previous.
        if (prev == address(0)) {
            require (next == tokenAccountBurnedMost[token], "Next account must be account that has burned most when no previous account supplied.");
        }
        else {
            require (total <= accountBurned[prev].amount, "Total burned must be less than or equal to previous account.");
        }
        // Check new next.
        if (next == address(0)) {
            require (prev == tokenAccountBurnedLeast[token], "Previous account must be account that has burned least when no next account supplied.");
        }
        else {
            require (total > accountBurned[next].amount, "Total burned must be more than next account.");
        }
        // Is the account staying in the same position?
        if (next == accountBurned[msg.sender].next && prev == accountBurned[msg.sender].prev) {
            // Nothing more to do.
            return;
        }
        // Remove account links from list.
        if (accountBurned[msg.sender].prev != address(0)) {
            accountBurned[accountBurned[msg.sender].prev].next = accountBurned[msg.sender].next;
        }
        if (accountBurned[msg.sender].next != address(0)) {
            accountBurned[accountBurned[msg.sender].next].prev = accountBurned[msg.sender].prev;
        }
        // Check if we are now first.
        if (prev == address(0)) {
            tokenAccountBurnedMost[token] = msg.sender;
        }
        else {
            require (accountBurned[prev].next == next, "Account must be after previous.");
            accountBurned[prev].next = msg.sender;
        }
        // Check if we are now last.
        if (next == address(0)) {
            tokenAccountBurnedLeast[token] = msg.sender;
        }
        else {
            require (accountBurned[next].prev == prev, "Account must be before next.");
            accountBurned[next].prev = msg.sender;
        }
        // Add account links to list.
        accountBurned[msg.sender].prev = prev;
        accountBurned[msg.sender].next = next;
    }

    /**
     * @dev Burn sender's tokens.
     * @param token Address of the token's contract.
     * @param amount Amount of tokens burned.
     */
    function burnTokens(MixTokenInterface token, uint amount, address prev, address next) external nonZero(amount) {
        // Transfer the tokens to this contract.
        // Wrap with require () in case the token contract returns false on error instead of throwing.
        require (token.transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
        // Record the tokens as burned.
        _burnTokens(address(token), amount, prev, next);
        // Emit the event.
        emit BurnTokens(token, 0, msg.sender, amount);
    }

    function getBurnTokensPrevNext(address token, uint amount) external view nonZero(amount) returns (address prev, address next) {
        // Get accountBurned mapping.
        mapping (address => AccountBurnedLinked) storage accountBurned = tokenAccountBurned[token];
        // Get total.
        uint total = accountBurned[msg.sender].amount + amount;
        // Get account with most burned.
        next = tokenAccountBurnedMost[token];
        // Search for first account that has burned less than sender.
        // accountBurned[0].amount == 0
        while (total <= accountBurned[next].amount) {
            next = accountBurned[next].next;
        }
        // Are we in the same position?
        if (next == msg.sender) {
            prev = accountBurned[msg.sender].prev;
            next = accountBurned[msg.sender].next;
        }
        else {
            prev = accountBurned[next].prev;
        }
    }

    /**
     * @dev Burn sender's tokens in association with a specific item.
     * @param token Address of the token's contract.
     * @param itemId Item to burn this token for.
     * @param amount Amount of tokens burned.
     */
    function burnTokensForItem(MixTokenInterface token, bytes32 itemId, uint amount) external tokenListsItem(token, itemId) nonZero(amount) {
        // Transfer the tokens to this contract.
        // Wrap with require () in case the token contract returns false on error instead of throwing.
        require (token.transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
        // Update the record of tokens burned.
        if (tokenAccountBurned[address(token)][msg.sender].amount == 0) {
            accountTokensBurnedList[msg.sender].push(address(token));
        }
        tokenAccountBurned[address(token)][msg.sender].amount += amount;
        if (itemAccountBurned[itemId][msg.sender].amount == 0) {
            accountItemsBurnedList[msg.sender].push(itemId);
        }
        itemAccountBurned[itemId][msg.sender].amount += amount;
        // Emit the event.
        emit BurnTokens(token, itemId, msg.sender, amount);
    }

    /**
     * @dev Get the amount of tokens an account has burned.
     * @param account Address of the account.
     * @param token Address of the token contract.
     * @return Amount of these tokens that this account has burned.
     */
    function getTokensBurned(address account, MixTokenInterface token) external view returns (uint) {
        return tokenAccountBurned[address(token)][account].amount;
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
            burned[i] = tokenAccountBurned[address(tokens[i])][account].amount;
        }
    }

}
