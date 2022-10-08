module ethos::checkers_board {
    use std::option::{Self, Option};
    use std::vector;
    
    friend ethos::checkers;

    #[test_only]
    friend ethos::checkers_board_tests;

    #[test_only]
    friend ethos::checkers_tests;

    const EMPTY: u8 = 0;
    const PLAYER1: u8 = 1;
    const PLAYER2: u8 = 2;

    const ROW_COUNT: u64 = 8;
    const COLUMN_COUNT: u64 = 8;
    const PLAYER_PIECES: u64 = 12;
    
    struct CheckersBoard has store, copy {
        spaces: vector<vector<Option<u8>>>,
        game_over: bool
    }

    struct SpacePosition has copy, drop {
        row: u64,
        column: u64
    }

    public(friend) fun new(): CheckersBoard {
        let spaces = vector[];

        let i=0;
        while (i < ROW_COUNT) {
            let row = vector[];

            let j=0;
            while (j < COLUMN_COUNT) {
                if (valid_space(i, j)) {
                    if (i < 4) {
                        vector::push_back(&mut row, option::some(PLAYER1))
                    } else if (i > 5) {
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

        let game_board = CheckersBoard { 
            spaces, 
            game_over: false
        };

        game_board 
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

    public(friend) fun space_at(game_board: &CheckersBoard, row_index: u64, column_index: u64): &Option<u8> {
        spaces_at(&game_board.spaces, row_index, column_index)
    }

    public(friend) fun space_at_mut(game_board: &mut CheckersBoard, row_index: u64, column_index: u64): &mut Option<u8> {
        spaces_at_mut(&mut game_board.spaces, row_index, column_index)
    }

    public(friend) fun empty_space_positions(game_board: &CheckersBoard): vector<SpacePosition> {
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

    public(friend) fun empty_space_count(game_board: &CheckersBoard): u64 {
        vector::length(&empty_space_positions(game_board))
    }

    fun valid_space(row: u64, column: u64): bool {
        if (row % 2 == 1) {
            column % 2 == 0
        } else {
            column % 2 == 1
        }
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

