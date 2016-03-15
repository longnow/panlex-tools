var dictionaries = require('./lib/dictionaries.js');
var parser = require('./lib/parser.js');
var nametag = require('./lib/nametag.js');

/* Make sure the dictionaries get loaded up front */
console.log('Loading taxonfinder dictionaries...');
dictionaries.load();
console.log('taxonfinder dictionaries are loaded');

var findNamesAndOffsets = function(html, isHtml) {
  return parser.findNamesAndOffsets(html, isHtml);
};

module.exports = {
  findNamesAndOffsets: findNamesAndOffsets,
  nametag: nametag
};
