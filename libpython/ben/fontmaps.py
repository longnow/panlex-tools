#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os
import regex as re

fontmap_directory = os.path.dirname(__file__) + '/fontmaps/'
fontmaps = {}

for font in ['JG_Pahawh_Third_Version', 'JG_Pahawh_Final_Version']:
    fontmaps['{}.ttf'.format(font)] = json.load(open(fontmap_directory + '{}.json'.format(font)))

def _decode_Myanmar1(string):
    string = string.replace('\u1039\u101a', '\u103b')
    string = string.replace('\u1039\u101b', '\u103c')
    string = string.replace('\u1039\u101d', '\u103d')
    string = string.replace('\u1039\u101f', '\u103e')
    string = re.sub(r'\u1004\u1039([\u1000-\u1021\u1025])', '\u1004\u103a\u1039\g<1>', string)
    string = string.replace('\u101e\u1039\u101e', '\u103f')
    string = re.sub(r'([\u1036-\u1038])(\u1039)', '\g<2>\g<1>', string)
    string = re.sub(r'\u1039(?![\u1000-\u1003\u1005-\u1008\u100b\u100c\u100f-\u1019\u101c])', '\u103a', string)
    string = re.sub(r'([\u1001\u1002\u1004\u1012\u1015\u101d])\u102c', '\g<1>\u102b', string)
    string = re.sub(r'([\u102f\u1030])([\u102d\u102e\u1032])', '\g<2>\g<1>', string)
    string = re.sub(r'(\u1036)(\u1037)', '\g<2>\g<1>', string)
    string = re.sub(r'[\u200c\u200d]', '', string)
    return string

def decode(string, font):
    if font == 'Myanmar1.ttf': return _decode_Myanmar1(string)
    output = ''
    for c in string:
        try:
            for char in fontmaps[font][hex(ord(c))].split():
                output += (chr(int(char, 16)))
        except KeyError:
            output += c
    return output

