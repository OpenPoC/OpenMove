module openmove::std {
    use std::vector::{empty, length, borrow, push_back};

    const E_OVERFLOW: u64 = 10001;

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

    public fun bit_at(data: &vector<u8>, i: u64): u8 {
        (*borrow<u8>(data, i / 8) >> (7 - (i % 8 as u8))) & 1
    }

    public fun count_same_prefix<T>(a: &vector<T>, b: &vector<T>): u64 {
        let count = 0u64;
        while (borrow<T>(a, count) == borrow<T>(b, count)) {
            count = count + 1;
        };
        count
    }

    public fun count_same_prefix_bits(a: &vector<u8>, b: &vector<u8>): u64 {
        let index = count_same_prefix(a, b) * 8;
        while (bit_at(a, index) == bit_at(b, index)) {
            index = index + 1;
        };
        index
    }
}