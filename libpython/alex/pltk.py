'''
PanLex ToolKit
'''

import unicodedata
import regex
from time import sleep
import simplejson as json
from unidecode import unidecode

# initialize these only if function called
nltk = None
TextBlob = None
MecabSoup = None
import urllib.request


def preprocess(entries):
  # perform across-the-board preprocessing of things that should !ALWAYS! be done
  result = []
  for entry in entries:
    processed_entry = []
    for col in entry:
      
      # nonstandard spaces/newlines
      col = regex.sub(r'[\u200B\uFEFF \n\u200E]', ' ', col).strip()

      # fullwidth punctuation, numbers
      col = col.replace('？', '?')
      col = col.replace('！', '!')
      if regex.search(r'\p{Nd}', col):
        col = unicodedata.normalize('NFKC', col).strip()  # North Florida Koi Club

      # "etc"
      col = regex.sub(r'[\,、;]?\s*etc\.?$', '...', col).strip()

      # ellipses
      col = regex.sub(r'・・・', '...', col)
      col = regex.sub(r'～', '...', col)
      col = regex.sub(r'\.\s*\.(\s*\.)+', ' … ', col).strip()
      col = regex.sub(r'\s*…\s*', ' … ', col).strip()
      col = regex.sub(r'^\s*…', '', col).strip()
      col = regex.sub(r'…\s*$', '', col).strip()

      # excess whitespace
      col = regex.sub(r'  +', r' ',col).strip()
      col = regex.sub(r'\( +','(',col).strip()
      col = regex.sub(r' +\)',')',col).strip()

      # weirdly placed commas
      col = regex.sub(r'\s* ,([^\s])', r', \1', col).strip()

      # digit separator commas
      col = regex.sub(r'(\d),(\d)', r'\1\2', col).strip()

      # surprise html encoded chars
      col = col.replace('&amp;', '&')
      col = col.replace('&quot;', '"')

      processed_entry.append(col)
    result.append(processed_entry)
  
  return result


PARENS = [(r'\(',r'\)'),(r'\[',r'\]'),(r'\{',r'\}'),(r'（',r'）'),(r'【',r'】')]
#,(r'‘',r'’')

def split_outside_parens(entries, cols, delim=r',', detectsentences=False, parens=PARENS):
  ''' Peforms a split of each specified column, but ignores anything in parens.
  entries    = list of entries, which are lists of columns
  cols    = list of columns (element indices) on which to perform operation
  delim   = regex of delimiter(s) at which to split
  parens  = list of tuples of opening and closing characters (regex escaped)
            to be considered parenthetical '''

  SOP_DELIM = ''
  TEMP_SENTENCE_PAREN = [(r'🁾',r'🂊')]

  if detectsentences:
    minwords = 5
    parens += TEMP_SENTENCE_PAREN
    minwords = str(minwords - 1)

  assert parens
  
  o_parens = [p[0] for p in parens]
  c_parens = [p[1] for p in parens]

  result = []
  for entry in entries:

    if not isinstance(entry, list):
      raise ValueError(entry, 'not a list; did you remember to split tabs yet?')

    paren_re = make_paren_regex(parens) + r'+\s*'

    for col in cols:

      try: entry[col]
      except: raise ValueError('index', col, 'not in entry:', entry)

      if not ''.join(entry[col]).startswith('⫷df⫸'):

        if detectsentences: # detect sentences and put special parens around them
          # start w/ capital letter, end with period(s)
          entry[col] = regex.sub(r'(\p{Lu}[^\s.]+(?:\s+[^\s.]+){'+minwords+r',}[\.!?]+)', TEMP_SENTENCE_PAREN[0][0]+r'\1'+TEMP_SENTENCE_PAREN[0][1], entry[col])

        count = 0

        entry_letters = []

        for l in entry[col]:
          if list(filter(None, [regex.match(o_paren, l) for o_paren in o_parens])):
            # if letter is open paren
            entry_letters.append(l)
            count += 1
          elif list(filter(None, [regex.match(c_paren, l) for c_paren in c_parens])):
            # if letter is close paren
            entry_letters.append(l)
            count -= 1
          elif count == 0 and regex.match(delim, l):
            entry_letters.append(SOP_DELIM)
          else:
            entry_letters.append(l)

        entry[col] = [regex.sub(r'['+TEMP_SENTENCE_PAREN[0][0]+TEMP_SENTENCE_PAREN[0][1]+r']', '',  c).strip() for c in ''.join(entry_letters).split(SOP_DELIM)]

      else:
        entry[col] = [entry[col]]

    result.append(entry)
  return result


def make_paren_regex(parens=PARENS, maxnested=10):
  ''' Makes a regex to match any parenthetical content, up to a certain number
      of layers deep.
  parens  = list of tuples of opening and closing characters (regex escaped)
            to be considered parenthetical
  maxnested = max number of nested parens to match '''

  paren_res = []
  for p in parens:
    o, c = p
    oc = o + c
    fld  = (o + r'(?:[^' + oc + r']|') * (maxnested - 1)
    fld += o + r'[^' + c + r']*' + c
    fld += (r')*' + c) * (maxnested - 1)
    paren_res.append(fld)
  return r'(' + r'|'.join(paren_res) + r')'

def remove_parens(s, parens=PARENS):
  return regex.sub(make_paren_regex, '', s).strip()


EXDFPREP_RULES = {
  'eng-000' : {
    1 : {
      r'([^\s])\s+(some(?:one|body|thing)(?: or some(?:one|body|thing))?(?: (?:who|which|that) is)?|s\.[bot]\.?|o\.s\.?)([^\'’]|$)' : (r'\1 (\2)\3', ''),
      r'^((?:(?:'+make_paren_regex()[1:-1]+r')\s*)?)(some(?:one|body|thing)(?: or some(?:one|body|thing))?|s\.[bot]\.?|o\.s\.?)\s+([^\s])' : (r'\1(\2) \3', ''),
      r'^((?:(?:'+make_paren_regex()[1:-1]+r')\s*)?)(some(?:one|body|thing)[\'’]?s)\s+([^\s])' : (r'\1(\2) \3', ''),
      r'^((?:(?:'+make_paren_regex()[1:-1]+r')\s*)?)((?:\(?\s*to\s*\)?\s+)?be)\s+([^\(])'  : (r'\1(\2) \3', ''),
      r'^(\(?(?:a\s+)?(?:kind|type|sort|species) of\)?)\s*([^\s]+ ?[^\s]+)$' : (r'(\1) \2', r'⫷mcs2:art-300⫸IsA⫷mcs:eng-000⫸\2'),
    },
    2: {
      r'^((?:(?:'+make_paren_regex()[1:-1]+r')\s*)?)(the|an?)\s+([^\(])'   : (r'\1(\2) \3', ''),
      # r'^((?:(?:'+make_paren_regex()[1:-1]+r')\s*)?)(the)\s+([^\(])'   : (r'\1(\2) \3', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'),
      r'^((?:(?:'+make_paren_regex()[1:-1]+r')\s*)?)\((some(?:one|body|thing)(?: or some(?:one|body|thing))?|s\.[bot]\.?|o\.s\.?)\)\s+(which|that|who|to)' : (r'\1\2 \3', ''),
      r'\((some(?:one|body|thing)(?: or some(?:one|body|thing))?|s\.[bot]\.?|o\.s\.?)\)\s+(else(?:\'s)?)' : (r'(\1 \2)', ''),
      r'^\((some(?:one|body|thing)(?: or some(?:one|body|thing))?|s\.[bot]\.?|o\.s\.?)\)\s+' : (r'\1 ', ''),
    },
    3: {
      r'^((?:(?:'+make_paren_regex()[1:-1]+r')\s*)?)((?:not )?)[Tt]o\s+((?:'+make_paren_regex()[1:-1]+r')?\s*)(?!the(?: |$)|you|us$|him$|her$|them$|me$)' : (r'\1\2(to) \3', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Verbal'),
    },
    4: {
      r'(^|\s)\(a\) (lot|bit|posteriori|priori|fortiori|few|little|minute|same)(\s|$)' : (r'\1a \2\3', r''),
      r'^((?:(?:'+make_paren_regex()[1:-1]+r')\s*)?)((?:\(to\) )?)(become)\s+([^\s\()][^\s]*)$' : (r'\1\2\3 \4', r'⫷mcs2:art-316⫸Inchoative_of⫷mcs⫸\4'),
      r'^((?:(?:'+make_paren_regex()[1:-1]+r')\s*)?)((?:\(to\) )?)(make)\s+([^\s\()][^\s]*)$'   : (r'\1\2\3 \4', r'⫷mcs2:art-316⫸Causative_of⫷mcs⫸\4'),
    },
    5: {
      r'^((?:(?:'+make_paren_regex()[1:-1]+r')\s*)?)\((the|an?)\)\s+([^\(])'   : (r'\1(\2) \3', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'),
    },
  },
  'jpn-000' : {
    1: {
      r'^(.+)(である)$' : (r'\1(\2)', ''), # to be ~
      r'([\p{Han}\p{Katakana}](?:'+make_paren_regex()[1:-1]+r')?)(だ|の|な)$' : (r'\1(\2)', ''),
      r'^(.*[\p{Han}])(らせる)$' : (r'\1\2', r'⫷mcs2:art-316⫸Causative_of⫷mcs⫸\1る'),
      r'^(させる)$' : (r'\1', r'⫷mcs2:art-316⫸Causative_of⫷mcs⫸する'),
      r'^(を)(\p{Han})' : (r'(\1)\2', r''),
      r'(など)$' : (r'(\1)', ''),  # ... etc.
      r'^([^…]+)(くなる)$' : (r'\1\2', r'⫷mcs2:art-316⫸Inchoative_of⫷mcs⫸\1い'),  # to become ~ (keiyoshi)
      r'^([^…]+)(になる)$' : (r'\1\2', r'⫷mcs2:art-316⫸Inchoative_of⫷mcs⫸\1'),  # to become ~
      r'^[…\s]*(に)(なる)$' : (r'(\1)\2', r''),  # to become
    },
    2: {
      r'其((?:'+make_paren_regex()[1:-1]+r')?)\(の\)' : (r'其\1の', ''),
    },
  },
  'arb-000' : {
    1: {
      r'^(ال)' : (r'(\1)', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'), # definite article
    }
  },
  'spa-000' : {
    1 : {
      #r'([^\s])\s+\(?(alg(?:ui[eé]n|o|\.))\)?([^\'’])' : (r'\1 (\2)\3', ''),
      #r'^\(?(alg(?:ui[eé]n|o|\.))\)?\s+([^\s\(])' : (r'(\1) \2', ''),
      r'^\(?([Ee]l|[Uu]n)\)?\s+([^\s\(])'  : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender'),
      r'^\(?([Ll]os|[Uu]nos)\)?\s+([^\s\(])'  : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
      r'^\(?([Ll]a|[Uu]na)\)?\s+([^\s\(])'  : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender'),
      r'^\(?([Ll]as|[Uu]nas)\)?\s+([^\s\(])'  : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
      r'^\(?([Ss]er|[Ee]star)\)?\s+([^\s\(])'  : (r'(\1) \2', ''),
      #r'\s+of(\s*(?:\([^\)]*\)\s*)*)$'          : (r' (of)\1', ''),
      r'^\s*¡|!\s*$'  : ('', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Interjection'),
      r'[¿\?]' : ('', '⫷dcs2:art-303⫸ForceProperty⫷dcs:art-303⫸InterrogativeForce'),
      r'[¡\!]' : ('', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Interjection'),
      r'^idioma ([^\s\(][^\s]*)$' : (r'(idioma) \1', ''),
      r'^(\(?(?:una?\s+)?(?:clase) de\)?)\s*([^\s]+ ?[^\s]+)$' : (r'(\1) \2', r'⫷mcs2:art-300⫸IsA⫷mcs:spa-000⫸\2'),
    }
  },
  'cat-000' : {
    1 : {
      r'[¿\?]' : ('', '⫷dcs2:art-303⫸ForceProperty⫷dcs:art-303⫸InterrogativeForce'),
    },
  },
  'ile-000' : {
    1 : {
      r'^\(?([Ll][ie])\)?\s+([^\s\(])'  : (r'(\1) \2',  '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'),
      r'^\(?([Uu]n)\)?\s+([^\s\(])'  : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'),
    },
  },
  'ast-000' : {
    1 : {
      r'^\(?([Ee]l)\)?\s+([^\s\(])'  : (r'(\1) \2',  '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender'),
      r'^\(?([Ll]os)\)?\s+([^\s\(])'  : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
      r'^\(?([Ll]a)\)?\s+([^\s\(])'  : (r'(\1) \2',  '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender'),
      r'^\(?([Ll]es)\)?\s+([^\s\(])'  : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
    }
  },
  'gle-000' : {
    1 : {
      r'^(an)\s+([^\(])' : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'), # def art
    }
  },
  'als-000' : {
    1 : {
      r'^(i/e|e/i|të|[ie])\s+([^\(])' : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Adjectival'),
    }
  },
  'nob-000' : {
    1 : {
      r'^((?:(?:'+make_paren_regex()[1:-1]+r')\s*)?)((?:\(?\s*å\s*\)?\s+)?bli)\s+([^\(])'  : (r'\1(\2) \3', ''),
      r'^\(?([Ee]l|[Uu]n)\)?\s+([^\s\(])'  : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender'),
      r'^\(?([Ll]os|[Uu]nos)\)?\s+([^\s\(])'  : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
      r'^\(?([Ll]a|[Uu]na)\)?\s+([^\s\(])'  : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender'),
      r'^\(?([Ll]as|[Uu]nas)\)?\s+([^\s\(])'  : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
    },
    2: {
      r'^((?:(?:'+make_paren_regex()[1:-1]+r')\s*)?)å\s+' : (r'\1(å) ', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Verbal'),
    },
  },
  'fra-000' : {
    1 : {
      r'^(.+)\s+\(?(quelqu[\'’]un|quelque chose)\)?' : (r'\1 (\2)', ''),
      r'\(?(q\.?q\.?(?:ch|un?)\.?)\)?' : (r'(\1)', ''),
      r'^([Ll][\'’])([^\s\(])' : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'),
      r'^([Ll]e)\s+([^\s\(])'     : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender'),
      r'^([Ll]a)\s+([^\s\(])'     : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender'),
      r'^([Ll]es)\s+([^\s\(])'    : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
      r'^([Uu]n)\s+([^\s\(])'     : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender'),
      r'^([Uu]ne)\s+([^\s\(])'    : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender'),
      r'^(ê\.|être)\s+([^\s\(])'   : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Adjectival'),
      r'^(\(?(?:type|sorte|espèce) d[e\']\)?)\s*(.+)$' : (r'(\1) \2', r'⫷mcs2:art-300⫸IsA⫷mcs:fra-000⫸\2'),
    },
    2: {
      r'^devenir\s+([^\s]+)$' : (r'devenir \1', r'⫷dcs2:art-316⫸Inchoative_of⫷dcs⫸\1')
    }
  },
  'isl-000' : {
    1 : {
      r'^(vera)\s+'   : (r'(\1) ', ''),
      r'([^\s])\s+(e\-(?:[ðimnstu]|ar?|rs?))(\s|$)' : (r'\1 (\2)\3', ''),

      """
      e-a  einhverja, einhverra    (fem acc sg, msc acc pl; msc/fem/neu gen pl)
      e-ar einhverjar, einhverrar  (fem nom/acc pl; fem gen sg)
      e-ð  eitthvað     (neu nom/acc sg substant)
      e-i  einhverri    (fem dat sg)
      e-m  einhverjum   (msc dat sg, msc/fem/neu dat pl)
      e-n  einhvern     (msc acc sg)
      e-r  einhver      (msc/fem nom sg)
      e-(r)s einhvers   (msc/neu gen sg)
      e-t  eitthvert    (neu nom/acc sg demonstr)
      e-u  einhverju    (neu dat sg)
      """

      r'^(e\-(?:[ðimnstu]|ar?|rs?))\s+([^\s])' : (r'(\1) \2', ''),
    },
  },
  'ces-000' : {
    1 : {
      r'^(být)\s+'   : (r'(\1) ', ''),
    },
    2: {
    }
  },
  'fin-000' : {
    1 : {
      r'^(olla)\s+'   : (r'(\1) ', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Adjectival'),
    },
    2: {
      r'^tulla\s+(.+)$' : (r'tulla \1', r'⫷dcs2:art-316⫸Inchoative_of⫷dcs⫸\1')
    }
  },
  'deu-000' : {
    1 : {
      r'^((?:(?:'+make_paren_regex()[1:-1]+r')\s*)?)(ein(?:e[mnrs]?)?|die|das|de[mnrs])\s+([^\(])'   : (r'\1(\2) \3', ''),
    },
    2: {
    }
  },
  'general' : {
    998 : {
      r'(^\s*…|…\s*$)' : ('', ''),
      r'^((?:[^\s][^\s]?\.)+)$' : (r'\1.', ''),
    },
    999 : {
      r'(.)[！!]$'  : (r'\1', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Interjection'),
      r'(.)\?$' : (r'\1', '⫷dcs2:art-303⫸ForceProperty⫷dcs:art-303⫸InterrogativeForce'),
      r'^\?+$' : (r'', ''),
      r'["“”]'  : ('', ''),
      r'\.$' : (r'', ''),
    }
  }
}

def exdfprep(entries, sourcecols, tocol=-1, lang='eng-000', pretag_special_lvs=True):
  ''' Parenthesizes "definitional" parts of an expression, and adds appropriate pretagged elements.
  entries    = list of entries, lists of elements; column with expressions to be process must be a list
  sourcecols = list of columns (element indices) on which to perform operation
  tocol   = new col in which to deposit pretagged content (end); if -1, use end of source col
  from    = regex of delimiters from which to convert '''

  result = []

  for entry in entries:

    paren_re = make_paren_regex()

    if tocol >= 0: # prepare new column, update source col indices
      entry.insert(tocol, '')
      sourcecols = [(col + 1 if col >= tocol else col) for col in sourcecols]

    if len(lang) == 3:
      lang += '-000'

    if lang not in EXDFPREP_RULES:
      print('WARNING: Language not supported by exdfprep:', lang)
      print('Reverting to general rules')
      lang = 'general'

    for col in sourcecols:

      try: entry[col]
      except: raise ValueError('index', col, 'not in entry:', entry)

      if not ''.join(entry[col]).startswith('⫷df⫸'):

        if not isinstance(entry[col], list):
          raise ValueError(entry[col], ': not a list; did you remember to do a synonym split?')
        else:
          result1 = []

          for syn in entry[col]:
            pretags = ''

            rules = EXDFPREP_RULES[lang]

            if lang != 'general':
              rules.update(EXDFPREP_RULES['general'])

            for stage in rules:
              for rule in rules[stage]:
                if regex.search(rule, syn):
                  replacement, pretag = rules[stage][rule]
                  if '\\' in pretag:
                    pretag_addn = regex.sub(rule, pretag, syn).strip()
                    old = syn
                    while old != pretag_addn:
                      old = pretag_addn
                      pretag_addn = regex.sub(rule, pretag, pretag_addn).strip()
                    pretag_addn = regex.sub(paren_re, '', pretag_addn).strip()
                    pretag_addn = regex.sub('⫸ +', '⫸', pretag_addn)
                    pretags += pretag_addn
                  else:
                    pretags += pretag.strip()
                  syn = regex.sub(rule, replacement, syn).strip()

            if tocol >= 0:
              entry[tocol] += pretags # new prepared column
            else:
              syn += pretags # right after source

            # pretag special language varieties:
            if pretag_special_lvs:
              # integers
              int_m = regex.match(r'^(?:⫷..⫸)?(\d+)($|⫷)', syn.strip())
              if int_m:
                if int_m.group(1) in ['747']:
                  print('WARNING: Did not pretag potentially special number:', int_m.group(1))
                else:
                  syn = regex.sub(r'^(?:⫷[^⫸]+⫸)?', '⫷ex:art-269⫸', syn.strip()).strip()


            result1.append(syn)

          entry[col] = result1

    result.append(entry)

  return result


def mnsplit(entries, col, delim='⁋'):
  try: assert isinstance(col, int)
  except: raise ValueException('col must be integer')
  if delim != '⁋':
    entries = split_outside_parens(entries, [col], delim)
    entries = joincol(entries, col, '⁋')
  result = []
  for entry in entries:
    assert isinstance(entry[col], str)
    for mn in regex.split('⁋', entry[col]):
      result.append(entry[:col] + [mn] + entry[col+1:])
  return result


def separate_parentheticals(entries, cols, delim=r'[&,;]', parens=PARENS):
  ''' Separates parentheticals within an entry, to multiple sets of parentheses (for division into
      different columns, etc)
  entries = list of entries
  cols    = list of columns (element indices) on which to perform operation
  delim   = regex of delimiters at which to split
  parens  = list of tuples of opening and closing characters (regex escaped)
            to be considered parenthetical '''

  result = []

  for entry in entries:

    for col in cols:
      try: entry[col]
      except: raise ValueError('index', col, 'not in entry:', entry)
      for p in parens:
        o, c = p
        from_re = o + r'([^' + c + r']*)\s*' + delim + r'\s*([^' + c + r']*)' + c
        oraw, craw = o.replace('\\',''), c.replace('\\','')
        # separate parentheticals
        new = regex.sub(from_re, oraw+r'\1'+craw+' '+oraw+r'\2'+craw, entry[col])
        while entry[col] != new:
          entry[col] = new
          new = regex.sub(from_re, oraw+r'\1'+craw+' '+oraw+r'\2'+craw, new)
        entry[col] = regex.sub(r'\s+\)', ')', entry[col])

    result.append(entry)

  return result


def convert_between_cols(entries, conversion_rules, fromcol, tocol=-1, syn_delim='‣', delim='‣'):
  ''' Convert between columns, using a dictionary/dictionaries of conversion rules.
  entries    = list of elements (columns)
  conversion_rules = dict of conversions  { from : to } OR list of dicts of conversions to do in order
  fromcol = col from which to look
  tocol   = new col in which to deposit replacements (end); if -1, use end of source col
  syn_delim = delimiter between synonyms for each entry
  delim   = delimiter to use between replacements if not a fully-formed tag '''

  assert isinstance(tocol, int)
  cols_total = len(entries[0])
  if tocol >= 0: # update source col index if making new col
    cols_total += 1
    if fromcol >= tocol: fromcol += 1

  if not isinstance(conversion_rules, list):
    conversion_rules = [conversion_rules]

  new_entries = entries
  for curr_conv_rules in conversion_rules:
    result = []
    for entry in new_entries:
      if tocol >= 0:
        if len(entry) < cols_total: # prepare new column
          entry.insert(tocol, '')
        curr_tocol = tocol
      else:
        curr_tocol = fromcol

      colbuffer = ''

      newcol = []
      for exp in entry[fromcol].split(syn_delim):
        for rule in curr_conv_rules:
          m = regex.search(rule, exp)
          if m:
            # if the conversion to isn't explicit tags, add the standard delimiter
            if '⫷' not in curr_conv_rules[rule] and colbuffer:
              colbuffer += delim
            # if capture group exists, sub from the column
            if '\\' in curr_conv_rules[rule]:
              colbuffer += regex.sub(rule, curr_conv_rules[rule], m.group(0))
            # else just add the target
            else:
              colbuffer += curr_conv_rules[rule]
            exp = regex.sub(rule, ' ', exp).strip()
            exp = regex.sub(r'  +', ' ', exp.strip())
        newcol.append(exp)
      colbuffer = regex.sub(r'  +', ' ', colbuffer.strip())

      entry[fromcol] = syn_delim.join(newcol)
      entry[curr_tocol] += colbuffer
      result.append(entry)
    new_entries = result

  return entries


def splitcol(entries, col, delim=''):
  result = []
  for entry in entries:
    assert isinstance(entry[col], str)
    entry[col] = [e.strip() for e in regex.split(delim, entry[col]) if e.strip()]
    result.append(entry)
  return result

def joincol(entries, col, delim=''):
  result = []
  for entry in entries:
    assert isinstance(entry[col], list)
    entry[col] = delim.join(entry[col])
    result.append(entry)
  return result


def remove_nested_parens(entries, cols, parens=PARENS):
  result = []

  o_parens = [p[0] for p in parens]
  c_parens = [p[1] for p in parens]

  for entry in entries:

    for col in cols:
      try: entry[col]
      except: raise ValueError('index', col, 'not in entry:', entry)

      count = 0

      entry_letters = []

      for l in entry[col]:
        if list(filter(None, [regex.match(o_paren, l) for o_paren in o_parens])):
          if not count > 0:
            entry_letters.append(l)
          count += 1
        elif list(filter(None, [regex.match(c_paren, l) for c_paren in c_parens])):
          if not count > 1:
            entry_letters.append(l)
          count -= 1
        else:
          entry_letters.append(l)

      entry[col] = ''.join(entry_letters)

      """
      for paren in parens:
        out_o, out_c = paren
        for paren2 in parens:
          in_o, in_c = paren2
          new = regex.sub(r'(' + out_o + r'[^' + in_o + r']*)' + in_o + r'([^' + in_c + r']*)' + in_c + r'([^' + out_c + r']*' + out_c + r')', r'\1\2\3', entry[col]).strip()
          while entry[col] != new:
            entry[col] = new
            new = regex.sub(r'(' + out_o + r'[^' + in_o + r']*)' + in_o + r'([^' + in_c + r']*)' + in_c + r'([^' + out_c + r']*' + out_c + r')', r'\1\2\3', new)
      """

    result.append(entry)

  return result


def regexsubcol(refrom, reto, cols, entries):
  result = []
  for entry in entries:
    for col in cols:
      try: entry[col]
      except: raise ValueError('index', col, 'not in entry:', entry)
      entry[col] = regex.sub(refrom, reto, entry[col]).strip()
    result.append(entry)
  return result


def prepsyns(entries, cols, refrom, lng, delim='‣', splitdetectsentences=True, pretag_special_lvs=True):
  """ Splits at given regex (outside parens), runs exdfprep, joins with syn delimiter,
  and removes nested parens.
  entries = list of entries
  cols    = cols on which to operate
  refrom  = regex to split synonyms
  lng     = language, for exdfprep
  delim   = output delimiter for synonyms
  """
  assert isinstance(cols, list)
  result = []
  entries = split_outside_parens(entries, cols, refrom, detectsentences=splitdetectsentences)
  entries = exdfprep(entries, cols, lang=lng, pretag_special_lvs=pretag_special_lvs)
  for entry in entries:
    for col in cols:
      # remove parens on entries enclosed entirely in parens
      # for paren in PARENS:
      #   entry[col] = [regex.sub(r'^' + paren[0] + r'(.*)' + paren[1] + r'$', r'\1', syn) for syn in entry[col]]
      entry[col] = delim.join(nodupes(filter(None, entry[col])))
    result.append(entry)
  result = remove_nested_parens(entries, cols)
  return result

def nodupes(ls):
  result = []
  for l in ls:
    if l not in result:
      result.append(l)
  return result


def resolve_xrefs(entries, fromcol, hwcol, xref_format=r'^= (.+)$'):
  """ Resolve cross-references by copying information from other entries.
  entries = list of entries
  fromcol = column with cross-references to resolve
  hwcol   = column with headwords that are being referenced
  xref_format = regex to detect crossrefs. capture group 1 should match a potential headword.
  """
  result = []
  for entry in entries:
    try: entry[fromcol]
    except: raise ValueError('index', fromcol, 'not in entry:', entry)
    m = regex.match(xref_format, entry[fromcol])
    if m:
      try: hw = entry[hwcol]
      except: raise ValueError('index', hwcol, 'not in entry:', entry)
      try: xref = m.group(1)
      except: raise ValueError('crossref format regex has no capture group:', xref_format)
      for entry2 in entries:
        try: entry2[hwcol]
        except: raise ValueError('index', hwcol, 'not in entry:', entry2)
        if entry2[hwcol] == xref:
          result.append(entry2[:hwcol] + [hw] + entry2[hwcol+1:])
    else: # no match, just pass through
      result.append(entry)
  return result


def get_normalize_scores(exps, lang='eng-000'):
  """ 
  exps = list of expressions to get scores
  lang = panlex language variety, including hyphen and 3 digit id
  returns dict of expressions and their scores
  """
  assert isinstance(exps, list)

  url = 'http://api.panlex.org/norm/ex/' + lang

  # build proper query string
  query  = '{ "tt" : ["'
  for exp in exps:
    query += exp.replace('"', '\\"')
    query += '","'
  query = query[:-3] + '"] }'

  req = urllib.request.Request(url, query.encode('utf-8'))

  with urllib.request.urlopen(req) as r:
    response = r.read().strip()

  result = json.loads(response)

  scores = {}
  for exp in exps:
    scores[exp] = result['norm'][exp]['score']

  sleep(0.5)

  return scores


def normalize(entries, col, threshold=50, lang='eng-000'):
  """ keeps/discards entries based on expressions in given column. """
  assert col < len(entries[0])
  result = []
  scores = get_normalize_scores([entry[col] for entry in entries])
  for entry in entries:
    if scores[entry[col]] >= threshold:
      result.append(entry)
  return result


def jpn_normalize(entries, col, delim='‣', maxlen=3, dftag='⫷df⫸'):
  """ Keeps, or retags entries based on expressions in given column. """
  if not MecabSoup:
    from MecabSoup import MecabSoup

  assert col < len(entries[0])
  result = []
  for entry in entries:
    if not isinstance(entry[col], list):
      entry[col] = entry[col].split(delim)
    newentry = []
    for syn in entry[col]:
      syn_noparens = regex.sub(make_paren_regex(), '', syn).strip()
      syn_noparens = regex.sub(r'⫷.*', '', syn_noparens).strip()
      syn_noparens = regex.sub(r'\s*…\s*', '', syn_noparens).strip()
      if len(syn_noparens) <= maxlen: # too short, no need to analyze
        newentry.append(syn)
        print(syn)
      else:
        if MecabSoup(syn_noparens).length > maxlen:
          # retag
          newentry.append(dftag+syn)
          print(dftag+syn)
        else:
          newentry.append(syn)
          print(syn)
    result.append(entry[:col] + [delim.join(newentry).replace(delim+dftag[0],dftag[0])] + entry[col+1:])
  return result


def lemmatize_verb(text):
  if not TextBlob:
    from textblob import TextBlob
  if not nltk:
    import nltk

  ops = r'|'.join([p[0] for p in PARENS])
  cps = r'|'.join([p[1] for p in PARENS])

  text_annot = []
  paren_counter = 0
  last_paren_word = False
  for word in text.split(' '):
    for letter in word:
      if regex.match(ops, letter):
        paren_counter += 1
      elif regex.match(cps, letter):
        paren_counter -= 1
        if paren_counter == 0:
          last_paren_word = True
    text_annot.append((word, paren_counter == 0 and not last_paren_word))
    last_paren_word = False


  to_blob = ' '.join([w[0] for w in text_annot if w[1]])
  to_blob = regex.sub(r'\s+,', ',', to_blob).strip()
  to_blob = regex.sub(r' n\'t', 'n\'t', to_blob).strip()
  to_blob = to_blob.split(' ')

  blob = TextBlob(' '.join(to_blob))

  assert(len(blob.words) == len(to_blob))

  if ('it' in text and not text.startswith('it')) or 'him' in text:
    tags = nltk.pos_tag(['it'] + blob.words)[1:]
  else:
    tags = nltk.pos_tag(blob.words)


  lemmatized_verbs = ' '.join([TextBlob(tags[i][0]).words[0].lemmatize('v') if tags[i][1] in ['VB','VBD','VBP','VBZ'] else to_blob[i] for i in range(len(tags))])

  print(blob.words, '-->', tags, '---->', lemmatized_verbs)

  return lemmatized_verbs


def single_expsplit(exp, splitdelim='/', expdelim='‣'):
  assert isinstance(exp, str)
  """ splits individual expressions based on some punctuation cue """
  p = make_paren_regex()[1:-1]
  prs = ''.join([r[0] for r in PARENS]) + ''.join([r[1] for r in PARENS])
  done = False
  while not done:
    exp = exp.split(expdelim)
    newexp = []
    for ex in exp:
      newex = ex
      if splitdelim == '/': # fwd slash, no space
        newex = regex.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^/\s'+prs+']+)/([^\s'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+r')*)$', r'\1\2\3\5\6'+expdelim+r'\1\2\4\5\6', newex)

      elif splitdelim == '()': # parens, space agnostic
        newex = regex.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^'+prs+']+)\(([^\)\s]+)\)([^'+prs+']*)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
        newex = regex.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^'+prs+']*)\(([^\)\s]+)\)([^'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)

      elif splitdelim == '(ns)': # parens, no space
        newex = regex.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^\s'+prs+']+)\(([^\)\s]+)\)([^\s'+prs+']*)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
        newex = regex.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^\s'+prs+']*)\(([^\)\s]+)\)([^\s'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)

      elif splitdelim == '[]': # brackets, space agnostic
        newex = regex.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^'+prs+']+)\[([^\]]+)\]([^'+prs+']*)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
        newex = regex.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^'+prs+']*)\[([^\]]+)\]([^'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)

      elif splitdelim == '[ns]': # brackets, no space
        newex = regex.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^\s'+prs+']+)\[([^\]]+)\]([^\s'+prs+']*)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
        newex = regex.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^\s'+prs+']*)\[([^\]]+)\]([^\s'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)

      elif splitdelim == '{}': # braces, space agnostic
        newex = regex.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^'+prs+']+)\{([^\}]+)\}([^'+prs+']*)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
        newex = regex.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^'+prs+']*)\{([^\}]+)\}([^'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)

      elif splitdelim == '{ns}': # braces, no space
        newex = regex.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^\s'+prs+']+)\{([^\}]+)\}([^\s'+prs+']*)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
        newex = regex.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^\s'+prs+']*)\{([^\}]+)\}([^\s'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
      else:
        raise ValueException('invalid delimiter')
      newex = regex.sub(r'\s*'+expdelim+r'\s*', expdelim, newex).strip()
      newex = regex.sub(r'\s\s+', ' ', newex).strip()
      newexp.append(newex)
    if set(newexp) == set(exp):
      done = True
    exp = expdelim.join(newexp)
  return exp


def expsplit(entries, cols, splitdelim='/', expdelim='‣'):
  for col in cols:
    assert col < len(entries[0])
  result = []
  for entry in entries:
    newentry = []
    for col in range(len(entry)):
      newcol = entry[col]
      if col in cols:
        splitcol = newcol if isinstance(newcol, list) else newcol.split(expdelim)
        newcol = [single_expsplit(exp, splitdelim, expdelim) for exp in splitcol]
        newcol = expdelim.join(newcol)
      newentry.append(newcol)
    result.append(newentry)
  return result

NO_DECAP = ['I', 'March', 'May', 'Turkey', 'Ashavan', 'Asha', 'Zarathushtra', 'Ahura', 'Khwarrah', 'Fravashi', 'Fravashis', 'Mazda', 'Mithra']

def decap(entries, cols):
  # decapitalize the first (after parens) letter of each given column (except for some key words)
  for col in cols:
    assert col < len(entries[0])
  result = []
  for entry in entries:
    newentry = []
    for col in range(len(entry)):
      newcol = entry[col]
      if col in cols:
        m = regex.match(r'^((?:'+make_paren_regex()[1:-1]+r')?)\s*(.*)$', newcol)
        if not m:
          raise ValueException('unexpected un-match:', newcol)
        else:
          paren, rest = m.group(1), m.group(2)
          if not list(filter(None, [regex.search(r'^'+nd+r'(?:\s|‣|⫷|;|,|\.|:|$)', rest) for nd in NO_DECAP])):
            newcol = paren + ' ' + rest[0].lower() + rest[1:]
            newcol = newcol.strip()
      newentry.append(newcol)
    result.append(newentry)
  return result


def tsv_to_entries(infile):
  entries = [line.split('\t') for line in infile.readlines()]
  return preprocess(entries)

def delete_col(entries, col):
  assert col < len(entries[0])
  return [entry[:col] + entry[col+1:] for entry in entries]


def correct_homoglyphs(entries, cols, target_script='Latn'):
  # convert any stray characters from other scripts (Latin, Cyrillic, Greek)
  # to their homoglyphs in the target_script script
  for col in cols:
    assert col < len(entries[0])
  assert target_script in ['Latn', 'Cyrl', 'Grek']
  if not HOMOGLYPH_DICTS: __init_homoglyph_dicts()
  result = []
  for entry in entries:
    newentry = []
    for col in range(len(entry)):
      newcol = entry[col]
      if col in cols:
        newcol = ''.join([HOMOGLYPH_DICTS[target_script][c] if c in HOMOGLYPH_DICTS[target_script].keys() else c for c in newcol])
      newentry.append(newcol)
    result.append(newentry)
  return result

HOMOGLYPH_DICTS = {}

def __init_homoglyph_dicts():
  HOMOGLYPHS = [
    ('A','Α','А'),
    ('B','Β','В'),
    ('C','Ϲ','С'),
    ('E','Ε','Е'),
    ('F','Ϝ',''),
    ('G','','Ԍ'),
    ('H','Η','Н'),
    ('I','Ι','І'),
    ('J','','Ј'),
    ('K','Κ','К'),
    ('M','Μ','М'),
    ('N','Ν',''),
    ('O','Ο','О'),
    ('P','Ρ','Р'),
    ('S','','Ѕ'),
    ('T','Τ','Т'),
    ('V','','Ѵ'),
    ('X','Χ','Х'),
    ('Y','Υ','Ү'),
    ('Z','Ζ',''),
    ('a','α','а'),
    ('b','β','Ь'),
    ('c','ϲ','с'),
    ('d','','ԁ'),
    ('e','ε','е'),
    ('h','','һ'),
    ('i','ι','і'),
    ('j','','ј'),
    ('k','κ','к'),
    ('o','ο','о'),
    ('p','ρ','р'),
    ('s','ς','ѕ'),
    ('t','τ','т'),
    ('v','ν','ѵ'),
    ('w','','ѡ'),
    ('x','χ','х'),
    ('y','γ','у'),
    ('Ä','','Ӓ'),
    ('Ö','','Ӧ'),
    #('ß','β',''),
    ('ä','','ӓ'),
    ('ö','','ӧ')
  ]
  TO_LATN, TO_CYRL, TO_GREK = {}, {}, {}
  for triple in HOMOGLYPHS:
    latn, grek, cyrl = triple
    if latn and grek:
      TO_LATN[grek] = latn
      TO_GREK[latn] = grek
    if latn and cyrl:
      TO_LATN[cyrl] = latn
      TO_CYRL[latn] = cyrl
    if grek and cyrl:
      TO_GREK[cyrl] = grek
      TO_CYRL[grek] = cyrl
  global HOMOGLYPH_DICTS
  HOMOGLYPH_DICTS = {
    'Latn' : TO_LATN,
    'Cyrl' : TO_CYRL,
    'Grek' : TO_GREK
  }


def __all_vowels_to_a(s, vowels='AEIOUYaeiouy'):
  return ''.join(['a' if unidecode(letter) in vowels else letter for letter in s])

def __degrade(s):
  return s.replace('j','i').replace('w','u')

def synthesize_strings(s1, s2, max_overlap=4, vowels='AEIOUYaeiouy'):
  # return a synthesis of the first and second strings, based on max_overlap amount

  max_overlap = min(max_overlap, min(len(s1),len(s2))) # account for string lengths
  
  # first check for exact matches, then inexact matches, on all lengths except 1
  for overlap in range(max_overlap, 1, -1):
    for match in range(overlap, 1, -1):
      s1p = s1[-overlap:] if overlap == match else s1[-overlap:-overlap+match]
      s2p = s2[:match]
      s1pd = __all_vowels_to_a(__degrade(s1p))
      s2pd = __all_vowels_to_a(__degrade(s2p))
      if s1p == s2p or s1pd == s2pd:
        return s1[:-overlap]+s2
  # now length 1 exact, or degraded
  for overlap in range(max_overlap, 0, -1):
    s1l = s1[-overlap]
    s2l = s2[0]
    s1ld = __degrade(s1l)
    s2ld = __degrade(s2l)
    if s1l == s2l or s1ld == s2ld:
      return s1[:-overlap]+s2

  return s1+s2