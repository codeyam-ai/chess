 
#[test_only]
module ethos::checkers_tests {
    use sui::test_scenario;
    use ethos::checkers::{Self, CheckersGame};
    use ethos::checkers_board;

    const PLAYER1: address = @0xCAFE;
    const PLAYER2: address = @0xA1C05;

    #[test]
    fun test_game_create() {
        let scenario = &mut test_scenario::begin(&PLAYER1);
        {
            checkers::create_game(PLAYER2, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, &PLAYER1);
        {
            let game = test_scenario::take_owned<CheckersGame>(scenario);
            
            assert!(checkers::player1(&game) == &PLAYER1, 0);
            assert!(checkers::player2(&game) == &PLAYER2, 0);
            assert!(checkers::move_count(&game) == 0, checkers::move_count(&game));
          
            let game_board = checkers::board_at(&game, 0);
            let empty_space_count = checkers_board::empty_space_count(game_board);
            assert!(empty_space_count == 8, empty_space_count);

            test_scenario::return_owned(scenario, game)
        }   
    }
}