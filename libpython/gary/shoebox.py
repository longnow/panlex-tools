
from collections import defaultdict, namedtuple
import regex as re

from gary import ignore_parens_list

@ignore_parens_list
def split_words(text:str) -> list:
    return re.split('\s*;\s*', text)

def empty_line(text):
    return len(text.strip()) == 0


class ShoeboxParser:
    def __init__(self):
        pass
        
    def parse(self, filename):
        pattern = re.compile('^\\\\(\w+)\s+(.*)$')
        current_record = []
        started = False
        
        with open(filename) as infile:
            for line in infile:
                
                if empty_line(line) and started:
                    if len(current_record) > 0:
                        yield current_record
                    current_record = []
                
                match = pattern.search(line)
                
                if match:
                    if not match[1].startswith('_'):
                        started = True
                        current_record.append( (match[1],match[2]))
            if len(current_record) > 0:
                yield current_record
