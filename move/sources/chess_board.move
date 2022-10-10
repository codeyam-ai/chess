module ethos::chess_board {
    use std::option::{Self, Option};
    use std::vector;
    
    friend ethos::chess;

    #[test_only]
    friend ethos::chess_board_tests;

    #[test_only]
    friend ethos::chess_tests;

    const EMPTY: u8 = 0;
    const PLAYER1: u8 = 1;
    const PLAYER2: u8 = 2;

    const QUEEN: u8 = 1;
    const KING: u8 = 2;
    const ROOK: u8 = 3;
    const BISHOP: u8 = 4;
    const KNIGHT: u8 = 5;
    const PAWN: u8 = 6;

    const ROW_COUNT: u64 = 8;
    const COLUMN_COUNT: u64 = 8;

    const EEMPTY_SPACE: u64 = 0;
    const EWRONG_PLAYER: u64 = 1;
    const EBAD_DESTINATION: u64 = 2;
    const EOCCUPIED_SPACE: u64 = 3;
    
    struct ChessBoard has store, copy {
        spaces: vector<vector<Option<ChessPiece>>>,
        game_over: bool
    }

    struct ChessPiece has store, copy, drop {
        type: u8,
        player_number: u8
    }

    struct SpacePosition has copy, drop {
        row: u64,
        column: u64
    }

    struct MoveEffects has drop {
        jumps: vector<SpacePosition>
    }

    public(friend) fun new(): ChessBoard {
        let spaces = vector[];

        let i=0;
        while (i < ROW_COUNT) {
            let row = vector[];

            let j=0;
            while (j < COLUMN_COUNT) {
                if (i == 0 || i == 7) {
                    if (j == 0 || j == 7) {
                        let piece = create_piece(ROOK, i==0);
                        vector::push_back(&mut row, option::some(piece));
                    } else if (j == 1 || j == 6) {
                        let piece = create_piece(KNIGHT, i==0);
                        vector::push_back(&mut row, option::some(piece));
                    } else if (j == 2 || j == 5) {
                        let piece = create_piece(BISHOP, i==0);
                        vector::push_back(&mut row, option::some(piece));
                    } else if (j == 3) {
                        let piece = create_piece(KING, i==0);
                        vector::push_back(&mut row, option::some(piece));
                    } else if (j == 4) {
                        let piece = create_piece(QUEEN, i==0);
                        vector::push_back(&mut row, option::some(piece));
                    }
                } else if (i == 1 || i == 6) {
                    let piece = create_piece(PAWN, i==1);
                    vector::push_back(&mut row, option::some(piece));
                } else {
                    vector::push_back(&mut row, option::none());
                };

                j = j + 1;
            };

            vector::push_back(&mut spaces, row);

            i = i + 1;
        };

        let game_board = ChessBoard { 
            spaces, 
            game_over: false
        };

        game_board 
    }

    public(friend) fun modify(board: &mut ChessBoard, player_number: u8, from_row: u64, from_col: u64, to_row: u64, to_col: u64): bool {
        assert!(to_row < ROW_COUNT && to_col < COLUMN_COUNT, EBAD_DESTINATION);
        
        let old_space = space_at_mut(board, from_row, from_col);
        assert!(option::is_some(old_space), EEMPTY_SPACE);
        
        let piece = option::extract(old_space);
        assert!(piece.player_number == player_number, EWRONG_PLAYER);

        assert!(is_valid_move(piece, from_row, from_col, to_row, to_col), EBAD_DESTINATION);
        let new_space = space_at_mut(board, to_row, to_col);

        if (option::is_some(new_space)) {
            let chess_piece = option::borrow(new_space);

            if (chess_piece.player_number != player_number) {
                option::swap(new_space, piece);
                return true
            }
        };
        
        assert!(option::is_none(new_space), EOCCUPIED_SPACE);
        option::fill(new_space, piece);

        true
    }
    
    public fun row_count(): u64 {
        ROW_COUNT
    }

    public fun column_count(): u64 {
        COLUMN_COUNT
    }

    fun spaces_at(spaces: &vector<vector<Option<ChessPiece>>>, row_index: u64, column_index: u64): &Option<ChessPiece> {
        let row = vector::borrow(spaces, row_index);
        vector::borrow(row, column_index)
    }

    fun spaces_at_mut(spaces: &mut vector<vector<Option<ChessPiece>>>, row_index: u64, column_index: u64): &mut Option<ChessPiece> {
        let row = vector::borrow_mut(spaces, row_index);
        vector::borrow_mut(row, column_index)
    }

    public(friend) fun space_at(board: &ChessBoard, row_index: u64, column_index: u64): &Option<ChessPiece> {
        spaces_at(&board.spaces, row_index, column_index)
    }

    public(friend) fun space_at_mut(board: &mut ChessBoard, row_index: u64, column_index: u64): &mut Option<ChessPiece> {
        spaces_at_mut(&mut board.spaces, row_index, column_index)
    }

    public(friend) fun piece_at(board: &ChessBoard, row: u64, column: u64): ChessPiece {
        let option = space_at(board, row, column);
        
        if (option::is_none(option)) {
            return ChessPiece { 
                type: EMPTY, 
                player_number: EMPTY
            }
        };

        *option::borrow(option)
    }

    public(friend) fun piece_at_access(board: &ChessBoard, row: u64, column: u64): (u8, u8) {
        let piece = piece_at(board, row, column);
        (piece.type, piece.player_number)
    }

    public(friend) fun empty_space_positions(game_board: &ChessBoard): vector<SpacePosition> {
        let empty_spaces = vector<SpacePosition>[];

        let row = 0;
        while (row < ROW_COUNT) {
            let column = 0;
            while (column < COLUMN_COUNT) {
                let space = space_at(game_board, row, column);
                if (option::is_none(space)) {
                    vector::push_back(&mut empty_spaces, SpacePosition { row, column })
                };
                column = column + 1;
            };
            row = row + 1;
        };

        empty_spaces
    }

    public(friend) fun empty_space_count(game_board: &ChessBoard): u64 {
        vector::length(&empty_space_positions(game_board))
    }

    fun create_piece(type: u8, player_1: bool): ChessPiece {
        let player_number = PLAYER1;
        if (!player_1) {
            player_number = PLAYER2;
        };
        ChessPiece {
            type,
            player_number
        }
    }

    fun is_valid_move(piece: ChessPiece, from_row: u64, from_col: u64, to_row: u64, to_col: u64): bool {
        if (piece.type == PAWN) {
            if (piece.player_number == PLAYER1) {
                if (from_row + 1 == to_row && from_col == to_col) {
                    return true
                }
            } else {
                if (from_row == to_row + 1 && from_col == to_col) {
                    return true
                }
            }
        } else if (piece.type == ROOK) {
            if (
                (from_row == to_row && from_col != to_col) ||
                (from_row != to_row && from_col == to_col)
            ) {
                return true
            }
        } else if (piece.type == KNIGHT) {
            if (
                (from_row + 2 == to_row && (from_col + 1 == to_col || from_col == to_col + 1)) ||
                (from_row == to_row + 2 && (from_col + 1 == to_col || from_col == to_col + 1)) ||
                (from_row + 1 == to_row && (from_col + 2 == to_col || from_col == to_col + 2)) ||
                (from_row == to_row + 1 && (from_col + 2 == to_col || from_col == to_col + 2))
            ) {
                return true
            }
        } else if (piece.type == KING) {
            if (
                (from_row + 1 == to_row || from_row == to_row + 1 || from_row == to_row) &&
                (from_col + 1 == to_col || from_row == to_col + 1 || from_col == to_col)
            ) {
                return true
            }
        } else {
            return true
        };
        
        false
    }

}

