#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# PanLex ToolKit

import unicodedata
import regex as re
from unidecode import unidecode
from bs4 import Tag
from time import sleep

def preprocess(entries):
    # perform across-the-board preprocessing of things that should !ALWAYS! be done
    result = []
    for entry in entries:
        processed_entry = []
        for col in entry:

            # nonstandard spaces/newlines/control characters
            col = re.sub(r'[\x19\xa0\x7f\u200B\u200E\uFEFF\n]', ' ', col).strip()

            # fullwidth punctuation, numbers
            col = col.replace('？', '?')
            col = col.replace('！', '!')
            # if re.search(r'\p{Nd}', col):
            #     col = unicodedata.normalize('NFKC', col).strip()

            # parenthesis standardization
            if '(' in col or ')' in col:
                col = col.replace('（','(').replace('）',')')

            # hyphen to hyphen-minus
            col = col.replace('‐','-')

            # "etc"
            col = re.sub(r'[\,、;]?\s*(etc| u\.ä\.?)\.?$', '', col).strip()
            # ellipses
            col = re.sub(r'・・・', '...', col)
            col = re.sub(r'__+', '...', col)
            col = re.sub(r'[～〜]', '...', col)
            col = re.sub(r'\.\s*\.(\s*\.)+', ' … ', col).strip()
            col = re.sub(r'\s*…\s*', ' … ', col).strip()
            col = re.sub(r'^\s*…', '', col).strip()
            col = re.sub(r'…\s*$', '', col).strip()

            # excess whitespace
            col = re.sub(r'    +', r' ',col).strip()
            col = re.sub(r'\( +','(',col).strip()
            col = re.sub(r' +\)',')',col).strip()

            # weirdly placed commas
            col = re.sub(r'\s* ,([^\s])', r', \1', col).strip()

            # digit separator commas
            col = re.sub(r'(\d),(\d\d\d)', r'\1\2', col).strip()
            col = re.sub(r'(\d)\.(\d\d\d)', r'\1\2', col).strip()

            # surprise html encoded chars
            col = col.replace('&amp;', '&')
            col = col.replace('&quot;', '"')

            processed_entry.append(col)
        result.append(processed_entry)

    return result


PARENS = [(r'\(',r'\)'),(r'\[',r'\]'),(r'\{',r'\}'),(r'（',r'）'),(r'【',r'】')]

def split_outside_parens(entries, cols, delim=r',', parens=PARENS):
    ''' Peforms a split of each specified column, but ignores anything in parens.
    entries        = list of entries, which are lists of columns
    cols        = list of columns (element indices) on which to perform operation
    delim     = regex of delimiter(s) at which to split
    parens    = list of tuples of opening and closing characters (regex escaped)
                        to be considered parenthetical '''

    SOP_DELIM = ''
    TEMP_PAREN = [(r'🁾',r'🂊')]

    # detect sentences
    parens += TEMP_PAREN
    minwords = 4

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

                # detect sentences/other non splittable things and put special parens around them
                # sentences: start w/ capital letter, end with period(s)
                entry[col] = re.sub(r'(\p{Lu}(?:'+make_paren_regex(cap=False)+r'|[^\s\(\)\[\].])+(?:\s+(?:'+make_paren_regex(cap=False)+r'|[^\s\(\)\[\].])+){'+str(minwords)+r',}[\.!?]+)', TEMP_PAREN[0][0]+r'\1'+TEMP_PAREN[0][1], entry[col])
                # commas separating decimals or digit groups
                entry[col] = re.sub(r'(\d+(?:,\d+)+)', TEMP_PAREN[0][0]+r'\1'+TEMP_PAREN[0][1], entry[col])

                count = 0

                entry_letters = []

                for l in entry[col]:
                    if list(filter(None, [re.match(o_paren, l) for o_paren in o_parens])):
                        # if letter is open paren
                        entry_letters.append(l)
                        count += 1
                    elif list(filter(None, [re.match(c_paren, l) for c_paren in c_parens])):
                        # if letter is close paren
                        entry_letters.append(l)
                        count -= 1
                    elif count == 0 and re.match(delim, l):
                        entry_letters.append(SOP_DELIM)
                    else:
                        entry_letters.append(l)

                entry[col] = [re.sub(r'['+TEMP_PAREN[0][0]+TEMP_PAREN[0][1]+r']', '',    c).strip() for c in ''.join(entry_letters).split(SOP_DELIM)]

            else:
                entry[col] = [entry[col]]

        result.append(entry)
    return result


def make_paren_regex(parens=PARENS, maxnested=10, cap=True):
    ''' Makes a regex to match any parenthetical content, up to a certain number
            of layers deep.
    parens    = list of tuples of opening and closing characters (regex escaped)
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
    result = r'|'.join(paren_res) + r')'
    result = r'(' + result if cap else r'(?:' + result
    return result

def remove_parens(s, parens=PARENS):
    return re.sub(make_paren_regex(), '', s).strip()


EXDFPREP_RULES = {
    'eng-000' : {
        1: {
            r'(^| )big bird($)' : (r'\1(big) bird\2', '⫷mcs2:art-300⫸IsA⫷mcs:eng-000⫸bird'),
            r'^you (sg|pl)\.?$' : (r'you (\1)', ''),
            r'(^| )potatoe( |$)' : (r'\1potato\2', ''),
            r'(^| )to day( |$)' : (r'\1today\2', ''),
        },
        2: {
            r'([^\s])\s+(s(?:\-|o(?:me|em))(?: other )?(?: other )?(?:one|body|thing)(?:(?: or |\s*/\s*)s(?:\-|o(?:me|em))(?: other )?(?:one|body|thing))?(?: (?:who|which|that) is)?|s\.[bot]\.?|o\.s\.?)([^\'’]|$)' : (r'\1 (\2)\3', ''),
            r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)(s(?:\-|o(?:me|em))(?: other )?(?:one|body|thing)(?:(?: or |\s*/\s*)s(?:\-|o(?:me|em))(?: other )?(?:one|body|thing))?|s\.[bot]\.?|o\.s\.?)\s+([^\s])' : (r'\1(\2) \3', ''),
            r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)(s(?:\-|o(?:me|em))(?: other )?(?:one|body|thing)[\'’]?s)\s+([^\s])' : (r'\1(\2) \3', ''),
            r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)((?:(?:for (?:something|s\.t\.?))?\(?\s*to\s*\)?\s+)?be)\s+([^\(])'    : (r'\1(\2) \3', ''),
            r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)(\(?(?:a\s+)?(?:kind|variety|type|sort|species) of(?: an?(?= ))?\)?|k\.?o\.)\s*' : (r'\1(\2) ', r''),
        },
        3: {
            r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)([Tt]he|[Aa]n?)\s+((?:'+make_paren_regex(cap=False)+r'\s*)*[^\(\)\[\]\s]+)$'     : (r'\1(\2) \3', ''),            # r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)(the)\s+([^\(])'     : (r'\1(\2) \3', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'),
            r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)\((s(?:\-|o(?:me|em))(?: other )?(?:one|body|thing)(?:(?: or |\s*/\s*)s(?:\-|o(?:me|em))(?: other )?(?:one|body|thing))?|s\.[bot]\.?|o\.s\.?)\)\s+(which|that|who|to)' : (r'\1\2 \3', ''),
            r'\((s(?:\-|o(?:me|em))(?: other )?(?:one|body|thing)(?:(?: or |\s*/\s*)s(?:\-|o(?:me|em))(?: other )?(?:one|body|thing))?|s\.[bot]\.?|o\.s\.?)\)\s+(else(?:\'s)?)' : (r'(\1 \2)', ''),
            r'^\((s(?:\-|o(?:me|em))(?: other )?(?:one|body|thing)(?:(?: or |\s*/\s*)s(?:\-|o(?:me|em))(?: other )?(?:one|body|thing))?|s\.[bot]\.?|o\.s\.?)\)\s+' : (r'\1 ', ''),
            r'^((?:[^\s\(\)\[\]]+\s)?)((?:'+make_paren_regex(cap=False)+r')?\s*)(\(?(?:kind|variety|type|sort|species) of(?: an?)?\)?|\(?k\.?o\.\)?)\s*([^\s]+ ?[^\s]+)$' : (r'\2 (\3) \1\4', r'⫷mcs2:art-300⫸IsA⫷mcs:eng-000⫸\4'),
            r'^((?:'+make_paren_regex(cap=False)+r')?\s*)(\(?(?:a\s+)?(?:kind|variety|type|sort|species) of(?: an?)?\)?|\(?k\.?o\.\)?)\s*([^\s]+ ?[^\s]+)$' : (r'\1 (\2) \3', r'⫷mcs2:art-300⫸IsA⫷mcs:eng-000⫸\3'),
        },
        4: {
            r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)((?:not )?)[Tt]o\s+(?!the(?: |$)|you(?: |$)|us(?: |$)|him(?: |$)|her(?: |$)|them(?: |$)|me(?: |$)|[wt]?here(?: |$)|no(?: |$)|one\'s(?: |$)|oneself(?: |$)'+make_paren_regex(cap=True)+r'$)' : (r'\1\2(to) ', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Verbal'),
            r'(^| )make to ' : (r'\1make (to) ', '')
        },
        5: {
            r'(^|\s)\(a\) (lot|bit|posteriori|priori|fortiori|few|little|minute|same|while|propos|capella)(\s|$)' : (r'\1a \2\3', r''),
            r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)((?:\(to\) )?)(become)\s+([^\s\()][^\s]*)$' : (r'\1\2\3 \4', r'⫷mcs2:art-316⫸Inchoative_of⫷mcs⫸\4'),
            r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)((?:\(to\) )?)(make\s+)((?:\(to\)\s+)?)((?:'+make_paren_regex(cap=False)+r'\s*)?)\s+(?!space(?: |$)|room(?: |$)|out(?: |$)|love(?: |$))([^\s\()][^\s]*)$'     : (r'\1\2\3\4 \5 \6', r'⫷mcs2:art-316⫸Causative_of⫷mcs⫸\6'),
        },
        6: {
            # r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)\(([Tt]he|[Aa]n?)\)\s+((?:(?:'+make_paren_regex()[1:-1]+'|[^\(\)\[\]\s]+))(?: (?:'+make_paren_regex()[1:-1]+'|[^\(\)\[\]\s]+))?)$'     : (r'\1(\2) \3', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'),
            r' ?\(n\.?\)$' : ('', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'),
            r' ?\(v\.?\)$' : ('', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Verbal'),
            r' ?\(v\.?i\.?\)$' : ('', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸IntransitiveVerb'),
            r' ?\(v\.?t\.?\)$' : ('', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸TransitiveVerb'),
            r' ?\(sg\.?\)$' : ('', '⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸SingularNumber'),
            r' ?\(singular\)$' : ('', '⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸SingularNumber'),
            r' ?\([pP]l?\.?\)$' : ('', '⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
            r' ?\(plural\)$' : ('', '⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
            r' ?\(excl?(usive)?\)$' : ('', '⫷dcs2:art-303⫸PersonProperty⫷dcs:art-303⫸FirstPersonExclusive'),
            r' ?\(incl?(usive)?\)$' : ('', '⫷dcs2:art-303⫸PersonProperty⫷dcs:art-303⫸FirstPersonInclusive'),
            r' ?\(impol(ite)?\)$' : ('', '⫷dcs2:art-317⫸register⫷dcs:art-317⫸vulgarRegister'),
            r' ?\(pol(ite)?\)$' : ('', '⫷dcs2:art-317⫸register⫷dcs:art-306⫸POL'),
            r'^do it$' : ('⫷df⫸do it', ''),
            r'fæces' : ('faeces', ''),
            r'^to become$' : ('(to) become', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Verbal'),
            r'\(the\) whole lot⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun' : ('the whole lot', '')
        },
    },
    'jpn-000' : {
        1: {
            r'^(.+)(である)$' : (r'\1(\2)', ''), # to be ~
            r'([\p{Han}\p{Katakana}]'+make_paren_regex(cap=False)+r'?)(だ|の|な)$' : (r'\1(\2)', ''),
            r'^(.*[\p{Han}])(らせる)$' : (r'\1\2', r'⫷mcs2:art-316⫸Causative_of⫷mcs⫸\1る'),
            r'^(させる)$' : (r'\1', r'⫷mcs2:art-316⫸Causative_of⫷mcs⫸する'),
            r'^(が)(\p{Han})' : (r'(\1)\2', r''),
            # r'^(を)(\p{Han})' : (r'(\1)\2', r''),
            r'^(を)' : (r'(\1)', r''),
            r'(など)$' : (r'(\1)', ''),    # ... etc.
            r'^([^…]+)(くなる)$' : (r'\1\2', r'⫷mcs2:art-316⫸Inchoative_of⫷mcs⫸\1い'),    # to become ~ (keiyoshi)
            r'^([^…]+)(になる)$' : (r'\1\2', r'⫷mcs2:art-316⫸Inchoative_of⫷mcs⫸\1'),    # to become ~
            r'^[…\s]*(に)(なる)$' : (r'(\1)\2', r''),    # to become
        },
        2: {
            r'其('+make_paren_regex(cap=False)+r'?)\(の\)' : (r'其\1の', ''),
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
            r'^\(?([Ee]l|[Uu]n)\)?\s+([^\s\(])'    : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'), # Masculine not determined
            r'^\(?([Ll]os|[Uu]nos)\)?\s+([^\s\(])'    : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
            r'^\(?([Ll]a|[Uu]na)\)?\s+([^\s\(])'    : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender'),
            r'^\(?([Ll]as|[Uu]nas)\)?\s+([^\s\(])'    : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
            r'^\(?([Ss]er|[Ee]star)\)?\s+([^\s\(])'    : (r'(\1) \2', ''),
            #r'\s+of(\s*(?:\([^\)]*\)\s*)*)$'                    : (r' (of)\1', ''),
            r'^\s*¡|!\s*$'    : ('', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Interjection'),
            r'[¿\?]' : ('', '⫷dcs2:art-303⫸ForceProperty⫷dcs:art-303⫸InterrogativeForce'),
            r'[¡\!]' : ('', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Interjection'),
            r'^idioma ([^\s\(][^\s]*)$' : (r'(idioma) \1', ''),
            r'^(\(?(?:una?\s+)?(?:clase) de\)?)\s*([^\s]+ ?[^\s]+)$' : (r'(\1) \2', r'⫷mcs2:art-300⫸IsA⫷mcs:spa-000⫸\2'),
        },
        2 : {
            r' \(m\.?\)$' : ('', '⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender'),
            r' \(f\.?\)$' : ('', '⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender'),
        }
    },
    'cat-000' : {
        1 : {
            r'[¿\?]' : ('', '⫷dcs2:art-303⫸ForceProperty⫷dcs:art-303⫸InterrogativeForce'),
        },
    },
    'nld-000' : {
        1 : {
            r'^soort (\S*)$' : (r'(soort) \1', r'⫷mcs2:art-300⫸IsA⫷mcs:nld-000⫸\1'),
        },
        2 : {
            r'^soort (.*)$' : (r'(soort) \1', r''),
        },
    },
    'ile-000' : {
        1 : {
            r'^\(?([Ll][ie])\)?\s+([^\s\(])'    : (r'(\1) \2',    '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'),
            r'^\(?([Uu]n)\)?\s+([^\s\(])'    : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'),
        },
    },
    'ast-000' : {
        1 : {
            r'^\(?([Ee]l)\)?\s+([^\s\(])'    : (r'(\1) \2',    '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender'),
            r'^\(?([Ll]os)\)?\s+([^\s\(])'    : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
            r'^\(?([Ll]a)\)?\s+([^\s\(])'    : (r'(\1) \2',    '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender'),
            r'^\(?([Ll]es)\)?\s+([^\s\(])'    : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
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
            r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)((?:\(?\s*å\s*\)?\s+)?bli)\s+([^\(])'    : (r'\1(\2) \3', ''),
        },
        2: {
            r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)å\s+' : (r'\1(å) ', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Verbal'),
        },
    },
    'dan-000' : {
        1: {
            r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)(e[nt])\s+' : (r'\1(\2) ', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'),
        },
    },
    'fra-000' : {
        1 : {
            r'^(.+)\s+(quelqu[\'’]un|quelque chose)' : (r'\1 (\2)', ''),
            r'\(?(q\.?q\.?(?:ch|un?|n)\.?)\)?' : (r'(\1)', ''),
            r'^([Ll][\'’])([^\s\(])' : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun'),
            r'^([Ll]e)\s+([^\s\(])'         : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender'),
            r'^([Ll]a)\s+([^\s\(])'         : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender'),
            r'^([Ll]es)\s+([^\s\(])'        : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸NumberProperty⫷dcs:art-303⫸PluralNumber'),
            r'^([Uu]n)\s+([^\s\(])'         : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender'),
            r'^([Uu]ne)\s+([^\s\(])'        : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Noun⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender'),
            r'^(ê\.|être)\s+([^\s\(])'     : (r'(\1) \2', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Adjectival'),
            r'^(\(?(?:type|sorte|espèce) d[e\']\)?)\s*(.+)$' : (r'(\1) \2', r'⫷mcs2:art-300⫸IsA⫷mcs:fra-000⫸\2'),
        },
        2: {
            r'^devenir\s+([^\s]+)((?:\s*'+make_paren_regex(cap=False)+r')?$)' : (r'devenir \1\2', r'⫷dcs2:art-316⫸Inchoative_of⫷dcs⫸\1'),
            r' \(m\.?\)$' : ('', '⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸MasculineGender'),
            r' \(f\.?\)$' : ('', '⫷dcs2:art-303⫸GenderProperty⫷dcs:art-303⫸FeminineGender'),
        }
    },
    'isl-000' : {
        1 : {
            r'^(vera)\s+'     : (r'(\1) ', ''),
            r'(^|[^\s]\s+)(e\-(?:[ðimnstu]|ar?|rs?))(\s|$)' : (r'\1(\2)\3', ''),

            # e-a    einhverja, einhverra        (fem acc sg, msc acc pl; msc/fem/neu gen pl)
            # e-ar einhverjar, einhverrar    (fem nom/acc pl; fem gen sg)
            # e-ð    eitthvað         (neu nom/acc sg substant)
            # e-i    einhverri        (fem dat sg)
            # e-m    einhverjum     (msc dat sg, msc/fem/neu dat pl)
            # e-n    einhvern         (msc acc sg)
            # e-r    einhver            (msc/fem nom sg)
            # e-(r)s einhvers     (msc/neu gen sg)
            # e-t    eitthvert        (neu nom/acc sg demonstr)
            # e-u    einhverju        (neu dat sg)

            r'^([^z]*)z([^z]*)$'     : (r'\1z\2', r'⫷ex:isl-000⫸\1s\2'), # 1973 reforms
        },
        2 : {
            r'⫷ex:isl-000⫸([^z⫷]*)z([^z⫷]*)'     : ('', ''),
        },
    },
    'ces-000' : {
        # a (také) = and (also)
        1 : {
            r'^(být)\s+'     : (r'(\1) ', ''), # to be
            r'^(nějaký)\s+' : (r'(\1) ', ''), # some, a(n)
        },
        2: {
        }
    },
    'fin-000' : {
        1 : {
            r'^(olla)\s+'     : (r'(\1) ', ''),
        },
        2: {
            r'^(tulla)\s+(.+)$' : (r'\1 \2', r'⫷dcs2:art-316⫸Inchoative_of⫷dcs⫸\2')
        }
    },
    'deu-000' : {
        1 : {
            r'((?:etw(?:\.|as)|jemand(?:en)?)(?: oder etwas)?(?:,? (?:der|was))?)([^\'’]|$)' : (r'(\1)\2', ''),
            r'\s+(d\.[ih]\..*)$' : (r' (\1)', ''),
            r'(^| )(o\.ä\.)( |$)' : (r'\1(\2)\3', ''),
            r'^((?:'+make_paren_regex(cap=False)+r'\s*)?)(ein(?:e[mnrs]?)?|die|das|de[mnrs])\s+([^\(])'     : (r'\1(\2) \3', ''),
        },
        2: {
        },
    },
    'rus-000' : {
        1: {
            r'(^|[^ ] +)((?:что|чего|чему|ч[её]м|чьих|чей|кто|кого|кем|кому?)\-л(?:ибо|\.)?(?: в (?:что|чего|чему|ч[её]м|чьих|чей|кто|кого|кем|кому?)\-л(?:ибо|\.)?)?)( |$)' : (r'\1(\2)\3', ''),
            r' (и т\.\s*п\.)' : (r' (\1)', ''),

            # something:    что-л (n/a), чего (g), чему (d), чем (i), чём (p)
            # someone:        кто-л (n), кого (g/a), кому (d), кем (i), ком (p)
        },
        2: {
            r'^\(((?:что|ч[её]м|чему|чего|чьих|кого|кем|кому)\-л\.?(?: в (?:что|ч[её]м|чему|чего|кого|кем|кому)\-л\.?)?)\)$' : (r'\1', ''),
        }
    },
    'general' : {
        998 : {
            r'(^\s*…|…\s*(?:$|⫷))' : ('', ''),
            # # r'^((?:[^\s][^\s]?\.)+)$' : (r'\1.', ''),
            r'\s+(\.(?:$|⫷))' : (r'\1', ''),
            r'\s*(\))\s*\.\s*($|⫷)' : (r'\1\2', ''),
        },
        999 : {
            r'(.)[！!]$'    : (r'\1', '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Interjection'),
            # r'(.)[？\?]$' : (r'\1', '⫷dcs2:art-303⫸ForceProperty⫷dcs:art-303⫸InterrogativeForce'),
            r'^\?+$' : ('', ''),
            r'["“”]'    : ('', ''),
            # delete periods at end, but only when no periods in exp already, and len > 6
            r'^([^\.]{6,})\s*\.$' : (r'\1', ''),
            r'^\(([^\(\)]*)\)$' : (r'⫷df⫸\1', ''),
            r'^\[([^\[\]]*)\]$' : (r'⫷df⫸\1', ''),
            r'^（([^\(\)]*)）$' : (r'⫷df⫸\1', ''),
            # numbered/lettered entries in front
            r'^[АБВГДЕЖЗабвгдежзABCDEFGHabcdefgh\d]\)\s+' : (r'', ''),
        }
    }
}

def exdfprep(entries, sourcecols, tocol=-1, lang='eng-000', pretag_special_lvs=True):
    ''' Parenthesizes "definitional" parts of an expression, and adds appropriate pretagged elements.
    entries        = list of entries, lists of elements; column with expressions to be process must be a list
    sourcecols = list of columns (element indices) on which to perform operation
    tocol     = new col in which to deposit pretagged content (end); if -1, use end of source col
    from        = regex of delimiters from which to convert '''

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
                                if re.search(rule, syn):
                                    replacement, pretag = rules[stage][rule]
                                    if '\\' in pretag:
                                        pretag_addn = re.sub(rule, pretag, syn).strip()
                                        old = syn
                                        while old != pretag_addn:
                                            old = pretag_addn
                                            pretag_addn = re.sub(rule, pretag, pretag_addn).strip()
                                        pretag_addn = re.sub(paren_re, '', pretag_addn).strip()
                                        pretag_addn = re.sub('⫸ +', '⫸', pretag_addn)
                                        pretags += pretag_addn
                                    else:
                                        pretags += pretag.strip()
                                    syn = re.sub(rule, replacement, syn).strip()

                        if tocol >= 0:
                            entry[tocol] += pretags # new prepared column
                        else:
                            syn += pretags # right after source

                        # pretag special language varieties:
                        if pretag_special_lvs:
                            # integers
                            int_m = re.match(r'^(?:⫷..⫸)?(\d+)($|⫷)', syn.strip())
                            if int_m:
                                if int_m.group(1) in ['747','411','911','119']:
                                    print('WARNING: Did not pretag potentially special number:', int_m.group(1))
                                else:
                                    syn = re.sub(r'^(?:⫷[^⫸]+⫸)?', '⫷ex:art-269⫸', unicodedata.normalize('NFKC', syn)).strip()


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
        for mn in re.split('⁋', entry[col]):
            result.append(entry[:col] + [mn] + entry[col+1:])
    return result


def separate_parentheticals(entries, cols, delim=r'[&,;]', parens=PARENS):
    ''' Separates parentheticals within an entry, to multiple sets of parentheses (for division into
            different columns, etc)
    entries = list of entries
    cols        = list of columns (element indices) on which to perform operation
    delim     = regex of delimiters at which to split
    parens    = list of tuples of opening and closing characters (regex escaped)
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
                new = re.sub(from_re, oraw+r'\1'+craw+' '+oraw+r'\2'+craw, entry[col])
                while entry[col] != new:
                    entry[col] = new
                    new = re.sub(from_re, oraw+r'\1'+craw+' '+oraw+r'\2'+craw, new)
                entry[col] = re.sub(r'\s+\)', ')', entry[col])

        result.append(entry)

    return result


def convert_between_cols(entries, conversion_rules, fromcol, tocol=-1, syn_delim='‣', delim='‣'):
    ''' Convert between columns, using a dictionary/dictionaries of conversion rules.
    entries        = list of elements (columns)
    conversion_rules = dict of conversions    { from : to } OR list of dicts of conversions to do in order
    fromcol = col from which to look
    tocol     = new col in which to deposit replacements (end); if -1, use end of source col
    syn_delim = delimiter between synonyms for each entry
    delim     = delimiter to use between replacements if not a fully-formed tag '''

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
                    m = re.search(rule, exp)
                    if m:
                        # if the conversion to isn't explicit tags, add the standard delimiter
                        if '⫷' not in curr_conv_rules[rule] and colbuffer:
                            colbuffer += delim
                        # if capture group exists, sub from the column
                        if '\\' in curr_conv_rules[rule]:
                            colbuffer += re.sub(rule, curr_conv_rules[rule], m.group(0))
                        # else just add the target
                        else:
                            colbuffer += curr_conv_rules[rule]
                        exp = re.sub(rule, ' ', exp).strip()
                        exp = re.sub(r'    +', ' ', exp.strip())
                newcol.append(exp)
            colbuffer = re.sub(r'    +', ' ', colbuffer.strip())

            entry[fromcol] = syn_delim.join(newcol)
            entry[curr_tocol] += colbuffer
            result.append(entry)
        new_entries = result

    return entries


def splitcol(entries, col, delim=''):
    result = []
    for entry in entries:
        assert isinstance(entry[col], str)
        entry[col] = [e.strip() for e in re.split(delim, entry[col]) if e.strip()]
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
                if list(filter(None, [re.match(o_paren, l) for o_paren in o_parens])):
                    if not count > 0:
                        entry_letters.append(l)
                    count += 1
                elif list(filter(None, [re.match(c_paren, l) for c_paren in c_parens])):
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
                    new = re.sub(r'(' + out_o + r'[^' + in_o + r']*)' + in_o + r'([^' + in_c + r']*)' + in_c + r'([^' + out_c + r']*' + out_c + r')', r'\1\2\3', entry[col]).strip()
                    while entry[col] != new:
                        entry[col] = new
                        new = re.sub(r'(' + out_o + r'[^' + in_o + r']*)' + in_o + r'([^' + in_c + r']*)' + in_c + r'([^' + out_c + r']*' + out_c + r')', r'\1\2\3', new)
            """

        result.append(entry)

    return result


def regexsubcol(refrom, reto, cols, entries):
    result = []
    for entry in entries:
        for col in cols:
            try: entry[col]
            except: raise ValueError('index', col, 'not in entry:', entry)
            entry[col] = re.sub(refrom, reto, entry[col]).strip()
        result.append(entry)
    return result


def prepsyns(entries, cols, refrom, lng, delim='‣', pretag_special_lvs=True):
    """ Splits at given regex (outside parens), runs exdfprep, joins with syn delimiter,
    and removes nested parens.
    entries = list of entries
    cols        = cols on which to operate
    refrom    = regex to split synonyms
    lng         = language, for exdfprep
    delim     = output delimiter for synonyms
    """
    assert isinstance(cols, list)
    result = []
    # split at given delimiter
    entries = split_outside_parens(entries, cols, refrom)
    # prepare as expression
    entries = exdfprep(entries, cols, lang=lng, pretag_special_lvs=pretag_special_lvs)
    # join with consistent synonym delimiter
    for entry in entries:
        for col in cols:
            entry[col] = delim.join(nodupes(filter(None, entry[col])))
        result.append(entry)
    # remove nested parens
    result = remove_nested_parens(entries, cols)
    # detect taxa, report if extract_taxa is advised
    # detect_taxa(entries, cols, delim=delim)
    return result

def nodupes(ls):
    result = []
    for l in ls:
        if l not in result:
            result.append(l)
    return result

def resolve_xrefs(entries, fromcol, hwcol, xref_format=r'^= (.+)$', delim='‣'):
    """ Resolve cross-references by copying information from other entries.
    entries = list of entries
    fromcol = column with cross-references to resolve
    hwcol     = column with headwords that are being referenced
    xref_format = regex to detect crossrefs. capture group 1 should match a potential headword.
    """
    xref_marker = '𝀿'
    result = []
    for entry in entries:
        try: entry[fromcol]
        except: raise ValueError('index', fromcol, 'not in entry:', entry)
        m = re.match(xref_format, entry[fromcol])
        if m:
            try: hw = entry[hwcol]
            except: raise ValueError('index', hwcol, 'not in entry:', entry)
            try: xref = m.group(1)
            except: raise ValueError('crossref format regex has no capture group:', xref_format)
            for entry2 in entries:
                try: entry2[hwcol]
                except: raise ValueError('index', hwcol, 'not in entry:', entry2)
                if entry2[hwcol] == xref:
                    entry2 = entry2[:fromcol] + [xref_marker+entry2[fromcol]] + entry2[fromcol+1:]
                    entry2 = entry2[:hwcol] + [hw] + entry2[hwcol+1:]
                    result.append(entry2)
        else: # no match, just pass through
            result.append(entry)

    # step2: if fromcols match, group the two together as a synonym pair
    result2 = []
    done_indices = []
    for i, entry in enumerate(result):
        if i not in done_indices:
            hws, to = [entry[hwcol]], entry[fromcol]
            for j, entry2 in enumerate(result):
                hw2, to2 = entry2[hwcol], entry2[fromcol]
                if xref_marker+to == to2:
                    hws.append(hw2)
                    done_indices.append(j)
            result2.append(entry[:hwcol] + [delim.join(hws)] + entry[hwcol+1:])

    result2 = [entry for entry in result2 if not entry[fromcol].startswith(xref_marker)]

    return result2


def get_normalize_scores(exps, lang='eng-000'):
    """
    exps = list of expressions to get scores
    lang = panlex language variety, including hyphen and 3 digit id
    returns dict of expressions and their scores
    """
    assert isinstance(exps, list)

    try:
        urllib.request
    except:
        import urllib.request

    try:
        sleep
    except:
        from time import sleep

    try:
        json
    except:
        import simplejson as json

    url = 'http://api.panlex.org/norm/ex/' + lang

    # build proper query string
    query  = '{ "tt" : ["'
    query += '","'.join([exp.replace('"', '\\"') for exp in exps])
    query += '"] }'

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


JPN_NORMALIZE_EXCEPTIONS = ['おねえちゃん', 'おにいちゃん', 'のんべえ', '一人一人']

def jpn_normalize(entries, col, delim='‣', maxlen=3, dftag='⫷df⫸', suppress_print=True):
    """ Keeps, or retags entries based on expressions in given column. """
    try:
        MecabSoup
    except:
        from MecabSoup import MecabSoup

    assert col < len(entries[0])
    result = []
    for entry in entries:
        if not isinstance(entry[col], list):
            entry[col] = entry[col].split(delim)
        newentry = []
        for syn in entry[col]:
            syn_noparens = re.sub(make_paren_regex(), '', syn).strip()
            syn_noparens = re.sub(r'⫷.*', '', syn_noparens).strip()
            syn_noparens = re.sub(r'\s*…\s*', '', syn_noparens).strip()
            for exc in JPN_NORMALIZE_EXCEPTIONS:
                syn_noparens = re.sub(exc, 'X', syn_noparens).strip()
            if len(syn_noparens) <= maxlen or not re.sub(r'\p{Katakana}+','',syn_noparens).strip(): # too short to analyze, or all katakana
                newentry.append(syn)
                if not suppress_print:
                    print(syn)
            else:
                if MecabSoup(syn_noparens).length > maxlen or '。' in syn_noparens:
                    # retag
                    newentry.append(dftag+syn)
                    if not suppress_print:
                        print(dftag+syn)
                else:
                    newentry.append(syn)
                    if not suppress_print:
                        print(syn)
        result.append(entry[:col] + [delim.join(newentry).replace(delim+dftag[0],dftag[0])] + entry[col+1:])
    return result


def lemmatize_verb(text):
    try:
        TextBlob
    except:
        from textblob import TextBlob

    try:
        nltk
    except:
        import nltk

    ops = r'|'.join([p[0] for p in PARENS])
    cps = r'|'.join([p[1] for p in PARENS])

    text_annot = []
    paren_counter = 0
    last_paren_word = False
    for word in text.split(' '):
        for letter in word:
            if re.match(ops, letter):
                paren_counter += 1
            elif re.match(cps, letter):
                paren_counter -= 1
                if paren_counter == 0:
                    last_paren_word = True
        text_annot.append((word, paren_counter == 0 and not last_paren_word))
        last_paren_word = False


    to_blob = ' '.join([w[0] for w in text_annot if w[1]])
    to_blob = re.sub(r'\s+,', ',', to_blob).strip()
    to_blob = re.sub(r' n\'t', 'n\'t', to_blob).strip()
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
                newex = re.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^/\s'+prs+']+)/([^\s'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+r')*)$', r'\1\2\3\5\6'+expdelim+r'\1\2\4\5\6', newex)

            elif splitdelim == '()': # parens, space agnostic
                newex = re.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^'+prs+']+)\(([^\)\s]+)\)([^'+prs+']*)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
                newex = re.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^'+prs+']*)\(([^\)\s]+)\)([^'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)

            elif splitdelim == '(ns)': # parens, no space
                newex = re.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^\s'+prs+']+)\(([^\)\s]+)\)([^\s'+prs+']*)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
                newex = re.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^\s'+prs+']*)\(([^\)\s]+)\)([^\s'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)

            elif splitdelim == '[]': # brackets, space agnostic
                newex = re.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^'+prs+']+)\[([^\]]+)\]([^'+prs+']*)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
                newex = re.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^'+prs+']*)\[([^\]]+)\]([^'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)

            elif splitdelim == '[ns]': # brackets, no space
                newex = re.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^\s'+prs+']+)\[([^\]]+)\]([^\s'+prs+']*)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
                newex = re.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^\s'+prs+']*)\[([^\]]+)\]([^\s'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)

            elif splitdelim == '{}': # braces, space agnostic
                newex = re.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^'+prs+']+)\{([^\}]+)\}([^'+prs+']*)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
                newex = re.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^'+prs+']*)\{([^\}]+)\}([^'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)

            elif splitdelim == '{ns}': # braces, no space
                newex = re.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^\s'+prs+']+)\{([^\}]+)\}([^\s'+prs+']*)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
                newex = re.sub(r'^((?:[^'+prs+']|'+p+')*)(^|\s)([^\s'+prs+']*)\{([^\}]+)\}([^\s'+prs+']+)(\s|$)((?:[^'+prs+']|'+p+')*)$', r'\1\2\3\5\6\7'+expdelim+r'\1\2\3\4\5\6\7', newex)
            else:
                raise ValueException('invalid delimiter')
            newex = re.sub(r'\s*'+expdelim+r'\s*', expdelim, newex).strip()
            newex = re.sub(r'\s\s+', ' ', newex).strip()
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
                m = re.match(r'^('+make_paren_regex(cap=False)+r'?)\s*(.*)$', newcol)
                if not m:
                    raise ValueException('unexpected non-match:', newcol)
                else:
                    paren, rest = m.group(1), m.group(2)
                    if not list(filter(None, [re.search(r'^'+nd+r'(?:\s|‣|⫷|;|,|\.|:|$)', rest) for nd in NO_DECAP])):
                        newcol = paren + ' ' + rest[0].lower() + rest[1:] if rest else ''
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

def delete_cols(entries, cols):
    result = entries
    for col in sorted(cols, reverse=True):
        result = delete_col(result, col)
    return result

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
        ('ŋ','η',''),
        ('p','ρ','р'),
        ('s','ς','ѕ'),
        ('t','τ','т'),
        ('v','ν','ѵ'),
        ('w','','ѡ'),
        ('x','χ','х'),
        ('y','γ','у'),
        ('Ä','','Ӓ'),
        ('Ö','','Ӧ'),
        ('ä','','ӓ'),
        ('ö','','ӧ')
        #('ß','β',''),
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

def insert_into_tilde(s1, s2, max_overlap=4, vowels='AEIOUYaeiouy'):
    # choose how best to synthesize strings depending on context
    # first make sure a single tilde is in s2 in the first place
    s2_separated = re.match(r'^([^~]*)~([^~]*)$', s2)
    if not s2_separated:
        # print('tilde count != 1, returning string as is:', s2)
        return s2

    s2_pre, s2_post = s2_separated.group(1), s2_separated.group(2)

    if s2_pre.endswith(' ') and s2_post.startswith(' '):
        # tilde surrounded by space, just put s1 in there
        return s2.replace('~', s1)
    elif s2_pre.endswith(' ') or s2_post.startswith('~'):
        # tilde at beginning/after space
        return s2_pre + synthesize_strings(s1, s2_post)
    elif s2_pre.endswith('~') or s2_post.startswith(' '):
        # tilde at end/before space
        return synthesize_strings(s2_pre, s1) + s2_post
    else:
        # ambiguous, so do two merges
        return synthesize_strings(synthesize_strings(s2_pre, s1), s2_post)


def extract_taxa(entries, col, delim='‣'):
    # reqno = 0
    print('\nextracting taxa...')
    try:
        requests
    except:
        import requests
    try:
        # reqno += 1
        r = requests.get('http://127.0.0.1:3000', params={'text': 'string'})
    except:
        raise ConnectionError('Must initialize taxonfinder')
    else:
        result = []
        for entry in entries:
            newentry = []
            for syn in entry[col].split(delim):
                if re.search(r'\p{Latin}', syn.replace('⫷df⫸','')):
                    r = requests.get('http://127.0.0.1:3000', params={'text': syn}, headers={'Connection':'close'}).json()
                    if r:
                        for match in r:
                            offsets, name = match['offsets'], match['name']
                            print(name)
                            if offsets[1] - offsets[0] == len(syn):
                                syn = '⫷ex:lat-003⫸' + name
                            else:
                                # detect "sp(p)." notation and add meaning classification
                                if re.search(name + ' spp?\.?', syn):
                                    syn = re.sub(name + ' spp?\.?', ' ', syn).strip()
                                    syn += '⫷mcs2:art-300⫸IsA⫷mcs:lat-003⫸' + name
                                if syn.startswith('⫷mcs'):
                                    syn = '⫷ex:lat-003⫸' + name + syn
                                else:
                                    syn += '⫷ex:lat-003⫸' + name
                newentry.append(syn)
            entry[col] = delim.join(newentry)

        return entries
        print('done')


def get_next_sibling_tag(tag):
    # next tag method for beautifulsoup (siblings only)
    for nextsib in tag.next_siblings:
        if isinstance(nextsib, Tag):
            return nextsib
    return None

def get_next_tag(tag):
    # next tag method for beautifulsoup
    for nexttag in tag.next_elements:
        if isinstance(nexttag, Tag):
            return nexttag
    return None

def classify_cmn(entries, col, delim='‣'):
    """ Classifies unknown cmn as simplified/traditional/both. """
    try:
        hantool
    except:
        from hantool import HanText

    ht = HanText('')

    simptag, tradtag = '⫷ex:cmn-000⫸', '⫷ex:cmn-001⫸'

    assert col < len(entries[0])
    result = []
    for entry in entries:
        if not isinstance(entry[col], list):
            entry[col] = entry[col].split(delim)
        newentry = []
        for syn in entry[col]:
            if syn:
                ht.update(syn)
                if ht.is_simp():
                    # print(simptag+syn)
                    newentry.append(simptag+syn)
                if ht.is_trad():
                    # print(tradtag+syn)
                    newentry.append(tradtag+syn)
                # if ht.is_trad_only():
                #     print('!!!', syn)
        result.append(entry[:col] + [delim.join(newentry).replace(delim+simptag[0],simptag[0])] + entry[col+1:])
    return result


def tb_to_wn(tb):
    # Convert Penn Treebank to WordNet POS tags
    tb = tb[:2] if tb[:2] in ['NN','JJ','VB'] else 'RB'
    return {'NN':wn.NOUN,'JJ':wn.ADJ,'VB':wn.VERB,'RB':wn.ADV}[tb]
