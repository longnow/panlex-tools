#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import panlex
import sqlite3
import regex as re
from collections import defaultdict, Counter
import os
import zipfile
import requests
from tqdm import tqdm

data_directory = os.path.dirname(__file__) + '/data/'

# def update_panlex_lite():
#     r = requests.get('http://dev.panlex.org/db/panlex_lite.zip', stream=True)
#     with open(data_directory + 'panlex_lite.zip', 'wb') as f:
#         total_length = int(r.headers.get('content-length'))
#         for chunk in tqdm(r.iter_content(chunk_size=1024), total=total_length): 
#             if chunk:
#                 f.write(chunk)
#                 f.flush()

def get_lv_code(lv):
    if re.match(r'^[a-z]{3}-[0-9]{3,}$', lv):
        lc = lv[:3]
        vc = int(lv[4:])
    else: raise ValueError("lv must be in the format xxx-000")
    conn = sqlite3.connect(data_directory + 'db.sqlite')
    c = conn.cursor()
    c.execute("SELECT lv FROM lv WHERE lc=? AND vc=?", (lc, vc))
    try:
        return c.fetchone()[0]
    except TypeError:
        return None

def all_ex(lv):
    conn = sqlite3.connect(data_directory + 'db.sqlite')
    c = conn.cursor()
    lv_code = get_lv_code(lv)
    c.execute("SELECT tt FROM ex WHERE lv=?", (lv_code,))
    return [e[0] for e in c.fetchall()]

def char_counts(lv):
    output = Counter()
    for ex in all_ex(lv):
        output.update(ex)
    return output

def get_scores(str_list, lv, ui=[]):
    str_list = list(str_list)
    result = panlex.query_norm('/norm/expr/{}'.format(lv), {'txt' : str_list, 'grp' : ui})
    return {string : result['norm'][string]['score'] for string in result['norm']}

def get_degraded_scores(str_list, lv, ui=[]):
    str_list = list(str_list)
    output = {}
    result = panlex.query_norm('/norm/expr/{}'.format(lv), {'txt' : str_list, 'grp' : ui, 'degrade' : True})
    for string in result['norm']:
        output[string] = {}
        output[string][string] = 0
        for entry in result['norm'][string]:
            if entry['txt']: output[string][entry['txt']] = entry['score']
    return output

def perl_re(in_re, out=''):
    in_re = re.sub(r'/', r'\/', in_re)
    out = re.sub(r'\\g<(\d+)>', r'\\\1', out)
    out = re.sub(r'\\g<(.+)>', r'$+{\1}', out)
    return in_re, out
    # return "return $_[0] =~ s/{}/{}/rg".format(in_re, out)

def get_redeg_scores(str_list, lv, in_re, out, ui=[]):
    str_list = list(str_list)
    rx = perl_re(in_re, out)
    output = {}
    result = panlex.query_norm('/norm/expr/{}'.format(lv), {'txt' : str_list, 'grp' : ui, 'regex' : rx, 'degrade' : True})
    for string in result['norm']:
        output[string] = {}
        output[string][string] = 0
        for entry in result['norm'][string]:
            if entry['txt']: output[string][entry['txt']] = entry['score']
    return output

def get_custom_deg_scores(str_list, lv, deg_func, include_std_deg=True, ui=[]):
    str_list = list(str_list)
    output = {}
    deg_dict = defaultdict(list)
    for string in all_ex(lv):
        deg_dict[deg_func(string)].append(string)
    for string in str_list:
        deg_dict[deg_func(string)].extend([string, deg_func(string)])
    strs_to_check = []
    for string in str_list:
        strs_to_check.extend(deg_dict[deg_func(string)])
    result = get_scores(strs_to_check, lv, ui)
    for string in str_list:
        output[string] = {}
        output[string][string] = result[string]
        output[string][deg_func(string)] = result[deg_func(string)]
        for deg_string in deg_dict[string]:
            output[string][deg_string] = result[deg_string]
    if include_std_deg:
        result = get_degraded_scores(strs_to_check, lv, ui)
        for string in str_list:
            for deg_string in deg_dict[deg_func(string)]:
                output[string].update(result[deg_string])
    return output

def get_cp(lv):
    result = panlex.query('/langvar/{}'.format(lv), {'include' : 'langvar_char'})['langvar']['langvar_char']
    cps = set()
    for r in result:
        cps.update(range(r[0], r[1] + 1))
    return cps

apos_candidates = [
    0x05f3,  # HEBREW PUNCTUATION GERESH
    0xa78c,  # LOWERCASE SALTILLO
    0x02bb,  # MODIFIER LETTER TURNED COMMA
    0x2019,  # RIGHT SINGLE QUOTATION MARK
    0x02bc,  # MODIFIER LETTER APOSTROPHE
]
def apostrophe(lv):
    cps = get_cp(lv)
    for candidate in apos_candidates:
        if candidate in cps:
            return chr(candidate)
    c = char_counts(lv)
    scores = {i : c[i] for i in c if i in map(chr, apos_candidates)}
    try:
        return max(scores, key=lambda x: scores[x])
    except ValueError:
        return chr(apos_candidates[-1])