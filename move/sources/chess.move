module ethos::chess {
    use std::string::{Self, String};
    use std::option::{Self, Option};

    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use sui::event;
    use sui::transfer;
    use sui::table::{Self, Table};
   
    use ethos::chess_board::{Self, ChessBoard, ChessPiece};

    const EINVALID_PLAYER: u64 = 0;
    const EGAME_OVER: u64 = 1;

    const PLAYER1: u8 = 1;
    const PLAYER2: u8 = 2;

    struct ChessGame has key, store {
        id: UID,
        name: String,
        description: String,
        url: Url,
        player1: address,
        player2: address,
        moves: Table<u64, ChessMove>,
        boards: Table<u64, ChessBoard>,
        current_player: address,
        winner: Option<address>
    }

    struct ChessPlayerCap has key, store {
        id: UID,
        game_id: ID,
        player_number: u8,
        name: String,
        description: String,
        url: Url
    }

    struct ChessMove has store {
        from_row: u64,
        from_column: u64,
        to_row: u64,
        to_column: u64,
        player: address,
        player_number: u8,
        epoch: u64
    }

    struct NewChessGameEvent has copy, drop {
        game_id: ID,
        player1: address,
        player2: address,
        board_spaces: vector<vector<Option<ChessPiece>>>
    }

    struct ChessMoveEvent has copy, drop {
        game_id: ID,
        from_row: u64,
        from_column: u64,
        to_row: u64,
        to_column: u64,
        player: address,
        player_number: u8,
        board_spaces: vector<vector<Option<ChessPiece>>>,
        epoch: u64
    }

    struct ChessGameOverEvent has copy, drop {
        game_id: ID,
        winner: address,
        epoch: u64
    }

    public entry fun create_game(player2: address, ctx: &mut TxContext) {
        let game_uid = object::new(ctx);
        let player1 = tx_context::sender(ctx);
        let new_board = chess_board::new();
        
        let name = string::utf8(b"Ethos Chess");
        let description = string::utf8(b"Chess - built on Sui  - by Ethos");
        let board_spaces = *chess_board::spaces(&new_board);
        let url = url::new_unsafe_from_bytes(b"https://arweave.net/ZUrXvtGA19RqxjUZ6QXHIy_W2MyctjGZLtMZheslvPo");
        let moves = table::new<u64, ChessMove>(ctx);
        let boards = table::new<u64, ChessBoard>(ctx);
        table::add(&mut boards, 0, new_board);

        let game = ChessGame {
            id: game_uid,
            name,
            description,
            url,
            player1,
            player2,
            moves,
            boards,
            current_player: player1,
            winner: option::none()
        };
        
        let game_id = object::uid_to_inner(&game.id);
        
        let player1_cap = ChessPlayerCap {
            id: object::new(ctx),
            game_id,
            player_number: PLAYER1,
            name,
            description,
            url,
        };

        let player2_cap = ChessPlayerCap {
            id: object::new(ctx),
            game_id,
            player_number: PLAYER2,
            name,
            description,
            url,
        };

        event::emit(NewChessGameEvent {
            game_id,
            player1,
            player2,
            board_spaces
        });
        
        transfer::share_object(game);
        transfer::transfer(player1_cap, player1);
        transfer::transfer(player2_cap, player2);
    }

    public entry fun make_move(game: &mut ChessGame, from_row: u64, from_column: u64, to_row: u64, to_column: u64, ctx: &mut TxContext) {
        let player = tx_context::sender(ctx);  
        let epoch = tx_context::epoch(ctx);

        assert!(game.current_player == player, EINVALID_PLAYER);

        let player_number = PLAYER1; 
        if (player == game.player2) {
            player_number = PLAYER2;
        };

        let board = current_board_mut(game);
        assert!(!*chess_board::game_over(board), EGAME_OVER);

        let new_board = *board;
        
        chess_board::modify(&mut new_board, player_number, from_row, from_column, to_row, to_column);
        
        if (*chess_board::game_over(&new_board)) {
            event::emit(ChessGameOverEvent {
                game_id: object::uid_to_inner(&game.id),
                winner: player,
                epoch
            });
            option::fill(&mut game.winner, player);
        };

        if (player == game.player1) {
            game.current_player = *&game.player2;
        } else {
            game.current_player = *&game.player1;
        };

        let board_spaces = *chess_board::spaces(&new_board);

        event::emit(ChessMoveEvent {
            game_id: object::uid_to_inner(&game.id),
            from_row,
            from_column,
            to_row,
            to_column,
            player,
            player_number,
            board_spaces,
            epoch
        });

        let new_move = ChessMove {
          from_row,
          from_column,
          to_row,
          to_column,
          player,
          player_number,
          epoch
        };

        let total_moves = table::length(&game.moves);
        table::add(&mut game.moves, total_moves, new_move);

        let total_boards = table::length(&game.boards);
        table::add(&mut game.boards, total_boards, new_board);
    }

    public fun game_id(game: &ChessGame): &UID {
        &game.id
    }

    public fun player1(game: &ChessGame): &address {
        &game.player1
    }

    public fun player2(game: &ChessGame): &address {
        &game.player2
    }

    public fun move_count(game: &ChessGame): u64 {
        table::length(&game.moves)
    }

    public fun board_at(game: &ChessGame, index: u64): &ChessBoard {
        table::borrow(&game.boards, index)
    }

    public fun board_at_mut(game: &mut ChessGame, index: u64): &mut ChessBoard {
        table::borrow_mut(&mut game.boards, index)
    }

    public fun current_board(game: &ChessGame): &ChessBoard {
        let last_board_index = table::length(&game.boards) - 1;
        board_at(game, last_board_index)
    }

    public fun current_board_mut(game: &mut ChessGame): &mut ChessBoard {
        let last_board_index = table::length(&game.boards) - 1;
        board_at_mut(game, last_board_index)
    }

    public fun piece_at(game: &ChessGame, row: u64, column: u64): ChessPiece {
        let board = current_board(game);
        chess_board::piece_at(board, row, column)
    }

    public fun piece_at_access(game: &ChessGame, row: u64, column: u64): (u8, u8) {
        let board = current_board(game);
        chess_board::piece_at_access(board, row, column)
    }


    public fun current_player(game: &ChessGame): &address {
        &game.current_player
    }

    public fun player_cap_game_id(player_cap: &ChessPlayerCap): &ID {
        &player_cap.game_id
    }

    public fun player_cap_player_number(player_cap: &ChessPlayerCap): &u8 {
        &player_cap.player_number
    }

    public fun winner(game: &ChessGame): &Option<address> {
        &game.winner
    }

    public fun game_over(game: &ChessGame): &bool {
        chess_board::game_over(current_board(game))
    }
}