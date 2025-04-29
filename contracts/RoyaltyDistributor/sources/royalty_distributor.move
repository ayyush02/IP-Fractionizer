module ip_fractionalizer::royalty_distributor {
    use std::signer;
    use std::string;
    use std::vector;
    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin;
    use ip_fractionalizer::patent_token;

    /// Errors that can be encountered during royalty distribution
    const E_NOT_PATENT_OWNER: u64 = 1;
    const E_INSUFFICIENT_BALANCE: u64 = 2;
    const E_INVALID_AMOUNT: u64 = 3;
    const E_DISTRIBUTION_FAILED: u64 = 4;

    /// Struct to track royalty payments for a patent
    struct RoyaltyPayment has key {
        patent_id: string::String,
        total_distributed: u64,
        last_distribution_time: u64,
        payment_history: vector<u64>,
    }

    /// Initialize royalty payment tracking for a patent
    public entry fun initialize_royalty_tracking(
        account: &signer,
        patent_id: string::String,
    ) {
        let account_addr = signer::address_of(account);
        
        // Verify patent ownership
        let (_, _, _) = patent_token::get_patent_details(account_addr);
        
        // Initialize royalty payment tracking
        move_to(account, RoyaltyPayment {
            patent_id,
            total_distributed: 0,
            last_distribution_time: 0,
            payment_history: vector::empty(),
        });
    }

    /// Distribute royalties to token holders
    public entry fun distribute_royalties(
        account: &signer,
        patent_id: string::String,
        amount: u64,
    ) acquires RoyaltyPayment {
        let account_addr = signer::address_of(account);
        let royalty_payment = borrow_global_mut<RoyaltyPayment>(account_addr);
        
        // Verify patent ownership and get details
        let (_, total_supply, royalty_rate) = patent_token::get_patent_details(account_addr);
        
        // Calculate royalty amount
        let royalty_amount = (amount * royalty_rate) / 100;
        
        // Verify sufficient balance
        let coin_store = coin::balance<aptos_coin::AptosCoin>(account_addr);
        assert!(coin_store >= royalty_amount, E_INSUFFICIENT_BALANCE);
        
        // Get all token holders and their balances
        let token_holders = vector::empty();
        let total_tokens = 0;
        
        // Calculate distribution amounts
        let distribution_amounts = vector::empty();
        let i = 0;
        while (i < vector::length(&token_holders)) {
            let holder = *vector::borrow(&token_holders, i);
            let balance = patent_token::balance_of(holder);
            let holder_share = (balance * royalty_amount) / total_supply;
            vector::push_back(&mut distribution_amounts, holder_share);
            i = i + 1;
        };
        
        // Distribute royalties
        i = 0;
        while (i < vector::length(&token_holders)) {
            let holder = *vector::borrow(&token_holders, i);
            let amount = *vector::borrow(&distribution_amounts, i);
            if (amount > 0) {
                coin::transfer<aptos_coin::AptosCoin>(account, holder, amount);
            };
            i = i + 1;
        };
        
        // Update payment tracking
        royalty_payment.total_distributed = royalty_payment.total_distributed + royalty_amount;
        royalty_payment.last_distribution_time = aptos_framework::timestamp::now_seconds();
        vector::push_back(&mut royalty_payment.payment_history, royalty_amount);
    }

    /// Get royalty payment history
    public fun get_payment_history(owner: address): (u64, u64, vector<u64>) acquires RoyaltyPayment {
        let royalty_payment = borrow_global<RoyaltyPayment>(owner);
        (
            royalty_payment.total_distributed,
            royalty_payment.last_distribution_time,
            royalty_payment.payment_history
        )
    }

    /// Get total distributed royalties
    public fun get_total_distributed(owner: address): u64 acquires RoyaltyPayment {
        let royalty_payment = borrow_global<RoyaltyPayment>(owner);
        royalty_payment.total_distributed
    }
} 