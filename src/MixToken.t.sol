pragma solidity ^0.5.9;

import "ds-test/test.sol";
import "mix-item-store/ItemStoreIpfsSha256.sol";
import "./MixToken.sol";


contract Token is MixTokenBase {

    constructor(string memory symbol, string memory name, uint decimals, MixTokenRegistry tokenRegistry, bytes32 itemId) public
        MixTokenBase(symbol, name, decimals, tokenRegistry, itemId)
    {
        accountBalance[msg.sender] = 10;
    }

}


contract MixTokenReceiverMock is MixTokenReceiverInterface {

    /**
     * @return bytes4(keccak256("receiveMixToken(address,uint,bytes)"))
     */
    function onMixTokenReceived(address, uint, bytes calldata) external returns (bytes4) {
        return 0x3c8c71b0;
    }
}


contract MixTokenTest is DSTest {

    MixTokenRegistry tokenRegistry;
    Token token;
    MixTokenReceiverMock tokenReceiver;
    ItemStoreRegistry itemStoreRegistry;
    ItemStoreIpfsSha256 itemStore;

    function setUp() public {
        itemStoreRegistry = new ItemStoreRegistry();
        itemStore = new ItemStoreIpfsSha256(itemStoreRegistry);
        bytes32 itemId = itemStore.create(hex"02", hex"1234");
        tokenRegistry = new MixTokenRegistry(itemStoreRegistry);
        token = new Token('a', 'A', 16, tokenRegistry, itemId);
        tokenReceiver = new MixTokenReceiverMock();
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
