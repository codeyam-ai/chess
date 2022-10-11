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

  truncateMiddle: (s, length=6) => `${s.slice(0,length)}...${s.slice(length * -1)}`
}

module.exports = utils;
  