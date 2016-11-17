#!/usr/bin/env python3

import regex as re

def getRecords(filename):
    with open(filename) as fin:
        started = False
        fields = []
        
        for line in fin:
            match = re.search('^\\\\(\S+)\s+(.*)', line)
            if match:
                if match[1] == 'le':
                    if started:
                        print(fields)
                        yield fields
                        fields = []
                        fields.append( (match[1],match[2]) )
                else:
                    fields.append( (match[1],match[2]) )
                    started = True
