# -*- coding: utf-8 -*-

import string
import re
import codecs
from lxml import etree
from xmlparsefunctions import *

source = 'aaa-bbb-Author'

# Enter font and size for entries in first language
lang1font = 'LongZapSILDoulosL,Bold'
lang1size = '13.800'

# Enter font and size for entries in second language
lang2font = 'LongZapSILDoulosL'
lang2size = '12.902'

# Enter font and size for part of speech (word class) indicator
posfont = 'LongZapSILDoulosL,Italic'
possize = '11.719'

# Enter font and size for numerical meaning delimiters
numdelfont = 'LongZapSILDoulosL'
numdelsize = '12.902'

# Enter font and size for parenthetical information
parnotefont = 'LongZapSILDoulosL,Italic'
parnotesize = '11.719'

# Enter correct unicode codes for incorrectly encoded characters
chardict = {u'ß': "'",
            u'ç': u'\u02c6',
            u'à': u'a\u0301\u0331'}

# Enter max and min values of y2 in bounding box
y2min = 135
y2max = 680

root = etree.parse(source + '-0.xml')
out = codecs.open(source + '-1.txt', 'w', encoding='utf-8')

lang1 = note = pos = lang2 = num = ''                         # strings storing the accumulated characters in each category
charstate = ''                                                # variable storing the state of the current character
origcharlist = []                                             # builds an inventory of orig characters in file
revcharlist = []

for tag in root.findall('.//text'):

    prevcharstate = charstate
    
    bbox = tag.get('bbox').split(',')
    ymin = float(bbox[1])
    ymax = float(bbox[3])

    if ymax < y2min or ymin > y2max:                         # ignores the page headers which happen to be in same font as lang1 or lang2 expressions.  based on the height of the position of the character on the page
        continue

    origchar = tag.text

    if origchar not in origcharlist:
        origcharlist.append(origchar)

    # fix encoding errors

    if origchar in chardict:
        char = chardict[origchar]
    else:
        char = origchar

    if char not in revcharlist:
        revcharlist.append(char)

    size = tag.get('size')

    acceptsize = [lang1size, lang2size, possize, numdelsize, parnotesize]

    if size not in acceptsize:
        continue

    font = tag.get('font')
    
    if (char == '(' or char == ')'):                               # fixes incorrectly typeset parentheses
        font = parnotefont
        size = parnotesize
    
    if font == lang1font and size == lang1size:                                        
        if char == ' ' and prevcharstate != 'lang1':             
            continue
        charstate = 'lang1'
        if prevcharstate == 'pos':
            lang1 = note = pos = lang2 = num = ''                  # wipes out the current line if there is no lang2 expression, does not print
        if prevcharstate == 'lang2' or prevcharstate == 'note':    # if new lang1 headword and previous state was lang2 or parenthetical note, print line and start over
            output_record(out, lang1, pos, lang2, note)
            lang1 = note = pos = lang2 = num = ''
        lang1 += char

    elif font == numdelfont and size == numdelsize and re.match(r'[\d\.]', char):       
        if prevcharstate == 'lang2' or prevcharstate == 'note':
            output_record(out, lang1, pos, lang2, note)
            note = lang2 = num = ''                               # don't reset lang1 or pos back to ''
        if prevcharstate == 'num':                                # ignore the second character of a number (if there is one) and the following period
            continue
        charstate = 'num'
        num += char

    elif font == lang2font and size == lang2size:                                     
        if char == ' ' and prevcharstate != 'lang2':
            continue
        charstate = 'lang2'
        lang2 += char
        
    elif font == parnotefont and size == parnotesize and (char == '(' or charstate == 'note'):                 
        charstate = 'note'
        note += char

    elif font == posfont and size == possize:                 
        if prevcharstate != 'pos':                              
            pos = '' 
        charstate = 'pos'
        pos += char
                      
    else:
        continue


output_record(out, lang1, pos, lang2, note)                        # gets output for last line in source

out.close()

char_inventory(origcharlist, revcharlist)                          # outputs a list of characters encoded in xml input, and revised characters in txt output 
