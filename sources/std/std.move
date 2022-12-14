module openmove::std {
    use std::vector::{empty, length, borrow, push_back, append, contains, pop_back, borrow_mut};

    const E_OVERFLOW: u64 = 10001;

    /// Get a slice of a vector with start and end index.
    public fun slice<T: copy>(data: &vector<T>, start: u64, end: u64): vector<T> {
        assert!(end >= start, E_OVERFLOW);
        assert!(length<T>(data) >= end, E_OVERFLOW);

        let cp = empty<T>();
        while (start < end) {
            push_back(&mut cp, *borrow<T>(data, start));
            start = start + 1
        };
        cp
    }

    /// Check whether vector a contains b at the offset
    public fun contains_slice<T>(data: &vector<T>, sub: &vector<T>, offset: u64): bool {
        let i = 0u64;
        while (i < length<T>(sub)) {
            if (borrow<T>(sub, i) != borrow<T>(data, offset + i)) {
                return false
            };
            i = i + 1;
        };
        true
    }

    /// Convert bytes 256 base to hex nibbles of 16 base 
    public fun bytes_to_nibbles(data: &vector<u8>): vector<u8> {
        let hex = empty<u8>();
        let i = 0u64;
        while (i < length<u8>(data)) {
            let v = *borrow<u8>(data, i);
            push_back(&mut hex, ((v >> 4) as u8));
            push_back(&mut hex, ((v & 0x0F) as u8));
            i = i + 1;
        };
        hex
    }

    /// Read the `i` bit of vector<u8>
    public fun bit_at(data: &vector<u8>, i: u64): u8 {
        (*borrow<u8>(data, i / 8) >> (7 - (i % 8 as u8))) & 1
    }

    /// Count the shared prefix size of two vectors.
    public fun count_same_prefix<T>(a: &vector<T>, b: &vector<T>): u64 {
        let count = 0u64;
        while (borrow<T>(a, count) == borrow<T>(b, count)) {
            count = count + 1;
        };
        count
    }

    /// Count the shared bits of two vector<u8>.
    public fun count_same_prefix_bits(a: &vector<u8>, b: &vector<u8>): u64 {
        let index = count_same_prefix(a, b) * 8;
        while (bit_at(a, index) == bit_at(b, index)) {
            index = index + 1;
        };
        index
    }

    /// Encode u64 without zero prefixes in big-endian, zero will be encoded as empty bytes
    public fun encode_compact(v: u64, started: bool): vector<u8> {
        let i = 8u8;
        let bytes = empty<u8>();
        while (i > 0) {
            let byte = (v >> (i * 8 - 8)) & 0xff;
            if (!started && byte > 0) {
                started = true;
            };
            if (started) {
                push_back(&mut bytes, (byte as u8));
            };
            i = i - 1;
        };

        bytes
    }

    /// Decode u64 from bytes without zero prefixes in big-endian, empty bytes will be decoded as zero
    public fun decode_u64_compact(bytes: &vector<u8>): u64 {
        let v = 0u64;
        let size = length<u8>(bytes);
        let i = 0u64;
        while (i < size) {
            v = (v << 8) + (*borrow<u8>(bytes, i) as u64);
            i = i + 1;
        };
        v
    }

    public fun encode_u64_compact(v: u64): vector<u8> {
        encode_compact(v, false)
    }

    /// Encode u128 without zero prefixes in big-endian, zero will be encoded as empty bytes
    public fun encode_u128_compact(v: u128): vector<u8> {
        let b = (v >> 64) & 0xFFFFFFFFFFFFFFFF;
        let l = v & 0xFFFFFFFFFFFFFFFF;
        if (b > 0) {
            let v = encode_compact((b as u64), false);
            append(&mut v, encode_compact((l as u64), true));
            v
        } else {
            encode_compact((b as u64), false)
        }
    }

    /// Decode u128 from bytes without zero prefix in big-endian
    public fun decode_u128_compact(bytes: &vector<u8>): u128 {
        let v = 0u128;
        let size = length<u8>(bytes);
        let i = 0u64;
        while (i < size) {
            v = (v << 8) + (*borrow<u8>(bytes, i) as u128);
            i = i + 1;
        };
        v
    }

    // Deduplicate in place
    public fun deduplicate<T: drop>(list: &mut vector<T>) {
        let i = 1u64;
        while (i < length<T>(list)) {
            let j = 0u64;
            {
                let v = borrow<T>(list, i);
                while (j < i && borrow<T>(list, j) != v) {
                    j = j + 1;
                };
            };
            if (j == i) { // unique item
                i = i + 1;
            } else {
                let last = pop_back(list);
                if (i < length<T>(list)) {
                    *borrow_mut(list, i) = last;
                } else {
                    return
                };
            };
        };
    }

    /// Go through the list, and pick out the unique items
    public fun unique_of<T: copy>(list: &vector<T>): vector<T> {
        let uniques = empty<T>();
        let i = 0u64;
        while (i < length<T>(list)) {
            let item = borrow<T>(list, i);
            if (!contains<T>(&uniques, item)) {
                push_back(&mut uniques, *item);
            };
            i = i + 1;
        };
        uniques
    }

    /// Count unique items that're in both m and n.
    public fun count_unique<T>(m: &vector<T>, n: &vector<T>): u64 {
        let i = 0u64;
        let count = 0u64;
        while (i < length<T>(m)) {
            let v = borrow<T>(m, i);
            let j = 0;
            while (j < i && borrow<T>(m, j) != v) {
                j = j + 1;
            };
            if (j == i && contains<T>(n, v)) {
                count = count + 1;
            };
            i = i + 1;
        };
        count
    }

    #[test]
    fun test_deduplicate() {
        let a = x"01020304010403050201060701";
        deduplicate(&mut a);
        assert!(a == x"01020304070605", 0);
    }

    #[test]
    fun test_unique_of() {
        assert!(unique_of(&x"0102030102040104") == x"01020304", 0);
        assert!(unique_of(&x"0102030405") == x"0102030405", 0);
    }

    #[test]
    fun test_count_uniqueue() {
        assert!(count_unique(&x"010203010204", &x"010305") == 2, 0);
        assert!(count_unique(&x"010203010204", &x"010203010204") == 4, 0);
        assert!(count_unique(&x"010203010204", &x"050605") == 0, 0);
    }
}