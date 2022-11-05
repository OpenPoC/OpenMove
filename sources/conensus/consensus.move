module openmove::consensus {
    use std::vector::length;
    use openmove::std::count_unique;

    /// Calculate the minimum majority of N that's bigger than a third of N, at least 2f + 1
    public fun least_majority(n: u64): u64 {
        1 + n * 2 / 3
    }

    /// Calculate the max faulty nodes of N without impacting the quorum, so f = N / 3
    public fun max_faulty(n: u64): u64 {
        n / 3
    }

    /// Calculate the least total nodes allowing f faulty nodes without impacting the quorum, so 3f + 1
    public fun least_total_with_faulty(f: u64): u64 {
        1 + 3 * f
    }

    /// Verify the quorum for majority, so at least 2f + 1 of signers for N validators
    public fun verify_majority<T>(validators: &vector<T>, signers: &vector<T>): bool {
        count_unique(validators, signers) >= least_majority(length<T>(validators))
    }

    #[test]
    public fun test_verify_majority() {
        assert!(verify_majority(&x"010203040506", &x"0102030405"),0);
        assert!(!verify_majority(&x"010203040506", &x"01020304"),0);
        assert!(!verify_majority(&x"0102030405060102040503", &x"01020304"),0);
    }
}