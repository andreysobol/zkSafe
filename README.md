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

# Trusted setup

```
cd prover
```

First, we start a new "powers of tau" trusted setup ceremony, size: 2**20

```
snarkjs powersoftau new bn128 20 pot20_0000.ptau -v
```

First contribution to the ceremony

```
snarkjs powersoftau contribute pot20_0000.ptau pot20_0001.ptau --name="First contribution" -v
```

Prepare circuit specific phase2. Finalize the ceremony

```
snarkjs powersoftau prepare phase2 pot20_0001.ptau pot20_final.ptau -v
```

Export verification key

```
snarkjs groth16 setup ../circuits/src/multisig.r1cs pot12_final.ptau multisig.zkey
```