
import subprocess
from subprocess import PIPE


def _convert_tags(text):
    lines = text.splitlines()
    tagged_words = []
    for line in lines:
        if line.strip() == 'EOS':
            yield tagged_words
            tagged_words = []
        else:
            fields = line.split('\t')
            word = fields[0]
            tag = fields[1].split(',')[0]
            tagged_words.append((word,tag))


def _fetch_results(input_text):
    proc = subprocess.Popen(['mecab'], stdout=PIPE, stdin=PIPE)
    result = proc.communicate(input=input_text.encode('utf-8)'))
    if result:
        return result[0].decode()
    else:
        return []


def tag_text(text):
    output_text = _fetch_results(text)
    yield from _convert_tags(output_text)
