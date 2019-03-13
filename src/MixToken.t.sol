pragma solidity ^0.5.4;

import "ds-test/test.sol";
import "./MixToken.sol";


contract Token is MixTokenBase {

    constructor() public {
        accountBalance[msg.sender] = 10;
    }

}

contract MixTokenTest is DSTest {

    Token token;
    MixTokenReceiverBase tokenReceiver;

    function setUp() public {
        token = new Token();
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
