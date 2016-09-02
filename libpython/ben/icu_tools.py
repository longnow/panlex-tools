#!usr/bin/env python3
# -*- coding: utf-8 -*-

import icu

def all_glyphs(prop):
    return [c.encode('utf-16', 'surrogatepass').decode('utf-16') for c in icu.UnicodeSetIterator(icu.UnicodeSet(r'[:{}:]'.format(prop)))]

def all_cps(prop):
    return list(map(glyph_cp, all_glyphs(prop)))

def glyph_name(glyph, default=''):
    if len(glyph) > 1:
        raise TypeError('glyph must be a string with length of 1')
    elif len(glyph) == 0:
        return default
    else:
        return icu.Char.charName(glyph)

def cp_glyph(cp, default=''):
    try:
        return chr(int(cp, 16))
    except ValueError:
        return default

def cp_name(cp, default=''):
    return glyph_name(cp_glyph(cp), default)

def glyph_cp(glyph):
    return hex(ord(glyph))[2:]
