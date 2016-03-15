var expect = require('chai').expect,
    fs = require('fs'),
    nametag = require('../lib/nametag'),
    tagText = nametag.tagText,
    injectString = nametag.injectString;

// describe('#checksATestDocument', function() {
//   it('logs the results of a run against a test file', function() {
//     console.log(tagText(fs.readFileSync('test.txt').toString()));
//   });
// });

describe('#tagText', function() {
  it('tags names in text', function() {
    expect(tagText('A Felis leo was here')).to.
      eq('A <name found="Felis leo">Felis leo</name> was here');
  });
  it('tags abbreviated names in text', function() {
    expect(tagText('Felis; A F. leo was here')).to.
      eq('Felis; A <name found="Felis leo" original="F. leo">F. leo</name> was here');
  });
  it('properly tags around special characters', function() {
    expect(tagText('It must have been the (Rosaceae);')).to.
      eq('It must have been the (<name found="Rosaceae">Rosaceae</name>);');
    expect(tagText('It must have been the (Rosa rugosa);')).to.
      eq('It must have been the (<name found="Rosa rugosa">Rosa rugosa</name>);');
  });
});

describe('#injectString', function() {
  it('adds strings to the right index', function() {
    expect(injectString('starting string', 'with a ', 9)).to.eq('starting with a string');
  });
  it('can add to the beginning', function() {
    expect(injectString('starting string', 'the ', 0)).to.eq('the starting string');
  });
  it('can add to the end', function() {
    expect(injectString('starting string', '.', 15)).to.eq('starting string.');
  });
});
