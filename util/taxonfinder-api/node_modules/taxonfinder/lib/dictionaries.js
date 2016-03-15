var fs = require('fs');
var path = require('path');
var hashes = { };
var dictionariesLoaded = false;
var dictionariesToLoad = [
  'dict_ambig',
  'dict_bad',
  'family',
  'family_new',
  'genera',
  'genera_family',
  'genera_new',
  'overlap_new',
  'ranks',
  'species',
  'species_bad',
  'species_new'
];

var addToMasterDictionary = function(words, dictionaryName) {
  var currentWord = null;
  for (var i=0 ; i<words.length ; i++) {
    currentWord = words[i].toLowerCase().trim();
    if (currentWord == '') continue;
    if (hashes[dictionaryName] === undefined) hashes[dictionaryName] = { };
    hashes[dictionaryName][currentWord] = true;
  }
};

var load = function() {
  if (dictionariesLoaded) return true;
  for (var i=0 ; i<dictionariesToLoad.length ; i++) {
    var dictionaryName = dictionariesToLoad[i];
    addToMasterDictionary(fs.readFileSync(path.resolve(__dirname, 'dictionaries', dictionaryName + '.txt')).
      toString().split('\n'), dictionaryName);
  }
  dictionariesLoaded = true;
  return true;
};

module.exports = {
  load: load,
  hashes: hashes
};
