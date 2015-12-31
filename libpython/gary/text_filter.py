
import regex as re


from . import ignore_parens

def strip_ws(text, **kwargs):
    return text.strip()


def normalize_punctuation(text):
    text = re.sub('[.,/?!]+\s*$', '', text)
    text = re.sub('\s*\.{3,}\s*', ' … ', text)
    text = re.sub('^\((.*)\)$', r'\1', text)

    return text

def remove_final_punct(text, **kwargs):
    text = re.sub('[.,/?!]+\s*$', '', text)
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


