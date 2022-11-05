module openmove::crypto {
    use std::vector::empty;

    public fun public_key_to_address(_pub: &vector<u8>): vector<u8> {
        empty<u8>()
    }


}