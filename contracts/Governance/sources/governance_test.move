#[test_only]
module ip_fractionalizer::governance_test {
    use std::signer;
    use ip_fractionalizer::patent_token;
    use ip_fractionalizer::governance;
    use aptos_framework::timestamp;

    #[test(creator = @0x123, voter1 = @0x456, voter2 = @0x789)]
    fun test_proposal_creation_and_voting(
        creator: &signer,
        voter1: &signer,
        voter2: &signer,
    ) {
        // Initialize test accounts
        account::create_account_for_test(signer::address_of(creator));
        account::create_account_for_test(signer::address_of(voter1));
        account::create_account_for_test(signer::address_of(voter2));

        // Initialize patent token
        let patent_id = string::utf8(b"US12345678");
        let total_supply = 1000;
        let royalty_rate = 10;
        patent_token::initialize(creator, patent_id, total_supply, royalty_rate);
        patent_token::mint(creator, patent_id, total_supply);

        // Initialize governance
        let quorum_threshold = 50; // 50% required
        let voting_period = 86400; // 1 day
        governance::initialize_governance(creator, patent_id, quorum_threshold, voting_period);

        // Transfer tokens to voters
        patent_token::transfer(creator, signer::address_of(voter1), 400);
        patent_token::transfer(creator, signer::address_of(voter2), 300);

        // Create proposal
        let proposal_type = governance::PROPOSAL_TYPE_LICENSE;
        let description = string::utf8(b"License proposal for Company XYZ");
        governance::create_proposal(creator, patent_id, proposal_type, description);

        // Vote on proposal
        governance::vote(voter1, patent_id, 0, true); // Yes vote
        governance::vote(voter2, patent_id, 0, false); // No vote

        // Get proposal details
        let (id, creator_addr, stored_patent_id, stored_type, stored_desc, start_time, end_time, status, yes_votes, no_votes) = 
            governance::get_proposal(signer::address_of(creator), 0);

        // Verify proposal details
        assert!(id == 0, 0);
        assert!(creator_addr == signer::address_of(creator), 1);
        assert!(stored_patent_id == patent_id, 2);
        assert!(stored_type == proposal_type, 3);
        assert!(stored_desc == description, 4);
        assert!(yes_votes == 400, 5); // Voter1's balance
        assert!(no_votes == 300, 6); // Voter2's balance
    }

    #[test(creator = @0x123)]
    #[expected_failure(abort_code = E_INVALID_PROPOSAL_TYPE)]
    fun test_invalid_proposal_type(creator: &signer) {
        account::create_account_for_test(signer::address_of(creator));

        let patent_id = string::utf8(b"US12345678");
        let total_supply = 1000;
        let royalty_rate = 10;
        patent_token::initialize(creator, patent_id, total_supply, royalty_rate);
        patent_token::mint(creator, patent_id, total_supply);

        governance::initialize_governance(creator, patent_id, 50, 86400);
        governance::create_proposal(creator, patent_id, 4, string::utf8(b"Invalid proposal")); // Invalid type
    }

    #[test(creator = @0x123, voter = @0x456)]
    #[expected_failure(abort_code = E_NOT_TOKEN_HOLDER)]
    fun test_voting_without_tokens(creator: &signer, voter: &signer) {
        account::create_account_for_test(signer::address_of(creator));
        account::create_account_for_test(signer::address_of(voter));

        let patent_id = string::utf8(b"US12345678");
        let total_supply = 1000;
        let royalty_rate = 10;
        patent_token::initialize(creator, patent_id, total_supply, royalty_rate);
        patent_token::mint(creator, patent_id, total_supply);

        governance::initialize_governance(creator, patent_id, 50, 86400);
        governance::create_proposal(creator, patent_id, governance::PROPOSAL_TYPE_LICENSE, string::utf8(b"Test proposal"));
        governance::vote(voter, patent_id, 0, true); // Voter has no tokens
    }
} 