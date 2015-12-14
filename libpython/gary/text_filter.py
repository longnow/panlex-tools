
import regex as re

from util.source import ignore_parens

def strip_ws(text, **kwargs):
    return text.strip()



def remove_final_punct(text, **kwargs):
    start = text
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


