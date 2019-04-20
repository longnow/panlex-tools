#!/usr/bin/env python3
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

class Rbnf:
    def __init__(self, tag="spellout", locale="", rules=""):
        if rules:
            self._rbnf = icu.RuleBasedNumberFormat(rules)
        else:
            if tag.lower() not in {"spellout", "duration", "ordinal", "numbering_system"}:
                raise ValueError("tag must be 'spellout', 'duration', 'ordinal', or 'numbering_system'")
            self._rbnf = icu.RuleBasedNumberFormat(getattr(icu.URBNFRuleSetTag, tag.upper()), icu.Locale(locale))

    def format(self, number):
        return self._rbnf.format(number)

    @property
    def ruleset(self):
        return self._rbnf.getDefaultRuleSetName()

    @ruleset.setter
    def ruleset(self, ruleset_name):
        try:
            self._rbnf.setDefaultRuleSet(ruleset_name)
        except icu.ICUError:
            raise ValueError(f"{ruleset_name} not a valid ruleset. See {self.__class__.__name__}.rulesets() for valid rulesets.")
    
    def rulesets(self):
        return {self._rbnf.getRuleSetName(i) for i in range(self._rbnf.getNumberOfRuleSetNames())}
    
    def rules(self):
        return self._rbnf.getRules()

    def parse(self, string):
        try:
            return self._rbnf.parse(string)
        except icu.ICUError:
            raise ValueError("unable to parse string")
    
