
#[test_only]
module ethos::chess_board_tests {
    use ethos::chess_board::{CheckerBoard};
    use sui::transfer;

    const EMPTY: u8 = 0;
    const QUEEN: u8 = 1;
    const KING: u8 = 2;
    const ROOK: u8 = 3;
    const BISHOP: u8 = 4;
    const KNIGHT: u8 = 5;
    const PAWN: u8 = 6;

    struct TestChessBoard has key {
        board: CheckerBoard
    }

    #[test]
    fun test_new() {
        use ethos::chess_board::{new, row_count, column_count, empty_space_count, piece_at};

        let board = new();
        assert!(row_count() == 8, row_count());
        assert!(column_count() == 8, column_count());
        let empty_space_count = empty_space_count(&board);
        assert!(empty_space_count == 32, empty_space_count);
        
        let pawn = piece_at(&board, 1, 0);
        assert!(pawn == &PAWN, (*pawn as u64));
        let knight = piece_at(&board, 0, 1);
        assert!(knight == &KNIGHT, (*knight as u64));
        let rook = piece_at(&board, 0, 0);
        assert!(rook == &ROOK, (*rook as u64));
        let king = piece_at(&board, 0, 3);
        assert!(king == &KING, (*king as u64));
        let queen = piece_at(&board, 0, 4);
        assert!(queen == &QUEEN, (*queen as u64));

        let pawn = piece_at(&board, 6, 0);
        assert!(pawn == &PAWN, (*pawn as u64));
        let knight = piece_at(&board, 7, 1);
        assert!(knight == &KNIGHT, (*knight as u64));
        let rook = piece_at(&board, 7, 0);
        assert!(rook == &ROOK, (*rook as u64));
        let king = piece_at(&board, 7, 3);
        assert!(king == &KING, (*king as u64));
        let queen = piece_at(&board, 7, 4);
        assert!(queen == &QUEEN, (*queen as u64));

        transfer::share_object(TestChessBoard { board })
    }

    #[test]
    fun test_modify() {
        use ethos::chess_board::{new, modify, piece_at};

        let board = new();
        modify(&mut board, 1, 1, 2, 1);

        assert!(piece_at(&board, 1, 1) == &EMPTY, (*piece_at(&board, 1, 1) as u64));
        assert!(piece_at(&board, 2, 1) == &PAWN, (*piece_at(&board, 2, 1) as u64));

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_modify_bad_from_empty() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, 2, 1, 3, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_modify_bad_from_wrong_player() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, 6, 1, 5, 1);

        transfer::share_object(TestChessBoard { board });
    }

    
}