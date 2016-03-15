var clean = function(string) {
  string = string.replace(/^[^0-9A-Za-z]+/g, '');
  string = string.replace(/[^0-9A-Za-z]+$/g, '');
  return string;
};

var addWordToEndOfOffsetList = function(wordsWithOffsets, word, offset) {
  if (wordsWithOffsets.length === 0) {
    wordsWithOffsets.push({ word: word, offset: offset });
  } else {
    var lastWord = wordsWithOffsets.pop();
    lastWord['word'] += word;
    wordsWithOffsets.push(lastWord);
  }
  return wordsWithOffsets;
};

var explodeText = function(text) {
  var words = text.split(/( |&nbsp;|<|>|\t|\n|\r|;|\.)/i);
  var offset = 0;
  var wordsWithOffsets = [];
  var index = 0;
  for (var i=0 ; i<words.length ; i++) {
    var word = words[i];
    if (word === '') continue;
    if (word === '<') {
      wordsWithOffsets[index] = { word: word, offset: offset };
    } else if (word === '>' || word === '.' || word === ';' || word === ':' || /^\s+$/.test(word)) {
      wordsWithOffsets = addWordToEndOfOffsetList(wordsWithOffsets, word, offset);
    } else {
      if (wordsWithOffsets[index] === undefined) {
        wordsWithOffsets[index] = { word: word, offset: offset };
      } else {
        wordsWithOffsets = addWordToEndOfOffsetList(wordsWithOffsets, word, offset);
      }
      index += 1;
    }
    offset += word.length;
  }
  return wordsWithOffsets;
};

var isStopTag = function(tag) {
  tag = tag.toLowerCase();
  if (tag[0] === '/') tag = tag.substring(1);
  if (tag === 'p' || tag === 'td' || tag === 'tr' || tag === 'table' ||
     tag === 'hr' || tag === 'ul' || tag === 'li') {
    return true;
  }
  return false;
}

var removeTagsFromElements = function(wordsWithOffsets) {
  var withinTag = false;
  var finalWords = [];
  var match = null;
  for (var i=0 ; i<wordsWithOffsets.length ; i++) {
    var word = wordsWithOffsets[i]['word'].trim();
    if (withinTag) {
      // ...tag>
      if (match = word.match(/^(.*)>$/im)) withinTag = false;
      continue;
    }
    // <tag>
    if (match = word.match(/^<(\/?.*[a-z0-9-]\/?)>$/im)) {
      word = match[1];
      if (isStopTag(word)) finalWords.push({ word: null });
      continue;
    }
    // <tag...
    if (match = word.match(/^<([a-z0-9!].*)$/im)) {
      word = match[1];
      if (isStopTag(word)) finalWords.push({ word: null });
      withinTag = true;
      continue;
    }
    finalWords.push(wordsWithOffsets[i]);
  }
  return finalWords;
};

var ucfirst = function(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
};

var extract = function(hash, target) {
  for (var key in hash) {
    target[key] = hash[key];
  }
};

module.exports = {
  clean: clean,
  addWordToEndOfOffsetList: addWordToEndOfOffsetList,
  explodeText: explodeText,
  isStopTag: isStopTag,
  removeTagsFromElements: removeTagsFromElements,
  ucfirst: ucfirst,
  extract: extract
};
