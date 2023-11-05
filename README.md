# zkSafe

## Aggregated Zero Knowledge Multisig on EVM blockchains

Using multisig in EVM blockchains, there is a trade-off between security (the number of signatures) and gas cost. The more signatures, the more expensive the transactions. If we introduce waiting time into this equation, there will be a trilemma - time, the number of signatures, and gas usage.

Thanks to the use of ZK technologies, it is possible to create batches of multisig transactions with a low transaction cost and a high number of signatures (and thus a higher level of security). However, we will sacrifice waiting time.

# Gas efficiency

On a batch of 50 transactions our zkSafe contract will be 2.5 times cheaper than single signature EOA ERC20 transfer. Compared to the Gnosis Safe, our contract will be 5 times cheaper.

Using batch of 6 transactions our zkSafe contract become more efficient than Gnosis Safe. Using batch of 14 transactions our zkSafe contract become more efficient than EOA ERC20 transfer.

![alt text](gas_usage/graph.png)

Data [source](/gas_usage/gas_usage.py) for this calculations and graph

# UX flow

User can deposit money to our contract using `deposit` method. He provide `multisig_id` - pedersen hash of `n`, `m` and `public_keys`. `m` - size of all participants, `n` - number of signatures required to execute transaction.

When user want to make a transaction, he sign `operation` message. `operation` message contain `amount`, `token` and `to` address. User send aggregated signature to operator.

Operator combine signatures from different users and generate zk proof. Operator send proof to contract calling method `execute`.

Operator can't steal money, because he can't create valid signature without private keys of participants. So protocol is secure and totally trustless.

# Technologies

## Zero knowledge

- [Circom](https://github.com/iden3/circom) - zk circuit language
- [Circomlib](https://github.com/iden3/circomlib) - zk circuits library
- [Pedersen hash](https://github.com/iden3/circomlib/blob/master/circuits/pedersen.circom) - hash function
- [EDDSA](https://github.com/iden3/circomlib/blob/master/circuits/eddsa.circom) - signature scheme
- [Groth16](https://eprint.iacr.org/2016/260.pdf) - zk proof system
- [SnarkJS](https://github.com/iden3/snarkjs) - zk proof system implementation

## Contracts

- [Foundry][https://github.com/foundry-rs/foundry] - EVM testing framework
- [OpenZeppelin](contracts/lib/openzeppelin-contracts) - ERC20 token

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

# Build circuit

Build circom:

```
cd /tmp
git clone https://github.com/iden3/circom.git
cargo build --release
cargo install --path circom
```

Install dependencies for circuit:


```
cd circuits
npm install
```

Build circuit:

```
circom multisig.circom --r1cs --wasm --sym --c
```

# Trusted setup

```
cd prover
npm install
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