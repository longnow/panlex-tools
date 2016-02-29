
import regex as re


def normalize_punct(text):
    text = re.sub('\s*\uFE4D\s*', ' \u2026 ', text)
    return text
