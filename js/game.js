const React = require('react');
const ReactDOM = require('react-dom/client');
const { EthosWrapper, SignInButton, ethos } = require('ethos-connect');
const { JsonRpcProvider, Network } = require("@mysten/sui.js");

const { contractAddress } = require('./constants');
const { 
  eById, 
  eByClass, 
  addClass, 
  removeClass,
  truncateMiddle,
  setOnClick,
  formatBalance
} = require('./utils');
const modal = require('./modal');
const board = require('./board');
const moves = require('./moves');

const DASHBOARD_LINK = 'https://ethoswallet.xyz/dashboard';

let walletSigner;
let isCurrentPlayer;
let games;
let activeGame;
let walletContents = {};
let contentsInterval;
let selectedPiece;
let faucetUsed = false;

function init() {
  // test();
  
  const ethosConfiguration = {
    appId: 'ethos-chess'
  };

  const start = eById('ethos-start');
  const button = React.createElement(
    SignInButton,
    {
      key: 'sign-in-button',
      className: 'start-button',
      children: "Sign In"
    }
  )

  const wrapper = React.createElement(
    EthosWrapper,
    {
      ethosConfiguration,
      onWalletConnected,
      children: [button]
    }
  )

  const root = ReactDOM.createRoot(start);
  root.render(wrapper);
  
  initializeClicks();
}

async function pollForNextMove() {
  if (!walletSigner) return;

  const provider = new JsonRpcProvider(Network.DEVNET);
  const sharedObject = await provider.getObject(activeGame.address);
  const address = await walletSigner.getAddress()

  const { details: { data: { fields: game } } } = sharedObject;

  if (game.current_player === address) {
    isCurrentPlayer = true;
    removeClass(eById('current-player'), 'hidden');
    addClass(eById('not-current-player'), 'hidden')

    const boards = game.boards;
    const activeBoard = board.convertInfo(boards[boards.length - 1]);
    const gameInGames = games.find(
        (g) => g.address === activeGame.address
    )
    gameInGames.boards.push(activeBoard);
    gameInGames.current_player = address;
    board.display(activeBoard, game.player1 === address);

    if (game.winner && !game.winner?.fields) {
      if (game.winner === address) {
        modal.open("you-winner", 'board')
      } else {
        modal.open("opponent-winner", 'board')
      }
    }
  } else {
    setTimeout(pollForNextMove, 3000);
  }
}

async function handleResult(newBoard) { 
  const address = await walletSigner.getAddress();
  selectedPiece = null;

  if (!newBoard) {
    showInvalidMoveError();
    removeClass(eByClass('selected'), 'selected')
    removeClass(eByClass('destination'), 'destination')
    return;
  }

  if (newBoard.gameOver || (newBoard.winner && !newBoard.winner?.fields)) {
    if (newBoard.winner === address) {
      modal.open("you-winner", 'board')
    } else {
      modal.open("opponent-winner", 'board')
    }
    return;
  }

  isCurrentPlayer = false;
  addClass(eById('current-player'), 'hidden');
  removeClass(eById('not-current-player'), 'hidden')

  board.display(newBoard, activeGame.player1 === address);
  const game = games.find(
    (g) => g.address === activeGame.address
  )
  game.current_player = game.current_player === game.player1 ? game.player2 : game.player1;
  game.boards.push(newBoard)
  listGames();

  pollForNextMove();
}

function handleError({ gameOver, error }) {
    if (!error) {
        showGasError();
        return;
    }

    if (error.indexOf(`Identifier("chess_board") }, 1`) > -1) {
        showInvalidMoveError();
        reset();
        return;
    }

    eById('error-unknown-message').innerHTML = error;
    removeClass(eById("error-unknown"), 'hidden');
}

function showGasError() {
  removeClass(eById("error-gas"), 'hidden');
}

function showInvalidMoveError() {
  removeClass(eById("error-invalid-move"), 'hidden');
}

function showNotYourTurnError() {
  removeClass(eById("error-not-your-turn"), 'hidden');
}

async function tryDrip(address, balance) {
  if (!walletSigner || faucetUsed) return;

  faucetUsed = true;

  let success;
  try {
    success = await ethos.dripSui({ address });
  } catch (e) {
    console.log("Error with drip", e);
    faucetUsed = false;
    return;
  }

  if (!success) {
    const { balance: balanceCheck } = await ethos.getWalletContents(address, 'sui')
    if (balance !== balanceCheck) {
      success = true;      
    }
  }

  if (success) {
    removeClass(eById('faucet'), 'hidden');
    faucetUsed = true;
    loadWalletContents();
  }
}

async function loadWalletContents() {
  // return;
  if (!walletSigner) return;
  const address = await walletSigner.getAddress();
  eById('wallet-address').innerHTML = truncateMiddle(address, 4);
  walletContents = await ethos.getWalletContents(address, 'sui');
  const balance = (walletContents.suiBalance || "").toString();

  if (balance < 5000000) {
    tryDrip(address, balance);
  }

  eById('balance').innerHTML = formatBalance(balance, 9) + ' SUI';
}

async function loadGames() {
  if (!walletSigner) {
    setTimeout(loadGames, 500);
    return;
  }
  
  await loadWalletContents();

  const playerCaps = walletContents.nfts.filter(
    (nft) => nft.package === contractAddress
  ).map(
    (nft) => ({
      gameId: nft.extraFields.game_id
    })
  );

  const provider = new JsonRpcProvider(Network.DEVNET);
  const sharedObjects = await provider.getObjectBatch(playerCaps.map(p => p.gameId));

  games = sharedObjects.map(
    (sharedObject) => {
      const { details: { data: { fields } } } = sharedObject;
      return {
        ...fields,
        address: fields.id.id
      };
    }
  )

  listGames();
}

async function listGames() {
  const gamesList = eById('games-list');
  if (games.length < 2) {
    addClass(gamesList, 'hidden')
    return;
  } else {
    removeClass(gamesList, 'hidden')
  }
  
  const address = await walletSigner.getAddress();

  const gamesListList = eById('games-list-list');
  gamesListList.innerHTML = "";

  const sortedGames = games.sort((a, b) => a.winner && b.winner ? 0 : (a.winner ? 1 : -1))
  for (const game of sortedGames) {
    const gameItem = document.createElement("DIV");
    addClass(gameItem, 'game-item')
    gameItem.id = `game-${game.address}`;
    const otherPlayer = game.player1 === address ? game.player2 : game.player1;
    const turn = game.current_player === address ? "Your Turn" : "Opponent's Turn";
    const winLose = game.winner ? (
      game.winner === address ? "You Won!" : "You Lost"
    ) : null;
    gameItem.innerHTML = `
      <div>
        <div>
          Game vs. ${truncateMiddle(otherPlayer, 6)}
        </div>
        <div>
          ${winLose || turn}
        </div>
        <div>
          <button id='game-${game.address}' class='primary-button'>Switch</button>
        </div>
      </div>
    `;
    setOnClick(gameItem, () => setActiveGame(game));

    gamesListList.append(gameItem);
  }
}

function reset() {
    removeClass(eByClass('destination'), 'destination');
    removeClass(eByClass('selected'), 'selected');
    selectedPiece = null;
}

async function setActiveGame(game) {
  const address = await walletSigner.getAddress();
  activeGame = game;

  removeClass(eByClass('game-item'), 'hidden');
  
  const activeGameItem = eById(`game-${game.address}`);
  if (activeGameItem) {
    addClass(activeGameItem, 'hidden');
  } 

  if (game.winner && !game.winner?.fields) {
    if (game.winner === address) {
      modal.open("you-winner", 'board')
    } else {
      modal.open("opponent-winner", 'board')
    }
    return;
  }
  
  const playerColor = game.player1 === address ? 'white' : 'black';
  eById('player-color').innerHTML = playerColor;
 
  if (game.current_player === address) {
    isCurrentPlayer = true;
    addClass(eById('not-current-player'), 'hidden');
    removeClass(eById('current-player'), 'hidden');
  } else {
    addClass(eById('current-player'), 'hidden');
    removeClass(eById('not-current-player'), 'hidden');
    pollForNextMove();
  }

  eById('transactions-list').innerHTML = "";
  
  const boards = game.boards;
  const activeBoard = board.convertInfo(boards[boards.length - 1]);

  board.display(activeBoard, game.player1 === address);
  setOnClick(eByClass('tile-wrapper'), setPieceToMove)

  modal.close();
  removeClass(eById("game"), 'hidden');
  addClass(eByClass('play-button'), 'selected')
  addClass(eById('verifiable-top'), 'hidden');
  removeClass(eById('verifiable-bottom'), 'hidden');
}

async function setPieceToMove(e) {
  if (!isCurrentPlayer) {
    showNotYourTurnError();
    return;
  }

  let node = e.target;
  while (!node.dataset.player) {
    if (!node.parentNode) break;
    node = node.parentNode;
  }

  if (selectedPiece && selectedPiece !== node) {
    addClass(node, 'destination');
    moves.execute(walletSigner, selectedPiece.dataset, node.dataset, activeGame.address, handleResult, handleError)
  } else if (selectedPiece === node) {
    removeClass(node, 'selected');
    selectedPiece = null;
  } else {
    addClass(node, 'selected');
    selectedPiece = node;
  }
}

const initializeClicks = () => {
  setOnClick(eByClass('close-error'), () => {
    addClass(eByClass('error'), 'hidden');
  })
  setOnClick(eById('sign-in'), ethos.showSignInModal);
  setOnClick(eByClass('title'), ethos.showWallet)
  
  setOnClick(
    eById('balance'), 
    () => window.open(DASHBOARD_LINK)
  )
  setOnClick(
    eById('wallet-address'), 
    () => window.open(DASHBOARD_LINK)
  )

  setOnClick(
    eById('logout'),
    async (e) => {
      e.stopPropagation();
      await ethos.logout(walletSigner);
      window.location.reload();
    //   walletSigner = null;
    //   games = null;
    //   activeGame = null;
    //   walletContents = {};

    //   addClass(document.body, 'signed-out');
    //   removeClass(document.body, 'signed-in');
    //   removeClass(eById('game'), 'hidden');
      
    //   board.clear();
      
    //   modal.open('get-started', 'board', true);
    }
  );

  setOnClick(eById('close-modal'), () => modal.close(true));

  setOnClick(
    eByClass('play-button'), 
    () => {
      if (games && games.length > 0) {
        removeClass(eById('game'), 'hidden');
        setActiveGame(games.filter(g => !g.winner)[0] || games[0]);
      } else if (walletSigner) {
        eByClass('new-game')[0].onclick();
      } else {
        ethos.showSignInModal();
      }
    }
  );

  setOnClick(eByClass('keep-playing'), modal.close);

  setOnClick(eById('close-faucet'), () => {
    addClass(eById('faucet'), 'hidden')
  })
}

const onWalletConnected = async ({ signer }) => {
  walletSigner = signer;
  if (signer) {
    const address = await signer.getAddress();
    modal.close();
  
    addClass(document.body, 'signed-in');
    
    const prepMint = async () => {
      const mint = eById('mint-game');
      const mintButtonTitle = "Mint New Game";
      if (mint.innerHTML.indexOf(mintButtonTitle) === -1) {
        const mintButton = document.createElement("BUTTON");
        setOnClick(
          mintButton,
          async () => {
            const player2 = eById('player2-address').value;
            if (!player2 || player2.length === 0 || player2 === address) {
              removeClass(eById('player2-error'), 'hidden');
              return;
            } else {
              addClass(eById('player2-error'), 'hidden');
            }

            modal.open('loading', 'container');

            const signableTransaction = {
                kind: "moveCall",
                data: {
                    packageObjectId: contractAddress,
                    module: 'chess',
                    function: 'create_game',
                    typeArguments: [],
                    arguments: [player2],
                    gasBudget: 5000
                }
            };
        
            try {
              const data = await ethos.transact({
                signer: walletSigner, 
                signableTransaction
              })

              if (!data) {
                modal.open('create-error', 'container');
                return;
              }

              const gameData = data.effects.events.find(
                e => e.moveEvent
              ).moveEvent.fields;
              const { game_id, player1, player2, board_spaces } = gameData;
              const game = {
                address: game_id,
                player1,
                player2,
                current_player: address,
                winner: null,
                boards: [
                  {
                    board_spaces,
                    game_over: false
                  }
                ]
              }
              
              games.push(game);
              await listGames();
              setActiveGame(game);
              ethos.hideWallet();
            } catch (e) {
              console.log("Error creating new game", e);
              modal.open('create-error', 'container');
              return;
            }
          }
        );
        mintButton.innerHTML = mintButtonTitle;
        mint.appendChild(mintButton);
      }
    }

    prepMint();
    modal.open('loading', 'container');

    setOnClick(
      eByClass('new-game'),
      async () => {
        modal.open('mint', 'container');
      }
    );
    
    await loadGames();
   
    if (!contentsInterval) {
      contentsInterval = setInterval(loadWalletContents, 3000)
    }

    if (games.length === 0) {
      modal.open('mint', 'board', true);  
    } else {
      modal.close();
      setActiveGame(games.filter(g => !g.winner)[0] || games[0]);
    }
    
    removeClass(document.body, 'signed-out');

    setOnClick(
      eById('copy-address'),
      () => {
        const innerHTML = eById('copy-address').innerHTML;
        eById('copy-address').innerHTML = "Copied!"
        navigator.clipboard.writeText(address)
        setTimeout(() => {
          eById('copy-address').innerHTML = innerHTML;
        }, 1000);
      }
    );
  } else {
    modal.open('get-started', 'board', true);
    setOnClick(eByClass('new-game'), ethos.showSignInModal)
    addClass(document.body, 'signed-out');
    removeClass(document.body, 'signed-in');
  }
}

window.requestAnimationFrame(init);