const { ethos } = require("ethos-connect-staging");
const { contractAddress } = require("./constants");
const board = require('./board');

let moves = {};

const constructTransaction = (selected, destination, activeGameAddress) => {
  return {
    network: 'sui',
    address: contractAddress,
    moduleName: 'chess',
    functionName: 'make_move',
    inputValues: [
      activeGameAddress,
      selected.row,
      selected.column,
      destination.row,
      destination.column
    ],
    gasBudget: 20000
  }
}

const execute = async (walletSigner, selected, destination, activeGameAddress, onComplete, onError) => {
  const details = constructTransaction(selected, destination, activeGameAddress);

  ethos.transact({
    id: 'move',
    signer: walletSigner, 
    details,
    onCompleted: async ({ data }) => {
      ethos.hideWallet();

      if (data?.effects?.status?.error === "InsufficientGas") {
        onError()
        return;
      }

      if (data.error) {
        onError(data.error);
        return;
      }

      if (!data) return;
      const { effects } = data;
      const { gasUsed, events} = effects;
      const { computationCost, storageCost, storageRebate } = gasUsed;

      if (!events) {
        onComplete();
        return;
      }

      let event
      if (events.length === 2) {
        onComplete(events[0].moveEvent.fields);
        event = events[1].moveEvent;
      } else {
        event = events[0].moveEvent;
      }
      
      onComplete(board.convertInfo(event));
      
      // const { fields } = event;
      // const { last_tile: lastTile } = fields;
      // const transaction = {
      //   gas: computationCost + storageCost - storageRebate,
      //   computation: computationCost,
      //   storage: storageCost - storageRebate,
      //   move: fields.direction,
      //   lastTile: {
      //     row: lastTile[0],
      //     column: fields.last_tile[1]
      //   },
      //   moveCount: fields.move_count
      // };

      // const transactionElement = document.createElement("DIV");
      // addClass(transactionElement, 'transaction');
      // transactionElement.innerHTML = `
      //   <div class='transaction-left'>
      //     <div class='transaction-count'>
      //       ${transaction.moveCount + 1}
      //     </div>
      //     <div class='transaction-direction'>
      //       ${directionNumberToSymbol(transaction.move.toString())}
      //     </div>
      //   </div>
      //   <div class="transaction-right">
      //     <div class=''>
      //       <span class="light">
      //         Computation:
      //       </span>
      //       <span>
      //         ${transaction.computation}
      //       </span>
      //     </div>
      //     <div class=''>
      //       <span class="light">
      //         Storage:
      //       </span>
      //       <span>
      //         ${transaction.storage}
      //       </span>
      //     </div>
      //     <div class=''>
      //       <span class='light'>
      //         Gas:
      //       </span>
      //       <span class=''>
      //         ${transaction.gas}
      //       </span>
      //     </div>
      //   </div>
      // `;

      // eById('transactions-list').prepend(transactionElement);
      // removeClass(eById('transactions'), 'hidden');
    }
  })
}

const reset = () => moves = []

module.exports = {
  constructTransaction,
  execute,
  reset
};