
#[test_only]
module ethos::checkers_board_tests {
    use ethos::checkers_board::CheckersBoard;
    use sui::transfer;

    struct TestGameBoard has key {
        game_board: CheckersBoard
    }

    #[test]
    fun test_new() {
        use ethos::checkers_board::{new, row_count, column_count, empty_space_count};

        let game_board = new();
        assert!(row_count(&game_board) == 8, row_count(&game_board));
        assert!(column_count(&game_board) == 8, column_count(&game_board));
        let empty_space_count = empty_space_count(&game_board);
        assert!(empty_space_count == 8, empty_space_count);

        transfer::share_object(TestGameBoard { game_board })
    }
}