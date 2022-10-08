module ethos::checkers {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use std::string::{Self, String};
    use sui::event;
    use sui::transfer;
    use std::vector;
    use std::option::{Self, Option};
    use ethos::checker_board::{Self, CheckerBoard};

    const EInvalidPlayer: u64 = 0;

    struct CheckersGame has key, store {
        id: UID,
        name: String,
        description: String,
        url: Url,
        player1: address,
        player2: address,
        moves: vector<CheckersMove>,
        boards: vector<CheckerBoard>,
        current_player: address,
        winner: Option<address>
    }

    struct CheckersMove has store {
        from_row: u8,
        from_column: u8,
        to_row: u8,
        to_column: u8,
        player: address,
        epoch: u64
    }

    struct NewCheckersGameEvent has copy, drop {
        game_id: ID,
        player1: address,
        player2: address
    }

    struct CheckersMoveEvent has copy, drop {
        game_id: ID,
        from_row: u8,
        from_column: u8,
        to_row: u8,
        to_column: u8,
        player: address,
        board_spaces: vector<vector<Option<u8>>>,
        epoch: u64
    }

    struct CheckersGameOverEvent has copy, drop {
        game_id: ID,
        winner: address
    }

    public entry fun create_game(player2: address, ctx: &mut TxContext) {
        let uid = object::new(ctx);
        let player1 = tx_context::sender(ctx);
        let new_board = checker_board::new();
        
        let game = CheckersGame {
            id: uid,
            name: string::utf8(b"Ethos Checkers"),
            description: string::utf8(b"Checkers - built on Sui  - by Ethos"),
            url: url::new_unsafe_from_bytes(b"https://CheckerBoard.png"),
            player1,
            player2,
            moves: vector[],
            boards: vector[new_board],
            current_player: player1,
            winner: option::none()
        };

        event::emit(NewCheckersGameEvent {
            game_id: object::uid_to_inner(&game.id),
            player1,
            player2
        });
        
        transfer::transfer(game, player1);
    }

    public entry fun make_move(game: CheckersGame, fromRow: u8, fromColumn: u8, toRow: u8, toColumn: u8) {

    }

    public fun player1(game: &CheckersGame): &address {
        &game.player1
    }

    public fun player2(game: &CheckersGame): &address {
        &game.player2
    }

    public fun move_count(game: &CheckersGame): u64 {
        vector::length(&game.moves)
    }

    public fun board_at(game: &CheckersGame, index: u64): &CheckerBoard {
        vector::borrow(&game.boards, index)
    }

    public fun piece_at(game: &CheckersGame, row: u64, column: u64): &u8 {
        let last_board_index = vector::length(&game.boards) - 1;
        let last_board = vector::borrow(&game.boards, last_board_index);
        checker_board::piece_at(last_board, row, column)
    }

    public fun current_player(game: &CheckersGame): &address {
        &game.current_player
    }
}