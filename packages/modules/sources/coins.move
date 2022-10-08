address AppAdmin {

module coins {
    use aptos_framework::coin;
    use std::string::{utf8, String};
    use std::signer;
    use std::string;
    use aptos_std::type_info;

    struct BTC {}
    struct BNB {}
    struct ETH {}
    struct SOL {}
    struct USDC {}
    struct USDT {}
    struct DAI {}

    struct CoinCaps<phantom T> has key {
        mint: coin::MintCapability<T>,
        freeze: coin::FreezeCapability<T>,
        burn: coin::BurnCapability<T>,
    }

    public fun initialize<TokenType>(admin: &signer, decimals: u8){
        let name = type_info::struct_name(&type_info::type_of<TokenType>());
        init_coin<TokenType>(admin, name, name, decimals)
    }

    public entry fun init_coin<CoinType>(
        admin: &signer,
        name: vector<u8>,
        symbol: vector<u8>,
        decimals: u8,
    ) {
        let (burn, freeze, mint) =
            coin::initialize<CoinType>(
                admin,
                utf8(name),
                utf8(symbol),
                decimals,
                false
            );
        move_to(admin, CoinCaps {
            mint,
            freeze,
            burn,
        });
    }

    public fun mint<CoinType>(amount: u64): coin::Coin<CoinType> acquires CoinCaps {
        let caps = borrow_global<CoinCaps<CoinType>>(@AppAdmin);
        coin::mint(amount, &caps.mint)
    }

    #[cmd]
    public entry fun mint_to_wallet<CoinType>(user: &signer, amount: u64) acquires CoinCaps {
        let coin = mint<CoinType>(amount);
        if (!coin::is_account_registered<CoinType>(signer::address_of(user))) {
            coin::register<CoinType>(user);
        };
        coin::deposit(signer::address_of(user), coin);
    }

    public fun burn<TokenType>(tokens: coin::Coin<TokenType>) acquires CoinCaps{
        //token holder address
        let addr = type_info::account_address(&type_info::type_of<TokenType>());
        let cap = borrow_global<CoinCaps<TokenType>>(addr);
        let amt = coin::value(&tokens);
        if (amt == 0) {
            coin::destroy_zero<TokenType>(tokens);
        } else {
            coin::burn<TokenType>(tokens, &cap.burn);
        }
    }

    public fun deposit<CoinType>(user: &signer,coin: coin::Coin<CoinType>) {
        if (!coin::is_account_registered<CoinType>(signer::address_of(user))) {
            coin::register<CoinType>(user);
        };
        coin::deposit(signer::address_of(user), coin);
    }

    public fun init_coin_and_register<CoinType>(
        admin: &signer,
        name: String,
        symbol: String,
        decimals: u8
    ){
        init_coin<CoinType>(admin, *string::bytes(&name), *string::bytes(&symbol), decimals);
    }

    public entry fun deploy(admin: &signer) {
        init_coin_and_register<BTC>(
            admin,
            utf8(b"Bitcoin"),
            utf8(b"BTC"),
            8
        );

        init_coin_and_register<BNB>(
            admin,
            utf8(b"BNB"),
            utf8(b"BNB"),
            8
        );

        init_coin_and_register<ETH>(
            admin,
            utf8(b"Ethereum"),
            utf8(b"ETH"),
            8
        );

        init_coin_and_register<SOL>(
            admin,
            utf8(b"Solana"),
            utf8(b"SOL"),
            8
        );

        init_coin_and_register<USDC>(
            admin,
            utf8(b"USD Coin"),
            utf8(b"USDC"),
            8
        );

        init_coin_and_register<USDT>(
            admin,
            utf8(b"Tether"),
            utf8(b"USDT"),
            8
        );

        init_coin_and_register<DAI>(
            admin,
            utf8(b"DAI"),
            utf8(b"DAI"),
            8
        );

    }

    #[test(admin = @AppAdmin, user = @0x0123)]
    fun test(admin: &signer, user: &signer) acquires CoinCaps {
        use aptos_framework::aptos_account;
        aptos_account::create_account(signer::address_of(user));

        let amount = 10000;
        initialize<USDC>(admin,8);

        mint_to_wallet<USDC>(user,amount);
        assert!(coin::balance<USDC>(signer::address_of(user)) == amount, 1);

        let c = coin::withdraw<USDC>(user,amount);
        assert!(coin::value(&c) == amount, 1);

        burn(c)
    }

    #[test(admin = @AppAdmin)]
    fun test_deploy(admin: &signer){
        deploy(admin)
    }

}
}
