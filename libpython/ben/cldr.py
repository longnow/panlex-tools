#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
from collections import defaultdict
import os
from bs4 import BeautifulSoup
from ben.panlex import *
from ben.IETF_to_panlex import from_IETF
import regex as re
from langcodes import Language
from tqdm import tqdm

lang_list = json.load(open(os.path.dirname(__file__) + 'lang_list.json'))
lang_dict = defaultdict(lambda: defaultdict(lambda: defaultdict(defaultdict)))

for lang in lang_list:
    lang_dict[lang['language']][lang['script']][lang['territory']][lang['variant']] = lang['_uid']

key_list = ['language', 'script', 'territory', 'variant']
def get_uid(lang, lang_dict):
    for key in key_list:
        if key not in lang.keys():
            lang[key] = ''
    if lang['language'] == 'zh_Hant':
        lang['language'] = 'zh'
        lang['script'] = 'Hant'
    try:
        return lang_dict[lang['language']][lang['script']][lang['territory']][lang['variant']]
    except KeyError:
        return ''

def extract(file_list, tag_name, tag_parent, mn_dict, langs_not_found):
    for file in file_list:
        soup = BeautifulSoup(open(file), 'lxml')
        lang = {}
        for key in key_list:
            try:
                lang[key] = soup.identity.find(key)['type']
            except TypeError:
                lang[key] = ''
        uid = get_uid(lang, lang_dict)
        if uid:
            for tag in soup(tag_name):
                tag_type = tag['type']
                if tag_type not in mn_dict:
                    mn_dict[tag_type] = Mn()
                text = tag.text
                if text:
                    mn_dict[tag_type].dn_list.append(Dn(Ex(text, uid)))
        elif soup(tag_parent):
            lang['_uid'] = ''
            langs_not_found.append(lang)

def lang_to_tag(lang):
    if lang['variant']: variants=[lang['variant']]
    else: variants = []
    return Language(
        language=lang['language'], 
        script=lang['script'],
        region=lang['territory'],
        variants=variants).to_tag()

def test_lang_list():
    tag_list = [(lang_to_tag(l), l['_uid']) for l in lang_list]
    good_langs = []
    bad_langs = []
    mult_tags = []
    for tag, uid in tqdm(tag_list):
        uids = from_IETF(tag)
        if uid in uids:
            good_langs.append((uid, tag))
        else:
            bad_langs.append((uid, tag))
        if len(uids) != 1:
            mult_tags.append((uids, tag))
    return good_langs, bad_langs, mult_tags