const React = require('react');
const ReactDOM = require('react-dom/client');
const { EthosWrapper, SignInButton, ethos } = require('ethos-wallet-beta');
const { JsonRpcProvider } = require("@mysten/sui.js");

const { contractAddress } = require('./constants');
const { 
  eById, 
  eByClass, 
  addClass, 
  removeClass,
  truncateMiddle,
  setOnClick
} = require('./utils');
const modal = require('./modal');
const board = require('./board');
const moves = require('./moves');
const { active } = require('./board');

const DASHBOARD_LINK = 'https://ethoswallet.xyz/dashboard';

let walletSigner;
let isCurrentPlayer;
let games;
let activeGameAddress;
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

  const provider = new JsonRpcProvider('https://gateway.devnet.sui.io/');
  const sharedObject = await provider.getObject(activeGameAddress);
  const address = await walletSigner.getAddress()

  const { details: { data: { fields: game } } } = sharedObject;

  if (game.current_player === address) {
    isCurrentPlayer = true;
    removeClass(eById('current-player'), 'hidden');
    addClass(eById('not-current-player'), 'hidden')

    const boards = game.boards;
    const activeBoard = board.convertInfo(boards[boards.length - 1]);
    board.display(activeBoard);

    if (!game.winner.fields) {
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
  selectedPiece = null;

  if (!newBoard) {
    showInvalidMoveError();
    removeClass(eByClass('selected'), 'selected')
    removeClass(eByClass('destination'), 'destination')
    return;
  }
  
  if (newBoard.gameOver) {
    const address = await walletSigner.getAddress();
    if (newBoard.winner === address) {
      modal.open("you-winner", 'board')
    } else {
      modal.open("opponent-winner", 'board')
    }
  }

  isCurrentPlayer = false;
  addClass(eById('current-player'), 'hidden');
  removeClass(eById('not-current-player'), 'hidden')

  board.display(newBoard)

  pollForNextMove();
}

function handleError(error) {
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

async function syncAccountState() {
  if (!walletSigner) return;
  const address =  await walletSigner.getAddress();
  const provider = new JsonRpcProvider('https://gateway.devnet.sui.io/');
  await provider.syncAccountState(address);
}

async function tryDrip() {
  if (!walletSigner || faucetUsed) return;

  faucetUsed = true;

  const address =  await walletSigner.getAddress();

  let success;
  try {
    success = await ethos.dripSui({ address });
  } catch (e) {
    console.log("Error with drip", e);
    faucetUsed = false;
    return;
  }

  try {
    await syncAccountState();
  } catch (e) {
    console.log("Error with syncing account state", e);
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
  const balance = (walletContents.balance || "").toString();

  if (balance < 5000000) {
    tryDrip(address);
  }

  eById('balance').innerHTML = balance.replace(/\B(?=(\d{3})+(?!\d))/g, ",") + ' SUI';
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

  const provider = new JsonRpcProvider('https://gateway.devnet.sui.io/');
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

  // for (const gameItem of eByClass('game-item')) {
  //   gameItem.parentNode.remove(gameItem);
  // }

  for (const game of games) {
    const gameItem = document.createElement("DIV");
    addClass(gameItem, 'game-item')
    gameItem.id = `game-${game.address}`;
    const otherPlayer = game.player1 === address ? game.player2 : game.player1;
    const turn = game.current_player === address ? "Your Turn" : "Opponent's Turn";
    const winLose = game.winner?.fields ? null : (
      game.winner === address ? "You Won!" : "You Lost"
    );
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

    gamesList.append(gameItem);
  }
}

async function setActiveGame(game) {
  const address = await walletSigner.getAddress();
  activeGameAddress = game.address;

  removeClass(eByClass('game-item'), 'hidden');
  
  const activeGameItem = eById(`game-${game.address}`);
  if (activeGameItem) {
    addClass(activeGameItem, 'hidden');
  } 

  if (game.winner && !game.winner.fields) {
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
  moves.reset();
  
  const boards = game.boards;
  const activeBoard = board.convertInfo(boards[boards.length - 1]);

  board.display(activeBoard);
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
    moves.execute(walletSigner, selectedPiece.dataset, node.dataset, activeGameAddress, handleResult, handleError)
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
      walletSigner = null;
      games = null;
      activeGameAddress = null;
      walletContents = {};

      addClass(document.body, 'signed-out');
      removeClass(document.body, 'signed-in');
      removeClass(eById('game'), 'hidden');
      
      board.clear();
      
      modal.open('get-started', 'board', true);
    }
  );

  setOnClick(eById('close-modal'), () => modal.close(true));

  setOnClick(
    eByClass('play-button'), 
    () => {
      if (games && games.length > 0) {
        removeClass(eById('game'), 'hidden');
        setActiveGame(games.filter(g => !!g.winner.fields)[0] || games[0]);
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

            const details = {
              network: 'sui',
              address: contractAddress,
              moduleName: 'chess',
              functionName: 'create_game',
              inputValues: [player2],
              gasBudget: 5000
            };
        
            try {
              const data = await ethos.transact({
                signer: walletSigner, 
                details
              })

              if (!data) {
                modal.open('create-error', 'container');
                return;
              }

              const gameData = data.effects.events.find(
                e => e.moveEvent
              ).moveEvent.fields;
              const { board_spaces } = gameData;
              const game = {
                address: data.effects.created[0].reference.objectId,
                player1: address,
                player2,
                current_player: address,
                winner: { fields: {} },
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
      setActiveGame(games.filter(g => !!g.winner.fields)[0] || games[0]);
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