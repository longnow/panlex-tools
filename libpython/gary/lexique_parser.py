#!/usr/bin/python3


import regex as re

from bs4 import BeautifulSoup


class LexiqueParser(object):
    def __init__(self):
        self._ignore_list = ['lpSpAfterEntryName', 'lpMiniHeading', 'lpPunctuation']
    
    
    def _extract_entry(self, para):
        record = []

        for item in para.contents:
            if item.name == 'span':

                if item['class'][0] not in self._ignore_list:
                    key = re.sub('^lp', '', item['class'][0])

                    record.append((key,item.text))

        return record
    
    
    def getRecords(self, filename):
        with open(filename) as fin:
            text = fin.read()
            bs = BeautifulSoup(text, 'lxml')
            entries = bs.find_all('p',{'class':'lpLexEntryPara'})
            for para in entries:
                yield self._extract_entry(para)



if __name__ == '__main__':
    print('This is not a top-level script. Run the main script to use this module.')
