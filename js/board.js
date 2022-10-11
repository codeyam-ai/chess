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

        if (column.player_number) {
          spaceElement.innerHTML = pieces[`${column.player_number}${column.type}`]
          spaceElement.dataset.player = column.player_number;
          spaceElement.dataset.type = column.type;
        } else {
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

  diff: (spaces1, spaces2, direction) => {
    const reverse = isReverse(direction);
    const vertical = isVertical(direction);

    const tiles = {}
    const columns = spaces1[0].length;

    const start = reverse ? columns - 1 : 0;
    const end = reverse ? 0 : columns - 1;
    const increment = reverse ? -1 : 1;

    for (let i=start; reverse ? i>=end : i<=end; i+=increment) {
      const row1 = spaces1[i];
      for (let j=start; reverse ? j>=end : j<=end; j+=increment) {
        let tile1 = spaces1[i][j];
        const tile2 = spaces2[i][j];
        const index = (i * columns) + j;

        if (tile2 !== 99) {
          if (tile1 === tile2) continue;

          const searchStart = (vertical ? i : j) + increment;
          for (let x=searchStart; reverse ? x>=end : x<=end; x+=increment) {
            const distance = Math.abs(vertical ? x - i : x - j);
            const nextTile = vertical ? spaces1[x][j] : spaces1[i][x]
            
            if (nextTile === 99) continue;
            
            if (vertical) {
              spaces1[x][j] = 99;
            } else {
              spaces1[i][x] = 99;
            }
            
            const tile1Index = vertical ? (x * columns) + j : (i * columns) + x;
            tiles[tile1Index] = {
              [direction]: distance
            }

            if (nextTile === tile2 - 1) {
              tiles[index] = {
                merge: true
              }

              if (tile1 === 99) {
                x = (vertical ? i : j) + increment;
                tile1 = tile2 - 1;
                continue;
              } 
            } 
            break;
          }
        }
      }
    }
    return tiles;
  },

  convertInfo: (board) => {
    const { 
      spaces: rawSpaces, 
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