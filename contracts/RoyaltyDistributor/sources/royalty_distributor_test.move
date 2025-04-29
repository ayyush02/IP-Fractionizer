#[test_only]
module ip_fractionalizer::royalty_distributor_test {
    use std::signer;
    use ip_fractionalizer::patent_token;
    use ip_fractionalizer::royalty_distributor;
    use aptos_framework::aptos_coin;
    use aptos_framework::coin;

    #[test(creator = @0x123, holder1 = @0x456, holder2 = @0x789)]
    fun test_royalty_distribution(
        creator: &signer,
        holder1: &signer,
        holder2: &signer,
    ) {
        // Initialize test accounts
        account::create_account_for_test(signer::address_of(creator));
        account::create_account_for_test(signer::address_of(holder1));
        account::create_account_for_test(signer::address_of(holder2));

        // Mint some APT to the creator
        coin::register<aptos_coin::AptosCoin>(creator);
        coin::register<aptos_coin::AptosCoin>(holder1);
        coin::register<aptos_coin::AptosCoin>(holder2);
        aptos_coin::mint(signer::address_of(creator), 1000);

        // Initialize patent token
        let patent_id = string::utf8(b"US12345678");
        let total_supply = 1000;
        let royalty_rate = 10; // 10%
        patent_token::initialize(creator, patent_id, total_supply, royalty_rate);
        patent_token::mint(creator, patent_id, total_supply);

        // Initialize royalty tracking
        royalty_distributor::initialize_royalty_tracking(creator, patent_id);

        // Transfer tokens to holders
        patent_token::transfer(creator, signer::address_of(holder1), 400);
        patent_token::transfer(creator, signer::address_of(holder2), 300);

        // Distribute royalties
        let payment_amount = 1000;
        royalty_distributor::distribute_royalties(creator, patent_id, payment_amount);

        // Verify payment history
        let (total_distributed, last_time, history) = royalty_distributor::get_payment_history(signer::address_of(creator));
        assert!(total_distributed == 100, 0); // 10% of 1000
        assert!(vector::length(&history) == 1, 1);
        assert!(*vector::borrow(&history, 0) == 100, 2);
    }

    #[test(creator = @0x123)]
    #[expected_failure(abort_code = E_INSUFFICIENT_BALANCE)]
    fun test_insufficient_balance(creator: &signer) {
        account::create_account_for_test(signer::address_of(creator));
        coin::register<aptos_coin::AptosCoin>(creator);

        let patent_id = string::utf8(b"US12345678");
        let total_supply = 1000;
        let royalty_rate = 10;
        patent_token::initialize(creator, patent_id, total_supply, royalty_rate);
        patent_token::mint(creator, patent_id, total_supply);

        royalty_distributor::initialize_royalty_tracking(creator, patent_id);
        royalty_distributor::distribute_royalties(creator, patent_id, 1000);
    }
} 