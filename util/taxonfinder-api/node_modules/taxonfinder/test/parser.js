var expect = require('chai').expect,
    parser = require('../lib/parser'),
    utility = require('../lib/utility'),
    findNamesAndOffsets = parser.findNamesAndOffsets,
    isAbbreviatedGenusWithPeriod = parser.isAbbreviatedGenusWithPeriod,
    startsWithPunctuation = parser.startsWithPunctuation,
    endsWithPunctuation = parser.endsWithPunctuation,
    checkWordAgainstState = parser.checkWordAgainstState,
    prepareReturnHash = parser.prepareReturnHash,
    scoreSpecies = parser.scoreSpecies,
    isNotGenusOrFamily = parser.isNotGenusOrFamily,
    scoreGenus = parser.scoreGenus,
    scoreFamilyOrAbove = parser.scoreFamilyOrAbove,
    scoreRank = parser.scoreRank,
    buildState = parser.buildState;

describe('#findNamesAndOffsets', function() {
  it('finds and returns names and offsets', function() {
    var result = findNamesAndOffsets("The quick brown Animalia Vulpes vulpes (Canidae; Carnivora; Animalia) jumped over the lazy Canis lupis familiaris");
    expect(result[0]['name']).to.eq('Animalia');
    expect(result[0]['offsets'][0]).to.eq(16);
    expect(result[0]['offsets'][1]).to.eq(24);
    expect(result[1]['name']).to.eq('Vulpes vulpes');
    expect(result[1]['offsets'][0]).to.eq(25);
    expect(result[1]['offsets'][1]).to.eq(38);
    expect(result[2]['name']).to.eq('Canidae');
    expect(result[2]['offsets'][0]).to.eq(40);
    expect(result[2]['offsets'][1]).to.eq(47);
  });
  it('expands abbreviated genera', function() {
    var result = findNamesAndOffsets('Pomatomus, P. saltator');
    expect(result[0]['name']).to.eq('Pomatomus');
    expect(result[0]['offsets'][0]).to.eq(0);
    expect(result[0]['offsets'][1]).to.eq(9);
    expect(result[1]['name']).to.eq('Pomatomus saltator');
    expect(result[1]['original']).to.eq('P. saltator');
    expect(result[1]['offsets'][0]).to.eq(11);
    expect(result[1]['offsets'][1]).to.eq(22);
  });
  it('gets correct offsets when the string is exactly the name', function() {
    var result = findNamesAndOffsets('Amanita muscaria');
    expect(result[0]['name']).to.eq('Amanita muscaria');
    expect(result[0]['offsets'][0]).to.eq(0);
    expect(result[0]['offsets'][1]).to.eq(16);
  });
  it('gets correct offsets abbreviations are followed by genera', function() {
    var result = findNamesAndOffsets('P. Pomatomus more words');
    expect(result[0]['name']).to.eq('Pomatomus');
    expect(result[0]['offsets'][0]).to.eq(3);
    expect(result[0]['offsets'][1]).to.eq(12);
  });
  it('gets correct offsets abbreviations are followed by families', function() {
    var result = findNamesAndOffsets('P. Animalia more words');
    expect(result[0]['name']).to.eq('Animalia');
    expect(result[0]['offsets'][0]).to.eq(3);
    expect(result[0]['offsets'][1]).to.eq(11);
  });
  it('allows plain test', function() {
    var result = findNamesAndOffsets('Text <e this would break HTML parsing Amanita muscaria');
    expect(result[0]['name']).to.eq('Amanita muscaria');
    var result = findNamesAndOffsets('Text <e this would break HTML parsing Amanita muscaria', true);
    expect(result).to.be.empty;
  });
});

describe('#isAbbreviatedGenusWithPeriod', function() {
  it('recognizes abreviations with periods', function() {
    expect(isAbbreviatedGenusWithPeriod("G.")).to.eq('a');
    expect(isAbbreviatedGenusWithPeriod("Gr.")).to.eq('a');
  });
  it('recognizes non-abbreviations', function() {
    expect(isAbbreviatedGenusWithPeriod("Gr")).to.be.false;
    expect(isAbbreviatedGenusWithPeriod("Gro")).to.be.false;
  });
});

describe('#startsWithPunctuation', function() {
  it('recognizes strings starting with punctuation', function() {
    expect(startsWithPunctuation(".(Felis")).to.be.true;
    expect(startsWithPunctuation(";Felis")).to.be.true;
  });
  it('recognizes strings not starting with punctuation', function() {
    expect(startsWithPunctuation("Felis")).to.be.false;
    expect(startsWithPunctuation("Felis;")).to.be.false;
  });
});

describe('#endsWithPunctuation', function() {
  it('recognizes strings ending with punctuation', function() {
    expect(endsWithPunctuation("Felis)")).to.be.true;
    expect(endsWithPunctuation("Felis;")).to.be.true;
  });
  it('recognizes strings not ending with punctuation', function() {
    expect(endsWithPunctuation("Felis")).to.be.false;
    expect(endsWithPunctuation(";Felis")).to.be.false;
  });
});

describe('#checkWordAgainstState', function() {
  it('does nothing with null', function() {
    var response = checkWordAgainstState();
    expect(response['workingName']).to.be.undefined;
    expect(response['workingRank']).to.be.undefined;
    expect(response['returnNameHashes']).to.be.undefined;
    expect(Object.keys(response['genusHistory'])).to.be.empty;
  });
  it('does nothing with nonsense', function() {
    var response = checkWordAgainstState('nonsense');
    expect(response['workingName']).to.be.undefined;
    expect(response['workingRank']).to.be.undefined;
    expect(response['returnNameHashes']).to.be.undefined;
    expect(Object.keys(response['genusHistory'])).to.be.empty;
  });
  it('returns working name when finding potential abbreviations', function() {
    var response = checkWordAgainstState('F.', { workingName: 'Felis', workingRank: 'genus', workingScore: 'G' });
    expect(response['workingName']).to.eq('F');
    expect(response['workingRank']).to.eq('genus');
    expect(response['returnNameHashes'][0]['name']).to.eq('Felis');
  });
  it('recognizes potential abbreviated genera', function() {
    var response = checkWordAgainstState('F.');
    expect(response['workingName']).to.eq('F');
    expect(response['workingRank']).to.eq('genus');
  });
  it('recognizes genera', function() {
    var response = checkWordAgainstState('Felis');
    expect(response['workingName']).to.eq('Felis');
    expect(response['workingRank']).to.eq('genus');
  });
  it('recognizes unambiguous genera with full stops', function() {
    var response = checkWordAgainstState('Forsythia;');
    expect(response['workingName']).to.be.undefined;
    expect(response['returnNameHashes'][0]['name']).to.eq('Forsythia');
  });
  it('recognizes families and above', function() {
    var response = checkWordAgainstState('Animalia');
    expect(response['workingName']).to.be.undefined;
    expect(response['returnNameHashes'][0]['name']).to.eq('Animalia');
  });
  it('returns the last known name when encountering nonsense', function() {
    var response = checkWordAgainstState('nonsense', { workingName: 'Felis', workingRank: 'genus', workingScore: 'G' });
    expect(response['workingName']).to.be.undefined;
    expect(response['returnNameHashes'][0]['name']).to.eq('Felis');
  });
  // State Genus
  it('returns the species name if there is terminating punctuation', function() {
    var response = checkWordAgainstState('leo;', { workingName: 'Felis', workingRank: 'genus', workingScore: 'G' });
    expect(response['workingName']).to.be.undefined;
    expect(response['returnNameHashes'][0]['name']).to.eq('Felis leo');
  });
  it('returns the species name if there is terminating punctuation', function() {
    var response = checkWordAgainstState('leo;', { workingName: 'Felis', workingRank: 'genus', workingScore: 'G' });
    expect(response['workingName']).to.be.undefined;
    expect(response['returnNameHashes'][0]['name']).to.eq('Felis leo');
  });
  it('attaches species to genera', function() {
    var response = checkWordAgainstState('leo', { workingName: 'Felis', workingRank: 'genus', workingScore: 'G' });
    expect(response['workingName']).to.eq('Felis leo');
    expect(response['workingRank']).to.eq('species');
  });
  it('finds genera after genera', function() {
    var response = checkWordAgainstState('Felis', { workingName: 'Felis', workingRank: 'genus', workingScore: 'G' });
    expect(response['workingName']).to.eq('Felis');
    expect(response['workingRank']).to.eq('genus');
    expect(response['returnNameHashes'][0]['name']).to.eq('Felis');
  });
  it('finds families or above after genera', function() {
    var response = checkWordAgainstState('Animalia', { workingName: 'Felis', workingRank: 'genus', workingScore: 'G' });
    expect(response['workingName']).to.be.undefined;
    expect(response['returnNameHashes'][0]['name']).to.eq('Felis');
    expect(response['returnNameHashes'][1]['name']).to.eq('Animalia');
  });
  // State Species
  it('attaches species to species', function() {
    var response = checkWordAgainstState('leo', { workingName: 'Felis leo', workingRank: 'species', workingScore: 'GS' });
    expect(response['workingName']).to.eq('Felis leo leo');
    expect(response['workingRank']).to.eq('species');
  });
  it('attaches ranks to species', function() {
    var response = checkWordAgainstState('var', { workingName: 'Felis leo', workingRank: 'species', workingScore: 'GS' });
    expect(response['workingName']).to.eq('Felis leo var');
    expect(response['workingRank']).to.eq('rank');
  });
  it('attaches ranks to species and keeps punctuation', function() {
    var response = checkWordAgainstState('var.', { workingName: 'Felis leo', workingRank: 'species', workingScore: 'GS' });
    expect(response['workingName']).to.eq('Felis leo var.');
    expect(response['workingRank']).to.eq('rank');
  });
  it('starts a new name when in species and found genus', function() {
    var response = checkWordAgainstState('Amanita', { workingName: 'Felis leo', workingRank: 'species', workingScore: 'GS' });
    expect(response['workingName']).to.eq('Amanita');
    expect(response['workingRank']).to.eq('genus');
    expect(response['returnNameHashes'][0]['name']).to.eq('Felis leo');
  });
  it('returns two names when in species and found family or above', function() {
    var response = checkWordAgainstState('Animalia', { workingName: 'Felis leo', workingRank: 'species', workingScore: 'GS' });
    expect(response['workingName']).to.be.undefined;
    expect(response['returnNameHashes'][0]['name']).to.eq('Felis leo');
    expect(response['returnNameHashes'][1]['name']).to.eq('Animalia');
  });
  it('returns species when in species and the next word is nonsense', function() {
    var response = checkWordAgainstState('asdfasdf', { workingName: 'Felis leo', workingRank: 'species', workingScore: 'GS' });
    expect(response['workingName']).to.be.undefined;
    expect(response['returnNameHashes'][0]['name']).to.eq('Felis leo');
  });
  it('returns the species name if there is terminating punctuation', function() {
    var response = checkWordAgainstState('leo;', { workingName: 'Felis leo', workingRank: 'species', workingScore: 'GS' });
    expect(response['workingName']).to.be.undefined;
    expect(response['returnNameHashes'][0]['name']).to.eq('Felis leo leo');
  });
  // State Rank
  it('attaches species to ranks', function() {
    var response = checkWordAgainstState('leo', { workingName: 'Felis leo var.', workingRank: 'rank', workingScore: 'GSR' });
    expect(response['workingName']).to.eq('Felis leo var. leo');
    expect(response['workingRank']).to.eq('species');
  });
  it('starts a new name when in rank and found genus', function() {
    var response = checkWordAgainstState('Amanita', { workingName: 'Felis leo var.', workingRank: 'rank', workingScore: 'GSR' });
    expect(response['workingName']).to.eq('Amanita');
    expect(response['workingRank']).to.eq('genus');
    expect(response['returnNameHashes'][0]['name']).to.eq('Felis leo');
  });
  it('returns two names when in rank and found family or above', function() {
    var response = checkWordAgainstState('Animalia', { workingName: 'Felis leo var.', workingRank: 'rank', workingScore: 'GSR' });
    expect(response['workingName']).to.be.undefined;
    expect(response['returnNameHashes'][0]['name']).to.eq('Felis leo');
    expect(response['returnNameHashes'][1]['name']).to.eq('Animalia');
  });
  it('returns name when in rank and the next word is nonsense', function() {
    var response = checkWordAgainstState('asdfasdf', { workingName: 'Felis leo var.', workingRank: 'rank', workingScore: 'GSR' });
    expect(response['workingName']).to.be.undefined;
    expect(response['returnNameHashes'][0]['name']).to.eq('Felis leo');
  });
  // Various cases
  it('expands abbreviated genera', function() {
    var response = checkWordAgainstState('saltator;', { workingName: 'P', workingRank: 'genus', workingScore: 'g'});
    expect(response['workingName']).to.be.undefined;
    expect(response['returnNameHashes'][0]['name']).to.eq('P saltator');
  });
  it('doesnt return bad names', function() {
    var response = checkWordAgainstState('marina;', { workingName: 'Stella', workingRank: 'genus', workingScore: 'g'});
    expect(response['workingName']).to.be.undefined;
    expect(response['returnNameHashes']).to.be.undefined;
  });
});

describe('#prepareReturnHash', function() {
  it('fails on short strings', function() {
    expect(prepareReturnHash({ name: 'Aa' })).to.be.null;
  });
  it('fails on empty strings', function() {
    expect(prepareReturnHash({ name: '' })).to.be.null;
  });
  it('fails on just ambiguous genera', function() {
    expect(prepareReturnHash({ name: 'Felis', score: 'g' })).to.be.null;
  });
  it('chops off trailing ranks', function() {
    var response = prepareReturnHash({ name: 'Amanita sp', score: 'GR' });
    expect(response['name']).to.eq('Amanita');
  });
  it('fixes capitalization', function() {
    var response = prepareReturnHash({ name: 'AMANITA MUSCARIA', score: 'GS' });
    expect(response['name']).to.eq('Amanita muscaria');
    response = prepareReturnHash({ name: 'AMANITA (AMANITA) MUSCARIA', score: 'GGS' });
    expect(response['name']).to.eq('Amanita (Amanita) muscaria');
    response = prepareReturnHash({ name: 'AMANITA (AMANITA) MUSCARIA MUSCARIA', score: 'GGSS' });
    expect(response['name']).to.eq('Amanita (Amanita) muscaria muscaria');
    response = prepareReturnHash({ name: 'AMANITA (AMANITA) MUSCARIA MUSCARIA MUSCARIA', score: 'GGSSS' });
    expect(response['name']).to.eq('Amanita (Amanita) muscaria muscaria muscaria');
  });
  it('avoids infinite loops', function() {
    // I don't have a real example of this bug, but were ways to get
    // stuck in an infinite loop and this is a way to check for the fix.
    // (see, in index.js => if(currentString === nextString) ...)
    var response = prepareReturnHash({ name: 'Amanita [] muscaria', score: 'GRS' });
    expect(response['name']).to.eq('Amanita [] muscaria');
  });
  it('leaves everything else alone', function() {
    var response = prepareReturnHash({ name: 'Amanita', score: 'G' });
    expect(response['name']).to.eq('Amanita');
    response = prepareReturnHash({ name: 'Amanita muscaria', score: 'GS' });
    expect(response['name']).to.eq('Amanita muscaria');
  });
});

describe('#scoreSpecies', function() {
  it('fails on special characters', function() {
    expect(scoreSpecies(createState('(musculus', 'Mus'))).to.be.null;
  });
  it('fails on strings in the species_bad dictionary', function() {
    expect(scoreSpecies(createState('phobia', 'Mus'))).to.be.null;
  });
  it('fails on strings with numbers in them', function() {
    expect(scoreSpecies(createState('phob1a', 'Mus'))).to.be.null;
  });
  it('fails on lowercase strings when genera are capitalized', function() {
    expect(scoreSpecies(createState('musculus', 'MUS'))).to.be.null;
  });
  it('fails on capitalizes strings when genera are lower case', function() {
    expect(scoreSpecies(createState('MUSCULUS', 'Mus'))).to.be.null;
  });
  it('fails on non-species strings', function() {
    expect(scoreSpecies(createState('nonsense', 'Mus'))).to.be.null;
  });
  it('returns S for valid species', function() {
    expect(scoreSpecies(createState('musculus', 'Mus'))).to.eq('S');
  });
  it('returns S for valid species when everything is capitalized', function() {
    expect(scoreSpecies(createState('MUSCULUS', 'MUS'))).to.eq('S');
  });
});

describe('#isNotGenusOrFamily', function() {
  it('true for short strings', function() {
    expect(isNotGenusOrFamily(createState('Aa'))).to.be.true;
  });
  it('true for poorly capitalized strings', function() {
    expect(isNotGenusOrFamily(createState('amanita'))).to.be.true;
    expect(isNotGenusOrFamily(createState('AMANita'))).to.be.true;
  });
  it('true for strings in the overlap dictionary', function() {
    expect(isNotGenusOrFamily(createState('Goliath'))).to.be.true;
  });
  it('false for everything else', function() {
    expect(isNotGenusOrFamily(createState('Amanita'))).to.be.false;
  });
});

describe('#scoreGenus', function() {
  it('fails on non-genera strings', function() {
    expect(scoreGenus(createState('AMANita'))).to.be.null;
  });
  it('fails on non-genera strings', function() {
    expect(scoreGenus(createState('Itsnotaname'))).to.be.null;
  });
  it('returns g for ambiguous genera', function() {
    expect(scoreGenus(createState('Tuberosa'))).to.eq('g');
  });
  it('returns G for unambiguous genera', function() {
    expect(scoreGenus(createState('Amanita'))).to.eq('G');
  });
});

describe('#scoreFamilyOrAbove', function() {
  it('fails on non-family-or-above strings', function() {
    expect(scoreFamilyOrAbove(createState('ANIMalia'))).to.be.null;
  });
  it('fails on non-family-or-above strings', function() {
    expect(scoreFamilyOrAbove(createState('Itsnotaname'))).to.be.null;
  });
  it('returns f for ambiguous families', function() {
    expect(scoreFamilyOrAbove(createState('Sorghum'))).to.eq('f');
  });
  it('returns F for unambiguous families', function() {
    expect(scoreFamilyOrAbove(createState('Animalia'))).to.eq('F');
  });
});

describe('#scoreRank', function() {
  it('fails on special characters', function() {
    expect(scoreRank(createState('(var'))).to.be.null;
  });
  it('fails on capital characters', function() {
    expect(scoreRank(createState('VAR'))).to.be.null;
  });
  it('fails on non-ranks', function() {
    expect(scoreRank(createState('nonsense'))).to.be.null;
  });
  it('returns R for valid ranks', function() {
    expect(scoreRank(createState('var'))).to.eq('R');
  });
});

describe('#buildState', function() {
  it('sets reasonable defaults', function() {
    expect(Object.keys(buildState())).to.be.empty;
  });
});

var createState = function(word, workingName) {
  var cleanWord = utility.clean(word);
  var lowerCaseCleanWord = cleanWord.toLowerCase();
  return { word: word, cleanWord: cleanWord, lowerCaseCleanWord: lowerCaseCleanWord,
    workingName: workingName };
};
