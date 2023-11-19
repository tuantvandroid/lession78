module game_hero::sea_hero {
    use game_hero::hero::{Self, Hero};

    use sui::balance::{Self, Balance, Supply};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct SeaHeroAdmin has key,store {
        id: UID,
        supply: Supply<VBI_TOKEN>,
        monsters_created: u64,
        token_supply_max: u64,
        monster_max: u64
    }

    struct SeaMonster has key, store {
        id: UID,
        reward: Balance<VBI_TOKEN>
    }

    struct VBI_TOKEN has drop {}

    const EHERO_NOT_STRONG_ENOUGH: u64 = 0;
    const EINVALID_TOKEN_SUPPLY: u64 = 1;
    const EINVALID_MONSTER_SUPPLY: u64 = 2;

    fun init(ctx: &mut TxContext) {
        // create a game token with the name is VBI_TOKEN
        create(ctx);  
    }

     public fun create(ctx: &mut TxContext){
        transfer::transfer(
            SeaHeroAdmin {
                id: object::new(ctx),
                supply: balance::create_supply<VBI_TOKEN>(VBI_TOKEN {}),
                monsters_created: 0,
                token_supply_max: 1000000,
                monster_max: 10,
            },
            tx_context::sender(ctx)
        )
     }

    // --- Gameplay ---
    public fun slay(hero: &Hero, monster: SeaMonster): Balance<VBI_TOKEN> {
        // after attack succeeds, hero will have a reward with VBI_TOKEn
        let SeaMonster { id, reward } = monster;
        object::delete(id);
        assert!(
            hero::hero_strength(hero) >= balance::value(&reward),
            EHERO_NOT_STRONG_ENOUGH
        );

        reward
    }

    // --- Object and coin creation ---
    public entry fun create_sea_monster(admin: &mut SeaHeroAdmin, reward_amount: u64, recipient: address, ctx: &mut TxContext) {
        let current_coin_supply = balance::supply_value(&admin.supply);
        let token_supply_max = admin.token_supply_max;

        assert!(reward_amount < token_supply_max, EINVALID_TOKEN_SUPPLY);
        assert!(token_supply_max - reward_amount >= current_coin_supply, EINVALID_TOKEN_SUPPLY);
        assert!(admin.monster_max - 1 >= admin.monsters_created, EINVALID_MONSTER_SUPPLY);

        let monster = SeaMonster {
            id: object::new(ctx),
            reward: balance::increase_supply(&mut admin.supply, reward_amount),
        };
        admin.monsters_created = admin.monsters_created + 1;

        transfer::public_transfer(monster, recipient)
    }

    public fun monster_reward(monster: &SeaMonster): u64 {
        balance::value(&monster.reward)
    }
}
