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
        accountState[msg.sender].balance = 100;
        accountList.push(msg.sender);
    }

    function totalSupply() external view returns (uint) {
        return 100;
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

    function getBurnTokenPrevNext(MixTokenInterface token, uint amount) external view returns (address prev, address next) {
        (prev, next) = mixTokenBurn.getBurnTokenPrevNext(token, amount);
    }

    function burnToken(MixTokenInterface token, uint amount, address prev, address next) external {
        mixTokenBurn.burnToken(token, amount, prev, next);
    }

}


contract MixTokenBurnTest is DSTest {

    MixTokenRegistry mixTokenRegistry;
    Token token;
    MixItemStoreRegistry mixItemStoreRegistry;
    MixItemStoreIpfsSha256 mixItemStore;
    MixItemDagOneParent mixTokenItems;
    MixTokenBurn mixTokenBurn;

    AccountProxy account0;
    AccountProxy account1;
    AccountProxy account2;
    AccountProxy account3;
    AccountProxy account4;

    function setUp() public {
        mixItemStoreRegistry = new MixItemStoreRegistry();
        mixItemStore = new MixItemStoreIpfsSha256(mixItemStoreRegistry);
        bytes32 itemId = mixItemStore.create(hex"02", hex"1234");
        mixTokenRegistry = new MixTokenRegistry(mixItemStoreRegistry);
        token = new Token('a', 'A', mixTokenRegistry, itemId);
        mixTokenItems = new MixItemDagOneParent(mixItemStoreRegistry);
        mixTokenBurn = new MixTokenBurn(mixTokenRegistry, mixTokenItems);
        token.authorize(address(mixTokenBurn));

        account0 = new AccountProxy(token, mixTokenBurn);
        account1 = new AccountProxy(token, mixTokenBurn);
        account2 = new AccountProxy(token, mixTokenBurn);
        account3 = new AccountProxy(token, mixTokenBurn);
        account4 = new AccountProxy(token, mixTokenBurn);

        token.transfer(address(account0), 2);
        token.transfer(address(account1), 2);
        token.transfer(address(account2), 2);
        token.transfer(address(account3), 2);
        token.transfer(address(account4), 2);

        account0.authorize(address(mixTokenBurn));
        account1.authorize(address(mixTokenBurn));
        account2.authorize(address(mixTokenBurn));
        account3.authorize(address(mixTokenBurn));
        account4.authorize(address(mixTokenBurn));
    }

    function testControlBurnTokenZero() public {
        (address prev, address next) = account0.getBurnTokenPrevNext(token, 1);
        account0.burnToken(token, 1, prev, next);
    }

    function testFailBurnTokenZero() public {
        (address prev, address next) = account0.getBurnTokenPrevNext(token, 0);
        account0.burnToken(token, 0, prev, next);
    }

    function testControlBurnTokenNotEnough() public {
        (address prev, address next) = account0.getBurnTokenPrevNext(token, 2);
        account0.burnToken(token, 2, prev, next);
    }

    function testFailBurnTokenNotEnough() public {
        (address prev, address next) = account0.getBurnTokenPrevNext(token, 3);
        account0.burnToken(token, 3, prev, next);
    }

    function testBurnToken() public {
        assertEq(token.balanceOf(address(account0)), 2);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token), 0);

        (address prev, address next) = account0.getBurnTokenPrevNext(token, 1);
        account0.burnToken(token, 1, prev, next);
        assertEq(token.balanceOf(address(account0)), 1);
        assertEq(token.balanceOf(address(mixTokenBurn)), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token), 0);
        (address[] memory tokens, uint[] memory amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(amounts.length, 1);

        (prev, next) = account1.getBurnTokenPrevNext(token, 2);
        account1.burnToken(token, 2, prev, next);
        assertEq(token.balanceOf(address(account1)), 0);
        assertEq(token.balanceOf(address(mixTokenBurn)), 3);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token), 2);
    }

}
