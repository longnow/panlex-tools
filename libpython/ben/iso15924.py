#!/usr/bin/python3
# -*- coding: utf-8 -*-

import os
from collections import defaultdict
import zipfile
import io
import requests

data_directory = os.path.dirname(__file__) + '/data/'
iso15924_data_directory = data_directory + '/iso15924/'

try:
    os.mkdir(data_directory)
except FileExistsError: pass

try:
    os.mkdir(iso15924_data_directory)
except FileExistsError: pass

def _get_ISO_15924():
    url = 'http://unicode.org/iso15924/iso15924.txt.zip'
    zip_file = zipfile.ZipFile(io.BytesIO(requests.get(url).content))
    with open(iso15924_data_directory + 'iso15924.txt', 'wb') as file:
        for txtfile in zip_file.namelist():
            if txtfile.startswith('iso15924'):
                with zip_file.open(txtfile) as infile:
                    file.write(infile.read())

def update():
    _get_ISO_15924()

iso15924_dict = defaultdict(list)

def _initialize_ISO_15924():
    columns = ['code', 'number', 'en', 'fr', 'pva']
    if os.path.exists(iso15924_data_directory + 'iso15924.txt'): pass
    else: _get_ISO_15924()
    with open(iso15924_data_directory + 'iso15924.txt', 'r') as data_file:
        for line in data_file:
            if line.startswith('#') or not line.strip(): continue
            for i, column in enumerate(columns):
                iso15924_dict[column].append(line.split(';')[i])

def convert(string, outtype='code', intype=None):
    if not iso15924_dict: _initialize_ISO_15924()
    if not string: raise TypeError('convert() argument must be a non-empty string')
    output = []
    if intype: columns = [intype]
    else: columns = ['pva', 'fr', 'en', 'code', 'number']
    for column in columns:
        for i, value in enumerate(iso15924_dict[column]):
            if string == value: output.append(iso15924_dict[outtype][i])
        if output: break
        for i, value in enumerate(iso15924_dict[column]):
            if string in value: output.append(iso15924_dict[outtype][i])
        if output: break
    if any(output): return output
    else: return None