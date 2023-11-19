module game_hero::hero_test {
    use sui::coin::{Self};
    use sui::test_scenario;
    use game_hero::sea_hero::{Self,SeaHeroAdmin, SeaMonster};
    use game_hero::hero::{Self, Hero, Monter, GameInfo,GameAdmin};
    use game_hero::sea_hero_helper::{Self, HelpMeSlayThisMonster};
    use sui::balance::{Self, Balance};

    #[test]
    fun test_slay_monter() {
        let admin = @0xAD014;
        let player = @0x0;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, admin);
        {
            //init(test_scenario::ctx(scenario));
            hero::create(test_scenario::ctx(scenario));
        };
  
        // - create hero
        test_scenario::next_tx(scenario, player);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref = &game;
            let coin = coin::mint_for_testing(500, test_scenario::ctx(scenario));
            hero::acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        // - create monter
        test_scenario::next_tx(scenario, admin);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref = &game;
            let admin_cap = test_scenario::take_from_sender<GameAdmin>(scenario);
            hero::send_monter(game_ref, &mut admin_cap, 10, 10, player, test_scenario::ctx(scenario));
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_immutable(game);
        };

        // - slay
        test_scenario::next_tx(scenario, player);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref = &game;
            let hero = test_scenario::take_from_sender<Hero>(scenario);
            let monter = test_scenario::take_from_sender<Monter>(scenario);
            hero::attack(game_ref, &mut hero, monter, test_scenario::ctx(scenario));
            test_scenario::return_to_sender(scenario, hero);
            test_scenario::return_immutable(game);
        };


        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_slay_sea_monter() {
        // create scenario at test 1
        let admin = @0xAD014;
        let player = @0x0;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            hero::create(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, admin);
        {
            sea_hero::create(test_scenario::ctx(scenario));
        };

        // - create hero
        test_scenario::next_tx(scenario, player);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref = &game;
            let coin = coin::mint_for_testing(500, test_scenario::ctx(scenario));
            hero::acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        // - create sea monter
        test_scenario::next_tx(scenario, player);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let reserve_val = test_scenario::take_shared<SeaHeroAdmin>(scenario);
            let reserve = &mut reserve_val;
            sea_hero::create_sea_monster(reserve,10,player,test_scenario::ctx(scenario));
            test_scenario::return_shared(reserve_val);
            test_scenario::return_immutable(game);
        };

        // - slay
        test_scenario::next_tx(scenario, player);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let hero = test_scenario::take_from_sender<Hero>(scenario);
            let admin_cap = test_scenario::take_from_sender<GameAdmin>(scenario);
            let monter = test_scenario::take_from_sender<SeaMonster>(scenario);
            let reward = sea_hero::slay(&mut hero, monter);
            balance::value(&reward);

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_immutable(game);
        };

        test_scenario::end(scenario_val);

    }

    #[test]
    fun test_hero_helper_slay() {
        // complete function to make test scenario
        let admin = @0xAD014;
        let player = @0x0;
        let player2 = @0xCAFE;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            hero::create(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, admin);
        {
            sea_hero::create(test_scenario::ctx(scenario));
        };

        // - create hero
        test_scenario::next_tx(scenario, player);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref = &game;
            let coin = coin::mint_for_testing(500, test_scenario::ctx(scenario));
            hero::acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };
        // - create hero 2
        test_scenario::next_tx(scenario, player2);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref = &game;
            let coin = coin::mint_for_testing(500, test_scenario::ctx(scenario));
            hero::acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };
        // - create sea monter
        test_scenario::next_tx(scenario, player);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let admin_cap = test_scenario::take_from_sender<GameAdmin>(scenario);
            let admin = test_scenario::take_from_sender<SeaHeroAdmin>(scenario);
            sea_hero::create_sea_monster(&mut admin,10,player,test_scenario::ctx(scenario));
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_immutable(game);
        };
        // - create help
        test_scenario::next_tx(scenario, player);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let admin_cap = test_scenario::take_from_sender<GameAdmin>(scenario);
            let monster = test_scenario::take_from_sender<SeaMonster>(scenario);
            sea_hero_helper::create_help(monster, 10, player, test_scenario::ctx(scenario));
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_immutable(game);
            
        };
        
        // - slay
        test_scenario::next_tx(scenario, player2);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let admin_cap = test_scenario::take_from_sender<GameAdmin>(scenario);
            let monster = test_scenario::take_from_sender<SeaMonster>(scenario);
            let hero = test_scenario::take_from_sender<Hero>(scenario);
            let wrapper = test_scenario::take_from_sender<HelpMeSlayThisMonster>(scenario);
            let helper_reward = sea_hero_helper::attack(&mut hero, wrapper, test_scenario::ctx(scenario));
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_immutable(game);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_hero_attack_hero() {
        // complete function to make test scenario
        let admin = @0xAD014;
        let player = @0x0;
        let player2 = @0x0;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            hero::create(test_scenario::ctx(scenario));
        };

        // - create hero
        test_scenario::next_tx(scenario, player);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref = &game;
            let coin = coin::mint_for_testing(500, test_scenario::ctx(scenario));
            hero::acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };
        // - create hero 2
        test_scenario::next_tx(scenario, player2);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref = &game;
            let coin = coin::mint_for_testing(500, test_scenario::ctx(scenario));
            hero::acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };
        // - slay 1 vs 2
        test_scenario::next_tx(scenario, player);
        {
            let game = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref = &game;
            let hero1 = test_scenario::take_from_sender<Hero>(scenario);
            let hero2 = test_scenario::take_immutable<Hero>(scenario);
            hero::p2p_play(game_ref, &mut hero1,&mut hero2, test_scenario::ctx(scenario));
            assert!(hero1, 1);
            test_scenario::return_immutable(game);
        };
        // check who will win
        test_scenario::end(scenario_val);
    }
}
