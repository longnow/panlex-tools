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
    """Updates ISO 15924 data files to latest version from Unicode"""
    _get_ISO_15924()

iso15924_dict = defaultdict(lambda : defaultdict(list))

def _initialize_ISO_15924():
    columns = ['code', 'number', 'en', 'fr', 'pva', 'date']
    to_split = [
        'Ahom',
        'Cham',
        'Deva',
        'Dupl',
        'Ethi',
        'Geor',
        'Gujr',
        'Hang',
        'Hani',
        'Hano',
        'Hluw',
        'Hung',
        'Inds',
        'Ital',
        'Knda',
        'Lana',
        'Lepc',
        'Lisu',
        'Mand',
        'Modi',
        'Moon',
        'Mroo',
        'Mtei',
        'Mymr',
        'Narb',
        'Newa',
        'Nkgb',
        'Olck',
        'Orkh',
        'Plrd',
        'Piqd',
        'Rjng',
        'Sarb',
        'Sgnw',
        'Shaw',
        'Shrd',
        'Sidd',
        'Sind',
        'Takr',
        'Tfng',
        'Tglg',
        'Wara',
        'Xsux',
    ]
        
    if os.path.exists(iso15924_data_directory + 'iso15924.txt'): pass
    else: _get_ISO_15924()
    with open(iso15924_data_directory + 'iso15924.txt', 'r') as data_file:
        for line in data_file:
            if line.startswith('#') or not line.strip(): continue
            for i, column in enumerate(columns):
                splitline = [s.strip() for s in line.split(';')]
                if column in ['en', 'fr']:
                    if splitline[0] in to_split:
                        entry = splitline[i].replace(')', '')
                        entry = entry.replace(' (', ', ')
                        entry = entry.replace(', etc.', '')
                        iso15924_dict[splitline[0]][column].extend(entry.split(', '))
                    else:
                        iso15924_dict[splitline[0]][column].append(splitline[i])
                else:
                    iso15924_dict[splitline[0]][column] = splitline[i]

def convert(string, outtype='code', intype='en', exact=False):
    """Takes an input string and returns a list of matching ISO 15924 codes or 
    language/variety names.

    Args:
        string: string to convert.

        outtype: output format. defaults to 'code'. can be:
                'code' : ISO 15924 code (four letter)
                'number' : ISO 15924 number (three digit number)
                'en' : English Name
                'fr' : French Name
                'pva' : Property Value Alias (PVA)
                    (name used internally by Unicode)

        intype: input format (same possibilities as outtype).
            defaults to 'en'.
        
        exact: if True, will only return matches matching input string exactly. 
            if False, will search within strings to find matches.
            defaults to False.
        
    Returns:
        returns a list of matches (as strings) found within the ISO 15924
        database. if no matches are found, returns an empty list.
        
    Examples:
        >>> convert('Cyrillic')
        ['Cyrl', 'Cyrs']

        >>> convert('Armenian', 'number')
        ['230']

        >>> convert('Hira')
        ['Hira', 'Hrkt', 'Jpan']
        
        >>> convert('Armn', 'fr', 'code')
        ['arménien']

        >>> convert('Cyrillic', exact=True)
        ['Cyrl']

    """
    if not iso15924_dict: _initialize_ISO_15924()
    output = []
    if exact:
        for code in iso15924_dict:
            if intype in ['en', 'fr']:
                if string in iso15924_dict[code][intype]:
                    if outtype in ['en', 'fr']:
                        output.extend(iso15924_dict[code][outtype])
                    else:
                        output.append(iso15924_dict[code][outtype])
            else:
                if string == iso15924_dict[code][intype]:
                    if outtype in ['en', 'fr']:
                        output.extend(iso15924_dict[code][outtype])
                    else:
                        output.append(iso15924_dict[code][outtype])
    else:
        for code in iso15924_dict:
            if intype in ['en', 'fr']:
                for name in iso15924_dict[code][intype]:
                    if string in name:
                        if outtype in ['en', 'fr']:
                            output.extend(iso15924_dict[code][outtype])
                        else:
                            output.append(iso15924_dict[code][outtype])
            else:    
                if string in iso15924_dict[code][intype]:
                    if outtype in ['en', 'fr']:
                        output.extend(iso15924_dict[code][outtype])
                    else:
                        output.append(iso15924_dict[code][outtype])
    return [out for out in sorted(set(output)) if out]

def convertir(chaîne, type_sortie='code', type_entrée='fr', exact=False):
    """Prend une chaîne de saisie et retourne une liste des codes ISO 15924 ou 
    une liste des langues/variétés correspondantes.
    
    Args:
        chaîne: chaîne à convertir
        type_sortie: format de sortie. par défaut, 'code'. peut être:
                'code' : code ISO 15924 (quatre lettres)
                'numéro' : numéro ISO 15924 (numéro à trois chiffres)
                'fr' : Nom français
                'en' : Nom anglais
                'pva' : synonyme de valeur de propriété (PVA)
                    (nom utilisé en interne par Unicode)

        type_entrée: format d'entrée (mêmes options que type_sortie).
            par défaut, 'fr'.
        
        exact: si True, retourne les résultats correspondant exactement à la 
            chaîne d'entrée. si False, recherche dans les chaînes pour trouver
            des résultats. par défaut, False.
        
    Retourne:
        Retourne une liste des résultats (sous forme de chaînes) trouvé dans la
        base de données de ISO 15924. si l'absence des résultats, retourne une
        liste vide.
        
    Exemples:
        >>> convertir('cyrillique')
        ['Cyrl', 'Cyrs']

        >>> convertir('arménien', 'numéro')
        ['230']

        >>> convertir('hira')
        ['Hira', 'Hrkt', 'Jpan']
        
        >>> convertir('Armn', 'en', 'code')
        ['Armenian']

        >>> convertir('cyrillique', exact=True)
        ['Cyrl']

    """
    if type_sortie == 'numéro': type_sortie = 'number'
    if type_entrée == 'numéro': type_entréey = 'number'
    return convert(chaîne, type_sortie, type_entrée, exact)