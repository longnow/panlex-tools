#!/usr/bin/python3


import regex as re
import time

from bs4 import BeautifulSoup


class LexiqueParser(object):
    def __init__(self):
        self._ignore_list = ['lpSpAfterEntryName', 'lpMiniHeading', 'lpPunctuation']
    
    
    def _extract_entry(self, para, src_token=None):
        record = []
        if src_token:
            record.append( ('LexEntryName',src_token) )

        for item in para.contents:
            if item.name == 'span':
                if item['class'][0] not in self._ignore_list:
                    key = re.sub('^lp', '', item['class'][0])

                    record.append( (key,item.text) )

        return record
    
    
    def getRecords(self, filename:str) -> list:
        with open(filename) as fin:
            text = self._preprocess(fin.read())
            bs = BeautifulSoup(text, 'lxml')
            entries = bs.find_all('p')
            source = ''

            for para in entries:
                if 'class' in para.attrs:
                    if 'lpLexEntryPara' in para['class'] or 'lpLexEntryPara_KeepWithNext' in para['class']:
                        source = para.find('span', {'class':'lpLexEntryName'}).text.strip()
                        yield self._extract_entry(para)
                    elif 'lpLexEntryPara2' in para['class']:
                        yield self._extract_entry(para, source)

    def _preprocess(self,text):
        text = re.sub('<a [^>]*>', '', text)
        text = re.sub('</a' ,'', text)
        return text



if __name__ == '__main__':
    print('This is not a top-level script. Run the main script to use this module.')
