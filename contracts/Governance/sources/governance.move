module ip_fractionalizer::governance {
    use std::signer;
    use std::string;
    use std::vector;
    use std::option;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use ip_fractionalizer::patent_token;

    /// Errors that can be encountered during governance operations
    const E_NOT_TOKEN_HOLDER: u64 = 1;
    const E_PROPOSAL_NOT_FOUND: u64 = 2;
    const E_VOTING_CLOSED: u64 = 3;
    const E_ALREADY_VOTED: u64 = 4;
    const E_INSUFFICIENT_VOTES: u64 = 5;
    const E_INVALID_PROPOSAL_TYPE: u64 = 6;

    /// Types of proposals that can be created
    const PROPOSAL_TYPE_LICENSE: u8 = 1;
    const PROPOSAL_TYPE_ROYALTY: u8 = 2;
    const PROPOSAL_TYPE_TRANSFER: u8 = 3;

    /// Voting status
    const VOTING_STATUS_ACTIVE: u8 = 1;
    const VOTING_STATUS_PASSED: u8 = 2;
    const VOTING_STATUS_REJECTED: u8 = 3;

    /// Struct representing a proposal
    struct Proposal has key {
        id: u64,
        creator: address,
        patent_id: string::String,
        proposal_type: u8,
        description: string::String,
        start_time: u64,
        end_time: u64,
        status: u8,
        yes_votes: u64,
        no_votes: u64,
        voters: vector<address>,
    }

    /// Struct to track governance state
    struct GovernanceState has key {
        next_proposal_id: u64,
        proposals: vector<Proposal>,
        quorum_threshold: u64, // Percentage of total supply required
        voting_period: u64, // Duration in seconds
    }

    /// Initialize governance for a patent
    public entry fun initialize_governance(
        account: &signer,
        patent_id: string::String,
        quorum_threshold: u64,
        voting_period: u64,
    ) {
        let account_addr = signer::address_of(account);
        
        // Verify patent ownership
        let (_, _, _) = patent_token::get_patent_details(account_addr);
        
        // Initialize governance state
        move_to(account, GovernanceState {
            next_proposal_id: 0,
            proposals: vector::empty(),
            quorum_threshold,
            voting_period,
        });
    }

    /// Create a new proposal
    public entry fun create_proposal(
        account: &signer,
        patent_id: string::String,
        proposal_type: u8,
        description: string::String,
    ) acquires GovernanceState {
        let account_addr = signer::address_of(account);
        let governance_state = borrow_global_mut<GovernanceState>(account_addr);
        
        // Verify proposal type
        assert!(
            proposal_type == PROPOSAL_TYPE_LICENSE ||
            proposal_type == PROPOSAL_TYPE_ROYALTY ||
            proposal_type == PROPOSAL_TYPE_TRANSFER,
            E_INVALID_PROPOSAL_TYPE
        );
        
        // Create new proposal
        let proposal = Proposal {
            id: governance_state.next_proposal_id,
            creator: account_addr,
            patent_id,
            proposal_type,
            description,
            start_time: timestamp::now_seconds(),
            end_time: timestamp::now_seconds() + governance_state.voting_period,
            status: VOTING_STATUS_ACTIVE,
            yes_votes: 0,
            no_votes: 0,
            voters: vector::empty(),
        };
        
        // Add proposal to state
        vector::push_back(&mut governance_state.proposals, proposal);
        governance_state.next_proposal_id = governance_state.next_proposal_id + 1;
    }

    /// Vote on a proposal
    public entry fun vote(
        account: &signer,
        patent_id: string::String,
        proposal_id: u64,
        vote_yes: bool,
    ) acquires GovernanceState {
        let account_addr = signer::address_of(account);
        let governance_state = borrow_global_mut<GovernanceState>(account_addr);
        
        // Find proposal
        let proposal_index = find_proposal_index(&governance_state.proposals, proposal_id);
        assert!(proposal_index < vector::length(&governance_state.proposals), E_PROPOSAL_NOT_FOUND);
        
        let proposal = vector::borrow_mut(&mut governance_state.proposals, proposal_index);
        
        // Verify voting is still active
        assert!(proposal.status == VOTING_STATUS_ACTIVE, E_VOTING_CLOSED);
        assert!(timestamp::now_seconds() < proposal.end_time, E_VOTING_CLOSED);
        
        // Verify voter hasn't already voted
        let voter_index = find_address_index(&proposal.voters, account_addr);
        assert!(voter_index >= vector::length(&proposal.voters), E_ALREADY_VOTED);
        
        // Get voter's token balance
        let vote_weight = patent_token::balance_of(account_addr);
        assert!(vote_weight > 0, E_NOT_TOKEN_HOLDER);
        
        // Record vote
        if (vote_yes) {
            proposal.yes_votes = proposal.yes_votes + vote_weight;
        } else {
            proposal.no_votes = proposal.no_votes + vote_weight;
        };
        vector::push_back(&mut proposal.voters, account_addr);
        
        // Check if voting period has ended and update status
        if (timestamp::now_seconds() >= proposal.end_time) {
            let total_supply = patent_token::get_patent_details(account_addr).1;
            let total_votes = proposal.yes_votes + proposal.no_votes;
            let quorum = (total_votes * 100) / total_supply;
            
            if (quorum >= governance_state.quorum_threshold) {
                if (proposal.yes_votes > proposal.no_votes) {
                    proposal.status = VOTING_STATUS_PASSED;
                } else {
                    proposal.status = VOTING_STATUS_REJECTED;
                };
            };
        };
    }

    /// Get proposal details
    public fun get_proposal(
        owner: address,
        proposal_id: u64,
    ): (u64, address, string::String, u8, string::String, u64, u64, u8, u64, u64) acquires GovernanceState {
        let governance_state = borrow_global<GovernanceState>(owner);
        let proposal_index = find_proposal_index(&governance_state.proposals, proposal_id);
        assert!(proposal_index < vector::length(&governance_state.proposals), E_PROPOSAL_NOT_FOUND);
        
        let proposal = vector::borrow(&governance_state.proposals, proposal_index);
        (
            proposal.id,
            proposal.creator,
            proposal.patent_id,
            proposal.proposal_type,
            proposal.description,
            proposal.start_time,
            proposal.end_time,
            proposal.status,
            proposal.yes_votes,
            proposal.no_votes
        )
    }

    /// Helper function to find proposal index
    fun find_proposal_index(proposals: &vector<Proposal>, id: u64): u64 {
        let i = 0;
        while (i < vector::length(proposals)) {
            if (vector::borrow(proposals, i).id == id) {
                return i
            };
            i = i + 1;
        };
        vector::length(proposals)
    }

    /// Helper function to find address index
    fun find_address_index(addresses: &vector<address>, addr: address): u64 {
        let i = 0;
        while (i < vector::length(addresses)) {
            if (*vector::borrow(addresses, i) == addr) {
                return i
            };
            i = i + 1;
        };
        vector::length(addresses)
    }
} 