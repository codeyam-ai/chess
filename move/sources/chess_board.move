module ethos::chess_board {
    use std::option::{Self, Option};
    use std::vector;
    
    friend ethos::chess;

    #[test_only]
    friend ethos::chess_board_tests;

    #[test_only]
    friend ethos::chess_tests;

    const EMPTY: u8 = 0;
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
    
    struct CheckerBoard has store, copy {
        spaces: vector<vector<Option<u8>>>,
        game_over: bool
    }

    struct SpacePosition has copy, drop {
        row: u64,
        column: u64
    }

    struct MoveEffects has drop {
        jumps: vector<SpacePosition>
    }

    public(friend) fun new(): CheckerBoard {
        let spaces = vector[];

        let i=0;
        while (i < ROW_COUNT) {
            let row = vector[];

            let j=0;
            while (j < COLUMN_COUNT) {
                if (i == 0 || i == 7) {
                    if (j == 0 || j == 7) {
                        vector::push_back(&mut row, option::some(ROOK));
                    } else if (j == 1 || j == 6) {
                        vector::push_back(&mut row, option::some(KNIGHT));
                    } else if (j == 2 || j == 5) {
                        vector::push_back(&mut row, option::some(BISHOP));
                    } else if (j == 3) {
                        vector::push_back(&mut row, option::some(KING));
                    } else if (j == 4) {
                        vector::push_back(&mut row, option::some(QUEEN));
                    }
                } else if (i == 1 || i == 6) {
                    vector::push_back(&mut row, option::some(PAWN));
                } else {
                    vector::push_back(&mut row, option::some(EMPTY));
                };

                j = j + 1;
            };

            vector::push_back(&mut spaces, row);

            i = i + 1;
        };

        let game_board = CheckerBoard { 
            spaces, 
            game_over: false
        };

        game_board 
    }

    public(friend) fun modify(board: &mut CheckerBoard, from_row: u64, from_col: u64, to_row: u64, to_col: u64): bool {
        let old_space = space_at_mut(board, from_row, from_col);
        let piece = option::swap(old_space, EMPTY);

        assert!(piece != EMPTY, EEMPTY_SPACE);

        let new_space = space_at_mut(board, to_row, to_col);
        option::swap(new_space, piece);

        true
    }
    
    public fun row_count(): u64 {
        ROW_COUNT
    }

    public fun column_count(): u64 {
        COLUMN_COUNT
    }

    fun spaces_at(spaces: &vector<vector<Option<u8>>>, row_index: u64, column_index: u64): &Option<u8> {
        let row = vector::borrow(spaces, row_index);
        vector::borrow(row, column_index)
    }

    fun spaces_at_mut(spaces: &mut vector<vector<Option<u8>>>, row_index: u64, column_index: u64): &mut Option<u8> {
        let row = vector::borrow_mut(spaces, row_index);
        vector::borrow_mut(row, column_index)
    }

    public(friend) fun space_at(board: &CheckerBoard, row_index: u64, column_index: u64): &Option<u8> {
        spaces_at(&board.spaces, row_index, column_index)
    }

    public(friend) fun space_at_mut(board: &mut CheckerBoard, row_index: u64, column_index: u64): &mut Option<u8> {
        spaces_at_mut(&mut board.spaces, row_index, column_index)
    }

    public(friend) fun piece_at(board: &CheckerBoard, row: u64, column: u64): &u8 {
        option::borrow(space_at(board, row, column))
    }

    public(friend) fun empty_space_positions(game_board: &CheckerBoard): vector<SpacePosition> {
        let empty_spaces = vector<SpacePosition>[];

        let row = 0;
        while (row < ROW_COUNT) {
            let column = 0;
            while (column < COLUMN_COUNT) {
                let space = space_at(game_board, row, column);
                if (option::contains(space, &EMPTY)) {
                    vector::push_back(&mut empty_spaces, SpacePosition { row, column })
                };
                column = column + 1;
            };
            row = row + 1;
        };

        empty_spaces
    }

    public(friend) fun empty_space_count(game_board: &CheckerBoard): u64 {
        vector::length(&empty_space_positions(game_board))
    }


    // fun analyze_move(board: &CheckerBoard, piece: &u8, from_row: u64, from_col: u64, to_row: u64, to_col: u64): bool {
    //     assert!(to_row < ROW_COUNT, EBAD_DESTINATION);
    //     assert!(to_col < COLUMN_COUNT, EBAD_DESTINATION);
        
    //     true
    // }

}

