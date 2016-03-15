var parser = require('./parser');

var tagText = function(text, isHtml) {
  var lengthOfInjectedText = 0;
  var startTag = "<name>";
  var endTag = "</name>";
  var namesAndOffsets = parser.findNamesAndOffsets(text, isHtml);
  for(var i=0 ; i<namesAndOffsets.length ; i++) {
    startTag = '<name found="' + namesAndOffsets[i]['name'] + '"';
    if (namesAndOffsets[i]['original']) {
      startTag += ' original="' + namesAndOffsets[i]['original'] + '"';
    }
    startTag += '>';
    text = injectString(text, startTag, namesAndOffsets[i]['offsets'][0] + lengthOfInjectedText);
    lengthOfInjectedText += startTag.length;
    text = injectString(text, endTag, namesAndOffsets[i]['offsets'][1] + lengthOfInjectedText);
    lengthOfInjectedText += endTag.length;
  }
  // TODO: trying to clean up tags within tags. This is sloppy
  text = text.replace(/(<name[^>]+>[^<]*?)(<\/[a-mo-z].*?>)/img, '$2$1');
  text = text.replace(/(<name[^>]+>[^<]*)(<[a-z].*?>)(.*?<\/name>)/img, '$2$1$3');
  text = text.replace(/(<name[^>]+>[^<]*?)(<\/[a-mo-z].*?>)/img, '$2$1');
  text = text.replace(/(<name[^>]+>[^<]*)(<[a-z].*?>)(.*?<\/name>)/img, '$2$1$3');
  return text;
};

var injectString = function(sourceString, injection, atIndex) {
  return sourceString.substr(0, atIndex) + injection + sourceString.substr(atIndex);
};

module.exports = {
  tagText: tagText,
  injectString: injectString
};
