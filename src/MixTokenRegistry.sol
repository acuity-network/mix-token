pragma solidity ^0.5.11;

import "mix-item-store/MixItemStoreRegistry.sol";
import "./MixTokenInterface.sol";


contract MixTokenRegistry {

    mapping (address => bytes32) tokenItemId;

    mapping (bytes32 => address) itemIdToken;

    /**
     * @dev ItemStoreRegistry contract.
     */
    MixItemStoreRegistry public itemStoreRegistry;

    /**
     * @param _itemStoreRegistry Address of the ItemStoreRegistry contract.
     */
    constructor(MixItemStoreRegistry _itemStoreRegistry) public {
        // Store the address of the ItemStoreRegistry contract.
        itemStoreRegistry = _itemStoreRegistry;
    }

    function register(bytes32 itemId, MixTokenInterface token) external {
        MixItemStoreInterface itemStore = itemStoreRegistry.getItemStore(itemId);
        require (itemStore.getOwner(itemId) == msg.sender, "Item is not owned by sender.");
        require (token.owner() == msg.sender, "Token is not owned by sender.");
        require (itemStore.getEnforceRevisions(itemId), "Item does not enforce revisions.");
        require (!itemStore.getRetractable(itemId), "Item is retractable.");
        require (tokenItemId[address(token)] == 0, "Token has registered an item before.");
        require (itemIdToken[itemId] == address(0), "Item has been registered before.");

        tokenItemId[address(token)] = itemId;
        itemIdToken[itemId] = address(token);
    }

    function getItemId(address token) external view returns (bytes32) {
        return tokenItemId[token];
    }

    function getToken(bytes32 itemId) external view returns (address) {
        return itemIdToken[itemId];
    }

}
