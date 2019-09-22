pragma solidity ^0.5.11;

import "mix-item-store/MixItemStoreRegistry.sol";


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

    function register(bytes32 itemId) external {
        MixItemStoreInterface itemStore = itemStoreRegistry.getItemStore(itemId);
        require (itemStore.getEnforceRevisions(itemId), "Item does not enforce revisions.");
        require (!itemStore.getRetractable(itemId), "Item is retractable.");

        tokenItemId[msg.sender] = itemId;
        itemIdToken[itemId] = msg.sender;
    }

    function getItemId(address token) external view returns (bytes32) {
        return tokenItemId[token];
    }

    function getToken(bytes32 itemId) external view returns (address) {
        return itemIdToken[itemId];
    }

}
