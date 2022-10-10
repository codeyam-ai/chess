 
#[test_only]
module ethos::chess_tests {
    // use sui::test_scenario::{Self};
    // use sui::object;
    // use ethos::chess::{Self, ChessGame, ChessPlayerCap};
    // use ethos::chess_board;
   
    const PLAYER1: address = @0xCAFE;
    const PLAYER2: address = @0xA1C05;
    const NONPLAYER: address = @0xFACE;

    // #[test]
    // fun test_game_create() {
    //     let scenario = &mut test_scenario::begin(&PLAYER1);
    //     {
    //         chess::create_game(PLAYER2, test_scenario::ctx(scenario));
    //     };

    //     test_scenario::next_tx(scenario, &PLAYER1);
    //     {
    //         let game_wrapper = test_scenario::take_shared<ChessGame>(scenario);
    //         let game = test_scenario::borrow_mut(&mut game_wrapper);
    //         let player1_cap = test_scenario::take_owned<ChessPlayerCap>(scenario);
            
    //         assert!(chess::player1(game) == &PLAYER1, 0);
    //         assert!(chess::player2(game) == &PLAYER2, 0);
    //         assert!(chess::move_count(game) == 0, chess::move_count(game));
          
    //         let game_board = chess::board_at(game, 0);
    //         let empty_space_count = chess_board::empty_space_count(game_board);
    //         assert!(empty_space_count == 8, empty_space_count);

    //         let game_id = object::uid_to_inner(chess::game_id(game));
    //         assert!(chess::player_cap_game_id(&player1_cap) == &game_id, 1);

    //         test_scenario::return_owned(scenario, player1_cap);
    //         test_scenario::return_shared<ChessGame>(scenario, game_wrapper);
    //     };  

    //     test_scenario::next_tx(scenario, &PLAYER1);
    //     {
    //         let game_wrapper = test_scenario::take_shared<ChessGame>(scenario);
    //         let game = test_scenario::borrow_mut(&mut game_wrapper);
    //         let player2_cap = test_scenario::take_owned<ChessPlayerCap>(scenario);

    //         let game_id = object::uid_to_inner(chess::game_id(game));
    //         assert!(chess::player_cap_game_id(&player2_cap) == &game_id, 1);
    //         test_scenario::return_owned(scenario, player2_cap);

    //         test_scenario::return_shared<ChessGame>(scenario, game_wrapper);
    //     }
    // }

    // #[test]
    // fun test_make_move() {
    //     use ethos::chess::{create_game, make_move, piece_at, current_player};

    //     let scenario = &mut test_scenario::begin(&PLAYER1);
    //     {
    //         create_game(PLAYER2, test_scenario::ctx(scenario));
    //     };

    //     test_scenario::next_tx(scenario, &PLAYER1);
    //     {
    //         let game_wrapper = test_scenario::take_shared<ChessGame>(scenario);
    //         let game = test_scenario::borrow_mut(&mut game_wrapper);      

    //         make_move(game, 2, 1, 3, 2, test_scenario::ctx(scenario));

    //         test_scenario::return_shared<ChessGame>(scenario, game_wrapper);
    //     };

    //     test_scenario::next_tx(scenario, &PLAYER2);
    //     {
    //         let game_wrapper = test_scenario::take_shared<ChessGame>(scenario);
    //         let game = test_scenario::borrow_mut(&mut game_wrapper);

    //         assert!(piece_at(game, 2, 1) == &0, (*piece_at(game, 2, 1) as u64));
    //         assert!(piece_at(game, 3, 2) == &1, (*piece_at(game, 3, 2) as u64));
    //         assert!(current_player(game) == &PLAYER2, 1);

    //         make_move(game, 5, 4, 4, 3, test_scenario::ctx(scenario));

    //         test_scenario::return_shared<ChessGame>(scenario, game_wrapper);
    //     };

    //     test_scenario::next_tx(scenario, &PLAYER1);
    //     {
    //         let game_wrapper = test_scenario::take_shared<ChessGame>(scenario);
    //         let game = test_scenario::borrow_mut(&mut game_wrapper);

    //         assert!(piece_at(game, 5, 4) == &0, (*piece_at(game, 5, 4) as u64));
    //         assert!(piece_at(game, 4, 3) == &2, (*piece_at(game, 4, 3) as u64));
    //         assert!(current_player(game) == &PLAYER1, 2);

    //         test_scenario::return_shared<ChessGame>(scenario, game_wrapper);
    //     };
    // }

    // #[test]
    // #[expected_failure(abort_code = 0)]
    // fun test_aborts_if_wrong_player_tries_to_move() {
    //     use ethos::chess::{create_game, make_move, piece_at, current_player};

    //     let scenario = &mut test_scenario::begin(&PLAYER1);
    //     {
    //         create_game(PLAYER2, test_scenario::ctx(scenario));
    //     };

    //     test_scenario::next_tx(scenario, &PLAYER1);
    //     {
    //         let game_wrapper = test_scenario::take_shared<ChessGame>(scenario);
    //         let game = test_scenario::borrow_mut(&mut game_wrapper);      

    //         make_move(game, 2, 1, 3, 2, test_scenario::ctx(scenario));

    //         test_scenario::return_shared<ChessGame>(scenario, game_wrapper);
    //     };

    //     test_scenario::next_tx(scenario, &PLAYER1);
    //     {
    //         let game_wrapper = test_scenario::take_shared<ChessGame>(scenario);
    //         let game = test_scenario::borrow_mut(&mut game_wrapper);

    //         assert!(piece_at(game, 2, 1) == &0, (*piece_at(game, 2, 1) as u64));
    //         assert!(piece_at(game, 3, 2) == &1, (*piece_at(game, 3, 2) as u64));
    //         assert!(current_player(game) == &PLAYER2, 1);

    //         make_move(game, 5, 4, 4, 3, test_scenario::ctx(scenario));

    //         test_scenario::return_shared<ChessGame>(scenario, game_wrapper);
    //     };
    // }

    // #[test]
    // #[expected_failure(abort_code = 0)]
    // fun test_aborts_if_non_player_tries_to_move() {
    //     use ethos::chess::{create_game, make_move};

    //     let scenario = &mut test_scenario::begin(&PLAYER1);
    //     {
    //         create_game(PLAYER2, test_scenario::ctx(scenario));
    //     };

    //     test_scenario::next_tx(scenario, &NONPLAYER);
    //     {
    //         let game_wrapper = test_scenario::take_shared<ChessGame>(scenario);
    //         let game = test_scenario::borrow_mut(&mut game_wrapper);      

    //         make_move(game, 2, 1, 3, 2, test_scenario::ctx(scenario));

    //         test_scenario::return_shared<ChessGame>(scenario, game_wrapper);
    //     };
    // }

    // #[test]
    // fun test_game_over() {
    // }
}