#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# Mappings from legacy SIL fonts.

import os

def cp_to_char(cp):
    cp = ''.join([letter for letter in cp.lower() if letter in '0123456789abcdef'])
    return chr(int(cp, 16))

cameroon_map = { cp_to_char(line[0:4]) : cp_to_char(line[8:14]) for line in open(os.path.join(os.path.dirname(os.path.realpath(__file__)),'silmaps','Cameroon2Unicode.map')).readlines() if line.startswith('0x') }
cameroon_map['‰'] = '\u0323'

def cameroon(s):
    # map for Cam Cam (Cameroon) SILDoulos font
    return ''.join([cameroon_map[letter] if letter in cameroon_map.keys() else letter for letter in s])
