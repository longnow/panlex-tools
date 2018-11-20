#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import keyring
import psycopg2
from psycopg2.extras import NamedTupleCursor
import subprocess
import getpass
from contextlib import contextmanager
import ben.panlex
from collections import namedtuple
from tqdm import tqdm

DEBUG = False
USERNAME = getpass.getuser()
TABLES = {
    'Lv': 'langvar',
    'Ex': 'expr',
    'Df': 'definition',
    'Dn': 'denotation',
    'Mn': 'meaning',
    'Ap': 'source',
}

APOS_CANDIDATES = [
    '\u05f3',  # HEBREW PUNCTUATION GERESH
    '\ua78c',  # LOWERCASE SALTILLO
    '\u02bb',  # MODIFIER LETTER TURNED COMMA
    '\u2019',  # RIGHT SINGLE QUOTATION MARK
    '\u02bc',  # MODIFIER LETTER APOSTROPHE
]

POS_QUERY = """
select expr.txt, uid(langvar.lang_code, langvar.var_code), c.pos
from expr
join langvar on (langvar.id = expr.langvar)
join lateral (
  select coalesce(json_agg(b.pos), '[]'::json) as pos
  from (
    select json_build_object('txt', pos_expr.txt, 'score', grp_quality_score(array_agg(a.grp),array_agg(a.quality))) as pos
    from (
      select denotation_class.expr2 as pos_expr_id, denotationx.grp, denotationx.quality
      from denotationx
      join denotation_class on (denotation_class.denotation = denotationx.id)
      where denotationx.expr = expr.id and denotation_class.expr1 = 22080019
    ) a
    join expr pos_expr on (pos_expr.id = a.pos_expr_id)
    group by pos_expr.txt
    order by grp_quality_score(array_agg(a.grp),array_agg(a.quality)) desc, pos_expr.txt
 ) b
) c on true
where expr.langvar = uid_langvar(%s) and expr.txt = %s
"""

def db_connect():
    global conn, cur
    try:
        subprocess.run(['autossh', '-M 20000', '-f', '-NT', '-L 5432:localhost:5432', 'db.panlex.org'])
    except FileNotFoundError:
        pass
    try:
        conn = psycopg2.connect(
            dbname='plx',
            user=USERNAME,
            password=keyring.get_password('panlex_db', USERNAME),
            host='localhost')
    except psycopg2.OperationalError:
        keyring.set_password('panlex_db', USERNAME, getpass.getpass('Enter PanLex db password: '))
        conn = psycopg2.connect(
            dbname='plx',
            user=USERNAME,
            password=keyring.get_password('panlex_db', USERNAME),
            host='localhost')
    cur = conn.cursor(cursor_factory=NamedTupleCursor)

db_connect()

def query(query_string, args):
    if DEBUG:
        print(cur.mogrify(query_string, args).decode())
    try:
        cur.execute(query_string, args)
    except psycopg2.OperationalError:
        db_connect()
        cur.execute(query_string, args)
    return cur.fetchall()

class Lv(str):
    _cache = {}
    _uid_cache = {}
    _char_score_cache = {}
    _langvar_char_cache = {}
    def __init__(self, *args, **kwargs):
        self.uid = str(self)
        try:
            self.__dict__.update(self._cache[self._uid_cache[self.uid]]._asdict())
        except KeyError:
            result = query("SELECT * FROM langvar WHERE id = uid_langvar(%s)", (self.uid,))
            id = result[0].id
            self._cache[id] = result[0]
            self._uid_cache[self.uid] = id
            self.__dict__.update(self._cache[id]._asdict())

    def __repr__(self):
        return "{cls}({string})".format(cls=self.__class__.__name__, string=repr(str(self)))

    @classmethod
    def _precache(cls, langvar_char=False):
        for r in query("SELECT * FROM langvar", ()):
            uid = '{}-{}'.format(r.lang_code, str(r.var_code).zfill(3))
            cls._cache[r.id] = r
            cls._uid_cache[uid] = r.id
            if langvar_char:
                cls._langvar_char_cache[r.id] = set()
        if langvar_char:
            for r in query("SELECT * FROM langvar_char", ()):
                char_range = range(int(r.range_start, 16), int(r.range_end, 16) + 1)
                char_set = {chr(_) for _ in char_range}
                cls._langvar_char_cache[r.langvar].update(char_set)

    @classmethod
    def from_id(cls, id):
        try:
            data = cls._cache[id]
        except KeyError:
            result = query("SELECT * FROM langvar WHERE id = %s", (id,))
            cls._cache[id] = result[0]
            data = cls._cache[id]
        uid = '{}-{}'.format(data.lang_code, str(data.var_code).zfill(3))
        cls._uid_cache[uid] = data.id
        return Lv(uid)
    
    @property
    def lc(self):
        return self.lang_code

    @property
    def vc(self):
        return self.var_code
    
    @property
    def name(self):
        return Ex.from_id(self.name_expr)

    @property
    def script(self):
        return Ex.from_id(self.script_expr)

    @property
    def region(self):
        return Ex.from_id(self.region_expr)

    @property
    def langvar_char(self):
        try:
            return self._langvar_char_cache[self.id]
        except KeyError:
            output = set()
            for r in query("SELECT * FROM langvar_char WHERE langvar = %s", (self.id, )):
                output.update(range(int(r.range_start, 16), int(r.range_end, 16) + 1))
            output = {chr(_) for _ in output}
            self._langvar_char_cache[self.id] = output
            return self._langvar_char_cache[self.id]

    def char_score(self, char):
        if self.id in self._char_score_cache:
            try:
                return self._char_score_cache[self.id][char]
            except KeyError:
                return 0
        else:
            ex_list = Ex.from_lv(self, score=True)
            self._char_score_cache[self.id] = {}
            if DEBUG:
                ex_list = tqdm(ex_list)
            for ex in ex_list:
                score = ex.score
                for c in str(ex):
                    try:
                        self._char_score_cache[self.id][c] += score
                    except KeyError:
                        self._char_score_cache[self.id][c] = score
            try:
                return self._char_score_cache[self.id][char]
            except KeyError:
                return 0

    @classmethod
    def from_lc(cls, lc):
        output = []
        result = query("SELECT * FROM langvar WHERE lang_code=%s", (lc, ))
        for r in result:
            cls._cache[r.id] = r
            output.append(cls.from_id(r.id))
        return output
    
    def apostrophe(self):
        for candidate in APOS_CANDIDATES:
            if candidate in self.langvar_char:
                return candidate
        apos_scores = {candidate: self.char_score(candidate) for candidate in APOS_CANDIDATES}
        try:
            return max(apos_scores, key=lambda x: apos_scores[x])
        except ValueError:
            return APOS_CANDIDATES[-1]

# Lv._precache(langvar_char=True)

class Ex(ben.panlex.Ex):
    _cache = {}
    _score_cache = {}
    _langvar_cache = {}
    _TABLE = 'expr'

    @classmethod
    def _precache(cls, id_list=[], str_list=[], score=False):
        if not id_list and not str_list:
            raise TypeError("id_list or str_list must be provided")
        if id_list:
            id_list = tuple(id_list)
            for r in query("SELECT * FROM {} WHERE id IN %s".format(cls._TABLE), (id_list, )):
                cls._cache[r.id] = r
        else:
            str_list = tuple(map(str, str_list))
            for r in query("SELECT * FROM {} WHERE txt IN %s".format(cls._TABLE), (str_list, )):
                cls._cache[r.id] = r

    @property
    def id(self):
        try:
            return self._id
        except AttributeError:
            result = query("SELECT * FROM {} WHERE txt = %s AND langvar = uid_langvar(%s)".format(self._TABLE),
                            (str(self), self.lv))
            id = result[0].id
            self._cache[id] = result[0]
            self._id = id
            return self._id
    
    @property
    def score(self):
        try:
            return self._score
        except AttributeError:
            try:
                self._score = self._score_cache[self.id]
                return self._score
            except KeyError:
                query_string = """
                    SELECT expr.*,
                           grp_quality_score(array_agg(denotationx.grp),
                                             array_agg(denotationx.quality))
                                             AS score
                    FROM expr
                    JOIN denotationx ON (denotationx.expr = expr.id)
                    WHERE expr.id = %s
                    GROUP BY expr.id
                    """
                result = query(query_string, (self.id,))
                self._score_cache[id] = result[0].score
                self._score = result[0].score
                return self._score
            
    @classmethod
    def from_id(cls, id):
        try:
            data = cls._cache[id]
        except KeyError:
            result = query("SELECT * FROM {} WHERE id = %s".format(cls._TABLE), (id, ))
            cls._cache[id] = result[0]
            data = cls._cache[id]
        output = cls(data.txt, Lv.from_id(data.langvar))
        output._id = id
        return output
    
    @classmethod
    def from_ids(cls, ids):
        ids = tuple(ids)
        output = []
        if set(ids) <= cls._cache.keys():
            for id in ids:
                output.append(cls.from_id(id))
        else:
            for r in query("SELECT * FROM {} WHERE id IN %s".format(cls._TABLE), (ids, )):
                cls._cache[r.id] = r
                output.append(cls.from_id(r.id))
        return output

    @classmethod
    def from_lv(cls, lv, score=False, score_cache=True):
        if isinstance(lv, str):
            lv_ids = {Lv(lv).id}
        else:
            lv_ids = {Lv(_).id for _ in lv}
        output = []
        lv_ids_remaining = lv_ids.copy()
        for lv_id in lv_ids:
            if lv_id in cls._langvar_cache:
                if score:
                    if not cls._langvar_cache[lv_id] <= cls._score_cache.keys():
                        continue
                output.extend(cls.from_ids(cls._langvar_cache[lv_id]))
                lv_ids_remaining.remove(lv_id)
        if lv_ids_remaining:
            lv_ids_remaining = tuple(lv_ids_remaining)
            for lv_id in lv_ids_remaining:
                cls._langvar_cache[lv_id] = set()
            if score:
                if score_cache:
                    query_string = """
                        SELECT *
                        FROM exprx
                        WHERE langvar in %s
                        """
                else:
                    query_string = """
                        SELECT expr.*,
                            grp_quality_score(array_agg(denotationx.grp),
                                                array_agg(denotationx.quality))
                                                AS score
                        FROM expr
                        JOIN denotationx ON (denotationx.expr = expr.id)
                        WHERE expr.langvar in %s
                        GROUP BY expr.id
                        """
            else:
                query_string = "SELECT * FROM {} WHERE langvar in %s".format(cls._TABLE)
            for r in query(query_string, (lv_ids_remaining, )):
                cls._cache[r.id] = r
                cls._langvar_cache[r.langvar].add(r.id)
                if score:
                    cls._score_cache[r.id] = r.score
                data = cls._cache[r.id]
                ex = cls(data.txt, Lv.from_id(data.langvar))
                ex._id = data.id
                output.append(ex)
        return output

    def pos(self):
        return query(POS_QUERY, (self.lv, str(self)))[0].pos

    def apostrophe(self, as_lv=None):
        if as_lv:
            lv = Lv(as_lv)
        else:
            lv = Lv(self.lv)
        return self.sub(r"'", lv.apostrophe())

class Df(ben.panlex.Df, Ex):
    _TABLE = 'definition'

class Ap(ben.panlex.Ap):
    def apostrophe(self, lv_set=None, progress=False):
        if DEBUG:
            progress = True
        if not lv_set: lv_set = self.lv_set()
        lv_set = {Lv(_) for _ in lv_set}
        Ex.from_lv(lv_set, score=True)
        lv_apos = {lv: lv.apostrophe() for lv in lv_set}
        for mn in self:
            for lv in lv_set:
                mn.sub(r"'", lv_apos[lv], dn_list=mn(lv))
