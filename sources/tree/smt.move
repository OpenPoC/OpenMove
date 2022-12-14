module openmove::smt {
    use std::hash::sha3_256;
    use std::vector::{Self, length};
    use openmove::std::{slice, bit_at, count_same_prefix_bits};

    const EINVALID_SIZE: u64 = 20001;

    /// Size of ode value or hash
    const UNIT_SIZE: u64 = 32;

    /// Empty leaf node value
    const EMPTY_LEAF: vector<u8> = x"0000000000000000000000000000000000000000000000000000000000000000";
    
    /// Existing leaf node value
    const LEAF: vector<u8> = x"0000000000000000000000000000000000000000000000000000000000000001";
    
    /// Flag indicates a leaf node
    const FLAG_LEAF: u8 = 0;

    /// Flag indicates a branch node
    const FLAG_NODE: u8 = 1;


    /// Compute hash digest of a tree node
    public fun hash(flag: u8, left: vector<u8>, right: vector<u8>): vector<u8> {
        assert!(length<u8>(&left) == 32, EINVALID_SIZE);
        assert!(length<u8>(&right) == 32, EINVALID_SIZE);
        let data = vector[flag];
        vector::append(&mut data, left);
        vector::append(&mut data, right);
        sha3_256(data)
    }

    /// Compute the tree root
    public fun compute_root(path: &vector<u8>, node: vector<u8>, siblings: &vector<u8>): vector<u8> {
        let size = length<u8>(siblings) / UNIT_SIZE;
        assert!(length<u8>(siblings) == size * UNIT_SIZE, EINVALID_SIZE);
        assert!(length<u8>(path) == UNIT_SIZE, EINVALID_SIZE);
        assert!(length<u8>(&node) == UNIT_SIZE, EINVALID_SIZE);

        let index = size * UNIT_SIZE;
        while (size > 0) {
            if (bit_at(path, size) == 0) {
                node = hash(FLAG_NODE, node, slice<u8>(siblings, index - UNIT_SIZE, index));
            } else {
                node = hash(FLAG_NODE, slice<u8>(siblings, index - UNIT_SIZE, index), node);
            };
            size = size - 1
        };
        node
    }

    /// Compute the updated root of the tree with new leaf included
    public fun compute_root_with_proof(empty: bool, path: vector<u8>, proof_path: vector<u8>, siblings: &vector<u8>): vector<u8> {
        let node = hash(FLAG_LEAF, path, LEAF);
        if (empty) {
            return compute_root(&path, node, siblings)
        };

        let prefix_size = count_same_prefix_bits(&path, &proof_path);
        let proof_leaf = hash(FLAG_LEAF, proof_path, LEAF);
        node = if (bit_at(&path, prefix_size) == 0) {
            hash(FLAG_NODE, node, proof_leaf)
        } else {
            hash(FLAG_NODE, proof_leaf, node)    
        };

        let empty_branches = prefix_size - length<u8>(siblings);
        while (empty_branches > 0) {
            prefix_size = prefix_size - 1;
            node = if (bit_at(&path, prefix_size) == 0) {
                hash(FLAG_NODE, node, EMPTY_LEAF)
            } else {
                hash(FLAG_NODE, EMPTY_LEAF, node)
            };
            empty_branches = empty_branches - 1;
        };
        compute_root(&path, node, siblings)
    }

    /// Verify the non-existence of a leaf node
    /// `empty` indicates the parent branch is empty or not
    public fun verify_non_existence(root: &vector<u8>, empty: bool, path: &vector<u8>, proof_path: vector<u8>, proof_siblings: &vector<u8>): bool {
        // the first leaf of the tree
        if (root == &EMPTY_LEAF) {
            return true
        };

        if (count_same_prefix_bits(path, &proof_path) < length<u8>(proof_siblings)) {
            return false
        };

        let leaf = if (empty) {
            hash(FLAG_LEAF, proof_path, EMPTY_LEAF)
        } else {
            hash(FLAG_LEAF, proof_path, LEAF)
        };

        &compute_root(&proof_path, leaf, proof_siblings) == root
    }

    /// Verify the existence of a leaf node
    public fun verify_existence(root: &vector<u8>, path: vector<u8>, siblings: &vector<u8>): bool {
        let leaf = hash(FLAG_LEAF, path, LEAF);
        &compute_root(&path, leaf, siblings) == root
    }
}