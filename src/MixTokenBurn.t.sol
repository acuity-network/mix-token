pragma solidity ^0.5.11;

import "ds-test/test.sol";
import "mix-item-store/MixItemStoreIpfsSha256.sol";
import "./MixTokenBase.sol";
import "./MixTokenBurn.sol";

contract Token is MixTokenInterface, MixTokenBase {

    constructor(string memory symbol, string memory name, MixTokenRegistry tokenRegistry, bytes32 itemId) public
        MixTokenBase(symbol, name, tokenRegistry, itemId)
    {
        accountState[msg.sender].inUse = true;
        accountState[msg.sender].balance = 10;
        accountList.push(msg.sender);
    }

    function totalSupply() external view returns (uint) {
        return 10;
    }

}

contract MixTokenBurnTest is DSTest {

    MixTokenRegistry mixTokenRegistry;
    Token token;
    MixItemStoreRegistry mixItemStoreRegistry;
    MixItemStoreIpfsSha256 mixItemStore;
    MixItemDagOneParent mixTokenItems;
    MixTokenBurn mixTokenBurn;

    function setUp() public {
        mixItemStoreRegistry = new MixItemStoreRegistry();
        mixItemStore = new MixItemStoreIpfsSha256(mixItemStoreRegistry);
        bytes32 itemId = mixItemStore.create(hex"02", hex"1234");
        mixTokenRegistry = new MixTokenRegistry(mixItemStoreRegistry);
        token = new Token('a', 'A', mixTokenRegistry, itemId);
        mixTokenItems = new MixItemDagOneParent(mixItemStoreRegistry);
        mixTokenBurn = new MixTokenBurn(mixTokenRegistry, mixTokenItems);
        token.authorize(address(mixTokenBurn));
    }

    function testControlBurnTokensNotEnoughTokens() public {
        mixTokenBurn.burnTokens(token, 10);
    }

    function testFailBurnTokensNotEnoughTokens() public {
        mixTokenBurn.burnTokens(token, 11);
    }

    function testBurnTokens() public {
        assertEq(token.balanceOf(address(this)), 10);
        assertEq(mixTokenBurn.getTokensBurned(address(this), token), 0);
        mixTokenBurn.burnTokens(token, 5);
        assertEq(token.balanceOf(address(this)), 5);
        assertEq(mixTokenBurn.getTokensBurned(address(this), token), 5);
        mixTokenBurn.burnTokens(token, 1);
        assertEq(token.balanceOf(address(this)), 4);
        assertEq(mixTokenBurn.getTokensBurned(address(this), token), 6);
        mixTokenBurn.burnTokens(token, 2);
        assertEq(token.balanceOf(address(this)), 2);
        assertEq(mixTokenBurn.getTokensBurned(address(this), token), 8);
        mixTokenBurn.burnTokens(token, 2);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(mixTokenBurn.getTokensBurned(address(this), token), 10);
    }

    function testGetTokensBurnedMultiple() public {
        bytes32 itemId = mixItemStore.create(hex"0201", hex"1234");
        MixTokenInterface[] memory tokens = new MixTokenInterface[](4);
        tokens[0] = new Token('a', 'A', mixTokenRegistry, itemId);
        tokens[1] = new Token('a', 'A', mixTokenRegistry, itemId);
        tokens[2] = new Token('a', 'A', mixTokenRegistry, itemId);
        tokens[3] = new Token('a', 'A', mixTokenRegistry, itemId);
        tokens[0].authorize(address(mixTokenBurn));
        tokens[1].authorize(address(mixTokenBurn));
        tokens[2].authorize(address(mixTokenBurn));
        tokens[3].authorize(address(mixTokenBurn));
        mixTokenBurn.burnTokens(tokens[0], 5);
        mixTokenBurn.burnTokens(tokens[1], 4);
        mixTokenBurn.burnTokens(tokens[2], 3);
        mixTokenBurn.burnTokens(tokens[3], 2);
        uint[] memory burned = mixTokenBurn.getTokensBurnedMultiple(address(this), tokens);
        assertEq(burned.length, 4);
        assertEq(burned[0], 5);
        assertEq(burned[1], 4);
        assertEq(burned[2], 3);
        assertEq(burned[3], 2);
    }

}
