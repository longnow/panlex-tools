# -*- coding: utf-8 -*-

import string
import re
import codecs
from xmlparsefunctions import *

source = 'aaa-bbb-Author'

f = codecs.open(source + '-1.txt', encoding='utf-8')

lines = []
for line in f:
    line = re.sub(r'\n','',line)
    lines.append(line)

f.close()

poslist = []

f = codecs.open(source + '-2.txt', 'w', encoding='utf-8')

for line in lines:
    line = re.sub(r' +', ' ', line)
    line = line.split("\t")
    
    lang1 = line[0].strip()
    
    pos = re.split(r", ?", line[1])
    pos[0] = pos[0].strip()
               
    lang2 = line[2].strip()

    note = line[3].strip()
    if note != '':
        note = ' ' + note

## Hack some fixes for errors in -1.txt file (owing to incorrect typesetting in original pdf file)

    if lang1 == 'xxxxx':
        lang1 = 'yyyy'


## Create a frequency table of attested parts of speech

    poslist.append(pos[0])
    

## Put punctuation marks for exclamatives and interrogatives inside parentheses

    lang1 = re.sub('!', '(!)', lang1)      
    lang1 = re.sub(u'¡', u'(¡)', lang1)                  
    lang1 = re.sub('\?', '(?)', lang1)      
    lang1 = re.sub(u'\¿', u'(¿)', lang1)            

    lang2 = re.sub('!', '(!)', lang2)      
    lang2 = re.sub(u'¡', u'(¡)', lang2)                   
    lang2 = re.sub('\?', '(?)', lang2)      
    lang2 = re.sub(u'\¿', u'(¿)', lang2)    

## Adjust for synonym delimiters in lang1 and lang2 expressions

    lang1 = re.sub(', ?',u'‣',lang1)     
    lang2 = re.sub(', ?',u'‣',lang2)         

## Common additional adjustments for expressions in Spanish

    lang1 = re.sub(r'^esta ', 'estar ', lang1)
    lang1 = re.sub(r'^ser ', '(ser) ', lang1)   
    lang1 = re.sub(r'^estar ', '(estar) ', lang1)  
    lang1 = re.sub(r'^un ', '(un) ', lang1)  
    lang1 = re.sub(r'^una ', '(una) ', lang1)  

## Append parenthetical note to each synonym in lang1 expression

    lang1 = lang1.split(u'‣')
    newlang1 = lang1[0] + note                  
    if len(lang1) > 1:
        newlang1 += u'‣' + lang1[1] + note    

## Output to final text file

    f.write("\t".join([newlang1, pos[0], lang2]) + "\n")

    if len(pos) > 1:
        pos[1] = pos[1].strip()
        poslist.append(pos[1])
        f.write("\t".join([newlang1 + note, pos[1], lang2]) + "\n")        
    
f.close()

posdict = count(poslist)

sortposdict = sorted(posdict.items(), key = lambda x: (-1*x[1],x[0]))

print "Frequency table for parts of speech\n"

for item in sortposdict:                # prints a table of wc counts
    print item[0], "\t", item[1]    

print "\n\nParts of speech attested in source\n"

for item in sorted(set(poslist)):       # spits out the wc's used in the file, for use in wc.txt file in serialization stage
    print item
