"""
Uses MeCab Japanese parser (https://taku910.github.io/mecab/#download) to tokenize and retag
  Japanese expressions "too long" to be lemmatic.

Requires: MeCab + IPA 辞書 (UTF-8)

jpnexdf is for one-stop full-file processing, or just call MecabSoup within your own workflow.
"""

import regex
from subprocess import check_output

def jpnexdf(entries, col, delim='‣', maxlen=3, dftag='⫷df⫸'):
  """
  Arguments:
  entries : list of lists (rows) of: a) strings with delimited exps, or b) lists of pre-separated exps
  col     : column of jpn exps to process
  delim   : default exp delimiter. will separate exps with this on input if strings,
            and join them with this on output
  maxlen  : maximum morpheme count not to qualify for retagging
  deftag  : exps that exceed maxlen will be pretagged with this

  Output:
  result  : list of lists (rows) of strings with exps delimited by delim
  """
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
      if MecabSoup(syn_noparens).length > maxlen:
        # retag
        newentry.append(dftag+syn)
        print(dftag+syn)
      else:
        newentry.append(syn)
        print(syn)
    result.append(entry[:col] + [delim.join(newentry).replace(delim+dftag[0],dftag[0])] + entry[col+1:])
  return result


def make_paren_regex(parens=[(r'\(',r'\)'),(r'\[',r'\]'),(r'\{',r'\}'),(r'（',r'）'),(r'【',r'】')], maxnested=10):
  """
  Makes a regex to match any parenthetical content, up to a certain number
    of layers deep.

  parens  = list of tuples of opening and closing characters (regex escaped)
            to be considered parenthetical
  maxnested = max number of nested parens to match
  """
  paren_res = []
  for p in parens:
    o, c = p
    oc = o + c
    fld  = (o + r'(?:[^' + oc + r']|') * (maxnested - 1)
    fld += o + r'[^' + c + r']*' + c
    fld += (r')*' + c) * (maxnested - 1)
    paren_res.append(fld)
  return r'(' + r'|'.join(paren_res) + r')'


# Wrapper for command-line mecab output

class MecabSoup:
  def __init__(self, string):
    self.string = string
    self.rawoutput = check_output('mecab <<< "' + string + '"', shell=True).decode('utf-8')
    self.contents = [(word.split('\t')[0], word.split('\t')[1].split(',')) for word in self.rawoutput.split('\n')[:-2]]

    self.length = len(self.contents)
    self.wordlist = [word[0] for word in self.contents]
    self.poslist = [word[1][0] for word in self.contents]

  def __len__(self):
    return self.length
