pragma solidity ^0.5.11;

import "ds-test/test.sol";
import "mix-item-store/MixItemStoreIpfsSha256.sol";
import "./MixTokenBase.sol";
import "./MixTokenBurn.sol";


contract Token is MixTokenInterface, MixTokenBase {

    constructor(string memory symbol, string memory name) public
        MixTokenBase(symbol, name)
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

    function getBurnTokenPrev(MixTokenInterface token, uint amount) external view returns (address prev, address oldPrev) {
        (prev, oldPrev) = mixTokenBurn.getBurnTokenPrev(token, amount);
    }

    function getBurnItemPrev(bytes32 itemId, uint amount) external view returns (address tokenPrev, address tokenOldPrev, address itemPrev, address itemOldPrev) {
        (tokenPrev, tokenOldPrev, itemPrev, itemOldPrev) = mixTokenBurn.getBurnItemPrev(itemId, amount);
    }

    function burnToken(MixTokenInterface token, uint amount, address prev, address oldPrev) external {
        mixTokenBurn.burnToken(token, amount, prev, oldPrev);
    }

    function burnItem(bytes32 itemId, uint amount, address tokenPrev, address tokenOldPrev, address itemPrev, address itemOldPrev) external {
        mixTokenBurn.burnItem(itemId, amount, tokenPrev, tokenOldPrev, itemPrev, itemOldPrev);
    }

}


contract MixTokenBurnTest is DSTest {

    MixTokenRegistry mixTokenRegistry;
    MixItemStoreRegistry mixItemStoreRegistry;
    MixItemStoreIpfsSha256 mixItemStore;
    MixItemDagOneParentOnlyOwner mixTokenItems;
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

    bytes32 itemId0;

    function setUp() public {
        mixItemStoreRegistry = new MixItemStoreRegistry();
        mixItemStore = new MixItemStoreIpfsSha256(mixItemStoreRegistry);
        bytes32 itemId = mixItemStore.create(hex"02", hex"1234");
        mixTokenRegistry = new MixTokenRegistry(mixItemStoreRegistry);
        mixTokenItems = new MixItemDagOneParentOnlyOwner(mixItemStoreRegistry);
        mixTokenBurn = new MixTokenBurn(mixTokenRegistry, mixTokenItems);

        token0 = new Token('a', 'A');
        mixTokenRegistry.register(itemId, token0);

        account0 = new AccountProxy(token0, mixTokenBurn);
        account1 = new AccountProxy(token0, mixTokenBurn);
        account2 = new AccountProxy(token0, mixTokenBurn);
        account3 = new AccountProxy(token0, mixTokenBurn);
        account4 = new AccountProxy(token0, mixTokenBurn);

        token0.transfer(address(account0), 10);
        token0.transfer(address(account1), 10);
        token0.transfer(address(account2), 10);
        token0.transfer(address(account3), 10);
        token0.transfer(address(account4), 10);

        account0.authorize(address(mixTokenBurn));
        account1.authorize(address(mixTokenBurn));
        account2.authorize(address(mixTokenBurn));
        account3.authorize(address(mixTokenBurn));
        account4.authorize(address(mixTokenBurn));

        mixTokenItems.addChild(itemId, mixItemStore, hex"0201");
        itemId0 = mixItemStore.create(hex"0201", hex"1234");
    }

    function testControlBurnTokenZero() public {
        (address prev, address oldPrev) = account0.getBurnTokenPrev(token0, 1);
        account0.burnToken(token0, 1, prev, oldPrev);
    }

    function testFailBurnTokenZero() public {
        (address prev, address oldPrev) = account0.getBurnTokenPrev(token0, 0);
        account0.burnToken(token0, 0, prev, oldPrev);
    }

    function testControlBurnTokenNotEnough() public {
        (address prev, address oldPrev) = account0.getBurnTokenPrev(token0, 10);
        account0.burnToken(token0, 10, prev, oldPrev);
    }

    function testFailBurnTokenNotEnough() public {
        (address prev, address oldPrev) = account0.getBurnTokenPrev(token0, 11);
        account0.burnToken(token0, 11, prev, oldPrev);
    }

    function testControlBurnTokenOldPrevIncorrect() public {
        account0.burnToken(token0, 3, address(0), address(0));
        account1.burnToken(token0, 2, address(account0), address(0));
        account1.burnToken(token0, 4, address(0), address(account0));
    }

    function testFailBurnTokenOldPrevIncorrect() public {
        account0.burnToken(token0, 3, address(0), address(0));
        account1.burnToken(token0, 2, address(account0), address(0));
        account1.burnToken(token0, 4, address(0), address(0));
    }

    function testControlBurnTokenNotLessThanOrEqualToPrev() public {
        account0.burnToken(token0, 3, address(0), address(0));
        account1.burnToken(token0, 3, address(account0), address(0));
    }

    function testFailBurnTokenNotLessThanOrEqualToPrev() public {
        account0.burnToken(token0, 3, address(0), address(0));
        account1.burnToken(token0, 4, address(account0), address(0));
    }

    function testControlBurnTokenNotMoreThanNext() public {
        account0.burnToken(token0, 3, address(0), address(0));
        account1.burnToken(token0, 2, address(account0), address(0));
        account2.burnToken(token0, 3, address(account0), address(0));
    }

    function testFailBurnTokenNotMoreThanNext() public {
        account0.burnToken(token0, 3, address(0), address(0));
        account1.burnToken(token0, 2, address(account0), address(0));
        account2.burnToken(token0, 2, address(account0), address(0));
    }

    function testBurnToken() public {
        assertEq(token0.balanceOf(address(mixTokenBurn)), 0);

        assertEq(token0.balanceOf(address(account0)), 10);
        assertEq(token0.balanceOf(address(account1)), 10);
        assertEq(token0.balanceOf(address(account2)), 10);
        assertEq(token0.balanceOf(address(account3)), 10);

        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);

        (address prev, address oldPrev) = account0.getBurnTokenPrev(token0, 1);
        account0.burnToken(token0, 1, prev, oldPrev);
        assertEq(token0.balanceOf(address(account0)), 9);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);
        (address[] memory tokens, uint[] memory amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        address[] memory accounts;
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);

        (prev, oldPrev) = account1.getBurnTokenPrev(token0, 2);
        account1.burnToken(token0, 2, prev, oldPrev);
        assertEq(token0.balanceOf(address(account1)), 8);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 3);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 2);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 2);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 2);
        assertEq(accounts[0], address(account1));
        assertEq(accounts[1], address(account0));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 2);
        assertEq(amounts[1], 1);

        (prev, oldPrev) = account1.getBurnTokenPrev(token0, 2);
        account1.burnToken(token0, 2, prev, oldPrev);
        assertEq(token0.balanceOf(address(account1)), 6);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 5);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 4);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 2);
        assertEq(accounts[0], address(account1));
        assertEq(accounts[1], address(account0));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 4);
        assertEq(amounts[1], 1);

        (prev, oldPrev) = account2.getBurnTokenPrev(token0, 1);
        account2.burnToken(token0, 1, prev, oldPrev);
        assertEq(token0.balanceOf(address(account2)), 9);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 6);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 4);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 3);
        assertEq(accounts[0], address(account1));
        assertEq(accounts[1], address(account0));
        assertEq(accounts[2], address(account2));
        assertEq(amounts.length, 3);
        assertEq(amounts[0], 4);
        assertEq(amounts[1], 1);
        assertEq(amounts[2], 1);

        (prev, oldPrev) = account2.getBurnTokenPrev(token0, 8);
        account2.burnToken(token0, 8, prev, oldPrev);
        assertEq(token0.balanceOf(address(account2)), 1);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 14);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 4);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 9);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(accounts[1], address(account1));
        assertEq(accounts[2], address(account0));
        assertEq(amounts.length, 3);
        assertEq(amounts[0], 9);
        assertEq(amounts[1], 4);
        assertEq(amounts[2], 1);

        (prev, oldPrev) = account0.getBurnTokenPrev(token0, 8);
        account0.burnToken(token0, 8, prev, oldPrev);
        assertEq(token0.balanceOf(address(account0)), 1);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 22);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 9);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 4);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 9);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(accounts[1], address(account0));
        assertEq(accounts[2], address(account1));
        assertEq(amounts.length, 3);
        assertEq(amounts[0], 9);
        assertEq(amounts[1], 9);
        assertEq(amounts[2], 4);

        (prev, oldPrev) = account3.getBurnTokenPrev(token0, 5);
        account3.burnToken(token0, 5, prev, oldPrev);
        assertEq(token0.balanceOf(address(account3)), 5);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 27);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 9);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 4);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 9);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 5);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 5);
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 4);
        assertEq(accounts[0], address(account2));
        assertEq(accounts[1], address(account0));
        assertEq(accounts[2], address(account3));
        assertEq(accounts[3], address(account1));
        assertEq(amounts.length, 4);
        assertEq(amounts[0], 9);
        assertEq(amounts[1], 9);
        assertEq(amounts[2], 5);
        assertEq(amounts[3], 4);
    }

    function testBurnItem() public {
        assertEq(token0.balanceOf(address(mixTokenBurn)), 0);
        assertEq(mixTokenBurn.getItemBurnedTotal(itemId0), 0);

        assertEq(token0.balanceOf(address(account0)), 10);
        assertEq(token0.balanceOf(address(account1)), 10);
        assertEq(token0.balanceOf(address(account2)), 10);
        assertEq(token0.balanceOf(address(account3)), 10);

        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);

        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account0)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account0), itemId0), 0);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account1)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account1), itemId0), 0);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account2)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account2), itemId0), 0);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account3), itemId0), 0);

        (address tokenPrev, address tokenOldPrev, address itemPrev, address itemOldPrev) = account0.getBurnItemPrev(itemId0, 1);
        account0.burnItem(itemId0, 1, tokenPrev, tokenOldPrev, itemPrev, itemOldPrev);
        assertEq(token0.balanceOf(address(account0)), 9);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 1);
        assertEq(mixTokenBurn.getItemBurnedTotal(itemId0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account0), itemId0), 1);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account1)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account1), itemId0), 0);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account2)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account2), itemId0), 0);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account3), itemId0), 0);
        (address[] memory tokens, uint[] memory amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        bytes32[] memory itemIds;
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account0), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account1), 0, 0);
        assertEq(itemIds.length, 0);
        assertEq(amounts.length, 0);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account2), 0, 0);
        assertEq(itemIds.length, 0);
        assertEq(amounts.length, 0);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account3), 0, 0);
        assertEq(itemIds.length, 0);
        assertEq(amounts.length, 0);
        address[] memory accounts;
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (accounts, amounts) = mixTokenBurn.getItemAccountsBurned(itemId0, 0, 10);
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(account0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);

        (tokenPrev, tokenOldPrev, itemPrev, itemOldPrev) = account1.getBurnItemPrev(itemId0, 2);
        account1.burnItem(itemId0, 2, tokenPrev, tokenOldPrev, itemPrev, itemOldPrev);
        assertEq(token0.balanceOf(address(account1)), 8);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 3);
        assertEq(mixTokenBurn.getItemBurnedTotal(itemId0), 3);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 2);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account0), itemId0), 1);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account1), itemId0), 2);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account2)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account2), itemId0), 0);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account3), itemId0), 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 2);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account0), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account1), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 2);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account2), 0, 0);
        assertEq(itemIds.length, 0);
        assertEq(amounts.length, 0);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account3), 0, 0);
        assertEq(itemIds.length, 0);
        assertEq(amounts.length, 0);
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 2);
        assertEq(accounts[0], address(account1));
        assertEq(accounts[1], address(account0));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 2);
        assertEq(amounts[1], 1);
        (accounts, amounts) = mixTokenBurn.getItemAccountsBurned(itemId0, 0, 10);
        assertEq(accounts.length, 2);
        assertEq(accounts[0], address(account1));
        assertEq(accounts[1], address(account0));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 2);
        assertEq(amounts[1], 1);

        (tokenPrev, tokenOldPrev, itemPrev, itemOldPrev) = account1.getBurnItemPrev(itemId0, 2);
        account1.burnItem(itemId0, 2, tokenPrev, tokenOldPrev, itemPrev, itemOldPrev);
        assertEq(token0.balanceOf(address(account1)), 6);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 5);
        assertEq(mixTokenBurn.getItemBurnedTotal(itemId0), 5);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 4);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 0);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account0), itemId0), 1);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account1), itemId0), 4);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account2)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account2), itemId0), 0);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account3), itemId0), 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account0), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account1), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account2), 0, 0);
        assertEq(itemIds.length, 0);
        assertEq(amounts.length, 0);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account3), 0, 0);
        assertEq(itemIds.length, 0);
        assertEq(amounts.length, 0);
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 2);
        assertEq(accounts[0], address(account1));
        assertEq(accounts[1], address(account0));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 4);
        assertEq(amounts[1], 1);
        (accounts, amounts) = mixTokenBurn.getItemAccountsBurned(itemId0, 0, 10);
        assertEq(accounts.length, 2);
        assertEq(accounts[0], address(account1));
        assertEq(accounts[1], address(account0));
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 4);
        assertEq(amounts[1], 1);

        (tokenPrev, tokenOldPrev, itemPrev, itemOldPrev) = account2.getBurnItemPrev(itemId0, 1);
        account2.burnItem(itemId0, 1, tokenPrev, tokenOldPrev, itemPrev, itemOldPrev);
        assertEq(token0.balanceOf(address(account2)), 9);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 6);
        assertEq(mixTokenBurn.getItemBurnedTotal(itemId0), 6);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 4);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account0), itemId0), 1);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account1), itemId0), 4);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account2)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account2), itemId0), 1);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account3), itemId0), 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account0), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account1), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account2), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account3), 0, 0);
        assertEq(itemIds.length, 0);
        assertEq(amounts.length, 0);
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 3);
        assertEq(accounts[0], address(account1));
        assertEq(accounts[1], address(account0));
        assertEq(accounts[2], address(account2));
        assertEq(amounts.length, 3);
        assertEq(amounts[0], 4);
        assertEq(amounts[1], 1);
        assertEq(amounts[2], 1);
        (accounts, amounts) = mixTokenBurn.getItemAccountsBurned(itemId0, 0, 10);
        assertEq(accounts.length, 3);
        assertEq(accounts[0], address(account1));
        assertEq(accounts[1], address(account0));
        assertEq(accounts[2], address(account2));
        assertEq(amounts.length, 3);
        assertEq(amounts[0], 4);
        assertEq(amounts[1], 1);
        assertEq(amounts[2], 1);

        (tokenPrev, tokenOldPrev, itemPrev, itemOldPrev) = account2.getBurnItemPrev(itemId0, 8);
        account2.burnItem(itemId0, 8, tokenPrev, tokenOldPrev, itemPrev, itemOldPrev);
        assertEq(token0.balanceOf(address(account2)), 1);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 14);
        assertEq(mixTokenBurn.getItemBurnedTotal(itemId0), 14);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 1);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 4);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 9);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account0), itemId0), 1);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account1), itemId0), 4);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account2)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account2), itemId0), 9);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account3), itemId0), 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account0), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 1);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account1), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account2), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account3), 0, 0);
        assertEq(itemIds.length, 0);
        assertEq(amounts.length, 0);
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(accounts[1], address(account1));
        assertEq(accounts[2], address(account0));
        assertEq(amounts.length, 3);
        assertEq(amounts[0], 9);
        assertEq(amounts[1], 4);
        assertEq(amounts[2], 1);
        (accounts, amounts) = mixTokenBurn.getItemAccountsBurned(itemId0, 0, 10);
        assertEq(accounts.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(accounts[1], address(account1));
        assertEq(accounts[2], address(account0));
        assertEq(amounts.length, 3);
        assertEq(amounts[0], 9);
        assertEq(amounts[1], 4);
        assertEq(amounts[2], 1);

        (tokenPrev, tokenOldPrev, itemPrev, itemOldPrev) = account0.getBurnItemPrev(itemId0, 8);
        account0.burnItem(itemId0, 8, tokenPrev, tokenOldPrev, itemPrev, itemOldPrev);
        assertEq(token0.balanceOf(address(account0)), 1);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 22);
        assertEq(mixTokenBurn.getItemBurnedTotal(itemId0), 22);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 9);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 4);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 9);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 0);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account0), itemId0), 9);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account1), itemId0), 4);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account2)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account2), itemId0), 9);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account3)), 0);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account3), itemId0), 0);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 0);
        assertEq(amounts.length, 0);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account0), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account1), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account2), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account3), 0, 0);
        assertEq(itemIds.length, 0);
        assertEq(amounts.length, 0);
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(accounts[1], address(account0));
        assertEq(accounts[2], address(account1));
        assertEq(amounts.length, 3);
        assertEq(amounts[0], 9);
        assertEq(amounts[1], 9);
        assertEq(amounts[2], 4);
        (accounts, amounts) = mixTokenBurn.getItemAccountsBurned(itemId0, 0, 10);
        assertEq(accounts.length, 3);
        assertEq(accounts[0], address(account2));
        assertEq(accounts[1], address(account0));
        assertEq(accounts[2], address(account1));
        assertEq(amounts.length, 3);
        assertEq(amounts[0], 9);
        assertEq(amounts[1], 9);
        assertEq(amounts[2], 4);

        (tokenPrev, tokenOldPrev, itemPrev, itemOldPrev) = account3.getBurnItemPrev(itemId0, 5);
        account3.burnItem(itemId0, 5, tokenPrev, tokenOldPrev, itemPrev, itemOldPrev);
        assertEq(token0.balanceOf(address(account3)), 5);
        assertEq(token0.balanceOf(address(mixTokenBurn)), 27);
        assertEq(mixTokenBurn.getItemBurnedTotal(itemId0), 27);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account0), token0), 9);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account1), token0), 4);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account2)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account2), token0), 9);
        assertEq(mixTokenBurn.getAccountTokensBurnedCount(address(account3)), 1);
        assertEq(mixTokenBurn.getAccountTokenBurned(address(account3), token0), 5);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account0)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account0), itemId0), 9);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account1)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account1), itemId0), 4);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account2)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account2), itemId0), 9);
        assertEq(mixTokenBurn.getAccountItemsBurnedCount(address(account3)), 1);
        assertEq(mixTokenBurn.getAccountItemBurned(address(account3), itemId0), 5);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account0), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account1), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account2), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (tokens, amounts) = mixTokenBurn.getAccountTokensBurned(address(account3), 0, 0);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(token0));
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 5);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account0), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account1), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 4);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account2), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 9);
        (itemIds, amounts) = mixTokenBurn.getAccountItemsBurned(address(account3), 0, 0);
        assertEq(itemIds.length, 1);
        assertEq(itemIds[0], itemId0);
        assertEq(amounts.length, 1);
        assertEq(amounts[0], 5);
        (accounts, amounts) = mixTokenBurn.getTokenAccountsBurned(address(token0), 0, 10);
        assertEq(accounts.length, 4);
        assertEq(accounts[0], address(account2));
        assertEq(accounts[1], address(account0));
        assertEq(accounts[2], address(account3));
        assertEq(accounts[3], address(account1));
        assertEq(amounts.length, 4);
        assertEq(amounts[0], 9);
        assertEq(amounts[1], 9);
        assertEq(amounts[2], 5);
        assertEq(amounts[3], 4);
        (accounts, amounts) = mixTokenBurn.getItemAccountsBurned(itemId0, 0, 10);
        assertEq(accounts.length, 4);
        assertEq(accounts[0], address(account2));
        assertEq(accounts[1], address(account0));
        assertEq(accounts[2], address(account3));
        assertEq(accounts[3], address(account1));
        assertEq(amounts.length, 4);
        assertEq(amounts[0], 9);
        assertEq(amounts[1], 9);
        assertEq(amounts[2], 5);
        assertEq(amounts[3], 4);
    }

    function testGetAccountTokensBurned() public {
    }

    function testGetTokenAccountsBurned() public {
    }

    function testGetAccountItemsBurned() public {
    }

    function testGetItemAccountsBurned() public {
    }

}
