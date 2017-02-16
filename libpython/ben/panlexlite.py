#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sqlite3
from collections import defaultdict
import os

data_directory = os.path.dirname(__file__) + '/data/'
conn = sqlite3.connect(data_directory + 'db.sqlite')
c = conn.cursor()

class Lv(str):
    _cache = defaultdict(dict)
    # _include = {'cp', 'cu', 'dncount', 'excount', 'sc'}
    _columns = ['lv', 'lc', 'vc', 'uid', 'ex', 'tt']
    def __repr__(self):
        return "{cls}({string})".format(cls=self.__class__.__name__, string=repr(str(self)))

    def __getattr__(self, attr):
        if attr in ['_ipython_canary_method_should_not_exist_', '_ipython_display_']:
            return getattr(str(self), attr)
        try:
            return self._cache[self][attr]
        except KeyError:
            if attr == 'excount':
                c.execute("SELECT ex FROM ex WHERE lv=?", (self.lv,))
                self._cache[self][attr] = len(c.fetchall())
            else:
                c.execute("SELECT * FROM lv WHERE uid=?", (self,))
                data = {col : value for col, value in zip(self._columns, c.fetchone())}
                self._cache[self].update(data)
            try:
                return self._cache[self][attr]
            except KeyError:
                raise AttributeError('"{attr}" is not a valid {cls} object'.format(attr=attr, cls=self.__class__.__name__))

    # @classmethod
    # def precache(cls, lv_list, include=[]):
    #     if isinstance(include, str):
    #         include = [include]
    #     include = list(set(include) & cls._include)
    #     result = cls.panlex.query_all('/lv', {'uid': lv_list, 'include': include})['result']
    #     for r in result:
    #         cls._cache[r['uid']].update(r)
    # 
    @classmethod
    def from_lc(cls, lc, include=[]):
        # if isinstance(include, str):
        #     include = [include]
        # include = list(set(include) & cls._include)
        output = []
        c.execute("SELECT * FROM lv WHERE lc=?", (lc, ))
        result = c.fetchall()
        # result = cls.panlex.query_all('/lv', {'lc': lc, 'include': include})['result']
        for r in result:
            cls._cache[r[3]].update({col : value for col, value in zip(self._columns, r)})
            output.append(Lv(r['uid']))
        return output

