#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import panlex
import ben.iso639 as iso639
import os
from collections import defaultdict
from itertools import product
from langcodes import Language
import regex as re

data_directory = os.path.dirname(__file__) + '/data/'

class Lv(str):
    _cache = defaultdict(dict)
    _include = {
        'langvar_char',
        'langvar_cldr_char',
        'denotation_count',
        'expr_count',
        'script_expr_txt',
        'region_expr_langvar',
        'region_expr_txt',
        'region_expr_uid',
        }
    _v2_dict = {
        'cp': 'langvar_char',
        'cu': 'langvar_cldr_char',
        'dncount': 'denotation_count',
        'ex': 'name_expr',
        'excount': 'expr_count',
        'gp': 'grp',
        'lc': 'lang_code',
        'lv': 'id',
        'mu': 'mutable',
        'sc': 'script_expr',
        'td': 'name_expr_txt_degr',
        'tt': 'name_expr_txt',
        'sctt': 'script_expr_txt',
        'vc': 'var_code',
        }
    def __repr__(self):
        return "{cls}({string})".format(cls=self.__class__.__name__, string=repr(str(self)))

    def __getattr__(self, attr):
        if attr in ['_ipython_canary_method_should_not_exist_', '_ipython_display_']:
            return getattr(str(self), attr)
        if attr in self._v2_dict:
            attr = self._v2_dict[attr]
        try:
            return self._cache[str(self)][attr]
        except KeyError:
            if attr == 'all_ex':
                self._cache_all_ex()
            elif attr == 'IETF':
                self._cache_IETF()
            else:
                include = []
                if attr in self._include:
                    include.append(attr)
                self._cache[str(self)].update(panlex.query('/langvar/{}'.format(self), {'include': include})['langvar'])
            try:
                return self._cache[str(self)][attr]
            except KeyError:
                raise AttributeError('"{attr}" is not a valid {cls} object'.format(attr=attr, cls=self.__class__.__name__))

    @classmethod
    def precache(cls, lv_list=[], include=[], all_lv=False):
        if not (lv_list or all_lv):
            raise TypeError('either lv_list or all_lv must be specified')
        if isinstance(include, str):
            include = [include]
        strict_include = list(set(include) & cls._include)
        if all_lv:
            result = panlex.query('/langvar', {'limit': 0, 'include': strict_include, 'cache': False})['result']
        else:
            result = panlex.query('/langvar', {'limit': 0, 'uid': list(lv_list), 'include': strict_include, 'cache': False})['result']
        for r in result:
            cls._cache[r['uid']].update(r)
            if 'all_ex' in include:
                Lv(r['uid'])._cache_all_ex()

    @classmethod
    def _cache_IETF(cls):
        cls.precache(include=['script_expr_txt', 'region_expr_txt', 'region_expr_uid'], all_lv=True)
        for uid in cls._cache:
            cls._cache[uid]['IETF'] = set()
        result = panlex.query_all('/expr', {'trans_uid': 'art-420', 'uid': 'art-274', 'include': 'trans_txt'})['result']
        regions = {cls._cache[r['txt']]['region_expr'] for r in result}
        regions_result = panlex.query_all('/expr', {'trans_expr': list(regions), 'uid': 'art-006', 'include': 'trans_txt'})['result']
        regions_dict = {r['trans_txt']: r['txt'] for r in regions_result if len(r['txt']) == 2}
        for r in result:
            uid = r['txt']
            lang = cls._cache[uid]
            given_tag = Language.get(r['trans_txt'], normalize=False)
            normalized_tag = Language.get(r['trans_txt'], normalize=True)
            language_set = {lang['lang_code'], given_tag.language, normalized_tag.language}
            script_set = {lang['script_expr_txt'], given_tag.script, normalized_tag.script}
            region_set = {given_tag.region, normalized_tag.region}
            if lang['region_expr_uid'] == 'art-279' and lang['region_expr_txt'] != '001':
                region_set.add(lang['region_expr_txt'])
                try:
                    region_set.add(regions_dict[lang['region_expr_txt']])
                except KeyError:
                    pass
            if {'GB', 'UK'} & region_set: region_set |= {'GB', 'UK'}
            if {'001', None} & region_set: region_set |= {'001', None}
            for language, script, region in product(language_set, script_set, region_set):
                new_tag = normalized_tag.update_dict({'language': language, 'script': script, 'region': region})
                cls._cache[uid]['IETF'].add(str(new_tag))
            if lang['region_expr_uid'] == 'art-279' and lang['region_expr_txt'] == '001':
                for language, script, region in product({lang['lang_code']}, script_set, {'001', None}):
                    new_tag = normalized_tag.update_dict({'language': language, 'script': script, 'region': region})
                    cls._cache[uid]['IETF'].add(str(new_tag))


    @classmethod
    def from_lc(cls, lc, include=[]):
        if isinstance(include, str):
            include = [include]
        strict_include = list(set(include) & cls._include)
        output = []
        result = panlex.query('/langvar', {'limit': 0, 'lang_code': lc, 'include': strict_include})['result']
        for r in result:
            cls._cache[r['uid']].update(r)
            if 'all_ex' in include:
                cls(r['uid'])._cache_all_ex()
            output.append(Lv(r['uid']))
        return output

    @classmethod
    def guess_uid(cls, code, script=''):
        if len(code) == 2:
            code = iso639.convert(code, outtype='part3', intype='part1')[0]
        lc_list = iso639.expand_macrolanguage(code, include_self=True)
        output = []
        for lv in cls.from_lc(lc_list, ['expr_count', 'script_expr_txt']):
            if script:
                if lv.sctt == script:
                    output.append((lv, lv.excount))
            else:
                output.append((lv, lv.excount))
        return sorted(output, key=lambda x: x[1], reverse=True)

    @classmethod
    def from_IETF(cls, tag, normalize=True):
        if cls._cache:
            try:
                [cls._cache[uid]['IETF'] for uid in cls._cache]
            except KeyError:
                cls._cache_IETF()
        else:
            cls._cache_IETF()
        tag = str(Language.get(tag, normalize))
        output = []
        for uid in cls._cache:
            if tag in cls._cache[uid]['IETF']:
                output.append(uid)
        return output

    def _cache_all_ex(self):
        import sqlite3
        conn = sqlite3.connect(data_directory + 'panlex_lite/db.sqlite')
        c = conn.cursor()
        c.execute("SELECT tt FROM ex WHERE lv=?", (self.lv,))
        self._cache[self]['all_ex'] = tuple(e[0] for e in c.fetchall())

    @property
    def lc(self):
        return self[:3]
    
    @property
    def vc(self):
        return int(self[4:])