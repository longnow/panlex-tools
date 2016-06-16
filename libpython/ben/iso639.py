#!/usr/bin/python3
# -*- coding: utf-8 -*-

import os
import requests
from collections import defaultdict

data_directory = os.path.dirname(__file__) + '/data/'
iso639_data_directory = data_directory + '/iso639/'

try:
    os.mkdir(data_directory)
except FileExistsError: pass

try:
    os.mkdir(iso639_data_directory)
except FileExistsError: pass

iso_639_files = {
    'iso-639-3.tab': ['part3', 'part2b', 'part2t', 'part1', 'scope', 'language_type', 'ref_name'],
    'iso-639-3_Name_Index.tab': ['part3', 'print_name', 'inverted_name'],
    'iso-639-3-macrolanguages.tab': ['m_id', 'part3'],
    }
def _get_ISO_639_data_files(iso_639_file):
    url_base = 'http://www-01.sil.org/iso639-3/'
    with open(iso639_data_directory + iso_639_file, 'w', encoding='utf-8') as file:
        r = requests.get(url_base + iso_639_file)
        r.encoding = 'utf-8'
        file.write(r.text)

def update():
    for iso_639_file in iso_639_files:
        _get_ISO_639_data_files(iso_639_file)

iso639_dict = defaultdict(list)

def _initialize_ISO_639():
    for iso_639_file in iso_639_files:
        if os.path.exists(iso639_data_directory + iso_639_file): pass
        else: _get_ISO_639_data_files(iso_639_file)

    with open(iso639_data_directory + 'iso-639-3.tab', 'r') as data_file:
        for line in data_file:
            if line.startswith('Id') or not line.strip(): continue
            for i, attr in enumerate(iso_639_files['iso-639-3.tab']):
                iso639_dict[attr].append(line.split('\t')[i])

iso639_macro_dict = defaultdict(list)

def _initialize_ISO_639_macro():
    for iso_639_file in iso_639_files:
        if os.path.exists(iso639_data_directory + iso_639_file): pass
        else: _get_ISO_639_data_files(iso_639_file)

    with open(iso639_data_directory + 'iso-639-3-macrolanguages.tab', 'r') as data_file:
        for line in data_file:
            if line.startswith('M_Id') or not line.strip(): continue
            iso639_macro_dict[line.split('\t')[0]].append(line.split('\t')[1])

def convert(string, outtype='part3', intype=None):
    if not iso639_dict: _initialize_ISO_639()
    output = []
    if intype: columns = [intype]
    else: columns = ['part1', 'part2t', 'part2b', 'part3', 'inverted_name', 'print_name', 'ref_name']
    for column in columns:
        for i, pva in enumerate(iso639_dict[column]):
            if string == pva: output.append(iso639_dict[outtype][i])
        if output: return output
        for i, pva in enumerate(iso639_dict[column]):
            if string in pva: output.append(iso639_dict[outtype][i])
        if output: return output

def expand_macrolanguage(part3, include_self=False):
    if not iso639_macro_dict: _initialize_ISO_639_macro()
    output = iso639_macro_dict[part3]
    if include_self: output += [part3]
    return output
