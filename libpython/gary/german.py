
import regex as re

def remove_feminine_infl(text):
    text = re.sub('(.*)/in(?!\w)', r'\1', text)
    text = re.sub('(.*)/n(?!\w)', r'\1', text)
    return text

def remove_articles(text):
    if not re.search('^ein für alle', text):
        text = re.sub('^(?:die|der|das|dem|den|ein|eine|einen|einem)\s+', '', text)

    return text
