// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ZkSafe {
    struct OperationInfo {
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


    function execute(OperationInfo memory operationInfo, bytes32[] calldata zkProof) external {
        zkProof;

        require(multisigs[operationInfo.multisig_id][operationInfo.token] >= operationInfo.amount, "ZkSafe: insufficient funds");
        multisigs[operationInfo.multisig_id][operationInfo.token] -= operationInfo.amount;
        require(IERC20(operationInfo.token).transfer(operationInfo.to, operationInfo.amount), "ZkSafe: transfer failed");
        emit Execute(operationInfo.multisig_id, operationInfo.token, operationInfo.amount, operationInfo.to);
    }

}