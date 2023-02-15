 
#[test_only]
module ethos::chess_tests {
    use sui::test_scenario::{Self};
    use sui::object;
    use ethos::chess::{Self, ChessGame, ChessPlayerCap};
    use ethos::chess_board;
    use std::option;
   
    const PLAYER1: address = @0xCAFE;
    const PLAYER2: address = @0xA1C05;
    const NONPLAYER: address = @0xFACE;

    #[test]
    fun test_game_create() {
        let scenario = test_scenario::begin(PLAYER1);
        {
            chess::create_game(PLAYER2, test_scenario::ctx(&mut scenario));
        };
  
        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);
            let player1_cap = test_scenario::take_from_address<ChessPlayerCap>(&mut scenario, PLAYER1);
            
            assert!(chess::player1(&game) == &PLAYER1, 0);
            assert!(chess::player2(&game) == &PLAYER2, 0);
            assert!(chess::move_count(&game) == 0, chess::move_count(&game));
          
            let game_board = chess::board_at(&game, 0);
            let empty_space_count = chess_board::empty_space_count(game_board);
            assert!(empty_space_count == 32, empty_space_count);

            let game_id = object::uid_to_inner(chess::game_id(&game));
            assert!(chess::player_cap_game_id(&player1_cap) == &game_id, 1);
            assert!(chess::player_cap_player_number(&player1_cap) == &1, 1);

            test_scenario::return_to_address(PLAYER1, player1_cap);
            test_scenario::return_shared<ChessGame>(game);
        };  

        test_scenario::next_tx(&mut scenario, PLAYER2);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);
            let player2_cap = test_scenario::take_from_address<ChessPlayerCap>(&mut scenario, PLAYER2);

            let game_id = object::uid_to_inner(chess::game_id(&game));
            assert!(chess::player_cap_game_id(&player2_cap) == &game_id, 1);
            assert!(chess::player_cap_player_number(&player2_cap) == &2, (*chess::player_cap_player_number(&player2_cap) as u64));
            test_scenario::return_to_address(PLAYER2, player2_cap);

            test_scenario::return_shared<ChessGame>(game);
            test_scenario::end(scenario);
        }
    }

    #[test]
    fun test_make_move() {
        use ethos::chess::{create_game, make_move, piece_at_access, current_player};

        let scenario = test_scenario::begin(PLAYER1);
        {
            create_game(PLAYER2, test_scenario::ctx(&mut scenario));
        };

        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);      

            make_move(&mut game, 1, 1, 2, 1, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared<ChessGame>(game);
        };

        test_scenario::next_tx(&mut scenario, PLAYER2);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);

            let (type, player_number) = piece_at_access(&game, 1, 1);
            assert!(type == 0, (type as u64));
            assert!(player_number == 0, (type as u64));

            let (type, player_number) = piece_at_access(&game, 2, 1);
            assert!(type == 1, (type as u64));
            assert!(player_number == 1, (type as u64));

            assert!(current_player(&game) == &PLAYER2, 1);

            make_move(&mut game, 6, 1, 5, 1, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared<ChessGame>(game);
        };

        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);

            let (type, player_number) = piece_at_access(&game, 6, 1);
            assert!(type == 0, (type as u64));
            assert!(player_number == 0, (type as u64));

            let (type, player_number) = piece_at_access(&game, 5, 1);
            assert!(type == 1, (type as u64));
            assert!(player_number == 2, (type as u64));

            assert!(current_player(&game) == &PLAYER1, 2);

            test_scenario::return_shared<ChessGame>(game);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = chess::EINVALID_PLAYER)]
    fun test_aborts_if_wrong_player_tries_to_move() {
        use ethos::chess::{create_game, make_move};

        let scenario = test_scenario::begin(PLAYER1);
        {
            create_game(PLAYER2, test_scenario::ctx(&mut scenario));
        };

        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);      

            make_move(&mut game, 1, 1, 2, 1, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared<ChessGame>(game);
        };

        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);

            make_move(&mut game, 2, 1, 3, 1, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared<ChessGame>(game);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = chess::EINVALID_PLAYER)]
    fun test_aborts_if_non_player_tries_to_move() {
        use ethos::chess::{create_game, make_move};

        let scenario = test_scenario::begin(PLAYER1);
        {
            create_game(PLAYER2, test_scenario::ctx(&mut scenario));
        };

        test_scenario::next_tx(&mut scenario, NONPLAYER);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);      

            make_move(&mut game, 2, 1, 3, 2, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared<ChessGame>(game);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_game_over() {
        use ethos::chess::{create_game, make_move, winner, game_over};

        let scenario = test_scenario::begin(PLAYER1);
        {
            create_game(PLAYER2, test_scenario::ctx(&mut scenario));
        };

        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);      

            make_move(&mut game, 1, 2, 2, 2, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared<ChessGame>(game);
        };

        test_scenario::next_tx(&mut scenario, PLAYER2);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);      

            make_move(&mut game, 6, 3, 4, 3, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared<ChessGame>(game);
        };

        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);      

            make_move(&mut game, 0, 3, 3, 0, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared<ChessGame>(game);
        };

        test_scenario::next_tx(&mut scenario, PLAYER2);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);      

            make_move(&mut game, 4, 3, 3, 3, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared<ChessGame>(game);
        };

        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);      

            make_move(&mut game, 3, 0, 7, 4, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared<ChessGame>(game);
        };

        test_scenario::next_tx(&mut scenario, PLAYER2);
        {
            let game = test_scenario::take_shared<ChessGame>(&mut scenario);   

            assert!(*game_over(&game), 1);
            assert!(option::contains(winner(&game), &PLAYER1), 2);

            test_scenario::return_shared<ChessGame>(game);
        };

        test_scenario::end(scenario);
    }
}