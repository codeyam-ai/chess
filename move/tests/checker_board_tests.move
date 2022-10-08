
#[test_only]
module ethos::checker_board_tests {
    use ethos::checker_board::{CheckerBoard};
    use sui::transfer;

    struct TestCheckerBoard has key {
        board: CheckerBoard
    }

    #[test]
    fun test_new() {
        use ethos::checker_board::{new, row_count, column_count, empty_space_count};

        let board = new();
        assert!(row_count() == 8, row_count());
        assert!(column_count() == 8, column_count());
        let empty_space_count = empty_space_count(&board);
        assert!(empty_space_count == 8, empty_space_count);

        transfer::share_object(TestCheckerBoard { board })
    }

    #[test]
    fun test_modify() {
        use ethos::checker_board::{new, modify, piece_at};

        let board = new();
        modify(&mut board, 3, 1, 4, 2);

        assert!(piece_at(&board, 5, 4) == &0, (*piece_at(&board, 5, 4) as u64));
        assert!(piece_at(&board, 4, 3) == &2, (*piece_at(&board, 4, 3) as u64));

        transfer::share_object(TestCheckerBoard { board });
    }
}