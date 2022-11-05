module openmove::mpt {

    use std::vector::{borrow, push_back, length};
    use aptos_std::aptos_hash::keccak256;
    use openmove::std::{bytes_to_nibbles, contains_slice, slice};
    use openmove::rlp;

    const EINVALID_NODE: u64 = 21001;
    const EINVALID_NODE_HASH: u64 = 21002;
    const ENODE_MISSING: u64 = 21003;

    /// Verify mpt proof, and return the target value on success
    /// NOTE: proof is a plain concated list of nodes, so proof = concate(node0, node1, node2, ...)
    public fun verify_proof(hash: &vector<u8>, key: &vector<u8>, proof: vector<u8>): vector<u8> {
        let buf = rlp::new_buf(proof);
        let nibbles = bytes_to_nibbles(key);
        let nibble_offset = 0u64;
        push_back(&mut nibbles, 16);
        loop {
            let (node_data, _) = rlp::next(&mut buf); // Empty remaining byte should fail here
            assert!(&keccak256(node_data) == hash, EINVALID_NODE_HASH);
            let node = rlp::new_buf(node_data);
            rlp::unwrap_list(&mut node); // A non-list should fail here.
            let count = rlp::count(&node);
            if (count == 17) { // a full node
                let index = *borrow<u8>(&nibbles, nibble_offset);
                while (index > 0) { rlp::advance(&mut node); };
                hash = &rlp::read_bytes(&mut node);
                nibble_offset = nibble_offset + 1;
            } else if (count == 2) { // a short node
                let (path, has_value) = parse_compacted_path(&rlp::read_bytes(&mut buf));
                assert!(contains_slice(&nibbles, &path, nibble_offset), EINVALID_NODE);
                nibble_offset = nibble_offset + length<u8>(&path);
                let value_buf = rlp::new_buf(rlp::read_bytes(&mut buf));
                let value = rlp::read_bytes(&mut value_buf);
                if (has_value) {
                    return value
                };
                hash = &value;
            } else {
                abort(EINVALID_NODE)
            };
            assert!(length<u8>(hash) > 0, ENODE_MISSING);
        }
    }

    /// Parse encoded path of short nodes, return parsed path with wheter it has a value
    public fun parse_compacted_path(path: &vector<u8>): (vector<u8>, bool) {
        let flag = *borrow<u8>(path, 0) >> 8;
        let nibbles = bytes_to_nibbles(path);
        let offset = if (flag & 1 > 0) { // odd nibbles
            1
        } else { // even nibbles 
            2
        };
       (slice(&nibbles, offset, length<u8>(&nibbles)), flag > 1)
    }
}


/*

0eb5be412f275a18f6e4d622aee4ff40b21467c926224771b782d4c095d1444b // KeyHex

"0xf9 // list
0211 // 529 bytes
a0dafbcd5c3b5e6276b4e71222c3744d1ec6ad9d25ca1caed3e4821300effabfbe
a0e6dd70078a5e4c4489eda2558f368954b621dbe632ab9f0ac42a81cab2086360
a0fab2aecb9335f1f491c17d1bbd295ba34f0a44ce2c4e266a22bba6d560f7fce7
a039ff5bee25ebf0d905d99c7d805fb35045f957915baed5a2abade09cab8e3ad4
a0fa3c19bf4cb2e88cb08a4fc61ea277905a5bcb1df953aec8bfc1ba512ef0aa16
a07a85dfe092cbba00761f4c52ae5cb601bc1f0282ca7423f86bdeb95143a632ed
a0f4baeed83cd0218f9d7780e270d97f3e7793398a422fd75b9584d3eabd9abe2f
a00e99f5e3bd38bd07e8e707de66cacd48e1b1460c5b6d91081b37944fbde4c510
a0148713d650aaf825f6d7751b9a7f1e4efb22f9ff805e07c78cd4949025198515
a04ccc4f542e7e7cf2734e71527411707eb641d61dbf683ace3c154d051bbb6d5d
a058cc691a0dea93ced5ed5e43dddc6ef81eeff8f21b8f3c461be8d0f6eed86c0d  xx
a08a04afd8de0ee7384d09f584e3c518c71c8afd6671a873a9f8e79edd8b9e99e6
a030822a11451869be297b93ce2efa4ab16df21cc5015341e12c31dec7a996d2bc
a0597e14ee400a47aec47644df093cae414466667c727caaa48b0e44bbdc7fb13f
a077dd57c2a0735aa2668e460ad8b4bf06c3c25f5b9cd2bf10ecd3c250a1c6bcd4
a0992b04facd4b70aa6e2786c97bcef8e3234943646539fbc220048f17a4566fe0
80" // []


0xf9
0211
a065a6b0f08accaf855761b657ab145a373475dc641a8fc4349a0219feec4c6065
a00a811a75ca4fa82cd99c0eeafdaedce0af64138a482d0d1d031e5d35f81a6d49
a04a5d8cc1d810c1ae3bdf15dd57a0ede7454ec9f62e367c3d204fb17ead3059ea
a04bb84173ee48689268371d9256f12066bf60f886f6ced45cb6dae995b676d634
a0376d2e469356a4642ba0038e74829c2cdfab76533dac1060243214318094ef26
a060d7bb7104a882158bae88527f6967e89e905d51dc4cde35d1495eb60e5d4835
a0e996ae7e16f98133cb84fe1ad749b83646cfcb20309509b81af00a434993a5f3
a0ce9d97eb37a9a2e9429f95f183f3c045a976f3997030e3635541eff4dc698257
a078b5c11e06829884badc23e5f7152a91aa9aa71208adf67c4d0426d398597b25
a067359f64bc481f9008dca40d3ff1cd019829233b65025b39ae59fe4f8a0a8c59
a02b748a1e845aff5a0e62d9d2f6fc275f7508bd0c2d41d3bb6562f168db3e85f2
a038256946864ed412dc5ea8a6fc369b16a1318e0307bede87ba2195359bc0ab1c
a0e02feb52fcba9924bf4e68b2e53a79ebf3a9f6d6532e11ecc706ad46b65a39cb
a0bf4bff552a96e13cde2073dbad1d9f4b55118726181c5ed6c04de7c52726c46b
a03f2629eaeeb3e4952890ff1006e02fd6e465bfdb753f087587999b54b7c03cfe  xx
a06397c26d491f6b8eec2024b6728513be6a383e55bf64f646bba29c5d6656d621
80


 "0xf90211
 a00992bf5157eaccf4864601d39f9e073a7ae832309f230223db6cb7e192d11823
 a04ab49dfeebd9e2b8ba145ad1937fbc2c91fbd9a86e5de9759be478c655a54b69
 a0480076858d2242c98155fd717898670f2427d5f0dde708c4ebbe4d8cc94a28fb
 a09a6219d4e3d7fb9f45e8ac6a74f4d6fce0e009a8bf65844065ac2cb1a8992758
 a011b9db50426c079568a1aac799dc7bf14ff14b1e3ea500e57049b21e1223b219
 a0237997ff25176ee9982f6ff04588c13108c2207970e7cbdf4ba053ee03c0718a
 a0649b718b66c950d0216e0ca1f6d566fce8c58d60fc90929ea95218a03e355b71
 a0a10fd0f51606ade3d7bed5fc12fd91f3e0709035330f667d96518708c25c06b9
 a0ebe3cb77360b7936b89fbae60449bb66f931b4cd62ec6072430bf6c0e152e8f0
 a056dc243c796c4206bfc2f4c4f8860bce393be5e7abcc48cf275ba63911f76ec4
 a0a38b5bc381e2fe1fceeac9172c2237c48dc8696a8dfad0f67f9ada8bf23b0ecd
 a0d96d0af61760a9b5dbc8531b506ae61c157675bdf6e6719f2bf133fe69f8b811  xx
 a04847ffea8dd37e372503dabc3b008be95d6a436c64e326bdd5cbae9906ec0aa6
 a06c18eeece38b01f9a463d369ffbe2885fa0cfe021ffb347f12e1668ffbef970b
 a006792a2f5e5d1237dedb3d9e2644461225e3aced5f917460bfec2d5e21de4b70
 a08664b9c68f145eb508eb9efb09d5560bd29905481bb3c2e53e8deffd0fbcf1a8
 80",
 
 "0xf901d1
a0495b5e2d20a8769b14321be420a01b67392a8dcbb515d6bee5895b27b2d2421e
a02c022119fb1c58ad3bdbad080ea501d5cb2b2253bb8c8e088e87bfbc169d8ebf
a0c518164e9e397a46a06a5decbb01b6cf75ac4e7ac71e5de639f943d1c4b42c78
a0ecbd565caef93002509578bb84a24dd2b0040c1fbe9b2b55d6163dd4f1152791
a0a1c9fc1c2ceb6d868e3d5fcdf9af22e425b3338c68775539adfd7ef23fe5f94f
a04ea5eee92134ecc7ff696e5ba032428c7b50612095545ee6d74398ff2d7682d0  xx
a0e0fb116c65b975847f7456edab9c116a303bb866bc8571c1f9ae7ccc217cac28
80
a057cafd092a53a5ca82a531e542117fbb0dd2e9d44129d010d4f085890821b8b9
80
a050ce72a097660ec7ca33791064a3609f8bc0a48f534219f142ce0fa185c3b308
a0a45c2aca3b9c5d048476ce9e9e605ca64518b0bcd99944a21aa90fece547cf76
a0c2bdf2138ef40b0391c9c3bdef8d47129cd638bb4f43374baa20d18f45db3438
a096426f9802546b0d5471cee8056165f7032ed7edbc7c31540afb85a3d6f8941d
a0165285a42323980b1188f52c204522193b081d6b41444be2399bb8b600bc42e8
a0d840ee9b000cc16e01d90855ad26e962e6ba33dd66c90b6474a2397626c63a65
80",
            
"0xf851
80
80
80
80
80
80
80
80
80
80
80
a0bc291d4b083fc8e5f99c0a58afad4415d71b20766c95c7c0847e9bf05a491d9f  xx
a08b8528f4163f709da762e379406dc9b54e2762ca799142ace4527e7f4d87a721
80
80
80
80",

"0xf841
9e
3 e412f275a18f6e4d622aee4ff40b21467c926224771b782d4c095d1444 b  indicates a value node
a1
a0
2b9176b625f740c5b3c43ca502eb3363df27e2ba2ea14c3a3c12a80067e00ff5"   // value


*/

