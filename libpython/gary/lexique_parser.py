#!/usr/bin/python3

import io
import regex as re

from bs4 import BeautifulSoup

class LexiqueParser(object):
    """Parser for Lexique Pro HTML export format"""
    def __init__(self):
        self._ignore_list = ['lpSpAfterEntryName', 'lpPunctuation']
    
    
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
    
    
    def getRecords(self, inputfile, encoding='utf-8') -> list:
        """passes in string value with filename or file object for open file to read"""
        if isinstance(inputfile,str):
            with open(inputfile, encoding=encoding) as fin:
                text = self._preprocess(fin.read())
                bs = BeautifulSoup(text, 'lxml')
        elif isinstance(inputfile, io.TextIOWrapper):
            bs = BeautifulSoup(inputfile, 'lxml')
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
