# OpenMove
Open Source Move Code

## Branch

| Branch   | Compatible With Chain |
| -------- | --------------------  |
| main     | Aptos                 |


## Modules

### std

Extensions and utilities for standard libraries.

- Vector utilities like slicing and comparison

- Bytes utilities

- Integer serialization

### tree

Common merkle tree structures for proof verification.

- Sparse Merkle Tree for non-existence proof verifications

- Merkle Patricia Trie for proof verifications in Ethereum

## encoding

Common encoding/serialization lib.

- RLP encoding used in Ethereum

- ABI encoding and ABI Compacted encoding used in Ethereum

- SSZ encoding used in Ethereum 2.0


## Consensus

Common consensus utilities

- Least Majority as 2f + 1

- Max Faulty as n / 3


## Abort Code

| module   | abort_code starts at |
| -------- | -------------------- |
| std      | 10001                |
| tree     | 20001                |
| encoding | 30001                |
| crypto   | 40001                |

