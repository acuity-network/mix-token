pragma solidity ^0.5.4;

import "ds-test/test.sol";
import "./MixToken.sol";


contract MixTokenTest is DSTest {

    MixTokenBase mixToken;

    function setUp() public {
        mixToken = new MixTokenBase();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }

}
