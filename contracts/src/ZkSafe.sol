// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ZkSafe {
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


    function execute(Operation memory operation, bytes32[] calldata zkProof) external {
        zkProof;

        require(multisigs[operation.multisig_id][operation.token] >= operation.amount, "ZkSafe: insufficient funds");
        multisigs[operation.multisig_id][operation.token] -= operation.amount;
        require(IERC20(operation.token).transfer(operation.to, operation.amount), "ZkSafe: transfer failed");
        emit Execute(operation.multisig_id, operation.token, operation.amount, operation.to);
    }

}