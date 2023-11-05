// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console2.sol";

contract ZkSafe is Groth16Verifier{
    struct Operation {
        bytes32 multisig_id;
        uint256 amount;
        address token;
        address to;
    }

    mapping (bytes32 => mapping (address => uint256)) public multisigs; // multisigId => token => amount

    event Deposit(bytes32 indexed multisigId, address indexed token, uint256 amount);
    event Execute(bytes32 indexed multisigId, address indexed token, uint256 amount, address indexed to);

    function deposit(bytes32 multisigId, uint256 amount, address token) external payable {
        require(amount > 0, "ZkSafe: incorrect amount");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "ZkSafe: transfer failed");
        multisigs[multisigId][token] += amount;
        emit Deposit(multisigId, token, amount);
    }


    function execute(
        uint[2] calldata pA,
        uint[2][2] calldata pB,
        uint[2] calldata pC,
        Operation[] memory operations,
    ) external {

        uint256[operations.length*3] memory public_inputs;

        for (uint i = 0; i < operations.length; i++) {
            Operation memory op = operations[i];
            uint256[3] memory packed = packOperation(op);
            public_inputs[i*4] = multisig_id;
            public_inputs[i*4+1] = packed[0];
            public_inputs[i*4+2] = packed[1];
            public_inputs[i*4+3] = packed[2];
        }

        // verify zkProof

        varifyProof(pA, pB, pC, public_inputs);

        uint256 length = operations.length;
        for (uint i = 0; i < length; i++) {
            Operation memory op = operations[i];
            require(multisigs[op.multisig_id][op.token] >= op.amount, "ZkSafe: insufficient funds");
            multisigs[op.multisig_id][op.token] -= op.amount;
            require(IERC20(op.token).transfer(op.to, op.amount), "ZkSafe: transfer failed");
            emit Execute(op.multisig_id, op.token, op.amount, op.to);
        }
    }

    function packOperation(Operation memory op) public pure returns (uint256[3] memory) {
        uint256[3] memory packed;

        /***
         * Pack the fields in the following order:
         * [ amount (leftmost), token, to (rightmost) ]
         * Each field is padded with leading zeros to align to 253 bits, making up a total of 759 bits, which fits within three uint256 values.
         *
         * amount: 256 bits
         * token: 160 bits (20 bytes)
         * to: 160 bits (20 bytes)
         *
         * 0: 000_amount(253..0)
         * 1: 000_to(94..0)/token(160..0)/amount(256..253)
         * 2: 000_00000000000...to(66..0)
         *
         * The "amount" field is a full 256-bit unsigned integer, but only the lower 253 bits are used.
         * The "token" and "to" fields are addresses (160 bits each), but are also only using 253 bits to align with the packing format.
         * This custom packing ensures that each field stays within the 253-bit boundary.
         */


        // Define a mask to take only 253 bits.
        uint256 mask253Bits = (1 << 253) - 1;
        console2.log("mask253Bits:", mask253Bits);

        // Element 0: Just take the first 253 bits of the amount.
        packed[0] = op.amount & mask253Bits;

        // Create the second element with the last 3 bits of the amount, then the token, and finally the first 94 bits of 'to'.
        uint256 amount_high_3 = op.amount >> 253; // Gets the top 3 bits of amount
        uint256 token_160 = uint256(uint160(op.token));
        uint256 to_high_94 = uint256(uint160(op.to)) >> 66; // Gets the top 94 bits of 'to'
        packed[1] = uint256((amount_high_3 << 253) | (token_160 << 93) | to_high_94);

        // Create the third element with the remaining 66 bits of 'to', padded to fit into 253 bits.
        uint256 to_low_66 = uint256(uint160(op.to)) & ((1 << 66) - 1); // Gets the bottom 66 bits of 'to'
        packed[2] = uint256(to_low_66); // Keep as-is, with leading zeros


        return packed;
    }
}