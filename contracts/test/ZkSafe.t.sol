// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ZkSafe} from "../src/ZkSafe.sol";

contract CounterTest is Test {
    ZkSafe public zkSafe;

    function setUp() public {
        zkSafe = new ZkSafe();
    }
}
