pragma solidity ^0.5.10;

import "ds-test/test.sol";
import "mix-item-store/MixItemStoreIpfsSha256.sol";
import "./CreatorToken.sol";
import "./MixToken.t.sol";


contract CreatorTokenTest is DSTest {

    MixTokenRegistry mixTokenRegistry;
    MixItemStoreRegistry mixItemStoreRegistry;
    MixItemStoreIpfsSha256 mixItemStore;
    CreatorToken token;
    MockAccount mockAccount;

    function setUp() public {
        mixItemStoreRegistry = new MixItemStoreRegistry();
        mixItemStore = new MixItemStoreIpfsSha256(mixItemStoreRegistry);
        bytes32 itemId = mixItemStore.create(hex"02", hex"1234");
        mixTokenRegistry = new MixTokenRegistry(mixItemStoreRegistry);
        token = new CreatorToken('a', 'A', 16, 10, 1, address(this), mixTokenRegistry, itemId);
        mockAccount = new MockAccount(token);
    }

    function testConstants() public {
        assertEq0(bytes(token.symbol()), bytes('a'));
        assertEq0(bytes(token.name()), bytes('A'));
        assertEq(token.decimals(), 16);
        assertEq(token.totalSupply(), 10);
        assertEq(token.start(), block.timestamp);
        assertEq(token.owner(), address(this));
        assertEq(token.initialBalance(), 10);
        assertEq(token.dailyPayout(), 1);
    }

    function testControlTransferInsufficientBalance() public {
        token.transfer(address(0x1234), 1);
    }

    function testFailTransferInsufficientBalance() public {
        token.transfer(address(0x1234), 10);
        token.transfer(address(0x1234), 1);
    }

    function testTransfer() public {
        assertEq(token.balanceOf(address(this)), 10);
        assertEq(token.balanceOf(address(0x1234)), 0);
        assertEq(token.balanceOf(address(0x2345)), 0);
        assertTrue(token.transfer(address(0x1234), 5));
        assertEq(token.balanceOf(address(this)), 5);
        assertEq(token.balanceOf(address(0x1234)), 5);
        assertEq(token.balanceOf(address(0x2345)), 0);
        assertTrue(token.transfer(address(0x1234), 2));
        assertEq(token.balanceOf(address(this)), 3);
        assertEq(token.balanceOf(address(0x1234)), 7);
        assertEq(token.balanceOf(address(0x2345)), 0);
        assertTrue(token.transfer(address(0x2345), 1));
        assertEq(token.balanceOf(address(this)), 2);
        assertEq(token.balanceOf(address(0x1234)), 7);
        assertEq(token.balanceOf(address(0x2345)), 1);
        assertTrue(token.transfer(address(0x2345), 2));
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(0x1234)), 7);
        assertEq(token.balanceOf(address(0x2345)), 3);
    }

    function testControlTransferFromNotAuthorized() public {
        mockAccount.authorize(address(this));
        token.transfer(address(mockAccount), 5);
        token.transferFrom(address(mockAccount), address(this), 5);
    }

    function testFailTransferFromNotAuthorized() public {
        token.transfer(address(mockAccount), 5);
        token.transferFrom(address(mockAccount), address(this), 5);
    }

    function testControlTransferFromInsufficientBalance() public {
        mockAccount.authorize(address(this));
        token.transfer(address(mockAccount), 5);
        token.transferFrom(address(mockAccount), address(this), 5);
    }

    function testFailTransferFromInsufficientBalance() public {
        mockAccount.authorize(address(this));
        token.transferFrom(address(mockAccount), address(this), 5);
    }

    function testTransferFrom() public {
        assertEq(token.balanceOf(address(this)), 10);
        assertEq(token.balanceOf(address(mockAccount)), 0);
        assertEq(token.balanceOf(address(0x1234)), 0);
        mockAccount.authorize(address(this));
        assertTrue(token.transfer(address(mockAccount), 10));
        assertEq(token.balanceOf(address(mockAccount)), 10);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(0x1234)), 0);
        assertTrue(token.transferFrom(address(mockAccount), address(this), 3));
        assertEq(token.balanceOf(address(mockAccount)), 7);
        assertEq(token.balanceOf(address(this)), 3);
        assertEq(token.balanceOf(address(0x1234)), 0);
        assertTrue(token.transferFrom(address(mockAccount), address(0x1234), 5));
        assertEq(token.balanceOf(address(mockAccount)), 2);
        assertEq(token.balanceOf(address(this)), 3);
        assertEq(token.balanceOf(address(0x1234)), 5);
        assertTrue(token.transferFrom(address(mockAccount), address(this), 2));
        assertEq(token.balanceOf(address(mockAccount)), 0);
        assertEq(token.balanceOf(address(this)), 5);
        assertEq(token.balanceOf(address(0x1234)), 5);
    }

    function testAccountList() public {
        address[] memory accounts;
        uint[] memory balances;

        assertEq(token.getAccountCount(), 1);
        accounts = token.getAccounts();
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        (accounts, balances) = token.getAccountBalances();
        assertEq(accounts.length, 1);
        assertEq(accounts[0], address(this));
        assertEq(balances.length, 1);
        assertEq(balances[0], 10);

        assertTrue(token.transfer(address(0x1234), 5));
        assertEq(token.getAccountCount(), 2);
        accounts = token.getAccounts();
        assertEq(accounts.length, 2);
        assertEq(accounts[0], address(this));
        assertEq(accounts[1], address(0x1234));
        (accounts, balances) = token.getAccountBalances();
        assertEq(accounts.length, 2);
        assertEq(accounts[0], address(this));
        assertEq(accounts[1], address(0x1234));
        assertEq(balances.length, 2);
        assertEq(balances[0], 5);
        assertEq(balances[1], 5);

        assertTrue(token.transfer(address(0x1234), 1));
        assertEq(token.getAccountCount(), 2);
        accounts = token.getAccounts();
        assertEq(accounts.length, 2);
        assertEq(accounts[0], address(this));
        assertEq(accounts[1], address(0x1234));
        (accounts, balances) = token.getAccountBalances();
        assertEq(accounts.length, 2);
        assertEq(accounts[0], address(this));
        assertEq(accounts[1], address(0x1234));
        assertEq(balances.length, 2);
        assertEq(balances[0], 4);
        assertEq(balances[1], 6);

        assertTrue(token.transfer(address(0x2345), 4));
        assertEq(token.getAccountCount(), 3);
        accounts = token.getAccounts();
        assertEq(accounts.length, 3);
        assertEq(accounts[0], address(this));
        assertEq(accounts[1], address(0x1234));
        assertEq(accounts[2], address(0x2345));
        (accounts, balances) = token.getAccountBalances();
        assertEq(accounts.length, 3);
        assertEq(accounts[0], address(this));
        assertEq(accounts[1], address(0x1234));
        assertEq(accounts[2], address(0x2345));
        assertEq(balances.length, 3);
        assertEq(balances[0], 0);
        assertEq(balances[1], 6);
        assertEq(balances[2], 4);
    }

}
