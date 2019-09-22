pragma solidity ^0.5.11;

import "ds-test/test.sol";

import "./MixTokenBurn.sol";

contract MixTokenBurnTest is DSTest {
    MixTokenBurn burn;

    function setUp() public {
        burn = new MixTokenBurn();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
