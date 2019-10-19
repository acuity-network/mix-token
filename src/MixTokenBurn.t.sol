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
    MixItemStoreRegistry mixItemStoreRegistry;
    MixItemStoreIpfsSha256 mixItemStore;
    MixItemDagOneParent mixTokenItems;
    MixTokenBurn mixTokenBurn;

    AccountProxy account0;
    AccountProxy account1;
    AccountProxy account2;
    AccountProxy account3;
    AccountProxy account4;

    Token token0;
    Token token1;
    Token token2;
    Token token3;
    Token token4;

    function setUp() public {
        mixItemStoreRegistry = new MixItemStoreRegistry();
        mixItemStore = new MixItemStoreIpfsSha256(mixItemStoreRegistry);
        bytes32 itemId = mixItemStore.create(hex"02", hex"1234");
        mixTokenRegistry = new MixTokenRegistry(mixItemStoreRegistry);
        mixTokenItems = new MixItemDagOneParent(mixItemStoreRegistry);
        mixTokenBurn = new MixTokenBurn(mixTokenRegistry, mixTokenItems);

        token0 = new Token('a', 'A', mixTokenRegistry, itemId);
        token1 = new Token('a', 'A', mixTokenRegistry, itemId);
        token2 = new Token('a', 'A', mixTokenRegistry, itemId);
        token3 = new Token('a', 'A', mixTokenRegistry, itemId);
        token4 = new Token('a', 'A', mixTokenRegistry, itemId);

        account0 = new AccountProxy(token0, mixTokenBurn);
        account1 = new AccountProxy(token0, mixTokenBurn);
        account2 = new AccountProxy(token0, mixTokenBurn);
        account3 = new AccountProxy(token0, mixTokenBurn);
        account4 = new AccountProxy(token0, mixTokenBurn);

        token0.transfer(address(account0), 2);
        token0.transfer(address(account1), 2);
        token0.transfer(address(account2), 2);
        token0.transfer(address(account3), 2);
        token0.transfer(address(account4), 2);

        account0.authorize(address(mixTokenBurn));
        account1.authorize(address(mixTokenBurn));
        account2.authorize(address(mixTokenBurn));
        account3.authorize(address(mixTokenBurn));
        account4.authorize(address(mixTokenBurn));
    }

    function testControlBurnTokenZero() public {
        (address prev, address next) = account0.getBurnTokenPrevNext(token0, 1);
        account0.burnToken(token0, 1, prev, next);
    }

    function testFailBurnTokenZero() public {
        (address prev, address next) = account0.getBurnTokenPrevNext(token0, 0);
        account0.burnToken(token0, 0, prev, next);
    }

    function testControlBurnTokenNotEnough() public {
        (address prev, address next) = account0.getBurnTokenPrevNext(token0, 2);
        account0.burnToken(token0, 2, prev, next);
    }

    function testFailBurnTokenNotEnough() public {
        (address prev, address next) = account0.getBurnTokenPrevNext(token0, 3);
        account0.burnToken(token0, 3, prev, next);
    }

    function testBurnToken() public {
        assertEq(token0.balanceOf(address(account0)), 2);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 0);

        (address prev, address next) = account0.getBurnTokenPrevNext(token0, 1);
        account0.burnToken(token0, 1, prev, next);
        assertEq(token0.balanceOf(address(account0)), 1);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 0);
        (address[] memory tokens, uint[] memory amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        address[] memory accounts;
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 0);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);

        (prev, next) = account1.getBurnTokenPrevNext(token0, 2);
        account1.burnToken(token0, 2, prev, next);
        assertEq(token0.balanceOf(address(account1)), 0);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 3);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 2);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 4);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 2);
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 4);
        assertEq(accounts.length, 2);
        assertEq(accounts[0], address(account1));
        assertEq(accounts[1], address(account0));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 2);
        assertEq(amounts[1], 1);
    }

}
