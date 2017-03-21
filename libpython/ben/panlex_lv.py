#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import panlex
import ben.iso639 as iso639
import os
from collections import defaultdict

data_directory = os.path.dirname(__file__) + '/data/'

class Lv(str):
    _cache = defaultdict(dict)
    _include = {'cp', 'cu', 'dncount', 'excount', 'sctt'}

    def __repr__(self):
        return "{cls}({string})".format(cls=self.__class__.__name__, string=repr(str(self)))

    def __getattr__(self, attr):
        if attr in ['_ipython_canary_method_should_not_exist_', '_ipython_display_']:
            return getattr(str(self), attr)
        try:
            return self._cache[self][attr]
        except KeyError:
            if attr == 'all_ex':
                self._cache_all_ex()
            else:
                include = []
                if attr in self._include:
                    include.append(attr)
                self._cache[self].update(panlex.query('/lv/{}'.format(self), {'include': include})['lv'])
            try:
                return self._cache[self][attr]
            except KeyError:
                raise AttributeError('"{attr}" is not a valid {cls} object'.format(attr=attr, cls=self.__class__.__name__))

    @classmethod
    def precache(cls, lv_list=[], include=[], all_lv=False):
        if not (lv_list or all_lv):
            raise TypeError('either lv_list or all_lv must be specified')
        if isinstance(include, str):
            include = [include]
        all_ex = False
        if 'all_ex' in include:
            all_ex = True
        include = list(set(include) & cls._include)
        if all_lv:
            result = cls.panlex.query_all('/lv', {'include': include})['result']
        else:
            result = cls.panlex.query_all('/lv', {'uid': lv_list, 'include': include})['result']
        for r in result:
            cls._cache[r['uid']].update(r)
            if all_ex:
                Lv(r['uid'])._cache_all_ex()

    @classmethod
    def from_lc(cls, lc, include=[]):
        if isinstance(include, str):
            include = [include]
        all_ex = False
        if 'all_ex' in include:
            all_ex = True
        include = list(set(include) & cls._include)
        output = []
        result = cls.panlex.query_all('/lv', {'lc': lc, 'include': include})['result']
        for r in result:
            cls._cache[r['uid']].update(r)
            if all_ex:
                Lv(r['uid'])._cache_all_ex()
            output.append(Lv(r['uid']))
        return output

    @classmethod
    def guess_uid(cls, code, script=''):
        lc_list = iso639.expand_macrolanguage(code, include_self=True)
        output = []
        for lv in cls.from_lc(lc_list, ['excount', 'sctt']):
            if script:
                if lv.sctt == script:
                    output.append((lv, lv.excount))
            else:
                output.append((lv, lv.excount))
        return sorted(output, key=lambda x: x[1], reverse=True)

    def _cache_all_ex(self):
        import sqlite3
        conn = sqlite3.connect(data_directory + 'db.sqlite')
        c = conn.cursor()
        c.execute("SELECT tt FROM ex WHERE lv=?", (self.lv,))
        self._cache[self]['all_ex'] = tuple(e[0] for e in c.fetchall())
