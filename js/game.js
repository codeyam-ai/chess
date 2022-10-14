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

const DASHBOARD_LINK = 'https://ethoswallet.xyz/dashboard';

let walletSigner;
let playerNumber;
let games;
let activeGameAddress;
let walletContents = {};
let contentsInterval;
let selectedPiece;

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

function handleResult(newBoard) { 
  if (!newBoard) {
    showInvalidMoveError()
  }
  board.display(newBoard)
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

async function loadWalletContents() {
  // return;
  if (!walletSigner) return;
  const address = await walletSigner.getAddress();
  eById('wallet-address').innerHTML = truncateMiddle(address, 4);
  walletContents = await ethos.getWalletContents(address, 'sui');
  console.log("WALLET CONTENTS", walletContents)
  const balance = (walletContents.balance || "").toString();

  if (balance < 5000000) {
    console.log("HI BALANCE", balance)
    const success = await ethos.dripSui({ address });
    console.log("HI2", success)
    
    if (success) {
      removeClass(eById('faucet'), 'hidden');
    }
  }

  eById('balance').innerHTML = balance.replace(/\B(?=(\d{3})+(?!\d))/g, ",") + ' SUI';
}

async function loadGames() {
  if (!walletSigner) {
    setTimeout(loadGames, 500);
    return;
  }
  
  const gamesElement = eById('games-list');
  gamesElement.innerHTML = "";
  
  await loadWalletContents();
  
  // const playerCaps = [
  //     {
  //         "gameId": "0x282f75220a945dac998794e82fbd3f40638f583a"
  //     },
  //     {
  //         "gameId": "0x304594c2b29f3a07458b60fc27f3d30f73790b39"
  //     }
  // ];
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

  if (!games || games.length === 0) {
    const newGameArea = document.createElement('DIV');
    newGameArea.classList.add('text-center');
    newGameArea.classList.add('padded');
    newGameArea.innerHTML = `
      <p>
        You don't have any games yet.
      </p>
    `;
    gamesElement.append(newGameArea);
  }
}

async function setActiveGame(game) {
  activeGameAddress = game.address;

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
  removeClass(eById('move-instructions'), 'hidden');
}

async function setPieceToMove(e) {
  let node = e.target;
  while (!node.dataset.player) {
    if (!node.parentNode) break;
    node = node.parentNode;
  }

  if (selectedPiece && selectedPiece !== node) {
    addClass(node, 'destination');
    moves.execute(walletSigner, selectedPiece.dataset, node.dataset, activeGameAddress, handleResult, handleError)
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
      addClass(eById('loading-games'), 'hidden');

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
        setActiveGame(games[0]);
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

    // const response = await ethos.sign({ signer: walletSigner, signData: "YO" });
    // console.log("SIGN", response);
    
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
                boards: [
                  {
                    board_spaces,
                    game_over: false
                  }
                ]
              }
              setActiveGame(game);
              ethos.hideWallet();
            } catch (e) {
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

      // if (games.length === 1) {
        setActiveGame(games[0]);
      // }
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
    addClass(eById('loading-games'), 'hidden');
  }
}

window.requestAnimationFrame(init);