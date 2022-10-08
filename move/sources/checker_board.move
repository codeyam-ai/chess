module ethos::checker_board {
    use std::option::{Self, Option};
    use std::vector;
    
    friend ethos::checkers;

    #[test_only]
    friend ethos::checker_board_tests;

    #[test_only]
    friend ethos::checkers_tests;

    const Empty: u8 = 0;
    const PLAYER1: u8 = 1;
    const PLAYER2: u8 = 2;

    const RowCount: u64 = 8;
    const ColumnCount: u64 = 8;
    const PlayerPieces: u64 = 12;
    
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
        while (i < RowCount) {
            let row = vector[];

            let j=0;
            while (j < ColumnCount) {
                if (valid_space(i, j)) {
                    if (i < 4) {
                        vector::push_back(&mut row, option::some(PLAYER1))
                    } else if (i > 5) {
                        vector::push_back(&mut row, option::some(PLAYER2))
                    } else {
                        vector::push_back(&mut row, option::some(Empty))
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
        let old_space = space_at_mut(board, from_row, from_col);
        let piece = option::swap(old_space, Empty);

        let new_space = space_at_mut(board, to_row, to_col);
        option::swap(new_space, piece);

        true
    }
    
    public fun row_count(): u64 {
        RowCount
    }

    public fun column_count(): u64 {
        ColumnCount
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

    public(friend) fun empty_space_positions(game_board: &CheckerBoard): vector<SpacePosition> {
        let empty_spaces = vector<SpacePosition>[];

        let row = 0;
        while (row < RowCount) {
          let column = 0;
          while (column < ColumnCount) {
            let space = space_at(game_board, row, column);
            if (option::contains(space, &Empty)) {
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

    public(friend) fun piece_at(board: &CheckerBoard, row: u64, column: u64): &u8 {
        option::borrow(space_at(board, row, column))
    }


    // public fun print(spaces: &vector<vector<Option<u8>>>) {
    
    //     let row_index = 0;
    //     let rows = vector::length(spaces);

    //     while (row_index < rows) {
    //         let row = vector::borrow(spaces, row_index);
            
    //         let column_index = 0;
    //         let columns = vector::length(row);

    //         let row_values = vector<u8>[];
    //         while (column_index < columns) {
    //           let column = vector::borrow(row, column_index);
    //           if (option::is_none(column)) {
    //             vector::push_back(&mut row_values, 99);
    //           } else {
    //             vector::push_back(&mut row_values, *option::borrow(column))
    //           };
    //           column_index = column_index + 1
    //         };

    //         print_vector(row_values);
    //         row_index = row_index + 1
    //     }   
    // }

    // public fun print_vector(vec: vector<u8>) {
    //     use std::debug::print;
    //     print(&vec);
    // }

    // public fun print_vector_64(vec: &vector<u64>) {
    //     use std::debug::print;

    //     let length = vector::length(vec);
    //     let index = 0;
    //     while (index < length) {
    //       print(vector::borrow(vec, index));
    //       index = index + 1;
    //     }
    // }
}

