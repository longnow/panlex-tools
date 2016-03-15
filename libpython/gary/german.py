
import regex as re

def remove_feminine_infl(text):
    text = re.sub('(.*)/in(?!\w)', r'\1', text)
    text = re.sub('(.*)/n(?!\w)', r'\1', text)
    return text

def remove_article(text):
    if not re.search('^ein\s+((für alle)|(paar))', text):
        text = re.sub('^(?:die|der|das|dem|den|ein|eine|einen|einem)\s+', '', text)

    return text
