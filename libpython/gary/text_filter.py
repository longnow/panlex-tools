
import regex as re
import sys
import unicodedata

from . import ignore_parens

def strip_ws(text, **kwargs):
    return text.strip()


def pre_process(text):
    text = re.sub('(?<=\d)\s+(?=\d)', '', text)
    text = re.sub('\s*\.{3,}\s*', ' … ', text)
    text = re.sub('\s+', ' ', text)
    text = re.sub('\uFEFF', '', text)
    text = unicodedata.normalize('NFC', text)
    text = re.sub('[‐‑⁃－]', '-', text)
    text = re.sub('[\u200B\u00AD\u200E\u200F\u202A\u202C]', '', text)
    text = re.sub('^\s*…\s*', '', text)
    text = re.sub('\s*…\s*$', '', text)
    text = re.sub('\s*…\s*\)', ' …)', text)
    text = re.sub('\(\s*…\s*', '(… ', text)
    text = re.sub('(\d+)[,.;](\d+)', r'\1\2', text)

    return text.strip()



message_is_displayed = True
def normalize_punctuation(text):
    global message_is_displayed
    if not message_is_displayed:
        print('DEPRECATED: use pre_process instead',file=sys.stderr)
        message_is_displayed = True
    text = re.sub('[.,/?!;]+\s*$', '', text)
    text = re.sub('\s*\.{3,}\s*', ' … ', text)
    text = re.sub('^\((.*)\)$', r'\1', text)

    return text.strip()



def remove_final_punct(text, **kwargs):
    text = re.sub('[.,/?!:]+\s*$', '', text)
    return text


@ignore_parens
def normalize_separator(text, delim='\s*,\s*'):
        return re.sub(delim, '‣', text)



def apply(text, filter_list,debug=False):    
    for filt in filter_list:
        if debug:
            print('apply filter: %s' % filt.__name__)
        text = filt(text)
    
    return text


def flatten_parentheses(text:str, remove=False) -> str:
    if remove:
        replace_start, replace_end = ''
    else:
        replace_start, replace_end = ('[',']')

    text = list(text)
    count = 0
    for i in range(len(text)):
        if text[i] == '(':
            count += 1
            if count > 1:
                text[i] = replace_start
        elif text[i] == ')':
            if count > 1:
                text[i] = replace_end
            count -= 1

    return ''.join(text)

_cyrillic_chars = 'авемнорстухѐёѕіїјһӀ'
_latin_chars = 'aBeMHopcTyxèësiïjhI'

def cyrillic2latin(text):
    if re.search('^[^%s]$' % _cyrillic_chars, text):
        return text

    chars = list(text)
    for i in range(len(chars)):
        idx = _cyrillic_chars.find(chars[i])
        if idx > -1:
            chars[i] = _latin_chars[idx]

    return ''.join(chars)