pragma solidity ^0.5.4;

import "ds-test/test.sol";

import "./Erc223.sol";

contract Erc223Test is DSTest {
    Erc223 erc;

    function setUp() public {
        erc = new Erc223();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
