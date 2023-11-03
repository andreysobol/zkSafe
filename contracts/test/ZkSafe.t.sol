// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ZkSafe} from "../src/ZkSafe.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint (address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract CounterTest is Test {
    ZkSafe public zkSafe;
    MockERC20 public token;

    uint256 initialBalance = 1e24;
    bytes32 constant TEST_MULTISIG_ID = keccak256("TEST");


    function setUp() public {
        zkSafe = new ZkSafe();
        token = new MockERC20("Test", "TEST");

        token.mint(address(this), initialBalance);
        token.approve(address(zkSafe), initialBalance);
    }

    function assertTokenBalance(address tokenAddress, address holder, uint256 expectedBalance) internal {
        assertEq(IERC20(tokenAddress).balanceOf(holder), expectedBalance);
    }

    function testDeposit() public {
        uint256 depositAmount = 1e18; // 1 token, assuming 18 decimals
        zkSafe.deposit(TEST_MULTISIG_ID, depositAmount, address(token));

        assertEq(zkSafe.multisigs(TEST_MULTISIG_ID, address(token)), depositAmount);
        assertTokenBalance(address(token), address(zkSafe), depositAmount);
        assertTokenBalance(address(token), address(this), initialBalance - depositAmount); // Check if tokens are deducted
    }

    function testExecute() public {
        uint256 depositAmount = 1e18; // 1 token, assuming 18 decimals
        uint256 executeAmount = 1e18; // 1 token, assuming 18 decimals

        zkSafe.deposit(TEST_MULTISIG_ID, depositAmount, address(token));

        ZkSafe.Operation memory operation = ZkSafe.Operation({
            multisig_id: TEST_MULTISIG_ID,
            amount: executeAmount,
            token: address(token),
            to: address(this) // Send tokens back to the test address
        });

        bytes32[] memory dummyProof = new bytes32[](1);

        zkSafe.execute(operation, dummyProof);

        assertEq(zkSafe.multisigs(TEST_MULTISIG_ID, address(token)), 0);
        assertTokenBalance(address(token), address(this), initialBalance); // Test address should have all the tokens back
    }
}
