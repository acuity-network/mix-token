pragma solidity ^0.5.4;

import "ds-test/test.sol";
import "mix-item-store/item_store_ipfs_sha256.sol";
import "./MixToken.sol";


contract Token is MixTokenBase {

    constructor(string memory symbol, string memory name, uint decimals, ItemStoreRegistry itemStoreRegistry, bytes32 itemId)
    MixTokenBase(symbol, name, decimals, itemStoreRegistry, itemId) public {
        accountBalance[msg.sender] = 10;
    }

}

contract MixTokenTest is DSTest {

    Token token;
    MixTokenReceiverBase tokenReceiver;
    ItemStoreRegistry itemStoreRegistry;
    ItemStoreIpfsSha256 itemStore;

    function setUp() public {
        itemStoreRegistry = new ItemStoreRegistry();
        itemStore = new ItemStoreIpfsSha256(itemStoreRegistry);
        bytes32 itemId = itemStore.create(hex"02", hex"1234");
        token = new Token('a', 'A', 16, itemStoreRegistry, itemId);
        tokenReceiver = new MixTokenReceiverBase();
    }

    function test1() external {
        token.transfer(address(tokenReceiver), 5);
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }

}
