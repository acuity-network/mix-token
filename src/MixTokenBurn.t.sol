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

contract AccountProxy {

    MixTokenBase mixTokenBase;
    MixTokenBurn mixTokenBurn;

    constructor (MixTokenBase _mixTokenBase, MixTokenBurn _mixTokenBurn) public {
        mixTokenBase = _mixTokenBase;
        mixTokenBurn = _mixTokenBurn;
    }

    function authorize(address account) external {
        mixTokenBase.authorize(account);
    }

    function burnToken(MixTokenInterface token, uint amount, address prev, address next) external {
        mixTokenBurn.burnToken(token, amount, prev, next);
    }

    function getBurnTokenPrevNext(MixTokenInterface token, uint amount) external view returns (address prev, address next) {
        (prev, next) = mixTokenBurn.getBurnTokenPrevNext(token, amount);
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

    function testControlBurnTokenZero() public {
        (address prev, address next) = mixTokenBurn.getBurnTokenPrevNext(token, 1);
        mixTokenBurn.burnToken(token, 1, prev, next);
    }

    function testFailBurnTokenZero() public {
        (address prev, address next) = mixTokenBurn.getBurnTokenPrevNext(token, 0);
        mixTokenBurn.burnToken(token, 0, prev, next);
    }

    function testControlBurnTokenNotEnough() public {
        (address prev, address next) = mixTokenBurn.getBurnTokenPrevNext(token, 10);
        mixTokenBurn.burnToken(token, 10, prev, next);
    }

    function testFailBurnTokenNotEnough() public {
        (address prev, address next) = mixTokenBurn.getBurnTokenPrevNext(token, 11);
        mixTokenBurn.burnToken(token, 11, prev, next);
    }

    function testBurnToken() public {
        assertEq(token.balanceOf(address(this)), 10);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(this), token), 0);
        (address prev, address next) = mixTokenBurn.getBurnTokenPrevNext(token, 1);
        mixTokenBurn.burnToken(token, 1, prev, next);
        assertEq(token.balanceOf(address(this)), 9);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(this), token), 1);

        AccountProxy accountProxy = new AccountProxy(token, mixTokenBurn);

        token.transfer(address(accountProxy), 2);

        accountProxy.authorize(address(mixTokenBurn));
        (prev, next) = accountProxy.getBurnTokenPrevNext(token, 2);

        emit log_named_address("prev", prev);
        emit log_named_address("next", next);

        accountProxy.burnToken(token, 2, prev, next);
        assertEq(token.balanceOf(address(accountProxy)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(this), token), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(accountProxy), token), 2);
/*
        (prev, next) = mixTokenBurn.getBurnTokensPrevNext(token, 2);
        mixTokenBurn.burnTokens(token, 2, prev, next);
        assertEq(token.balanceOf(address(this)), 2);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(this), token), 7);

        (prev, next) = mixTokenBurn.getBurnTokensPrevNext(token, 2);
        mixTokenBurn.burnTokens(token, 2, prev, next);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(this), token), 9);
*/
    }
/*
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
*/
}
