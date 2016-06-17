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
    'iso-639-3.tab': ['part3', 'part2b', 'part2t', 'part1', 'scope', 'language_type', 'ref_name', 'comment'],
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
    """Updates ISO 639 data files to latest version from SIL"""

    for iso_639_file in iso_639_files:
        _get_ISO_639_data_files(iso_639_file)

iso639_dict = defaultdict(lambda : defaultdict(list))

def _initialize_ISO_639():
    for iso_639_file in iso_639_files:
        if os.path.exists(iso639_data_directory + iso_639_file): pass
        else: _get_ISO_639_data_files(iso_639_file)

    with open(iso639_data_directory + 'iso-639-3.tab', 'r') as data_file:
        for line in data_file:
            if line.startswith('Id') or not line.strip(): continue
            for i, attr in enumerate(iso_639_files['iso-639-3.tab']):
                splitline = [s.strip() for s in line.split('\t')]
                iso639_dict[splitline[0]][attr] = splitline[i]

    with open(iso639_data_directory + 'iso-639-3_Name_Index.tab', 'r') as data_file:
        for line in data_file:
            if line.startswith('Id') or not line.strip(): continue
            for i, attr in enumerate(iso_639_files['iso-639-3_Name_Index.tab'][1:], start=1):
                splitline = [s.strip() for s in line.split('\t')]
                iso639_dict[splitline[0]][attr].append(splitline[i])




iso639_macro_dict = defaultdict(list)

def _initialize_ISO_639_macro():
    for iso_639_file in iso_639_files:
        if os.path.exists(iso639_data_directory + iso_639_file): pass
        else: _get_ISO_639_data_files(iso_639_file)

    with open(iso639_data_directory + 'iso-639-3-macrolanguages.tab', 'r') as data_file:
        for line in data_file:
            if line.startswith('M_Id') or not line.strip(): continue
            iso639_macro_dict[line.split('\t')[0]].append(line.split('\t')[1])

def convert(string, outtype='part3', intype='print_name', exact=False):
    """Takes an input string and returns a list of matching ISO 639 codes or 
    language/variety names.

    Args:
        string: string to convert
        
        outtype: output format. defaults to 'part3'. can be:
            'part1' : ISO 639-1 (two letter)
            'part2t' : ISO 639-2/T (three letter, terminological)
            'part2b' : ISO 639-2/B (three letter, bibliographic)
            'part3' : ISO 639-3 (three letter)
            'print_name' : name of language or variety used in most contexts
                (e.g. "Isthmus Zapotec")
            'inverted_name' : form of name with language name root fronted
                (e.g. "Zapotec, Isthmus")
            'ref_name' : form of name by which the language or variety is 
                identified in the standard.

        intype: input format (same possibilities as outtype).
            defaults to 'print_name'.
        
        exact: if True, will only return matches matching input string exactly. 
            if False, will search within strings to find matches.
            defaults to False.
        
    Returns:
        returns a list of matches (as strings) found within the ISO 639
        database. if no matches are found, returns an empty list.
        
    Examples:
        >>> convert('Armenian')
        ['aen', 'axm', 'hye', 'xcl']

        >>> convert('Armenian', 'part2b')
        ['arm']

        >>> convert('arm', 'print_name')
        ['Darmiya', 'Marma', 'Suarmin', 'Utarmbung', 'Zarma']
        
        >>> convert('xcl', 'inverted_name', 'part3')
        ['Armenian, Classical']

        >>> convert('Armenian', exact=True)
        ['hye']

    """
    if not iso639_dict: _initialize_ISO_639()
    output = []
    if exact:
        for code in iso639_dict:
            if intype in ['inverted_name', 'print_name']:
                if string in iso639_dict[code][intype]:
                    if outtype in ['inverted_name', 'print_name']:
                        output.extend(iso639_dict[code][outtype])
                    else:
                        output.append(iso639_dict[code][outtype])
            else:
                if string == iso639_dict[code][intype]:
                    if outtype in ['inverted_name', 'print_name']:
                        output.extend(iso639_dict[code][outtype])
                    else:
                        output.append(iso639_dict[code][outtype])
        if output: return [out for out in sorted(set(output)) if out]
    else:
        for code in iso639_dict:
            if intype in ['inverted_name', 'print_name']:
                for name in iso639_dict[code][intype]:
                    if string in name:
                        if outtype in ['inverted_name', 'print_name']:
                            output.extend(iso639_dict[code][outtype])
                        else:
                            output.append(iso639_dict[code][outtype])
            else:    
                if string in iso639_dict[code][intype]:
                    if outtype in ['inverted_name', 'print_name']:
                        output.extend(iso639_dict[code][outtype])
                    else:
                        output.append(iso639_dict[code][outtype])
        if output: return [out for out in sorted(set(output)) if out]
    return []


def expand_macrolanguage(part3, include_self=False):
    """Takes an ISO 639-3 macrolanguage code and returns a list of all 
    individual languages and varieties within.
    
    Args:
        part3: An ISO 639-3 macrolanguage code (as a string)
    
        include_self: if True, includes the macrolanguage code itself in the 
            output. defaults to False.
    
    Returns:
        if code is found, returns a list of ISO 639-3 codes (as strings)
        within the macrolanguage code. if code is not found, returns an empty
        string.
    
    Examples:
        >>> expand_macrolanguage('bal')
        ['bcc', 'bgn', 'bgp']

        >>> expand_macrolanguage('bal', include_self=True)
        ['bal', 'bcc', 'bgn', 'bgp']

    """
    
    if not iso639_macro_dict: _initialize_ISO_639_macro()
    output = iso639_macro_dict[part3]
    if include_self: output += [part3]
    return sorted(set(output))
