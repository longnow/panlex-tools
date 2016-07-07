
from collections import defaultdict, namedtuple
import regex as re

from gary import ignore_parens_list

Record = namedtuple('Record', ['dob', 'eng', 'pos', 'phn'])

@ignore_parens_list
def split_words(text:str) -> list:
    return re.split('\s*;\s*', text)


class ShParser:
    def __init__(self, text):
        self.entries = []
        pattern = re.compile('^\\\\(\w+)\s+(.*)$')
        self.entries = []
        curr = defaultdict(list)

        for line in text.splitlines():
            match = pattern.search(line)

            if match and not match[1].startswith('_'):
                if match[1].strip() == 'lx' and len(curr) > 0:
                    self.entries.append(curr)
                    curr = defaultdict(list)
                    curr['lx'] = match[2]
                    curr['ps'] = ''

                if match[1] == 'ps':
                    if len(curr['ge']) > 0:
                        self.entries.append(curr)
                    curr['ge'] = []
                    curr['ps'] = match[2]

                if match[1] == 'ge':
                    word_list = split_words(match[2])
                    for word in word_list:
                        curr['ge'].append(word)


    def getEntries(self):
        for entry in self.entries:
            if 'lx' in entry:
                dob = entry['lx']
            else:
                dob = ''
            eng = '‣'.join( entry['ge'])
            pos = entry['ps']
            phn = entry['ph']

            yield Record(dob,eng,pos,phn)
