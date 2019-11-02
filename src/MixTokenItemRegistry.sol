pragma solidity ^0.5.11;

import "mix-item-store/MixItemStoreRegistry.sol";
import "./MixTokenInterface.sol";


contract MixTokenItemRegistry {

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

    function register(MixTokenOwnedInterface token, bytes32 itemId) external {
        // Check token.
        require (token.supportsInterface(0x01ffc9a7), "Token is not ERC165.");
        require (token.supportsInterface(0x23fb80f7), "Token is not MixTokenInterface.");
        require (token.owner() == msg.sender, "Token is not owned by sender.");
        // Check item.
        MixItemStoreInterface itemStore = itemStoreRegistry.getItemStore(itemId);
        require (itemStore.getOwner(itemId) == msg.sender, "Item is not owned by sender.");
        require (itemStore.getEnforceRevisions(itemId), "Item does not enforce revisions.");
        require (!itemStore.getRetractable(itemId), "Item is retractable.");
        // Check not registered before.
        require (tokenItemId[address(token)] == 0, "Token has been registered before.");
        require (itemIdToken[itemId] == address(0), "Item has been registered before.");
        // Record relationship.
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
