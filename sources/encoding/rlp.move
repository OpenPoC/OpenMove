module openmove::rlp {
    use std::vector::{borrow, append, length, empty, singleton, push_back};
    use openmove::std::{slice, encode_u64_compact, encode_u128_compact, decode_u64_compact, decode_u128_compact};
    use aptos_std::from_bcs;

    #[test_only]
    use aptos_std::debug::print;

    const E_DECODE_FAILURE: u64 = 30001;

    /// Value KINDs
    const BYTE: u64 = 0;
    const STRING: u64 = 1;
    const LIST: u64 = 2;

    struct Buf has drop {
        data: vector<u8>,
        offset: u64,
    }

    /// Unwrap fields of Buf
    public fun unwrap_buf(buf: Buf): (vector<u8>, u64) {
        let Buf { data, offset } = buf;
        (data, offset)
    }

    /// Create a new Buf instance
    public fun new_buf(data: vector<u8>): Buf {
        Buf { data: data, offset: 0 }
    }

    /// Update the offset of the Buf
    public fun update_offset(buf: &mut Buf, offset: u64) {
        buf.offset = offset;
    }

    /// Read a u64 from buf
    public fun read_u64(buf: &mut Buf): u64 {
        let (_, offset, size) = read(&buf.data, buf.offset);
        if (size == 1) {
            if (offset != buf.offset) {
                assert!(*borrow<u8>(&buf.data, offset) > 0x7f, E_DECODE_FAILURE);
            };
            let v = *borrow<u8>(&buf.data, offset);
            assert!(v != 0, E_DECODE_FAILURE);
            if (v == 80) {
                return 0
            };
        };
        buf.offset = offset + size;
        decode_u64_compact(&slice(&buf.data, offset, offset + size))
    }

    /// Read a u128 from buf
    public fun read_u128(buf: &mut Buf): u128 {
        let (_, offset, size) = read(&buf.data, buf.offset);
        if (size == 1) {
            if (offset != buf.offset) {
                assert!(*borrow<u8>(&buf.data, offset) > 0x7f, E_DECODE_FAILURE);
            };
            let v = *borrow<u8>(&buf.data, offset);
            assert!(v != 0, E_DECODE_FAILURE);
            if (v == 80) {
                return 0
            };
        };
        buf.offset = offset + size;
        decode_u128_compact(&slice(&buf.data, offset, offset + size))
    }

    /// Read as address from buf
    public fun read_address(buf: &mut Buf): address {
        let (_, offset, size) = read(&buf.data, buf.offset);
        buf.offset = offset + size;
        from_bcs::to_address(slice(&buf.data, offset, offset + size))
    }

    /// Read bytes
    public fun read_bytes(buf: &mut Buf): vector<u8> {
        let (_, offset, size) = read(&buf.data, buf.offset);
        if (size == 1 && offset != buf.offset) {
            assert!(*borrow<u8>(&buf.data, offset) > 0x7f, E_DECODE_FAILURE);
        };
        buf.offset = offset + size;
        slice(&buf.data, offset, offset + size)
    }

    /// Unwrap list
    public fun unwrap_list(buf: &mut Buf) {
        let (_, offset, _) = read(&buf.data, buf.offset);
        buf.offset = offset;
    }

    /// Unwrap list and return the list body as new buf
    public fun decode_list(buf: &mut Buf): Buf {
        let (_, offset, size) = read(&buf.data, buf.offset);
        buf.offset = offset + size;
        new_buf(slice(&buf.data, offset, buf.offset))
    }

    /// Read the current item with offset, returns kind, advanced offset and the size of the item
    public fun read(data: &vector<u8>, offset: u64): (u64, u64, u64) {
        let kind = (*borrow<u8>(data, offset) as u64);
        if (kind < 0x80) {
            (BYTE, offset, 1)
        } else if (kind < 0xb8) {
            let size = kind - 0x80;
            (STRING, offset + 1, size)
        } else if (kind < 0xc0) {
            let size = read_length(data, offset + 1, kind - 0xb7);
            (STRING, offset + kind - 0xb6, size)
        } else if (kind < 0xf8) {
            let size = kind - 0xc0;
            (LIST, offset + 1, size)
        } else {
            let size = read_length(data, offset + 1, kind - 0xf7);
            (LIST, offset + kind - 0xf6, size)
        }
    }

    /// Count encoded values in bytes
    public fun count_values(data: &vector<u8>): u64 {
        let n: u64 = 0;
        let offset: u64 = 0;
        let len: u64 = length<u8>(data);
        while (offset < len) {
            let size: u64;
            (_, offset, size) = read(data, offset);
            offset = offset + size;
            n = n + 1;
        };
        n
    }

    /// Read variable length with specified size of length bytes
    public fun read_length(data: &vector<u8>, offset: u64, len_size: u64): u64 {
        let length = 0u64;
        let check_first_byte = true;
        while (len_size > 0) {
            let v = (*borrow<u8>(data, offset) as u64);
            if (check_first_byte) {
                if (len_size == 1) {
                    assert!(v > 55, E_DECODE_FAILURE);
                } else {
                    assert!(v > 0, E_DECODE_FAILURE);
                };
                check_first_byte = false;
            };
            length = (length << 8) + v;
            len_size = len_size - 1;
            offset = offset + 1;
        };
        length
    }

    /// Encode length
    public fun encode_length(size: u64, prefix: u8): vector<u8> {
        if (size < 56) {
            singleton<u8>((size as u8) + prefix)
        } else {
            let i = 8u8;
            let started = false;
            let data = empty<u8>();
            while(i > 0) {
                let b = (size >> (i * 8 - 8)) & 0xff;
                if (!started && b > 0) {
                    started = true;
                    push_back(&mut data, prefix + i + 55);
                };
                if (started) {
                    push_back(&mut data, (b as u8));
                };
                i = i - 1;
            };
            data
        }
    }

    /// Encode bytes to be appended
    public fun write_bytes(data: &mut vector<u8>, value: vector<u8>) {
        let size = length<u8>(&value);
        if (size == 0) {
            push_back(data, 0x80);
            return
        } else if (size == 1) {
            let byte = *borrow<u8>(&value, 0);
            if (byte < 0x80) {
                push_back(data, byte);
                return
            };
        };
        append(data, encode_length(size, 0x80));
        append(data, value);
    }

    /// Encode integer as bytes to be appended
    public fun write_u64(data: &mut vector<u8>, value: u64) {
        write_bytes(data, encode_u64_compact(value));
    }

    /// Encode integer as bytes to be appended
    public fun write_u128(data: &mut vector<u8>, value: u128) {
        write_bytes(data, encode_u128_compact(value));
    }

    /// Write bytes as list
    public fun wrap_list(data: &mut vector<u8>, value: vector<u8>) {
        let size = length<u8>(&value);
        append(data, encode_length(size, 0xc0));
        append(data, value);
    }

    #[test]
    fun test_with_u64() {
        let values = vector<u64>[0x0, 0x1, 0x7f, 0x80, 0x1234567890123456u64];
        let expected = vector<vector<u8>>[
            x"80", x"01", x"7f", x"8180", x"881234567890123456"
        ];
        let i = 0u64;
        while (i < length<u64>(&values)) {
            let v = *borrow<u64>(&values, i);
            let buf = empty<u8>();
            write_u64(&mut buf, v);
            print(&buf);
            assert!(&buf == borrow<vector<u8>>(&expected, i), 0);
            let b = new_buf(buf);
            assert!(read_u64(&mut b) == v, 0);
            i = i + 1;
        };         
    }

    #[test]
    fun test_with_bytes() {
        let values = vector<vector<u8>>[x"",
		    x"00",
		    x"0f",
		    x"80",
		    x"34d0A4B1265619F3cAa97608B621a17531c5626f",
		    x"19F3cAa97608B621a17531c5626f34d0A4B1265619F3cAa97608B621a17531c5626f34d0A4B1265619F3cAa97608B621a17531c5626f",
		    x"34d0A4B1265619F3cAa97608B621a17531c5626f34d0A4B1265619F3cAa97608B621a17531c5626f34d0A4B1265619F3cAa97608B621a17531c5626ffa",
        ];
        let i = 0u64;
        let expected = vector<vector<u8>>[
            x"80", x"00", x"0f", x"8180",
            x"9434d0a4b1265619f3caa97608b621a17531c5626f",
            x"b619f3caa97608b621a17531c5626f34d0a4b1265619f3caa97608b621a17531c5626f34d0a4b1265619f3caa97608b621a17531c5626f",
            x"b83d34d0a4b1265619f3caa97608b621a17531c5626f34d0a4b1265619f3caa97608b621a17531c5626f34d0a4b1265619f3caa97608b621a17531c5626ffa",
        ];
        while (i < length<vector<u8>>(&values)) {
            let v = *borrow<vector<u8>>(&values, i);
            let buf = empty<u8>();
            write_bytes(&mut buf, v);
            print(&v);
            print(&buf);
            print(borrow<vector<u8>>(&expected, i));
            assert!(&buf == borrow<vector<u8>>(&expected, i), 0);
            let b = new_buf(buf);
            let res = read_bytes(&mut b);
            print(&res);
            assert!(res == v, 0);
            i = i + 1;
        };         
    }

    #[test]
    fun test_with_bytes_as_list() {
        let values = vector<vector<u8>>[x"", x"80", x"34d0A4B1265619F3cAa97608B621a17531c5626f",
        x"19F3cAa97608B621a17531c5626f34d0A4B1265619F3cAa97608B621a17531c5626f34d0A4B1265619F3cAa97608B621a17531c5626f",
        x"34d0A4B1265619F3cAa97608B621a17531c5626f34d0A4B1265619F3cAa97608B621a17531c5626f34d0A4B1265619F3cAa97608B621a17531c5626f"];
        let i = 0u64;
        while (i < length<vector<u8>>(&values)) {
            let v = *borrow<vector<u8>>(&values, i);
            let buf = empty<u8>();
            wrap_list(&mut buf, v);
            print(&v);
            print(&buf);
            let b = new_buf(buf);
            let Buf { data: res, offset: _ } = decode_list(&mut b);
            print(&res);
            assert!(res == v, 0);
            i = i + 1;
        };         
    }

    #[test, expected_failure(abort_code = 30001)]
    fun test_invalid_decoding_bytes_for_u64() {
        let buf = new_buf(x"00");
        read_u64(&mut buf);
    }

    #[test, expected_failure(abort_code = 30001)]
    fun test_invalid_decoding_bytes_a() {
        let buf = new_buf(x"8100");
        let _ = read_bytes(&mut buf);
    }

    #[test, expected_failure(abort_code = 30001)]
    fun test_invalid_decoding_bytes_b() {
        let buf = new_buf(x"817f");
        let _ = read_bytes(&mut buf);
    }

    #[test]
    fun test_nested_list() {
        /*
        struct {
			A []byte
			B [][]byte
			C [][][]byte
		} {
			[]byte{1, 100, 255},
			[][]byte{{1, 100, 255}},
			[][][]byte{{{1,100,255}, {1, 100, 255}}, {{1,100,255}, {1, 100, 255}}},
		}
        */
        let v = vector<u8>[1, 100, 255];
        let buf = empty<u8>();
        write_bytes(&mut buf, v);
        let bytes = copy buf;
        wrap_list(&mut buf, bytes);
        {
            let sub = empty<u8>();
            write_bytes(&mut sub, v);
            write_bytes(&mut sub, v);
            let sub_list = empty<u8>();
            wrap_list(&mut sub_list, sub);
            print(&sub_list);

            let list = empty<u8>();
            append(&mut list, sub_list);
            append(&mut list, sub_list);

            wrap_list(&mut buf, list);
        };
        let res = empty<u8>();
        wrap_list(&mut res, buf);
        print(&res);
        assert!(res == x"dc830164ffc4830164ffd2c8830164ff830164ffc8830164ff830164ff", 0);
    }
}

// Special cases
// encode:
// - integer 0  -> 80
// - integer 7f -> 7f
// - ''         -> 80
// - '\x00'     -> 00
// - '\x7f'     -> 7f
//
// decode:
// - 00        -> integer fail
// - 8100      -> fail
// - 817f      -> fail
