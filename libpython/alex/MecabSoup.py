"""
Wrapper for MeCab Japanese parser (https://taku910.github.io/mecab/#download)
to tokenize and retag Japanese expressions too long to be lemmatic.

Requires: MeCab + IPA 辞書 (UTF-8)
"""

import subprocess

class MecabSoup:
  def __init__(self, string):
    self.string = string
    proc = subprocess.Popen(['mecab'], stdout=subprocess.PIPE, stdin=subprocess.PIPE)
    self.rawoutput = proc.communicate(input=string.encode('utf-8)'))[0].decode('utf-8')
    self.contents = [(word.split('\t')[0], word.split('\t')[1].split(',')) for word in self.rawoutput.split('\n')[:-2]]

    self.length = len(self.contents)
    self.wordlist = [word[0] for word in self.contents]
    self.poslist = [word[1][0] for word in self.contents]

  def __len__(self):
    return self.length
