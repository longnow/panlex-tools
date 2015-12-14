
import regex as re

from util import *

@process_synonyms
def normalize_verb(text, **kwargs):
    return re.sub('^to\s+(.*)', r'\1', text)

def remove_article(text, **kwargs):
    return re.sub('^(?:a|an|the)', '', text)