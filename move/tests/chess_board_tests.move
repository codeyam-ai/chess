
#[test_only]
module ethos::chess_board_tests {
    use ethos::chess_board::{ChessBoard};
    use sui::transfer;

    const PLAYER1: u8 = 1;
    const PLAYER2: u8 = 2;

    const EMPTY: u8 = 0;
    const QUEEN: u8 = 1;
    const KING: u8 = 2;
    const ROOK: u8 = 3;
    const BISHOP: u8 = 4;
    const KNIGHT: u8 = 5;
    const PAWN: u8 = 6;

    struct TestChessBoard has key {
        board: ChessBoard
    }

    #[test]
    fun test_new() {
        use ethos::chess_board::{new, row_count, column_count, empty_space_count, piece_at_access};

        let board = new();
        assert!(row_count() == 8, row_count());
        assert!(column_count() == 8, column_count());
        let empty_space_count = empty_space_count(&board);
        assert!(empty_space_count == 32, empty_space_count);
        
        let (type, player_number) = piece_at_access(&board, 1, 0);
        assert!(type == PAWN, (type as u64));
        assert!(player_number == PLAYER1, (player_number as u64));

        let (type, player_number) = piece_at_access(&board, 0, 0);
        assert!(type == ROOK, (type as u64));
        assert!(player_number == PLAYER1, (player_number as u64));

        let (type, player_number) = piece_at_access(&board, 0, 1);
        assert!(type == KNIGHT, (type as u64));
        assert!(player_number == PLAYER1, (player_number as u64));

        let (type, player_number) = piece_at_access(&board, 0, 2);
        assert!(type == BISHOP, (type as u64));
        assert!(player_number == PLAYER1, (player_number as u64));

        let (type, player_number) = piece_at_access(&board, 0, 3);
        assert!(type == KING, (type as u64));
        assert!(player_number == PLAYER1, (player_number as u64));

        let (type, player_number) = piece_at_access(&board, 0, 4);
        assert!(type == QUEEN, (type as u64));
        assert!(player_number == PLAYER1, (player_number as u64));


        let (type, player_number) = piece_at_access(&board, 6, 0);
        assert!(type == PAWN, (type as u64));
        assert!(player_number == PLAYER2, (player_number as u64));

        let (type, player_number) = piece_at_access(&board, 7, 0);
        assert!(type == ROOK, (type as u64));
        assert!(player_number == PLAYER2, (player_number as u64));

        let (type, player_number) = piece_at_access(&board, 7, 1);
        assert!(type == KNIGHT, (type as u64));
        assert!(player_number == PLAYER2, (player_number as u64));

        let (type, player_number) = piece_at_access(&board, 7, 2);
        assert!(type == BISHOP, (type as u64));
        assert!(player_number == PLAYER2, (player_number as u64));

        let (type, player_number) = piece_at_access(&board, 7, 3);
        assert!(type == KING, (type as u64));
        assert!(player_number == PLAYER2, (player_number as u64));

        let (type, player_number) = piece_at_access(&board, 7, 4);
        assert!(type == QUEEN, (type as u64));
        assert!(player_number == PLAYER2, (player_number as u64));

        transfer::share_object(TestChessBoard { board })
    }

    #[test]
    fun test_modify() {
        use ethos::chess_board::{new, modify, piece_at_access};

        let board = new();
        modify(&mut board, PLAYER1, 1, 1, 2, 1);

        let (type, player_number) = piece_at_access(&board, 1, 1);
        assert!(type == EMPTY, (type as u64));
        assert!(player_number == EMPTY, (player_number as u64));
        
        let (type, player_number) = piece_at_access(&board, 2, 1);
        assert!(type == PAWN, (type as u64));
        assert!(player_number == PLAYER1, (player_number as u64));

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_modify_bad_from_empty() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, PLAYER1, 2, 1, 3, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 3)]
    fun test_modify_bad_space_occupied() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, PLAYER1, 0, 0, 0, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_modify_bad_from_wrong_player_player1() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, PLAYER2, 1, 1, 2, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_modify_bad_from_wrong_player_player2() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, PLAYER1, 6, 1, 5, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_modify_capture_piece() {
        use ethos::chess_board::{new, modify, empty_space_count};

        let board = new();
        modify(&mut board, PLAYER1, 0, 1, 2, 2);
        modify(&mut board, PLAYER1, 2, 2, 4, 3);

        assert!(empty_space_count(&board) == 32, empty_space_count(&board));
        modify(&mut board, PLAYER1, 4, 3, 6, 4);
        assert!(empty_space_count(&board) == 33, empty_space_count(&board));
        
        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_off_board_move_bottom() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, PLAYER1, 0, 6, 2, 7);
        modify(&mut board, PLAYER1, 2, 7, 4, 8);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_off_board_move_right() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, PLAYER1, 0, 6, 2, 7);
        modify(&mut board, PLAYER1, 2, 7, 4, 6);
        modify(&mut board, PLAYER1, 4, 6, 6, 7);
        modify(&mut board, PLAYER1, 6, 7, 8, 6);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_pawn_move() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, PLAYER1, 1, 1, 2, 2);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_pawn_move_2() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, PLAYER1, 1, 1, 2, 1);
        modify(&mut board, PLAYER1, 2, 1, 1, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_rook_move() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, PLAYER1, 1, 0, 2, 0);
        modify(&mut board, PLAYER1, 2, 0, 3, 0);
        modify(&mut board, PLAYER1, 0, 0, 2, 0);
        modify(&mut board, PLAYER1, 2, 0, 3, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_knight_move() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, PLAYER1, 0, 1, 2, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_knight_move_2() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, PLAYER1, 0, 1, 2, 2);
        modify(&mut board, PLAYER1, 2, 2, 3, 3);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_king_move() {
        use ethos::chess_board::{new, modify};

        let board = new();
        modify(&mut board, PLAYER1, 1, 3, 2, 3);
        modify(&mut board, PLAYER1, 2, 3, 3, 3);
        modify(&mut board, PLAYER1, 3, 3, 4, 3);
        modify(&mut board, PLAYER1, 0, 3, 1, 3);
        modify(&mut board, PLAYER1, 1, 3, 3, 3);

        transfer::share_object(TestChessBoard { board });
    }

}