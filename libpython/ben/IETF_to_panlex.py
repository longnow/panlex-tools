#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import keyring
import psycopg2
from psycopg2.extras import DictCursor
import subprocess
import getpass
from contextlib import contextmanager
from itertools import product
from langcodes import Language
from collections import defaultdict

USERNAME = getpass.getuser()

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
    cur = conn.cursor(cursor_factory=DictCursor)

db_connect()

def query(query_string, args=None):
    cur.execute(query_string, args)
    return cur.fetchall()

def cache_IETF():
    cache = {}
    result = query(
        """
        select expr.txt, exprsrc.txt as trans_txt 
        from expr
        inner join denotationx as denotation on denotation.expr = expr.id
        inner join denotationx as denotationsrc on denotationsrc.meaning = denotation.meaning and denotationsrc.expr != denotation.expr
        inner join expr as exprsrc on exprsrc.id = denotationsrc.expr
        where expr.langvar = uid_langvar('art-274') and denotationsrc.langvar = uid_langvar('art-420')
        """)
    for r in result:
        cache[r['txt']] = {}
        cache[r['txt']]['IETF'] = set()
    for r in query(
        """
        select 
            langvar.lang_code, 
            langvar.region_expr,
            uid(langvar.lang_code,langvar.var_code), 
            script_expr.txt as script_expr_txt, 
            uid(region_expr_langvar.lang_code,region_expr_langvar.var_code) as region_expr_uid, 
            region_expr.txt as region_expr_txt 
        from langvar 
        inner join expr on expr.id = langvar.name_expr 
        inner join expr as script_expr on script_expr.id = langvar.script_expr 
        inner join expr as region_expr on region_expr.id = langvar.region_expr 
        inner join langvar as region_expr_langvar on region_expr_langvar.id = region_expr.langvar 
        where uid(langvar.lang_code,langvar.var_code) = any(%s)
        """, (list(cache.keys()),)):
        cache[r['uid']].update(r)
    regions_dict = {}
    for r in query(
        """
        select expr.txt, exprsrc.txt as trans_txt
        from expr
        inner join denotationx as denotation on denotation.expr = expr.id
        inner join denotationx as denotationsrc on denotationsrc.meaning = denotation.meaning and denotationsrc.expr != denotation.expr
        inner join expr as exprsrc on exprsrc.id = denotationsrc.expr
        where expr.langvar = uid_langvar('art-006') and denotationsrc.expr = any(%s)
        """, ([l['region_expr'] for l in cache.values()],)):
        if len(r['txt']) == 2:
            regions_dict[r['trans_txt']] = r['txt']
    for r in result:
        uid = r['txt']
        lang = cache[uid]
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
            cache[uid]['IETF'].add(str(new_tag))
        if lang['region_expr_uid'] == 'art-279' and lang['region_expr_txt'] == '001':
            for language, script, region in product({lang['lang_code']}, script_set, {'001', None}):
                new_tag = normalized_tag.update_dict({'language': language, 'script': script, 'region': region})
                cache[uid]['IETF'].add(str(new_tag))
    return cache

def from_IETF(tag, normalize=False):
    cache = cache_IETF()
    tag = str(Language.get(tag, normalize))
    output = []
    for uid in cache:
        if tag in cache[uid]['IETF']:
            output.append(uid)
    return output
