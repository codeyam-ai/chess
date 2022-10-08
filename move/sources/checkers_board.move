module ethos::checkers_board {
    use std::option::{Self, Option};
    use std::vector;
    
    friend ethos::checkers;

    #[test_only]
    friend ethos::checkers_board_tests;

    #[test_only]
    friend ethos::checkers_tests;

    const PLAYER1: u8 = 0;
    const PLAYER2: u8 = 1;

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

        let game_board = CheckersBoard { 
          spaces, 
          game_over: false
        };

        game_board 
    }
    
    public fun row_count(board: &CheckersBoard): u64 {
        vector::length(&board.spaces)
    }

    public fun column_count(board: &CheckersBoard): u64 {
        vector::length(vector::borrow(&board.spaces, 0))
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

        let rows = row_count(game_board);
        let columns = column_count(game_board);
        
        let row = 0;
        while (row < rows) {
          let column = 0;
          while (column < columns) {
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

    public(friend) fun empty_space_count(game_board: &CheckersBoard): u64 {
        vector::length(&empty_space_positions(game_board))
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


    // use ethos::checkers_board::CheckersBoard;
    #[test_only]
    use sui::transfer;

    #[test_only]
    struct TestGameBoard has key {
        game_board: CheckersBoard
    }

    #[test_only]
    fun test_new() {
        // use ethos::checkers_board::{new, row_count, column_count, empty_space_count};

        let game_board = new();
        assert!(row_count(&game_board) == 8, row_count(&game_board));
        assert!(column_count(&game_board) == 8, column_count(&game_board));
        let empty_space_count = empty_space_count(&game_board);
        assert!(empty_space_count == 8, empty_space_count);

        transfer::share_object(TestGameBoard { game_board })
    }
}

