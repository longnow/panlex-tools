var expect = require('chai').expect,
    dictionaries = require('../lib/dictionaries'),
    hashes = dictionaries.hashes,
    load = dictionaries.load;

describe('#load', function() {
  it('adds a lot of words', function() {
    load();
    expect(Object.keys(hashes['family']).length).to.be.above(55230);
    expect(Object.keys(hashes['family_new']).length).to.be.above(41);
    expect(Object.keys(hashes['genera']).length).to.be.above(437061);
    expect(Object.keys(hashes['genera_new']).length).to.be.above(897);
    expect(Object.keys(hashes['species']).length).to.be.above(660011);
    expect(Object.keys(hashes['species_new']).length).to.be.above(1840);
    expect(Object.keys(hashes['species_bad']).length).to.be.above(1187);
    expect(Object.keys(hashes['ranks']).length).to.be.above(158);
    expect(Object.keys(hashes['overlap_new']).length).to.be.above(3025);
    expect(Object.keys(hashes['species_bad']).length).to.be.above(1187);
    expect(Object.keys(hashes['dict_ambig']).length).to.be.above(4166);
    expect(Object.keys(hashes['genera_family']).length).to.be.above(11);
    expect(Object.keys(hashes['dict_bad']).length).to.be.above(9);
  });

  it('adds family and above names', function() {
    load();
    expect(hashes['family']['animalia']).to.be.true;
    expect(hashes['family']['chordata']).to.be.true;
    expect(hashes['family']['mammalia']).to.be.true;
    expect(hashes['family']['primates']).to.be.true;
    expect(hashes['family']['hominidae']).to.be.true;
  });

  it('adds genera names', function() {
    load();
    expect(hashes['genera']['homo']).to.be.true;
    expect(hashes['genera']['geranium']).to.be.true;
    expect(hashes['genera']['giraffe']).to.be.true;
    expect(hashes['genera']['amanita']).to.be.true;
    expect(hashes['genera']['escherichia']).to.be.true;
  });

  it('adds species names', function() {
    load();
    expect(hashes['species']['sapiens']).to.be.true;
    expect(hashes['species']['cinereum']).to.be.true;
    expect(hashes['species']['camelopardalis']).to.be.true;
    expect(hashes['species']['muscaria']).to.be.true;
    expect(hashes['species']['coli']).to.be.true;
  });

  it('adds ranks', function() {
    load();
    expect(hashes['ranks']['sp']).to.be.true;
    expect(hashes['ranks']['var']).to.be.true;
    expect(hashes['ranks']['gen']).to.be.true;
    expect(hashes['ranks']['f']).to.be.true;
    expect(hashes['ranks']['subsp']).to.be.true;
  });
});
