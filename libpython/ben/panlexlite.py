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
    _columns = ['id',
                'lang_code',
                'var_code',
                'uid',
                'meaning',
                'name_expr',
                'name_expr_txt',
                'region_expr',
                'region_expr_txt',
                'script_expr',
                'script_expr_txt']
    def __repr__(self):
        return "{cls}({string})".format(cls=self.__class__.__name__, string=repr(str(self)))

    def __getattr__(self, attr):
        if attr in ['_ipython_canary_method_should_not_exist_', '_ipython_display_']:
            return getattr(str(self), attr)
        try:
            return self._cache[self][attr]
        except KeyError:
            if attr == 'excount':
                c.execute("SELECT ex FROM ex WHERE lv=?", (self.id,))
                self._cache[self][attr] = len(c.fetchall())
            else:
                c.execute("SELECT * FROM lv WHERE uid=?", (self,))
                data = {col : value for col, value in zip(self._columns, c.fetchone())}
                self._cache[self].update(data)
            try:
                return self._cache[self][attr]
            except KeyError:
                raise AttributeError('"{attr}" is not a valid {cls} object'.format(attr=attr, cls=self.__class__.__name__))

    @classmethod
    def from_lc(cls, lc, include=[]):
        output = []
        c.execute("SELECT * FROM langvar WHERE lang_code=?", (lc, ))
        result = c.fetchall()
        for r in result:
            cls._cache[r[3]].update({col : value for col, value in zip(cls._columns, r)})
            output.append(Lv(r[3]))
        return output

    def all_ex(self, include=[]):
        if 'score' in include:
            query = """
                SELECT s.txt, sum(s.quality) AS expr_quality FROM (
                SELECT expr.txt, max(denotationx.quality) AS quality
                FROM expr
                JOIN denotationx ON (denotationx.expr = expr.id)
                WHERE expr.langvar = ?
                GROUP BY expr.txt, denotationx.grp
                ) s
                GROUP BY s.txt
                """
        else:
            query = """
                SELECT txt FROM expr WHERE langvar = ?
                """
        c.execute(query, (self.id,))
        return [r if len(r) > 1 else r[0] for r in c.fetchall()]