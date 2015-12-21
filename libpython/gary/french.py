
import regex as re


def remove_article(text):
    return re.sub('^l[ea] ', '', text)
