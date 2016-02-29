
import regex as re


def remove_article(text):
    return re.sub('^l[ea] ', '', text)

def remove_feminine_infl(text):
    text = re.sub('(?<=\w+)\(e\)(?!\w)', '', text)
    text = re.sub('(?<=\w+)\(ne\)(?!\w)', '', text)

    return text
