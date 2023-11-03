# zkSafe

```
multisig_id - of
n: The total number of required signatures to approve a transaction.
m: The total number of participants (public keys) in the multisignature group.
publicKeys: An array of public keys for the participants.

OperationInfo {
    bytes32 multisig_id;
    uint256 amount;
    address token;
    address to;
}

#addMultisAccount(bytes32 multisig_id) - no zk no needs
deposit(bytes32 multisig_id, uint256 amount, address token) - no zk
execute(RecivedInfo[] calldata recivedInfo, bytes32[] calldata zkProof) - with zk
```