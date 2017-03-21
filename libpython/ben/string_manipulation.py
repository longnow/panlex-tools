#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import regex as re
try:
    import requests
except ImportError:
    pass
import subprocess
import atexit
import os
from time import sleep
spacy_parser = None
frogclient = None
supported_langs = ['eng', 'nld']

def initialize_spacy_parser():
    from spacy.en import English
    global spacy_parser
    if not spacy_parser:
        spacy_parser = English()

def initialize_frog_parser(port=12345):
    from pynlpl.clients.frogclient import FrogClient
    import subprocess
    import atexit
    import time
    global frogclient
    if not frogclient:
        frogserver_sp = subprocess.Popen(['frog', '-S', str(port)], stderr=subprocess.DEVNULL)
        atexit.register(frogserver_sp.terminate)
        time.sleep(10)
        frogclient = FrogClient('localhost', port)

def parts_of_speech(string, lang='eng'):
    output = []
    if lang == 'eng':
        initialize_spacy_parser()
        for token in spacy_parser(string):
            output.append(token.pos_)
    elif lang == 'nld':
        initialize_frog_parser()
        for token in frogclient.process(string):
            output.append(token[3])
    else:
        raise TypeError('currently supported languages are ' + str(supported_langs))
    return output

def lemmas(string, lang='eng'):
    output = []
    if lang == 'eng':
        initialize_spacy_parser()
        for token in spacy_parser(string):
            output.append(token.lemma_)
    elif lang == 'nld':
        initialize_frog_parser()
        for token in frogclient.process(string):
            output.append(token[1])
    else:
        raise TypeError('currently supported languages are ' + str(supported_langs))
    return output

def lemmatized(string, lang='eng', to_skip_list=None):
    if to_skip_list:
        skip_re = re.compile('|'.join(to_skip_list))
    output = ''
    if lang == 'eng':
        initialize_spacy_parser()
        for token in spacy_parser(string):
            if to_skip_list and skip_re.search(token.text): 
                output += token.text_with_ws
                continue
            output += token.text_with_ws.replace(token.text, token.lemma_)
    else:
        raise TypeError('currently supported languages for this function are ' + str(['eng']))
    return output

prohibited_chars = [
    chr(0x00ad),
    chr(0x200b),
    chr(0x200e),
    chr(0x200f),
    chr(0xfeff),
    chr(0xfffe),
]
def clean_str(str):
    output = re.sub(r'\s+', ' ', str)
    output = re.sub(r'\s*‣+\s*', '‣', output)
    for char in prohibited_chars:
        output = output.replace(char, '')
    output = output.strip('‣')
    output = re.sub(r'\(\)', '', output)
    output = re.sub(r'\( ', '(', output)
    output = re.sub(r' \)', ')', output)
    output = output.strip()
    return output

def expand_parens(string, parens="()", include_spaces=False, substitute_string=''):
    output = []
    open_paren = re.escape(parens[0])
    close_paren = re.escape(parens[1])
    substitute_string = re.escape(substitute_string)
    in_string = re.sub(open_paren + substitute_string, parens[0], string)
    in_string = re.sub(substitute_string + close_paren, parens[1], in_string)

    if include_spaces:
        regex1 = regex2 = re.compile(r'(^.*)' + open_paren + r'(.+)' + close_paren + r'(.*$)')
    else:
        regex1 = re.compile(r'(^.*\S)' + open_paren + r'(\S+)' + close_paren + r'(.*$)')
        regex2 = re.compile(r'(^.*)' + open_paren + r'(\S+)' + close_paren + r'(\S.*$)')

    re_match1 = regex1.search(in_string)
    re_match2 = regex2.search(in_string)
    if re_match1:
        within = re_match1.group(1) + re_match1.group(2) + re_match1.group(3)
        without = re_match1.group(1) + re_match1.group(3)
    elif re_match2:
        within = re_match2.group(1) + re_match2.group(2) + re_match2.group(3)
        without = re_match2.group(1) + re_match2.group(3)
    else:
        return [string]

    output = [clean_str(without), clean_str(within)]

    return output

def ordered_re_dict(re_dictionary):
    return OrderedDict([(key, re_dictionary[key]) for key in sorted(re_dictionary, key=len, reverse=True)])

def kludge_string(string, kludge_dict):
    try:
        return kludge_dict[string]
    except KeyError:
        return string

def distribute(string, delim, groups=[r'\S+', r'\S+']):
    """Distributes one part of a string to other parts of that string (seperated
    by a delimiter), returning a list of strings.

    Args:
        string: input string
        delim: regex matching delimiter between two parts of string to be
            distributed upon
        groups: list of regular expressions that match the parts of the string
            receiving the distributed portion of the string.
            defaults to [r'\S+', r'\S+'] (i.e. two blocks of non-whitespace)

    Returns:
        If delimiter and groups are found, returns a list of strings.
        If they are not found, returns a list containing just the original
            string.

    Examples:
        >>> distribute('hot spam/eggs', r'/')
        ['hot spam', 'hot eggs']
        >>> distribute('hot spam/eggs on toast', r'/')
        ['hot spam on toast', 'hot eggs on toast']
        >>> distribute('hot spam/eggs on toast', r'/', [r'\S+', r'\S+ on toast'])
        ['hot spam', 'hot eggs on toast']
    """
    output = []
    n = len(re.findall(delim, string)) + 1
    gps = groups + [groups[-1]] * (n - len(groups))
    rx = re.compile(delim.join([r'(' + group + r')' for group in gps]))
    re_match = rx.search(string)
    if re_match:
        output = [rx.sub(re_match.group(i), string) for i in range(1, n+1)]
    else:
        return [string]

    return output

def regex_pop(from_str, re_to_match, pops=1):
    rx = re.compile(re_to_match)
    pop = rx.findall(from_str)[0:pops]
    if not pop: return None
    to_str = rx.sub('', from_str, pops)
    if pops == 1:
        return pop[0], to_str
    else:
        return pop, to_str

def regex_pop_all(from_str, re_to_match):
    rx = re.compile(re_to_match)
    pop = rx.findall(from_str)
    to_str = rx.sub('', from_str)
    return pop, to_str

def _initialize_taxons():
    taxon_finder_sp = subprocess.Popen(['nodejs', os.environ['PANLEX_TOOLDIR'] + "/util/taxonfinder-api"], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL)
    atexit.register(taxon_finder_sp.terminate)

def _initialize_npm_util(util_name, port=3000):
    npm_util_sp = subprocess.Popen(['nodejs', os.environ['PANLEX_TOOLDIR'] + "/util/" + util_name, str(port)], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL)
    atexit.register(npm_util_sp.terminate)

def taxons(string, normalize=False):
    try:
        r = requests.get('http://localhost:3000', params={'text': string})
    except requests.exceptions.ConnectionError:
        _initialize_taxons()
        sleep(3)
    output = []
    stringlist = [string]
    if normalize:
        stringlist.append(' '.join([t.lower() if i % 2 else t.title() for i, t in enumerate(string.split())]))
        stringlist.append(' '.join([t.title() if i % 2 else t.lower() for i, t in enumerate(string.split())]))
        stringlist.append(' '.join([t.lower() if i % 3 else t.title() for i, t in enumerate(string.split())]))
        stringlist.append(' '.join([t.lower() if (i + 1) % 3 else t.title() for i, t in enumerate(string.split())]))
        stringlist.append(' '.join([t.lower() if (i + 2) % 3 else t.title() for i, t in enumerate(string.split())]))
    for st in stringlist:
        r = requests.get('http://localhost:3000', params={'text': st})
        o = r.json()
        if o not in output: output.append(o)
    return output

def multiple_replace(text, adict, regex=False):
    if not isinstance(adict, OrderedDict): adict = OrderedDict([(key, adict[key]) for key in sorted(adict, key=len, reverse=True)])
    if regex: rx = re.compile('(' + ')|('.join(adict.keys()) + ')')
    else: rx = re.compile('(' + ')|('.join(map(re.escape, adict.keys())) + ')')
    def one_xlat(match):
        for key, m in zip(adict.keys(), match.groups()):
            if m: return adict[key]
    return rx.sub(one_xlat, text)
	
def parenthesize(from_str, re_to_match, parens="()"):
    rx = re.compile(re_to_match)
    if rx.groups == 0: rx = re.compile(r'(' + re_to_match + r')')
    to_str = rx.sub(parens[0] + r'\1' + parens[1], from_str)
    return to_str

def remove_extra_parens(string):
    rx = re.compile(r'\(\s*\(([^\)]*)\)\s*\)')
    outstring = rx.sub(r'(\1)', string)
    if rx.search(outstring):
        outstring = remove_extra_parens(outstring)
    return outstring

def normalize_list(in_list, in_list_name, list_type, cmp_list=None, cmp_list_name=None):
    if cmp_list and not cmp_list_name:
        raise TypeError('if cmp_list is defined, cmp_list_name must be defined')
    if isinstance(in_list, list_type): out_list = [in_list]
    else: out_list = list(in_list)[:]
    if not all(map(lambda i: isinstance(i, list_type), out_list)):
        raise TypeError('all items in {} must be instances of {}'.format(in_list_name, list_type.__name__))
    if cmp_list:
        if len(out_list) == 1:
            out_list = out_list * len(cmp_list)
        elif len(out_list) > 1 and len(out_list) != len(cmp_list):
            raise TypeError('length of {} must be 0, 1, or the length of {}'.format(in_list_name, cmp_list_name))
    return out_list
