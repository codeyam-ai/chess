const { ethos } = require("ethos-connect");
const { contractAddress } = require("./constants");
const board = require('./board');

const constructTransaction = (selected, destination, activeGameAddress) => {
  return {
    kind: "moveCall",
    data: {
        packageObjectId: contractAddress,
        module: 'chess',
        function: 'make_move',
        typeArguments: [],
        arguments: [
          activeGameAddress,
          selected.row,
          selected.column,
          destination.row,
          destination.column
        ],
        gasBudget: 20000
    }
  }
}

const execute = async (walletSigner, selected, destination, activeGameAddress, onComplete, onError) => {
    const signableTransaction = constructTransaction(selected, destination, activeGameAddress);

    const data = await ethos.transact({
        signer: walletSigner,
        signableTransaction
    });
    
    ethos.hideWallet();

    if (data?.effects?.status?.error === "InsufficientGas") {
        onError({})
        return;
    }

    if (data?.effects?.status?.error) {
        onError({ error: data.effects.status.error })
        return;
    }

    if (data.error) {
        onError({ error: data.error });
        return;
    }

    if (!data) return;
    const { effects } = data;
    const { gasUsed, events} = effects;
    // const { computationCost, storageCost, storageRebate } = gasUsed;

    if (!events) {
        onComplete();
        return;
    }

    const { moveEvent } = events.find((e) => e.moveEvent && e.moveEvent.type.indexOf('ChessMoveEvent') > -1);
    onComplete(board.convertInfo(moveEvent));
    
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

module.exports = {
  constructTransaction,
  execute
};