
from collections import defaultdict, namedtuple
import regex as re

from gary import ignore_parens_list

Record = namedtuple('Record', ['dob', 'eng', 'pos', 'phn'])

@ignore_parens_list
def split_words(text:str) -> list:
    return re.split('\s*;\s*', text)


class ShoeboxParser:
    def __init__(self):
        pass
        
    def parse(self, infile):
        pattern = re.compile('^\\\\(\w+)\s+(.*)$')
        current_record = []
        started = False

        for line in infile:
            if len(line.strip()) == 0 and started:
                yield current_record
                current_record = []
            
            match = pattern.search(line)
            
            if match:
                if not match[1].startswith('_'):
                    started = True
                    current_record.append( (match[1],match[2]))

        yield current_record