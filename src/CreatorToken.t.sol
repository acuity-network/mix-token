pragma solidity ^0.5.10;

import "ds-test/test.sol";
import "mix-item-store/MixItemStoreIpfsSha256.sol";
import "./CreatorToken.sol";


contract MixTokenTest is DSTest {

    MixTokenRegistry mixTokenRegistry;
    MixItemStoreRegistry mixItemStoreRegistry;
    MixItemStoreIpfsSha256 mixItemStore;
    CreatorToken token;

    function setUp() public {
        mixItemStoreRegistry = new MixItemStoreRegistry();
        mixItemStore = new MixItemStoreIpfsSha256(mixItemStoreRegistry);
        bytes32 itemId = mixItemStore.create(hex"02", hex"1234");
        mixTokenRegistry = new MixTokenRegistry(mixItemStoreRegistry);
        token = new CreatorToken('a', 'A', 16, 400000, 1000, address(this), mixTokenRegistry, itemId);
    }

    function test1() external {
        token.transfer(address(0x1234), 0);
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }

}
