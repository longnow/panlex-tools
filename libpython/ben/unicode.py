#!/usr/bin/python3
# -*- coding: utf-8 -*-

import regex as re
import os
import ftplib
import zipfile
import gzip
import io
import pickle
import requests
from collections import defaultdict
from itertools import permutations

data_directory = os.path.dirname(__file__) + '/data/'

file_list = [
    ('Scripts.txt', {}),
    ('ScriptExtensions.txt', {}),
    ('DerivedGeneralCategory.txt', {}),
    ('Blocks.txt', {}),
    ('Unihan_Readings.txt', {'Unihan': True}),
    ('EastAsianWidth.txt', {'property_names': ['East_Asian_Width']}),
    ('Unihan_RadicalStrokeCounts.txt', {'Unihan': True}),
    ('IndicPositionalCategory.txt', {}),
    ('IndicSyllabicCategory.txt', {}),
    ('Unihan_DictionaryLikeData.txt', {'Unihan' : True}),
    ('DerivedNumericValues.txt', {'property_names': ['Numeric_Value', '', 'Numeric_Value_Rational']}),
    ('DerivedAge.txt', {}),
    ('PropList.txt', {'boolean' : True}),
    ('DerivedCoreProperties.txt', {'boolean' : True}),
    ('HangulSyllableType.txt', {}),
    ('LineBreak.txt', {'property_names': ['Line_Break']}),
    ]

try:
    os.mkdir(data_directory)
except FileExistsError: pass

def clean(string):
    return re.sub(r'[\s_-]', '', string.strip()).lower()

def _get_unicode_data_file(file_name, version=None, force=False):
    if version:
        url_dir = '/Public/' + str(version) + '/ucd/'
    else:
        url_dir = '/Public/UCD/latest/ucd/'
    path_list = ['', 'extracted/', 'auxiliary/']

    ftp = ftplib.FTP('ftp.unicode.org')
    ftp.login()
    ftp.cwd(url_dir)
    file_found = False
    for path in path_list:
        ftp.cwd(url_dir + path)
        try:
            with open(data_directory + file_name, 'wb') as out_file:
                ftp.retrbinary("RETR " + file_name, out_file.write)
            file_found = True
            break
        except ftplib.error_perm:
            pass
    if not file_found:
        ftp.cwd(url_dir)
        if force:
            with open(data_directory + 'Unihan.zip', 'wb') as zip_file:
                ftp.retrbinary("RETR Unihan.zip", zip_file.write)
        elif os.path.exists(data_directory + 'Unihan.zip'): pass
        else:
            with open(data_directory + 'Unihan.zip', 'wb') as zip_file:
                ftp.retrbinary("RETR Unihan.zip", zip_file.write)
        with open(data_directory + file_name, 'wb') as out_file, zipfile.ZipFile(data_directory + 'Unihan.zip') as zip_file:
            try:
                data = zip_file.open(file_name, 'r').read()
                out_file.write(data)
                file_found = True
            except:
                pass
    if not file_found: raise ftplib.error_perm(file_name + ' not found in Unicode data repository')

def _code_point_range_to_range(cprange):
    code_points = cprange.strip().split('..')
    start = int(code_points[0], base=16)
    if len(code_points) > 1:
        end = int(code_points[1], base=16)
    else:
        end = start
    return range(start, end + 1)

def _extract_data(file_name, property_names=[]):
    property_names = [_pa(p) for p in property_names]
    with open(data_directory + file_name, 'r') as data_file:
        output_list = [[]] * 0x110000
        for line in data_file:
            if not property_names:
                if line.startswith('# Property:'):
                    property_names = [_pa(line.replace('# Property:', '').strip())]
            if line.startswith('# @missing: '):
                data_line = line.replace('# @missing: ', '').strip().split(';')
                missing_cpr = _code_point_range_to_range(data_line[0])
                missing_data = [_pva(p, d) for p, d in zip(property_names, data_line[1:])]
                if file_name == 'ScriptExtensions.txt':
                    for code_point in missing_cpr:
                        output_list[code_point] = [(unicode_properties['sc'][code_point],)]
                else:
                    for code_point in missing_cpr:
                        output_list[code_point] = missing_data
            line = line.partition('#')[0]
            if not line.strip(): continue
            data_line = line.split(';')
            cpr = _code_point_range_to_range(data_line[0])
            if file_name == 'ScriptExtensions.txt':
                data = [tuple(data_line[1].strip().split())]
            else:
                data = [_pva(p, d) for p, d in zip(property_names, data_line[1:])]
            for code_point in cpr:
                output_list[code_point] = data
        output_dict = {property_name: [''] * 0x110000 for property_name in property_names if property_name}
        for i, property_name in enumerate(property_names):
            if property_name:
                for j, data in enumerate(output_list):
                    if data: output_dict[property_name][j] = data[i]
        return output_dict

def _extract_boolean_data(file_name):
    with open(data_directory + file_name, 'r') as data_file:
        output_dict = {}
        for line in data_file:
            if line.startswith('#') or not line.strip(): continue
            line = line.partition('#')[0]
            if not line.strip(): continue
            data_line = line.split(';')
            cpr = _code_point_range_to_range(data_line[0])
            property_name = _pa(data_line[1])
            for code_point in cpr:
                try:
                    output_dict[property_name][code_point] = True
                except KeyError:
                    output_dict[property_name] = [False] * 0x110000
                    output_dict[property_name][code_point] = True
        return output_dict

def _extract_Unihan_data(file_name):
    with open(data_directory + file_name, 'r') as data_file:
        output_dict = {}
        for line in data_file:
            if line.startswith('#') or not line.strip(): continue
            data_line = line.split('\t')
            code_point = int(data_line[0].replace('U+', '').strip(), base=16)
            property_name = _pa(data_line[1])
            data = data_line[2].strip()
            try:
                output_dict[property_name][code_point] = data
            except KeyError:
                output_dict[property_name] = [''] * 0x110000
                output_dict[property_name][code_point] = data
        return output_dict

def _populate_properties(file_name, property_names=[], Unihan=False, boolean=False, force=False):
    if force: _get_unicode_data_file(file_name, force=True)
    if os.path.exists(data_directory + file_name): pass
    else: _get_unicode_data_file(file_name)
    if boolean: data = _extract_boolean_data(file_name)
    elif Unihan: data = _extract_Unihan_data(file_name)
    else: data = _extract_data(file_name, property_names)
    unicode_properties.update(data)

def _populate_aliases(force=False):
    for file_name in ['PropertyAliases.txt', 'PropertyValueAliases.txt']:
        if force: _get_unicode_data_file(file_name, force=True)
        if os.path.exists(data_directory + file_name): pass
        else: _get_unicode_data_file(file_name)
        with open(data_directory + file_name, 'r') as data_file:
            for line in data_file:
                if line.startswith('#') or not line.strip(): continue
                data_line = [s.strip() for s in line.split(';')]
                if file_name == 'PropertyAliases.txt':
                    for alias in data_line:
                        property_aliases[alias] = data_line[0]
                        property_aliases[clean(alias)] = data_line[0]
                if file_name == 'PropertyValueAliases.txt':
                    for alias in data_line[1:]:
                        try:
                            property_value_aliases[data_line[0]][alias] = data_line[1]
                            property_value_aliases[data_line[0]][clean(alias)] = data_line[1]
                        except KeyError:
                            property_value_aliases[data_line[0]] = {}
                            property_value_aliases[data_line[0]][alias] = data_line[1]
                            property_value_aliases[data_line[0]][clean(alias)] = data_line[1]

                

try:
    with gzip.open(data_directory + 'unicode_properties.gz', 'rb') as gz_file:
        unicode_properties = pickle.load(gz_file)
except FileNotFoundError:
    unicode_properties = {}
    for i in file_list:
        _populate_properties(i[0], **i[1])
    with gzip.open(data_directory + 'unicode_properties.gz', 'wb') as gz_file:
        pickle.dump(unicode_properties, gz_file, protocol=-1)

property_aliases, property_value_aliases = {}, {}
_populate_aliases()

def force_update():
    global unicode_properties
    unicode_properties = {}
    print("getting aliases")
    _populate_aliases(force=True)
    for i in file_list:
        print("getting {}".format(i[0]))
        _populate_properties(i[0], force=True, **i[1])
    with gzip.open(data_directory + 'unicode_properties.gz', 'wb') as gz_file:
        pickle.dump(unicode_properties, gz_file, protocol=-1)

def list_properties():
    return sorted(unicode_properties.keys())

def get_property(char, unicode_property):
    if len(char) != 1:
        raise TypeError('get_property() expected a character, but string of length {} found'.format(len(char)))
    return unicode_properties[_pa(unicode_property)][ord(char)]

def _pa(prop):
    try:
        return property_aliases[clean(prop)]
    except KeyError:
        return prop.strip()

def _pva(prop, val):
    try:
        return property_value_aliases[clean(prop)][clean(val)]
    except KeyError:
        return val.strip()

def get_chars(unicode_property, value, max_chars=0, rx=False):
    if rx: rx = re.compile(value)
    output = []
    for i in range(len(unicode_properties[unicode_property])):
        if rx:
            if rx.search(unicode_properties[unicode_property][i]):
                output.append((hex(i), chr(i), unicode_properties[unicode_property][i]))
        else:
            if unicode_properties[unicode_property][i] == value:
                output.append(chr(i))
    return output

ansi_colors = ['black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white']
ansi_colors = {color: str(num) for num, color in enumerate(ansi_colors)}
def colored(string, fg_color, bg_color, bright=False):
    if bright: return '\x1b[3{};4{};1m{}\x1b[0m'.format(ansi_colors[fg_color], ansi_colors[bg_color], string)
    else: return '\x1b[3{};4{}m{}\x1b[0m'.format(ansi_colors[fg_color], ansi_colors[bg_color], string)

def color_script(string, print_legend=False):
    scripts = set()
    for char in string:
        scripts.add(get_property(char, 'Script'))
    scripts = sorted(scripts)
    colors = sorted(permutations(ansi_colors, 2))
    colors = [c + (False,) for c in colors] + [c + (True,) for c in colors]
    script_dict = {script: (color[1], color[0], color[2]) for script, color in zip(scripts, colors)}
    output = [colored(char, *script_dict[get_property(char, 'Script')]) for char in string]
    return ''.join(output)
