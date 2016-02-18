#!/usr/bin/env python
##   bgl2xdb.py 
##
##   Copyright (C) 2007 Mehdi Bayazee (Bayazee@Gmail.com)
##
##   This program is free software; you can redistribute it and/or modify
##   it under the terms of the GNU General Public License as published by
##   the Free Software Foundation; either version 2, or (at your option)
##   any later version.
##
##   This program is distributed in the hope that it will be useful,
##   but WITHOUT ANY WARRANTY; without even the implied warranty of
##   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##   GNU General Public License for more details.


__author__ = "Mehdi Bayazee"
__copyright__ = "Copyright (C) 2007 Mehdi Bayazee"

__revision__ = "$Id$"
__version__ = "0.2"

# Standard Python modules.
import gzip                      # Read and write gzipped files.
import sys                       # System-specific parameters and functions.
import os                        # Miscellaneous OS interfaces.
import time                      # Manipulate time values
import re                        # Regular Expression


XFarDicTag = """
<xfardic>
       <dbname>%s</dbname>
       <author>%s</author>
       <inputlang>%s</inputlang>
       <version>%s</version>
</xfardic>
"""

WordTag = """
    <word>
        <in>%s</in>
        <out>%s</out>
    </word>
"""

class BGL:
    '.Bgl (Babylon Glossary) Reader Class'
    def __init__(self, bglFileName):
        self.bglFileName = bglFileName
        # File formats to romove from DataBase
        self.TrimFileExts = ['.bmp', '.html'] 
        
    def open(self):
        print '\n+ Opening "%s"'.ljust(40)%self.bglFileName,
        try:
            bglFile = file(self.bglFileName, 'rb')
        except:
            print '\nIOError !\nNo such file or directory: %s\n'%self.bglFileName
            return False

        if not bglFile:
            return False
        # Reading and testing first 4 byte.
        # BGL file signature must be : 0x12340001 or 0x12340002
        sign = bglFile.read(6)
        if len(sign)<6 or sign[:3]!='\x12\x34\x00' or sign[3]=='\x00' or sign[3]>'\x02':
            print '\n%s is not a .BGL(Babylon Glossary) file !\n'%self.bglFileName
            return False
        # Calculating gz header and bypass it
        gz = ord(sign[4]) << 8 | ord(sign[5])
        bglFile.seek(gz)
        file('temp.tmp','wb').write(bglFile.read())
        del bglFile
        self.bglFile = gzip.open('temp.tmp','rb')
        print '\t\t[Ok]'.ljust(40)
        return True
    
    def close(self):
        'Close Bgl file & Remove temp file'
        print '+ Closing "%s"'.ljust(40)%self.bglFileName,
        self.bglFile.close()
        os.remove('temp.tmp')
        print '\t\t[Ok]'.ljust(40)
        
    def BglBlockReader(self):
        block = {'data': None}
        block['length'] = self.BglRawReader(1)
        block['type'] = block['length'] & 0xf
        block['length'] >>= 4
        if block['length'] < 4 :
            block['length'] = self.BglRawReader(block['length'] + 1)
        else:
            block['length'] -= 4
        if block['length'] :
            block['data'] = self.bglFile.read(block['length'])
        return block
        
    def BglRawReader(self, bytes):
        val = 0
        if bytes<1 or bytes>4:
            return 0
        buf = self.bglFile.read(bytes)
        if not buf:
            raise IOError, 'EOF !'
        for i in buf:
            val = val << 8 | ord(i)
        return val
    
    def readWord(self):
        try:
            block = self.BglBlockReader()
        except :
            return False
        if not block :
            return False
        try:
            lenHW = ord(block['data'][0]) + 1
            word = block['data'][1:lenHW].split('$')[0]
            #print word
            lenDF = (ord(block['data'][lenHW + 1])) + 1
            definition = block['data'][lenHW+2:lenDF+lenHW+1]

            return self.TrimBlock(word, definition)
        except:
            return None
        
    def TrimBlock(self, word, definition):
        "Remove unwanted data from word and it's definition"
        # It is link ! not data !!
        if word.count('@'):
            return None
        # return None if it is a file 
        for ext in self.TrimFileExts:
            if word.count(ext):
                return None
        
        word = word.strip()

        # spilting fragmented data
        try:
            definition += ' ' +  definition.split('\x18')[1]
        except:
            pass
        
        # we only need first piece of data 
        definition = definition.split('\x14')[0]
        
        # Converting to Persian(Arabic) 
        # TODO: support other charsets
        # definition = unicode(definition,'cp1256').encode('utf8')
        
        # Remove Tags
        definition = definition.replace('<BR>','\n')
        if definition.count('<'):
            definition = re.sub('<.{1,4}>','', definition)
        if definition.count('href'):
            definition = re.sub('<.*href.*>','', definition)
        
        definition = definition.replace('<','(')
        definition = definition.replace('>',')')
        
        #print "+[", word, "] - [", definition , "]"
        return word, definition
    
    def ReadBglHeader(self):
        if not self.bglFile:
            return False
        self._numEntries = 0
        while True:
            block = self.BglBlockReader()
            if not block or not block['length']:
                break
        return True
    
        

class XDB:
    def __init__(self, xdbFileName, dbname, author='Auto Generated with bgl2xdb.py', inputlang='en_US', version='1.0'):
        self.xdbFileName = xdbFileName
        print '+ Opening "%s"'.ljust(40)%self.xdbFileName,
        #self.xdbFile = codecs.open(self.xdbFileName, "w", "utf-8")
        self.xdbFile = file(self.xdbFileName, "w")
        self.xdbFile.write('<?xml version="1.0" encoding="utf-8" ?>\n')
        self.xdbFile.write('<!-- words converted with bgl2xdb.py tool [%s]-->\n'%time.ctime(time.time()))
        self.xdbFile.write('<!-- bgl2xdb.py Author: Mehdi Bayazee (Bayazee@gmail.com) -->\n\n')
        self.xdbFile.write('<words>')
        self.xdbFile.write(XFarDicTag%(dbname, author, inputlang, version))
        print '\t\t[Ok]'.ljust(40)
        
    def write(self, data):
        try:
            self.xdbFile.write(WordTag%data)
        except:
            pass
                           
    def close(self):
        print '+ Closing "%s"'.ljust(40)%self.xdbFileName,
        self.xdbFile.write('</words>')
        del self.xdbFile
        print '\t\t[Ok]'.ljust(40)

class Bgl2Xdb:
    def __init__(self, *args):
        self.counter = 0 # Word counter
        self.bglFileName = args[0][0]
        try:
            self.xdbFileName = args[0][1] # if we have target path
        except:
            self.xdbFileName = os.path.splitext(self.bglFileName)[0] + '.xdb'
        self.BGL = BGL(self.bglFileName)
    
    def convert(self):
        if not self.BGL.open():
            print 'Error in Reading bgl file !\n'
            return False
        self.BGL.ReadBglHeader()
        dbname = os.path.splitext(self.bglFileName)[0]
        dbname = os.path.split(dbname)[1]
        self.XDB = XDB(self.xdbFileName, dbname)
        print '+ Converting ...'
        while True:
            data = self.BGL.readWord()
            # Error or EOF
            if data == False :
                break
            
            elif data == None or data[0] == '' or data[1] == '': 
                continue
            else:
                #print  "[",data[0] , ']\n  [', data[1], "]\n==================\n"
                self.XDB.write(data)
                self.counter += 1
        self.XDB.close()
        self.BGL.close()
        print '\nOk! %d word converted from %s to %s !\n'%(self.counter, self.bglFileName, self.xdbFileName)

    
    
def Main():
    def Usage():
        print 'Bgl2Xdb.py v0.2\nBgl (Babylon Glossary) to xdb (XFarDic word DataBase) Converter by Bayazee@Gmail.com'
        print '\nUsage: python %s BglFile [XdbFile]\n\n' %sys.argv[0]
    if len(sys.argv) < 2 :
        Usage()
    else:
        converter = Bgl2Xdb(sys.argv[1:])
        converter.convert()
    
if __name__ == '__main__':
    Main()
