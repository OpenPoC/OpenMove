module openmove::crypto {
    use std::vector::length;
    use aptos_std::aptos_hash::keccak256;
    use openmove::std::slice;

    const EINVALID_PUBKEY: u64 = 40001;

    // Convert a ETH ecdsa secp256k1 public key (uncompressed with 65bytes) to an ETH address of 20 bytes
    public fun public_key_to_address(pub: &vector<u8>): vector<u8> {
        assert!(length<u8>(pub) == 65, EINVALID_PUBKEY);
        slice(&keccak256(slice(pub, 1, 65)), 12, 32)
    }

    #[test]
    fun test_pubkey_to_address() {
        let pub = x"04b0e8781ee3923754f99a6c87936b1e2aa9b5b5a1761a1323780a042b88cde9a25de9cb14901f747d7e2a63c2130e774c4236641f1263a1f566bf0e1c0a5c0d45";
        let addr = x"c5dfd53966abb04aec1d539f4d7e141b408fee7c";
        assert!(public_key_to_address(&pub) == addr, 0)
    }
}