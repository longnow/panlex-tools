
import regex as re

from gary import append_synonym

# dummy change for testing git
def remove_feminine_infl(text):
    text = re.sub('(.*)/a\M', r'\1', text)
    text = re.sub('(?<=\w\s*)\(a\)', '', text)
    text = re.sub('a\s*\(o\)(?!\w)', 'o', text)
    text = re.sub('@$', 'o', text)

    return text.strip()



def normalize_adj(text,pos):
    match = re.search('(?:estar|ser) (.*)', text)
    if match:
        text = match[1]
        pos = 'adj'

    return text,pos



def remove_articles(text):
    match = re.search('^(el|la|las|un|una)\s+', text)
    if match:
        tokens = text.split()
        if tokens[1] not in ['vez', 'poco', 'poquito', 'y', 'tras', 'de', 'del', 'mejor', 'más', 'pro']:
            text = re.sub('^(el|la|las|un|una)\s+', '', text)

    return text



def extract_noun(text, pos):
    match = re.search('^(el|la|las|un|una)\M\s*(.*)', text)
    if match and len(match[2]) > 0:
        text = match[2]
        pos = 'noun'
    return text,pos


def extract_question(text, pos):
    fields = re.split('\s*‣\s*', text)
    for i in range(len(fields)):
        match = re.search('^\s*(?:¿)?\s*(.*)\s*\?\s*$', fields[i])
        if match:
            fields[i] = match[1]
            pos = append_synonym(pos,'ques')
    text = '‣'.join(fields)

    return text,pos


def normalize_accent(text):
    text = re.sub('à', 'á', text)
    text = re.sub('è', 'é', text)
    text = re.sub('ì', 'í', text)
    text = re.sub('ò', 'ó', text)
    text = re.sub('ù', 'ú', text)
    text = re.sub('À', 'Á', text)
    text = re.sub('È', 'É', text)
    text = re.sub('Ì', 'Í', text)
    text = re.sub('Ò', 'Ó', text)
    text = re.sub('Ù', 'Ú', text)

    return text


def filter_article(text, pos):
    match = re.search('^(el|la|los|las|un|una)\s+(.*)', text)
    if match:
        if match[1] == 'el' or match[1] == 'los' or match[1] == 'un':
            text = match[2]
            if text not in ['agua', 'arca', 'hambre', 'arpa', 'águila']:
                pos = append_synonym(pos, 'm')
            else:
                pos = append_synonym(pos, 'f')
        elif match[1] == 'la' or match[1] == 'las' or match[1] == 'una':
            text = match[2]
            pos = append_synonym(pos, 'f')
        else:
            text = match[2]

    return text,pos
