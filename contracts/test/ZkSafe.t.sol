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

contract ZkSafeTest is Test {
    ZkSafe public zkSafe;
    MockERC20 public token;

    uint256 initialBalance = 1e24;
    bytes32 constant TEST_MULTISIG_ID = keccak256("TEST");


    function setUp() public {
        zkSafe = new ZkSafe();
        token = new MockERC20("Test", "TEST");

        token.mint(address(this), initialBalance);
        token.approve(address(zkSafe), initialBalance);
        console2.log("token address:", address(token));
    }

    function assertTokenBalance(address tokenAddress, address holder, uint256 expectedBalance) internal {
        assertEq(IERC20(tokenAddress).balanceOf(holder), expectedBalance);
    }

    function testDeposit() public {
        uint256 depositAmount = 1e18;
        zkSafe.deposit(TEST_MULTISIG_ID, depositAmount, address(token));

        assertEq(zkSafe.multisigs(TEST_MULTISIG_ID, address(token)), depositAmount);
        assertTokenBalance(address(token), address(zkSafe), depositAmount);
        assertTokenBalance(address(token), address(this), initialBalance - depositAmount);
    }

    function testExecute() public {
        uint256 depositAmount = 1e18;
        uint256 executeAmount = 1e18;

        ZkSafe.Operation[] memory operations = new ZkSafe.Operation[](1);
        bytes32[] memory dummyProofs = new bytes32[](1);

        zkSafe.deposit(TEST_MULTISIG_ID, depositAmount, address(token));

        ZkSafe.Operation memory operation = ZkSafe.Operation({
            multisig_id: TEST_MULTISIG_ID,
            amount: executeAmount,
            token: address(token),
            to: address(this)
        });

        operations[0] = operation;
        dummyProofs[0] = bytes32(0);

        uint256 gasBefore = gasleft();
        zkSafe.execute(operations, dummyProofs);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;


        assertEq(zkSafe.multisigs(TEST_MULTISIG_ID, address(token)), 0);
        assertTokenBalance(address(token), address(this), initialBalance);

        console2.log("Gas used for 1 transfer operation:", gasUsed);
    }

    function testExecuteMultipleAmount() public {
        uint256 amount = 50;
        uint256 depositAmount = 1e18;
        zkSafe.deposit(TEST_MULTISIG_ID, amount * depositAmount, address(token));

        ZkSafe.Operation[] memory operations = new ZkSafe.Operation[](amount);
        bytes32[] memory dummyProofs = new bytes32[](amount);

        for (uint256 i = 0; i < amount; i++) {
            ZkSafe.Operation memory operation = ZkSafe.Operation({
                multisig_id: TEST_MULTISIG_ID,
                amount: depositAmount,
                token: address(token),
                to: address(this)
            });

            operations[i] = operation;
            dummyProofs[i] = bytes32(0);
        }

        uint256 gasBefore = gasleft();
        zkSafe.execute(operations, dummyProofs);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;

        console2.log("Gas used for", amount, "transfer operations:", gasUsed);
    }

    function testExecuteMultipleAmounts2() public {
        uint256 maxOperations = 50;
        uint256 depositAmount = 1e18;

        for (uint256 amount = 1; amount <= maxOperations; amount++) {
            zkSafe.deposit(TEST_MULTISIG_ID, amount * depositAmount, address(token));

            ZkSafe.Operation[] memory operations = new ZkSafe.Operation[](amount);
            bytes32[] memory dummyProofs = new bytes32[](amount);

            for (uint256 i = 0; i < amount; i++) {
                operations[i] = ZkSafe.Operation({
                    multisig_id: TEST_MULTISIG_ID,
                    amount: depositAmount,
                    token: address(token),
                    to: address(this)
                });
                dummyProofs[i] = bytes32(0);
            }

            uint256 gasBefore = gasleft();
            zkSafe.execute(operations, dummyProofs);
            uint256 gasAfter = gasleft();
            uint256 gasUsed = gasBefore - gasAfter;

            console2.log("Gas used for", amount, "transfer operations:", gasUsed);
        }
    }

    function testErc20Transfer() public {
        uint256 transferAmount = 1e18;
        token.transfer(address(zkSafe), transferAmount);

        assertTokenBalance(address(token), address(zkSafe), transferAmount);
        assertTokenBalance(address(token), address(this), initialBalance - transferAmount);
    }

    function testErc20TransferFullBalance() public {
        uint256 transferAmount = initialBalance;
        token.transfer(address(zkSafe), transferAmount);

        assertTokenBalance(address(token), address(zkSafe), transferAmount);
        assertTokenBalance(address(token), address(this), 0);
    }

    function testPackOperation() public {
        ZkSafe.Operation memory operation = ZkSafe.Operation({
            multisig_id: TEST_MULTISIG_ID,
            amount: 1e18,
            token: address(token),
            to: address(this)
        });

        uint256[3] memory packed = zkSafe.packOperation(operation);
    }
}
