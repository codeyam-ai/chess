module ethos::checker_board {
    use std::option::{Self, Option};
    use std::vector;
    
    friend ethos::checkers;

    #[test_only]
    friend ethos::checker_board_tests;

    #[test_only]
    friend ethos::checkers_tests;

    const EMPTY: u8 = 0;
    const PLAYER1: u8 = 1;
    const PLAYER2: u8 = 2;

    const ROW_COUNT: u64 = 8;
    const COLUMN_COUNT: u64 = 8;
    const PLAYER_PIECES: u64 = 12;

    const EEMPTY_SPACE: u64 = 0;
    const EBAD_DESTINATION: u64 = 1;
    const EOCCUPIED_SPACE: u64 = 2;
    
    struct CheckerBoard has store, copy {
        spaces: vector<vector<Option<u8>>>,
        game_over: bool
    }

    struct SpacePosition has copy, drop {
        row: u64,
        column: u64
    }

    public(friend) fun new(): CheckerBoard {
        let spaces = vector[];

        let i=0;
        while (i < ROW_COUNT) {
            let row = vector[];

            let j=0;
            while (j < COLUMN_COUNT) {
                if (valid_space(i, j)) {
                    if (i < 3) {
                        vector::push_back(&mut row, option::some(PLAYER1))
                    } else if (i > 4) {
                        vector::push_back(&mut row, option::some(PLAYER2))
                    } else {
                        vector::push_back(&mut row, option::some(EMPTY))
                    }        
                } else {
                    vector::push_back(&mut row, option::none())
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
        assert_valid_move(board, from_row, from_col, to_row, to_col);
        
        let old_space = space_at_mut(board, from_row, from_col);
        let piece = option::swap(old_space, EMPTY);

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

    fun valid_space(row: u64, column: u64): bool {
        if (row % 2 == 1) {
            column % 2 == 0
        } else {
            column % 2 == 1
        }
    }

    fun assert_valid_move(board: &CheckerBoard, from_row: u64, from_col: u64, to_row: u64, to_col: u64): bool {
        let old_space = space_at(board, from_row, from_col);
        let new_space = space_at(board, to_row, to_col);

        let player1_move = option::contains(old_space, &PLAYER1);
        let player2_move = option::contains(old_space, &PLAYER2);
        assert!(player1_move || player2_move, EEMPTY_SPACE);

        if (player1_move) {
            assert!(to_row > from_row, EBAD_DESTINATION);
        } else {
            assert!(to_row < from_row, EBAD_DESTINATION);
        };

        assert!(from_col + 1 == to_col || from_col == to_col + 1, EBAD_DESTINATION);

        assert!(option::contains(new_space, &EMPTY), EOCCUPIED_SPACE);

        true
    }

}

