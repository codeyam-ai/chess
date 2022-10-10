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
const queue = require('./queue');
const board = require('./board');
const moves = require('./moves');

const DASHBOARD_LINK = 'https://ethoswallet.xyz/dashboard';

let walletSigner;
let games;
let activeGameAddress;
let walletContents = {};
let topTile = 2;
let contentsInterval;

window.onkeydown = (e) => {
  let direction;
  switch (e.keyCode) {
    case 37: 
      direction = "left";
      break;
    case 38: 
      direction = "up";
      break;
    case 39: 
      direction = "right";
      break;
    case 40: 
      direction = "down";
      break;
  }
  if (!direction) return;

  e.preventDefault();
  moves.execute(
    direction, 
    activeGameAddress, 
    walletSigner,
    (newBoard, direction) => {
      handleResult(newBoard, direction);
      loadWalletContents();
    },
    (error) => {
      if (error) {
        showUnknownError(error)
      } else {
        showGasError();
      }
    }
  );
}

function init() {
  // test();
  
  const ethosConfiguration = {
    appId: 'sui-8192'
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

function handleResult(newBoard, direction) { 
  const tiles = eByClass('tile');
  const resultDiff = board.diff(board.active().spaces, newBoard.spaces, direction);
 
  const scoreDiff = parseInt(newBoard.score) - parseInt(board.active().score)
  if (scoreDiff > 0) {
    const scoreDiffElement = eById('score-diff');
    scoreDiffElement.innerHTML = `+${scoreDiff}`;
    addClass(scoreDiffElement, 'floating');
    setTimeout(() => {
      removeClass(scoreDiffElement, 'floating');
    }, 2000);
  }

  for (const key of Object.keys(resultDiff)) {
    const resultItem = resultDiff[key];
    const tile = tiles[parseInt(key)];
    
    if (resultItem[direction]) {
      const className = `${direction}${resultItem[direction]}`;
      addClass(tile, className);
      setTimeout(() => {
        removeClass(tile, className);
      }, 500);
    }

    if (resultItem.merge) {
      setTimeout(() => {
        addClass(tile, "merge");
        setTimeout(() => {
          removeClass(tile, "merge");
        }, 500)
      }, 80);
    }
  }

  setTimeout(() => {
    board.display(newBoard)
  }, 150)
}

function showGasError() {
  queue.removeAll()
  removeClass(eById("error-gas"), 'hidden');
}

function showUnknownError(error) {
  queue.removeAll()
  eById('error-unknown-message').innerHTML = error;
  removeClass(eById("error-unknown"), 'hidden');
}

async function loadWalletContents() {
  if (!walletSigner) return;
  const address = await walletSigner.getAddress();
  eById('wallet-address').innerHTML = truncateMiddle(address, 4);
  walletContents = await ethos.getWalletContents(address, 'sui');
  const balance = (walletContents.balance || "").toString();

  if (balance < 5000000) {
    const success = await ethos.dripSui({ address });
    
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
  removeClass(eById('loading-games'), 'hidden');

  const gamesElement = eById('games-list');
  gamesElement.innerHTML = "";
  
  await loadWalletContents();
  
  addClass(eById('loading-games'), 'hidden');
  
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
      return fields;
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
  
  moves.load(
    walletSigner,
    activeGameAddress,
    (newBoard, direction) => {
      handleResult(newBoard, direction);
      loadWalletContents();
    },
    (error) => {
      if (error) {
        showUnknownError(error)
      } else {
        showGasError();
      }
    }
  );

  const boards = game.boards;
  const activeBoard = board.convertInfo(boards[boards.length - 1]);
  topTile = activeBoard.topTile || 2;
  board.display(activeBoard);

  modal.close();
  removeClass(eById("game"), 'hidden');
  addClass(eByClass('play-button'), 'selected')
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
            modal.open('loading', 'container');

            const details = {
              network: 'sui',
              address: contractAddress,
              moduleName: 'chess',
              functionName: 'create_game',
              inputValues: ["0xede0572dbe60ac1c2210715aefc5818d73995bea"],
              gasBudget: 5000
            };
        
            try {
              const data = await ethos.transact({
                signer: walletSigner, 
                details
              })

              console.log("DATA", data);

              if (!data) {
                modal.open('create-error', 'container');
                return;
              }

              const gameData = data.effects.events.find(
                e => e.moveEvent
              ).moveEvent.fields;
              const { board_spaces, score } = gameData;
              const game = {
                address: data.effects.created[0].reference.objectId,
                boards: [
                  {
                    score,
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
    console.log("GAMES", games);

    if (!contentsInterval) {
      contentsInterval = setInterval(loadWalletContents, 3000)
    }

    if (games.length === 0) {
      modal.open('mint', 'board', true);  
    } else {
      modal.close();

      if (games.length === 1) {
        setActiveGame(games[0]);
      }
    }
    
    removeClass(document.body, 'signed-out');

    const address = await signer.getAddress();

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












/// FOR TESTING ///

// function print(board) {
//   const rows = board.length;
  
//   const printRows = []
//   for (let i=0; i<rows; ++i) {
//     printRows.push(board[i].join(','));
//   }
//   console.log(printRows.join('\n'));
// }

// function test() {
//   const boardStart = [
//     [0,  0,  99, 99],
//     [99, 99, 1,  99],
//     [0,  0,  1,  99],
//     [1,  99, 1,  99]
//   ]
  
//   const boardLeft = [
//     [1,  99, 99, 99],
//     [1,  99, 99, 99],
//     [1,  1,  99, 99],
//     [2,  99, 99, 99]
//   ]
  
//   const boardRight = [
//     [99, 99, 99, 1],
//     [99, 99, 99, 1],
//     [99, 99, 1,  1],
//     [99, 99, 99, 2]
//   ]
  
//   const boardUp = [
//     [1,  1,  2,  99],
//     [1,  99, 1,  99],
//     [99, 99, 99, 99],
//     [99, 99, 99, 99]
//   ]
  
//   const boardDown = [
//     [99, 99, 99, 99],
//     [99, 99, 99, 99],
//     [1,  99, 1,  99],
//     [1,  1,  2,  99]
//   ]

//   const tests = [{
//     direction: "left",
//     board1: boardStart,
//     board2: boardLeft,
//     result: {"0":{"merge":true},"1":{"left":1},"6":{"left":2},"8":{"merge":true},"9":{"left":1},"10":{"left":1},"12":{"merge":true},"14":{"left":2}}
//   }, {
//     direction: "right",
//     board1: boardStart,
//     board2: boardRight,
//     result: {"0":{"right":3},"1":{"right":2},"3":{"merge":true},"6":{"right":1},"8":{"right":2},"9":{"right":1},"10":{"merge":true},"12":{"right":3},"14":{"right":1},"15":{"merge":true}}
//   },{        
//     direction: "up",
//     board1: boardStart,
//     board2: boardUp,
//     result: {"0":{"merge":true},"1":{"merge":true},"2":{"merge":true},"6":{"up":1},"8":{"up":2},"9":{"up":2},"10":{"up":2},"12":{"up":2},"14":{"up":2}}
//   }, {
//     direction: "down",
//     board1: boardStart,
//     board2: boardDown,
//     result: {"0":{"down":2},"1":{"down":3},"6":{"down":1},"8":{"merge":true},"9":{"down":1},"10":{"down":1},"13":{"merge":true},"14":{"merge":true}}   
//   }, {
//     direction: "down",
//     board1: [
//       [1, 1, 99,99],
//       [99,99,99,99],
//       [1, 99,99,99],
//       [99,99,99,99]
//     ],
//     board2: [
//       [99,99,99,99],
//       [99,99,99,99],
//       [1, 99,99,99],
//       [2, 1, 99,99]
//     ],
//     result: {"0":{"down":3},"1":{"down":3},"8":{"down":1},"12":{"merge":true}}
//   }]

//   for (const t of tests) {
//     const { direction, board1: rawBoard1, board2, result } = t;
//     const board1 = rawBoard1.map(c => [...c])
//     const actualResult = board.diff(board1, board2, direction)
//     for (const key of Object.keys(result)) {
//       if (actualResult[key].merge !== result[key].merge || actualResult[key][direction] !== result[key][direction]) {
//         console.log("TEST FAILED!", key)
//       }
//     }
//   }
// }