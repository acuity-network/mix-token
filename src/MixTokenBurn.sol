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

    /**
     * Mapping of token to list of accounts that have burned it.
     */
    mapping (address => address[]) tokenAccountsBurnedList;

    /**
     * Mapping of token to mapping of account to quantity burned.
     */
    mapping (address => mapping(address => uint)) tokenAccountBurned;

    /**
     * Mapping of itemId to list of accounts that have burned the token for the item.
     */
    mapping (bytes32 => address[]) itemAccountsBurnedList;

    /**
     * Mapping of itemId to mapping of account to quantity of tokens burned for the item.
     */
    mapping (bytes32 => mapping(address => uint)) itemAccountBurned;

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

    /**
     * @dev Burn senders tokens.
     * @param token Address of the token's contract.
     * @param amount Amount of tokens burned.
     */
    function burnTokens(MixTokenInterface token, uint amount) external nonZero(amount) {
        // Transfer the tokens to this contract.
        // Wrap with require() in case the token contract returns false on error instead of throwing.
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
        // Update the record of tokens burned.
        if (tokenAccountBurned[address(token)][msg.sender] == 0) {
            tokenAccountsBurnedList[address(token)].push(msg.sender);
        }
        tokenAccountBurned[address(token)][msg.sender] += amount;
        // Emit the event.
        emit BurnTokens(token, 0, msg.sender, amount);
    }

    /**
     * @dev Burn senders tokens.
     * @param token Address of the token's contract.
     * @param itemId Item to burn this token for.
     * @param amount Amount of tokens burned.
     */
    function burnTokensForItem(MixTokenInterface token, bytes32 itemId, uint amount) external tokenListsItem(token, itemId) nonZero(amount) {
        // Transfer the tokens to this contract.
        // Wrap with require() in case the token contract returns false on error instead of throwing.
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
        // Update the record of tokens burned.
        if (tokenAccountBurned[address(token)][msg.sender] == 0) {
            tokenAccountsBurnedList[address(token)].push(msg.sender);
        }
        tokenAccountBurned[address(token)][msg.sender] += amount;
        if (itemAccountBurned[itemId][msg.sender] == 0) {
            itemAccountsBurnedList[itemId].push(msg.sender);
        }
        itemAccountBurned[itemId][msg.sender] += amount;
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
        return tokenAccountBurned[address(token)][account];
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
            burned[i] = tokenAccountBurned[address(tokens[i])][account];
        }
    }

}
