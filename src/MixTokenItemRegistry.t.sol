pragma solidity ^0.5.11;

import "ds-test/test.sol";
import "mix-item-store/MixItemStoreIpfsSha256.sol";
import "./MixCreatorToken.sol";
import "./MixTokenItemRegistry.sol";


contract MixTokenItemRegistryTest is DSTest {

    MixTokenItemRegistry mixTokenRegistry;
    MixItemStoreRegistry mixItemStoreRegistry;
    MixItemStoreIpfsSha256 mixItemStore;
    MixCreatorToken mixCreatorToken;
    bytes32 itemId;
    MixTokenItemRegistryTestMockAccount mockAccount;

    function setUp() public {
        mixItemStoreRegistry = new MixItemStoreRegistry();
        mixItemStore = new MixItemStoreIpfsSha256(mixItemStoreRegistry);
        itemId = mixItemStore.create(hex"02", hex"1234");
        mixTokenRegistry = new MixTokenItemRegistry(mixItemStoreRegistry);
        mixCreatorToken = new MixCreatorToken('a', 'A', address(this), 10, 1);
        mockAccount = new MixTokenItemRegistryTestMockAccount(mixItemStore);
    }

    function testControl() public {
        mixTokenRegistry.register(mixCreatorToken, itemId);
    }

    function testFailTokenNotERC165() public {
        MixCreatorTokenNotERC165 token = new MixCreatorTokenNotERC165('a', 'A', address(this), 10, 1);
        mixTokenRegistry.register(token, itemId);
    }

    function testFailTokenNotMixTokenInterface() public {
        MixCreatorTokenNotMixTokenInterface token = new MixCreatorTokenNotMixTokenInterface('a', 'A', address(this), 10, 1);
        mixTokenRegistry.register(token, itemId);
    }

    function testFailTokenNotOwnedBySender() public {
        MixCreatorToken token = new MixCreatorTokenNotMixTokenInterface('a', 'A', address(0x1234), 10, 1);
        mixTokenRegistry.register(token, itemId);
    }

    function testFailItemNotOwnedBySender() public {
        bytes32 _itemId = mockAccount.createItem();
        mixTokenRegistry.register(mixCreatorToken, _itemId);
    }

    function testFailItemNotEnforceRevisions() public {
        bytes32 _itemId = mixItemStore.create(hex"00", hex"1234");
        mixTokenRegistry.register(mixCreatorToken, _itemId);
    }

    function testFailItemRetractable() public {
        bytes32 _itemId = mixItemStore.create(hex"04", hex"1234");
        mixTokenRegistry.register(mixCreatorToken, _itemId);
    }

    function testFailTokenRegisteredBefore() public {
        mixTokenRegistry.register(mixCreatorToken, itemId);
        bytes32 _itemId = mixItemStore.create(hex"02", hex"1234");
        mixTokenRegistry.register(mixCreatorToken, _itemId);
    }

    function testFailItemRegisteredBefore() public {
        mixTokenRegistry.register(mixCreatorToken, itemId);
        MixCreatorToken token = new MixCreatorToken('a', 'A', address(this), 10, 1);
        mixTokenRegistry.register(token, itemId);
    }

}

contract MixCreatorTokenNotERC165 is MixCreatorToken {

    constructor(string memory symbol, string memory name, address _owner, uint _initialBalance, uint _dailyPayout) public
        MixCreatorToken(symbol, name, _owner, _initialBalance, _dailyPayout) {}

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return (interfaceId == 0x23fb80f7);         // MixTokenInterface
    }
}

contract MixCreatorTokenNotMixTokenInterface is MixCreatorToken {

    constructor(string memory symbol, string memory name, address _owner, uint _initialBalance, uint _dailyPayout) public
        MixCreatorToken(symbol, name, _owner, _initialBalance, _dailyPayout) {}

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return (interfaceId == 0x01ffc9a7);    // ERC165
    }
}

contract MixTokenItemRegistryTestMockAccount {

    MixItemStoreIpfsSha256 mixItemStore;

    constructor(MixItemStoreIpfsSha256 _mixItemStore) public {
        mixItemStore = _mixItemStore;
    }

    function createItem() public returns (bytes32) {
        return mixItemStore.create(hex"02", hex"1234");
    }

}
