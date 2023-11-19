module game_hero::hero {
    use sui::coin::{Self, Coin};
    use sui::object::{Self,ID,UID};
    use sui::math;
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self,Option};

    const MAX_HP: u64 = 1000;
    const MAX_STRENGTH: u64 = 200;
    const MIN_SWORD_COST: u64 = 100;
    const MIN_ARMOR_COST: u64 = 100;
    const MAX_ARMOR: u64 = 200;

    const EHERO_NOT_STRONG_ENOUGH: u64 = 0;
    const EINSUFFICIENT_FUNDS: u64 = 1;
    const EINVALID_MONSTER_SUPPLY: u64 = 2;
    const EINVALID_TOKEN_SUPPLY: u64 = 3;
    const EMONTER_WON: u64 = 4;
    const EHERO1_WON: u64 = 5;
    const EHERO2_WON: u64 = 6;

    struct Hero has key, store {
        id: UID,
        hp: u64,
        mana: u64,
        level: u8,
        experience: u64,
        sword: Option<Sword>,
        armor: Option<Armor>,
        game_id: ID,
    }

    struct Sword has key, store {
        id: UID,
        magic: u64,
        strength: u64,
        game_id: ID,
    }

    struct Potion has key, store {
        id: UID,
        potency: u64,
        game_id: ID,
    }

    struct Armor has key,store {
        id: UID,
        guard: u64,
        game_id: ID,
    }

    struct Monter has key {
        id: UID,
        hp: u64,
        strength: u64,
        game_id: ID,
    }

    struct GameInfo has key {
        id: UID,
        admin: address
    }

    struct GameAdmin has key {
        id: UID,
        monter_created: u64,
        potions_created: u64,
        game_id: ID,
    }

    struct MonterSlainEvent has copy, drop {
        slayer_address: address,
        hero: ID,
        monter: ID,
        game_id: ID,
    }

    #[allow(unused_function)]
    fun init(ctx: &mut TxContext) {
        // Create a new game with Info & Admin
        create(ctx);  
    }

    public fun create(ctx: &mut TxContext){
        let sender = tx_context::sender(ctx);
        let id = object::new(ctx);
        let game_id = object::uid_to_inner(&id);
        transfer::freeze_object(
            GameInfo{
                id,
                admin: sender,
            }
        );

        transfer::transfer(
            GameAdmin{
                game_id,
                id: object::new(ctx),
                monter_created: 0,
                potions_created: 0,
            },
            sender
        );
    }

    // --- Gameplay ---
    public entry fun attack(game: &GameInfo, hero: &mut Hero, monter: Monter, ctx: &TxContext) {
        check_id(game, hero.game_id);
        check_id(game, monter.game_id);
        /// Completed this code to hero can attack Monter
        let Monter {id: monter_id, hp, strength: monter_strength, game_id} = monter;
        let hero_strength = hero_strength(hero);
        let monter_hp = hp;
        let hero_hp = hero.hp;
        while (monter_hp > hero_strength){
            monter_hp = monter_hp - hero_strength;
            assert!(hero_hp >= monter_strength, EMONTER_WON);
            hero_hp = hero_hp - monter_strength;
        };
        /// after attack, if success hero will up_level hero, up_level_sword and up_level_armor.
        hero.hp = hero_hp;
        hero.experience = hero.experience + hp;
        up_level_hero(hero);
        if(option::is_some(&hero.sword)){
            level_up_sword(option::borrow_mut(&mut hero.sword),1);
        };
        
        if(option::is_some(&hero.armor)){
            level_up_armor(option::borrow_mut(&mut hero.armor),1);
        };

        object::delete(monter_id);

    }

    public entry fun p2p_play(game: &GameInfo, hero1: &mut Hero, hero2: &mut Hero, ctx: &TxContext) {
        check_id(game, hero1.game_id);
        check_id(game, hero2.game_id);
   
        let hero1_strength = hero_strength(hero1);
        let hero2_strength = hero_strength(hero2);

        let hero1_hp = hero1.hp;
        let hero2_hp = hero2.hp;

        while (hero1_hp > 0 && hero2_hp > 0){
            hero1_hp = hero1_hp - hero2_strength;
            assert!(hero1_hp <= 0, EHERO2_WON);
            hero2_hp = hero2_hp - hero1_strength;
            assert!(hero2_hp <= 0, EHERO1_WON);
        }
    }

    public fun up_level_hero(hero: &Hero): u8 {
        // calculator strength
        hero.level + (hero.experience as u8) /100
    }

    public fun hero_strength(hero: &Hero): u64 {
        // calculator strength
        if(hero.hp == 0){
            return 0
        };
        let sword_strength = if(option::is_some(&hero.sword)){
            sword_strength(option::borrow(&hero.sword))
        }
        else{
            0
        };
        (hero.experience * hero.hp) + sword_strength
    }

    fun level_up_sword(sword: &mut Sword, amount: u64) {
        // up power/strength for sword
        sword.strength = sword.strength + amount;
    }

    fun level_up_armor(armor: &mut Armor, amount: u64) {
        // up power/strength for armor
        armor.guard = armor.guard + amount;
    }

    public fun sword_strength(sword: &Sword): u64 {
        // calculator strength of sword follow magic + strength
        sword.magic + sword.strength
    }

    public fun heal(hero: &mut Hero, potion: Potion) {
        // use the potion to heal
        assert!(hero.game_id == potion.game_id, 403);
        let Potion {id, potency, game_id: _ } = potion;
        object::delete(id);
        let new_hp = hero.hp + potency;
        hero.hp = math::min(new_hp, MAX_HP);
    }

    public fun equip_sword(hero: &mut Hero, new_sword: Sword): Option<Sword> {
        // change another sword
        option::swap_or_fill(&mut hero.sword, new_sword)
    }

    // --- Object creation ---
    public fun create_sword(game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext): Sword {
        // Create a sword, streight depends on payment amount
        let value = coin::value(&payment);
        assert!(value >= MIN_SWORD_COST, EINSUFFICIENT_FUNDS);
        transfer::public_transfer(payment,game.admin);
        let strength = (value - MIN_SWORD_COST) / MIN_SWORD_COST;
        Sword {
            id: object::new(ctx),
            magic: 1,
            strength: math::min(strength, MAX_STRENGTH),
            game_id: id(game)
        }
    }

    public fun create_armor(game: &GameInfo, amount: u64, ctx: &mut TxContext): Armor {
        // Create a sword, streight depends on payment amount
        let guard = amount;
        Armor {
            id: object::new(ctx),
            guard: math::min(guard, MAX_ARMOR),
            game_id: id(game)
        }
    }

    public entry fun acquire_hero(
        game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext
    ) {
        // call function create_armor
        let armor = create_armor(game, 10, ctx);
        // call function create_sword
        let sword = create_sword(game, payment, ctx);
        // call function create_hero
        let hero = create_hero(game, sword, armor, ctx);
        transfer::public_transfer(hero, tx_context::sender(ctx))
    }

    public fun create_hero(game: &GameInfo, sword: Sword, armor: Armor, ctx: &mut TxContext): Hero {
        // Create a new hero
        check_id(game, sword.game_id);
        Hero{
            id: object::new(ctx),
            hp: 100,
            mana: 0,
            level: 1,
            experience: 0,
            sword: option::some(sword),
            armor: option::some(armor),
            game_id: id(game)
        }
    }

    public fun check_id(game_info: &GameInfo, id: ID){
        assert!(id(game_info) == id, 403);
    }

    public fun id(game_info: &GameInfo): ID{
        object::id(game_info)
    }

    public entry fun send_potion(game: &GameInfo,  potency: u64, admin: &mut GameAdmin, player: address, ctx: &mut TxContext) {
        // send potion to hero, so that hero can healing
         check_id(game, admin.game_id);
        admin.potions_created = admin.potions_created + 1;
        // send potion to the designated player
        transfer::public_transfer(
            Potion { id: object::new(ctx), potency, game_id: id(game) },
            player
        )
    }

    public entry fun send_monter(game: &GameInfo, admin: &mut GameAdmin, hp: u64, strength: u64, player: address, ctx: &mut TxContext) {
        // send monter to hero to attacks
        check_id(game, admin.game_id);
        admin.monter_created = admin.monter_created + 1;
        transfer::transfer(
            Monter {id: object::new(ctx), hp, strength, game_id: id(game)},
            player
        )
    }
}
