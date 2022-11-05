# OpenMove
Open Source Move Code

## !!NOTE
We aim to provide production ready open source libraries for move ecosystem, however this does not indicate the code is bug-free. So please be assured that before you use it. Contribution with new issues or PRs is super welcome. 

## Branch

| Branch   | Compatible With Chain |
| -------- | --------------------  |
| main     | Aptos                 |


## Modules

| module   | stauts               |  abort_code starts at  |
| -------- | -------------------- | ---------------------  |
| std      | DONE                 | 10001                  |
| consensus| DONE                 | NULL                   |
| rlp      | DONE                 | 30001                  |
| mpt      | DONE                 | 21001                  |
| smt      | TO_BE_TESTED         | 20001                  |
| crypto   | DONE                 | 40001                  |
| abi      | TO_DO                | NULL                   |
| ssz      | TO_DO                | NULL                   |
| merkle   | TO_DO                | NULL                   |


### std

Extensions and utilities for standard libraries.

- Vector utilities like slicing and comparison and deduplication

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


## Donation

Thanks bro for buying me a coffee!

| Chain                                        | Wallet Address                                                        |
| -------------------------------------------- | --------------------------------------------------------------------- |
| Ethereum(including Layer2, BSC, Polygon, etc)| 0x9BB65F919483D2cB5455D24E8014E760E5272789                            |
| Aptos                                        | 0x0bdb628ee8e9e1b9e9c1545920612eca7d2b6cd96cefdcfa9e53a2d22ac84ca5    |
| Starcoin                                     | 0xc874a704893C44D9C3e5d772a7a9ad0d                                    |

