#[test_only]
module ip_fractionalizer::patent_token_test {
    use std::signer;
    use ip_fractionalizer::patent_token;

    #[test(creator = @0x123)]
    fun test_patent_token_initialization(creator: &signer) {
        let patent_id = string::utf8(b"US12345678");
        let total_supply = 1000;
        let royalty_rate = 5; // 5%

        // Initialize patent token
        patent_token::initialize(creator, patent_id, total_supply, royalty_rate);

        // Verify initialization
        let (stored_patent_id, stored_supply, stored_rate) = patent_token::get_patent_details(signer::address_of(creator));
        assert!(stored_patent_id == patent_id, 0);
        assert!(stored_supply == total_supply, 1);
        assert!(stored_rate == royalty_rate, 2);
    }

    #[test(creator = @0x123, recipient = @0x456)]
    fun test_token_transfer(creator: &signer, recipient: &signer) {
        let patent_id = string::utf8(b"US12345678");
        let total_supply = 1000;
        let royalty_rate = 5;

        // Initialize and mint tokens
        patent_token::initialize(creator, patent_id, total_supply, royalty_rate);
        patent_token::mint(creator, patent_id, total_supply);

        // Transfer tokens
        let transfer_amount = 100;
        patent_token::transfer(creator, signer::address_of(recipient), transfer_amount);

        // Verify balances
        assert!(patent_token::balance_of(signer::address_of(creator)) == total_supply - transfer_amount, 0);
        assert!(patent_token::balance_of(signer::address_of(recipient)) == transfer_amount, 1);
    }

    #[test(creator = @0x123)]
    fun test_royalty_rate_update(creator: &signer) {
        let patent_id = string::utf8(b"US12345678");
        let total_supply = 1000;
        let initial_rate = 5;
        let new_rate = 10;

        // Initialize patent token
        patent_token::initialize(creator, patent_id, total_supply, initial_rate);

        // Update royalty rate
        patent_token::update_royalty_rate(creator, new_rate);

        // Verify update
        let (_, _, stored_rate) = patent_token::get_patent_details(signer::address_of(creator));
        assert!(stored_rate == new_rate, 0);
    }
} 