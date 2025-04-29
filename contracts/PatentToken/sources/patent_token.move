module ip_fractionalizer::patent_token {
    use std::signer;
    use std::string;
    use aptos_framework::account;
    use aptos_framework::token;
    use aptos_framework::aptos_coin;
    use aptos_framework::coin;

    /// Errors that can be encountered during token operations
    const E_NOT_PATENT_OWNER: u64 = 1;
    const E_INVALID_TOKEN_AMOUNT: u64 = 2;
    const E_PATENT_NOT_FOUND: u64 = 3;
    const E_INSUFFICIENT_BALANCE: u64 = 4;

    /// Struct representing a patent token
    struct PatentToken has key {
        patent_id: string::String,
        total_supply: u64,
        royalty_rate: u64, // Percentage (0-100)
        owner: address,
        token_store: token::TokenStore,
    }

    /// Initialize a new patent token
    public entry fun initialize(
        account: &signer,
        patent_id: string::String,
        total_supply: u64,
        royalty_rate: u64,
    ) {
        let account_addr = signer::address_of(account);
        
        // Create token store
        token::create_token_store(account);
        
        // Initialize patent token
        move_to(account, PatentToken {
            patent_id,
            total_supply,
            royalty_rate,
            owner: account_addr,
            token_store: token::get_token_store(account_addr),
        });
    }

    /// Mint new patent tokens
    public entry fun mint(
        account: &signer,
        patent_id: string::String,
        amount: u64,
    ) acquires PatentToken {
        let account_addr = signer::address_of(account);
        let patent_token = borrow_global_mut<PatentToken>(account_addr);
        
        // Verify ownership
        assert!(patent_token.owner == account_addr, E_NOT_PATENT_OWNER);
        
        // Mint new tokens
        token::mint_token(
            &mut patent_token.token_store,
            amount,
        );
    }

    /// Transfer patent tokens
    public entry fun transfer(
        from: &signer,
        to: address,
        amount: u64,
    ) acquires PatentToken {
        let from_addr = signer::address_of(from);
        let patent_token = borrow_global_mut<PatentToken>(from_addr);
        
        // Verify sufficient balance
        assert!(token::balance_of(&patent_token.token_store) >= amount, E_INSUFFICIENT_BALANCE);
        
        // Transfer tokens
        token::transfer(&mut patent_token.token_store, to, amount);
    }

    /// Get token balance for an address
    public fun balance_of(owner: address): u64 acquires PatentToken {
        let patent_token = borrow_global<PatentToken>(owner);
        token::balance_of(&patent_token.token_store)
    }

    /// Get patent details
    public fun get_patent_details(owner: address): (string::String, u64, u64) acquires PatentToken {
        let patent_token = borrow_global<PatentToken>(owner);
        (patent_token.patent_id, patent_token.total_supply, patent_token.royalty_rate)
    }

    /// Update royalty rate (only owner)
    public entry fun update_royalty_rate(
        account: &signer,
        new_rate: u64,
    ) acquires PatentToken {
        let account_addr = signer::address_of(account);
        let patent_token = borrow_global_mut<PatentToken>(account_addr);
        
        // Verify ownership
        assert!(patent_token.owner == account_addr, E_NOT_PATENT_OWNER);
        
        // Update royalty rate
        patent_token.royalty_rate = new_rate;
    }
} 