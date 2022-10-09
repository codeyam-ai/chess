
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
        modify(&mut board, 2, 1, 3, 2);

        assert!(piece_at(&board, 2, 1) == &0, (*piece_at(&board, 2, 1) as u64));
        assert!(piece_at(&board, 3, 2) == &1, (*piece_at(&board, 3, 2) as u64));

        transfer::share_object(TestCheckerBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_modify_bad_from() {
        use ethos::checker_board::{new, modify};

        let board = new();
        modify(&mut board, 3, 2, 4, 1);

        transfer::share_object(TestCheckerBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_modify_bad_to_player1() {
        use ethos::checker_board::{new, modify};

        let board = new();
        modify(&mut board, 2, 1, 1, 2);

        transfer::share_object(TestCheckerBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_modify_bad_to_player2() {
        use ethos::checker_board::{new, modify};

        let board = new();
        modify(&mut board, 5, 2, 6, 1);

        transfer::share_object(TestCheckerBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_occupied_space() {
        use ethos::checker_board::{new, modify};

        let board = new();
        modify(&mut board, 6, 1, 5, 2);

        transfer::share_object(TestCheckerBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_modify_destination_not_allowed_player_1() {
        use ethos::checker_board::{new, modify};

        let board = new();
        modify(&mut board, 2, 1, 3, 6);

        transfer::share_object(TestCheckerBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_modify_destination_not_allowed_player_2() {
        use ethos::checker_board::{new, modify};

        let board = new();
        modify(&mut board, 5, 0, 4, 3);

        transfer::share_object(TestCheckerBoard { board });
    }
}