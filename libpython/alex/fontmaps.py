#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# Mappings from legacy fonts.

import os

def cp_to_char(cp):
    cp = ''.join([letter for letter in cp.lower() if letter in '0123456789abcdef'])
    return chr(int(cp, 16))

CAMEROON_MAP = {}
NEWLAC_MAP = {}

def cameroon(s):
    # map for Cam Cam (Cameroon) SILDoulos font
    global CAMEROON_MAP
    if not CAMEROON_MAP:
        # initialize
        for line in open(os.path.join(os.path.dirname(os.path.realpath(__file__)),'fontmaps','Cameroon2Unicode.map')).readlines():
            if line.startswith('0x'):
                CAMEROON_MAP[cp_to_char(line[0:4])] = cp_to_char(line[8:14])
        CAMEROON_MAP['‰'] = '\u0323'
    return ''.join([CAMEROON_MAP[letter] if letter in CAMEROON_MAP.keys() else letter for letter in s])

def newlac(s):
    # map for New Lacito, developed by CNRS (http://cnrs.fr/)
    # this doesn't seem to work properly?? mapping file might be completely wrong
    global NEWLAC_MAP
    if not NEWLAC_MAP:
        # initialize
        for line in open(os.path.join(os.path.dirname(os.path.realpath(__file__)),'fontmaps','NewLac.map')).readlines():
            if '>\tU+' in line:
                froms, _, tos = line.split('\t')
                froms = hex(int(froms.strip()))
                tos = tos.strip().split(' ')
                NEWLAC_MAP[cp_to_char(froms)] = ''.join([cp_to_char(t) for t in tos])
        print(NEWLAC_MAP)
    return ''.join([NEWLAC_MAP[letter] if letter in NEWLAC_MAP.keys() else letter for letter in s])
