var expect = require('chai').expect,
    utility = require('../lib/utility'),
    clean = utility.clean,
    addWordToEndOfOffsetList = utility.addWordToEndOfOffsetList,
    isStopTag = utility.isStopTag,
    explodeText = utility.explodeText,
    removeTagsFromElements = utility.removeTagsFromElements,
    ucfirst = utility.ucfirst;

describe('#clean', function() {
  it('removes non-characters from beginning and ends of lines', function() {
    expect(clean("---abc")).to.eql("abc");
    expect(clean("abc---")).to.eql("abc");
    expect(clean("---abc---")).to.eql("abc");
  });
});

describe('#addWordToEndOfOffsetList', function() {
  it('appends strings to the end of the list', function() {
    var offsetList = [ { word: 'Abc', offset: 101 } ];
    addWordToEndOfOffsetList(offsetList, 'def');
    expect(offsetList[0]['word']).to.eq('Abcdef');
    expect(offsetList[0]['offset']).to.eq(101);
  });
  it('appends strings to the end of the list even when its empty', function() {
    var offsetList = [];
    addWordToEndOfOffsetList(offsetList, '', 101);
    expect(offsetList[0]['word']).to.eq('');
    expect(offsetList[0]['offset']).to.eq(101);
  });
});

describe('#isStopTag', function() {
  it('know valid stop tags', function() {
    expect(isStopTag('p')).to.be.true;
    expect(isStopTag('td')).to.be.true;
    expect(isStopTag('tr')).to.be.true;
    expect(isStopTag('table')).to.be.true;
    expect(isStopTag('hr')).to.be.true;
    expect(isStopTag('ul')).to.be.true;
    expect(isStopTag('li')).to.be.true;
    expect(isStopTag('/p')).to.be.true;
  });

  it('knows invalid stop tags', function() {
    expect(isStopTag('paragraph')).to.be.false;
    expect(isStopTag('\\p')).to.be.false;
    expect(isStopTag('img')).to.be.false;
    expect(isStopTag('/img')).to.be.false;
  });
});

describe('#removeTagsFromElements', function() {
  it('does nothing with plain text', function() {
    var result = removeTagsFromElements([{ word: 'hello' }]);
    expect(result.length).to.eq(1);
    expect(result[0]['word']).to.eq('hello');
  });
  it('replaces complete blocker tags with null', function() {
    var result = removeTagsFromElements([{ word: '<p>' }]);
    expect(result.length).to.eq(1);
    expect(result[0]['word']).to.be.null;
  });
  it('replaces split blocker tags with null', function() {
    var result = removeTagsFromElements([{ word: '<p' }, { word: 'class="b"' }, { word: '>' }]);
    expect(result.length).to.eq(1);
    expect(result[0]['word']).to.be.null;
  });
  it('removes complete non-blocker tags', function() {
    var result = removeTagsFromElements([{ word: '<span>' }]);
    expect(result).to.be.empty;
  });
  it('removes split non-blocker tags', function() {
    var result = removeTagsFromElements([{ word: '<span' }, { word: 'class="b"' }, { word: '>' }]);
    expect(result).to.be.empty;
  });
});

describe('#explodeText', function() {
  it('does something', function() {
    var result = explodeText('<p class="say">Hello. Goodbye</code>');
    expect(result[0]['word']).to.eq('<p ');
    expect(result[0]['offset']).to.eq(0);
    expect(result[1]['word']).to.eq('class="say">');
    expect(result[1]['offset']).to.eq(3);
    expect(result[2]['word']).to.eq('Hello. ');
    expect(result[2]['offset']).to.eq(15);
    expect(result[3]['word']).to.eq('Goodbye');
    expect(result[3]['offset']).to.eq(22);
    expect(result[4]['word']).to.eq('</code>');
    expect(result[4]['offset']).to.eq(29);
  });
});

describe('#ucfirst', function() {
  it('capitalizes the first letter', function() {
    expect(ucfirst('lower')).to.eq('Lower');
  });
});
