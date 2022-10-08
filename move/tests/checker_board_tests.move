
#[test_only]
module ethos::checker_board_tests {
    use ethos::checker_board::CheckerBoard;
    use sui::transfer;

    struct TestGameBoard has key {
        game_board: CheckerBoard
    }

    #[test]
    fun test_new() {
        use ethos::checker_board::{new, row_count, column_count, empty_space_count};

        let game_board = new();
        assert!(row_count() == 8, row_count());
        assert!(column_count() == 8, column_count());
        let empty_space_count = empty_space_count(&game_board);
        assert!(empty_space_count == 8, empty_space_count);

        transfer::share_object(TestGameBoard { game_board })
    }
}