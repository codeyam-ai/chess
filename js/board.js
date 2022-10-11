const { pieces } = require("./constants");
const { eById, eByClass, addClass, removeClass, isReverse, isVertical } = require("./utils");

let active;

module.exports = {
  active: () => active,

  display: (board) => {
    const spaces = board.spaces
    const spaceElements = eByClass('tile-wrapper');
    
    for (let i=0; i<spaces.length; ++i) {
      const row = spaces[i];

      for (let j=0; j<row.length; ++j) {
        const column = row[j];
        const spaceElement = spaceElements[(i * spaces.length) + j];

        spaceElement.dataset.row = i;
        spaceElement.dataset.column = j;

        removeClass(spaceElement, ['selected', 'destination']);
        if (column.player_number) {
          spaceElement.innerHTML = pieces[`${column.player_number}${column.type}`]
          spaceElement.dataset.player = column.player_number;
          spaceElement.dataset.type = column.type;
        } else {
          spaceElement.innerHTML = '';
          spaceElement.dataset.player = null;
          spaceElement.dataset.type = null;
        }
        
      }
    }

    active = board;
  },
  
  clear: () => {
    const tiles = eByClass('tile');
    for (const tile of tiles) {
      tile.innerHTML = "";
    }
  },

  convertInfo: (board) => {
    const { 
      spaces: rawSpaces, 
      board_spaces: rawBoardSpaces, 
      game_over: gameOver
    } = board.fields || board;
    const spaces = (rawSpaces || rawBoardSpaces).map(
      (rawRow) => rawRow.map(
        (rawSpace) => {
          return rawSpace.fields
        }
      )
    )
    return { spaces, gameOver }
  }
}