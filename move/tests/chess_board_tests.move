
#[test_only]
module ethos::chess_board_tests {
    use ethos::chess_board::{ChessBoard, new, modify, empty_space_count, piece_at_access, game_over};
    use sui::transfer;

    const EMPTY: u8 = 0;

    const PLAYER1: u8 = 1;
    const PLAYER2: u8 = 2;
   
    const PAWN: u8 = 1;
    const ROOK: u8 = 2;
    const KNIGHT: u8 = 3;
    const BISHOP: u8 = 4;
    const QUEEN: u8 = 5;
    const KING: u8 = 6;

    struct TestChessBoard has key {
        board: ChessBoard
    }

    #[test]
    fun test_new() {
        use ethos::chess_board::{row_count, column_count};

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
        assert!(type == QUEEN, (type as u64));
        assert!(player_number == PLAYER1, (player_number as u64));

        let (type, player_number) = piece_at_access(&board, 0, 4);
        assert!(type == KING, (type as u64));
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
        assert!(type == QUEEN, (type as u64));
        assert!(player_number == PLAYER2, (player_number as u64));

        let (type, player_number) = piece_at_access(&board, 7, 4);
        assert!(type == KING, (type as u64));
        assert!(player_number == PLAYER2, (player_number as u64));

        transfer::share_object(TestChessBoard { board })
    }

    #[test]
    fun test_modify() {
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
        let board = new();
        modify(&mut board, PLAYER1, 2, 1, 3, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 3)]
    fun test_modify_bad_space_occupied() {
        let board = new();
        modify(&mut board, PLAYER1, 0, 0, 0, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_modify_bad_from_wrong_player_player1() {
        let board = new();
        modify(&mut board, PLAYER2, 1, 1, 2, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_modify_bad_from_wrong_player_player2() {
        let board = new();
        modify(&mut board, PLAYER1, 6, 1, 5, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_modify_capture_piece() {
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
        let board = new();
        modify(&mut board, PLAYER1, 0, 6, 2, 7);
        modify(&mut board, PLAYER1, 2, 7, 4, 8);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_off_board_move_right() {
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
        let board = new();
        modify(&mut board, PLAYER1, 1, 1, 2, 2);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_pawn_move_2() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 1, 2, 1);
        modify(&mut board, PLAYER1, 2, 1, 1, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_modify_pawn_move_2_spaces() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 1, 3, 1);
        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_modify_pawn_move_2_spaces_player2() {
        let board = new();
        modify(&mut board, PLAYER2, 6, 1, 4, 1);
        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_pawn_move_2_spaces() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 1, 3, 1);
        modify(&mut board, PLAYER1, 3, 1, 5, 1);
        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_pawn_move_2_spaces_player2() {
        let board = new();
        modify(&mut board, PLAYER2, 6, 1, 4, 1);
        modify(&mut board, PLAYER2, 4, 1, 2, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_pawn_move_3() {
        let board = new();
        modify(&mut board, PLAYER2, 6, 1, 5, 1);
        modify(&mut board, PLAYER2, 5, 1, 6, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_modify_pawn_capture() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 1, 2, 1);
        modify(&mut board, PLAYER1, 2, 1, 3, 1);
        modify(&mut board, PLAYER1, 3, 1, 4, 1);
        modify(&mut board, PLAYER1, 4, 1, 5, 1);
        
        assert!(empty_space_count(&board) == 32, empty_space_count(&board));
        modify(&mut board, PLAYER1, 5, 1, 6, 2);
        assert!(empty_space_count(&board) == 33, empty_space_count(&board));

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_modify_pawn_capture_player2() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 1, 2, 1);
        modify(&mut board, PLAYER1, 2, 1, 3, 1);
        modify(&mut board, PLAYER1, 3, 1, 4, 1);
        modify(&mut board, PLAYER1, 4, 1, 5, 1);
        
        assert!(empty_space_count(&board) == 32, empty_space_count(&board));
        modify(&mut board, PLAYER2, 6, 2, 5, 1);
        assert!(empty_space_count(&board) == 33, empty_space_count(&board));

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_pawn_capture() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 1, 2, 1);
        modify(&mut board, PLAYER1, 2, 1, 3, 1);
        modify(&mut board, PLAYER1, 3, 1, 4, 1);
        modify(&mut board, PLAYER1, 4, 1, 5, 1);
        modify(&mut board, PLAYER2, 6, 2, 5, 2);
        modify(&mut board, PLAYER2, 5, 2, 4, 2);
        modify(&mut board, PLAYER1, 5, 1, 4, 2);

        transfer::share_object(TestChessBoard { board });
    }


    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_rook_move() {
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
        let board = new();
        modify(&mut board, PLAYER1, 0, 1, 2, 1);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_knight_move_2() {
        let board = new();
        modify(&mut board, PLAYER1, 0, 1, 2, 2);
        modify(&mut board, PLAYER1, 2, 2, 3, 3);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_bishop_move() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 2, 2, 2);
        modify(&mut board, PLAYER1, 0, 2, 1, 2);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_king_move() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 4, 2, 4);
        modify(&mut board, PLAYER1, 2, 4, 3, 4);
        modify(&mut board, PLAYER1, 3, 4, 4, 4);
        modify(&mut board, PLAYER1, 0, 4, 1, 4);
        modify(&mut board, PLAYER1, 1, 4, 3, 4);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_modify_bad_queen_move() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 4, 2, 4);
        modify(&mut board, PLAYER1, 2, 4, 3, 4);
        modify(&mut board, PLAYER1, 3, 4, 4, 4);
        modify(&mut board, PLAYER1, 0, 4, 1, 4);
        modify(&mut board, PLAYER1, 1, 4, 3, 3);

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_modify_queen_diagonal_move() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 3, 2, 3);
        modify(&mut board, PLAYER1, 2, 3, 3, 3);
        modify(&mut board, PLAYER1, 3, 3, 4, 3);
        modify(&mut board, PLAYER1, 0, 3, 1, 3);
        modify(&mut board, PLAYER1, 1, 3, 3, 1);

        let (type, player_number) = piece_at_access(&board, 3, 1);
        assert!(type == QUEEN, (type as u64));
        assert!(player_number == PLAYER1, (PLAYER1 as u64));

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_modify_queen_diagonal_move_one_space() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 4, 2, 4);
        modify(&mut board, PLAYER1, 2, 4, 3, 4);
        modify(&mut board, PLAYER1, 0, 3, 1, 4);

        let (type, _) = piece_at_access(&board, 1, 4);
        assert!(type == QUEEN, (type as u64));

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_bad_modify_queen_no_jump() {
        let board = new();
        modify(&mut board, PLAYER1, 0, 3, 3, 0);
        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_bad_modify_bishop_no_jump() {
        let board = new();
        modify(&mut board, PLAYER1, 0, 2, 2, 0);
        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_bad_modify_rook_no_jump() {
        let board = new();
        modify(&mut board, PLAYER1, 0, 0, 3, 0);
        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_castling_king_to_rook() {
        let board = new();
        modify(&mut board, PLAYER2, 6, 0, 4, 0);
        modify(&mut board, PLAYER2, 6, 1, 4, 1);
        modify(&mut board, PLAYER2, 6, 2, 4, 2);
        modify(&mut board, PLAYER2, 7, 1, 5, 2);
        modify(&mut board, PLAYER2, 7, 2, 6, 1);
        modify(&mut board, PLAYER2, 7, 3, 6, 2);
        modify(&mut board, PLAYER2, 7, 4, 7, 0);

        let (type, _) = piece_at_access(&board, 7, 2);
        assert!(type == KING, (type as u64));

        let (type, _) = piece_at_access(&board, 7, 3);
        assert!(type == ROOK, (type as u64));

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_castling_rook_to_king() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 0, 3, 0);
        modify(&mut board, PLAYER1, 1, 1, 3, 1);
        modify(&mut board, PLAYER1, 1, 2, 3, 2);
        modify(&mut board, PLAYER1, 0, 1, 2, 2);
        modify(&mut board, PLAYER1, 0, 2, 1, 1);
        modify(&mut board, PLAYER1, 0, 3, 1, 2);
        modify(&mut board, PLAYER1, 0, 0, 0, 4);

        let (type, _) = piece_at_access(&board, 0, 2);
        assert!(type == KING, (type as u64));

        let (type, _) = piece_at_access(&board, 0, 3);
        assert!(type == ROOK, (type as u64));

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_castling_king_to_rook2() {
        let board = new();
        modify(&mut board, PLAYER2, 6, 7, 4, 7);
        modify(&mut board, PLAYER2, 6, 6, 4, 6);
        modify(&mut board, PLAYER2, 6, 5, 4, 5);
        modify(&mut board, PLAYER2, 7, 6, 5, 5);
        modify(&mut board, PLAYER2, 7, 5, 6, 6);
        modify(&mut board, PLAYER2, 7, 4, 7, 7);

        let (type, _) = piece_at_access(&board, 7, 6);
        assert!(type == KING, (type as u64));

        let (type, _) = piece_at_access(&board, 7, 5);
        assert!(type == ROOK, (type as u64));

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_castling_rook_to_king2() {
        let board = new();
        modify(&mut board, PLAYER2, 6, 7, 4, 7);
        modify(&mut board, PLAYER2, 6, 6, 4, 6);
        modify(&mut board, PLAYER2, 6, 5, 4, 5);
        modify(&mut board, PLAYER2, 7, 6, 5, 5);
        modify(&mut board, PLAYER2, 7, 5, 6, 6);
        modify(&mut board, PLAYER2, 7, 7, 7, 4);

        let (type, _) = piece_at_access(&board, 7, 6);
        assert!(type == KING, (type as u64));

        let (type, _) = piece_at_access(&board, 7, 5);
        assert!(type == ROOK, (type as u64));

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_bad_castling_rook_already_moved() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 0, 3, 0);
        modify(&mut board, PLAYER1, 1, 1, 3, 1);
        modify(&mut board, PLAYER1, 1, 2, 3, 2);
        modify(&mut board, PLAYER1, 0, 1, 2, 2);
        modify(&mut board, PLAYER1, 0, 2, 1, 1);
        modify(&mut board, PLAYER1, 0, 3, 1, 2);
        modify(&mut board, PLAYER1, 0, 0, 1, 0);
        modify(&mut board, PLAYER1, 1, 0, 0, 0);
        modify(&mut board, PLAYER1, 0, 4, 0, 0);
        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_bad_castling_king_already_moved() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 0, 3, 0);
        modify(&mut board, PLAYER1, 1, 1, 3, 1);
        modify(&mut board, PLAYER1, 1, 2, 3, 2);
        modify(&mut board, PLAYER1, 0, 1, 2, 2);
        modify(&mut board, PLAYER1, 0, 2, 1, 1);
        modify(&mut board, PLAYER1, 0, 3, 1, 2);
        modify(&mut board, PLAYER1, 0, 4, 0, 3);
        modify(&mut board, PLAYER1, 0, 3, 0, 4);
        modify(&mut board, PLAYER1, 0, 0, 0, 4);
        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_castling_even_if_other_rook_moved() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 0, 3, 0);
        modify(&mut board, PLAYER1, 1, 1, 3, 1);
        modify(&mut board, PLAYER1, 1, 2, 3, 2);
        modify(&mut board, PLAYER1, 0, 1, 2, 2);
        modify(&mut board, PLAYER1, 0, 2, 1, 1);
        modify(&mut board, PLAYER1, 0, 3, 1, 2);
        modify(&mut board, PLAYER1, 1, 7, 3, 7);
        modify(&mut board, PLAYER1, 0, 7, 2, 7);
        modify(&mut board, PLAYER1, 0, 0, 0, 4);

        let (type, _) = piece_at_access(&board, 0, 2);
        assert!(type == KING, (type as u64));

        let (type, _) = piece_at_access(&board, 0, 3);
        assert!(type == ROOK, (type as u64));

        transfer::share_object(TestChessBoard { board });
    }

     #[test]
    fun test_castling_even_if_other_rook_moved_king_initiated() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 7, 3, 7);
        modify(&mut board, PLAYER1, 1, 6, 3, 6);
        modify(&mut board, PLAYER1, 1, 5, 3, 5);
        modify(&mut board, PLAYER1, 0, 6, 2, 5);
        modify(&mut board, PLAYER1, 0, 5, 1, 6);
        modify(&mut board, PLAYER1, 1, 0, 3, 0);
        modify(&mut board, PLAYER1, 0, 0, 2, 0);
        modify(&mut board, PLAYER1, 0, 4, 0, 7);

        let (type, _) = piece_at_access(&board, 0, 6);
        assert!(type == KING, (type as u64));

        let (type, _) = piece_at_access(&board, 0, 5);
        assert!(type == ROOK, (type as u64));

        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_en_passant() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 2, 3, 2);
        modify(&mut board, PLAYER1, 3, 2, 4, 2);
        modify(&mut board, PLAYER2, 6, 1, 4, 1);
        
        assert!(empty_space_count(&board) == 32, empty_space_count(&board));
        modify(&mut board, PLAYER1, 4, 2, 5, 1);
        assert!(empty_space_count(&board) == 33, empty_space_count(&board));
        
        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_pawn_promotion() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 2, 3, 2);
        modify(&mut board, PLAYER1, 3, 2, 4, 2);
        modify(&mut board, PLAYER1, 4, 2, 5, 2);
        modify(&mut board, PLAYER1, 5, 2, 6, 3);
        modify(&mut board, PLAYER1, 6, 3, 7, 2);
        
        let (type, player_number) = piece_at_access(&board, 7, 2);
        assert!(type == QUEEN, (type as u64));
        assert!(player_number == PLAYER1, (player_number as u64));
        
        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_pawn_promotion_player2() {
        let board = new();
        modify(&mut board, PLAYER2, 6, 2, 4, 2);
        modify(&mut board, PLAYER2, 4, 2, 3, 2);
        modify(&mut board, PLAYER2, 3, 2, 2, 2);
        modify(&mut board, PLAYER2, 2, 2, 1, 3);
        modify(&mut board, PLAYER2, 1, 3, 0, 2);
        
        let (type, player_number) = piece_at_access(&board, 0, 2);
        assert!(type == QUEEN, (type as u64));
        assert!(player_number == PLAYER2, (player_number as u64));
        
        transfer::share_object(TestChessBoard { board });
    }

    #[test]
    fun test_game_over() {
        let board = new();
        modify(&mut board, PLAYER1, 1, 2, 3, 2);
        modify(&mut board, PLAYER1, 0, 3, 3, 0);
        modify(&mut board, PLAYER1, 3, 0, 6, 3);
        modify(&mut board, PLAYER1, 6, 3, 7, 4);
        
        assert!(*game_over(&board), 1);

        transfer::share_object(TestChessBoard { board });
    }
}