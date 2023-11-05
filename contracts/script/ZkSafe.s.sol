// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {ZkSafe} from "../src/ZkSafe.sol";

contract ZkSafeScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        ZkSafe zkSafe = new ZkSafe();
        address zkSafeAddr = address(zkSafe);
        console2.log("ZkSafe address: ", zkSafeAddr);
        vm.stopBroadcast();
    }
}
