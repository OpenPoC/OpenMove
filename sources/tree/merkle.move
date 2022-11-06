module openmove::merkle {

    use std::hash::sha3_256;
    use std::vector::{singleton, append, length, borrow};
    use openmove::std::slice;

    const HASH_SIZE: u64 = 32;

    const FLAG_LEAF: u8 = 0;
    const FLAG_NODE: u8 = 1;

    const EINVALID_NODE: u64 = 22001;

    /// Verify merkle proof
    /// NOTE: proof is a plain concated list of sibling nodes, so proof = concate(node0, node1, node2, ...)
    public fun verify_proof(root: &vector<u8>, value: vector<u8>, proof: &vector<u8>): bool {
        let node = singleton<u8>(FLAG_LEAF);
        append(&mut node, value);
        let hash = sha3_256(node);
        let offset = 0u64;
        while (offset < length<u8>(proof)) {
            node = singleton<u8>(FLAG_NODE);
            let order = *borrow<u8>(proof, offset);
            offset = offset + HASH_SIZE + 1;
            if (order == 0) {
                append(&mut node, slice(proof, offset - HASH_SIZE, offset));
                append(&mut node, hash);
            } else if (order == 1) {
                append(&mut node, hash);
                append(&mut node, slice(proof, offset - HASH_SIZE, offset));
            } else {
                abort(EINVALID_NODE)
            };
            hash = sha3_256(node);
        };
        &hash == root
    }
}