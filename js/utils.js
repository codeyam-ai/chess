const BigNumber = require('bignumber.js');

const utils = {
  eById: (id) => document.getElementById(id),
  
  eByClass: (className) => document.getElementsByClassName(className),

  toArray: (itemOrItems) => {
    const itemsArray = Array.isArray(itemOrItems) || itemOrItems instanceof HTMLCollection ? 
      itemOrItems : 
      [itemOrItems];
    return itemsArray;
  },

  addClass: (elementOrElements, className) => {
    const allElements = utils.toArray(elementOrElements) 
    for (const element of allElements) {
      element.classList.add(className)
    }
  },

  removeClass: (elementOrElements, classNameOrNames) => {
    const allClassNames = utils.toArray(classNameOrNames) 
    const allElements = utils.toArray(elementOrElements) 
    for (const element of allElements) {
      element.classList.remove(...allClassNames)
    }
  },

  setOnClick: (elementOrElements, onClick) => {
    const allElements = utils.toArray(elementOrElements) 
    for (const element of allElements) {
      element.onclick = onClick;
    }
  },

  truncateMiddle: (s, length=6) => `${s.slice(0,length)}...${s.slice(length * -1)}`,

  formatBalance: (balance, decimals) => {
    if (!balance) return '---';
    
    let postfix = '';
    let bn = new BigNumber(balance.toString()).shiftedBy(-1 * decimals);

    if (bn.gte(1_000_000_000)) {
        bn = bn.shiftedBy(-9);
        postfix = ' B';
    } else if (bn.gte(1_000_000)) {
        bn = bn.shiftedBy(-6);
        postfix = ' M';
    } else if (bn.gte(10_000)) {
        bn = bn.shiftedBy(-3);
        postfix = ' K';
    }

    if (bn.gte(1)) {
        bn = bn.decimalPlaces(3, BigNumber.ROUND_DOWN);
    } else {
        bn = bn.decimalPlaces(6, BigNumber.ROUND_DOWN);
    }

    return bn.toFormat() + postfix;
  }
}

module.exports = utils;
  