pragma solidity ^0.5.4;

import "ds-test/test.sol";
import "./ERC223.sol";


contract ERC223Test is DSTest {

    ERC223Base erc223;

    function setUp() public {
        erc223 = new ERC223Base();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }

}
