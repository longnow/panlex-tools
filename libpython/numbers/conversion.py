
import os
from pickle import load

from num2words import num2words


def create_mapping(lang, max_value):
    numbers = list(range(max_value + 1))
    mapping = {}

    for number in numbers:
        word = num2words(number, lang=lang)
        mapping[word] = number

    return mapping



class Converter(object):
    def __init__(self):
        self.mappings = {}
        self.size_mappings = {}
        self.map639 = {'eng':'en', 'spa':'es', 'fra':'fr', 'deu':'de', 'lav':'lv', 'lit':'lt'}


    def num2word(self, num, language):
        return num2words(num, lang=language)


    def word2num(self, word, language, ensure=10000):
        lang = self.iso639map(language)
        if lang not in  self.mappings:
            mapping = self.load_mapping(lang, ensure)
            self.mappings[lang] = mapping
            self.size_mappings[lang] = ensure

        elif self.size_mappings[lang] < ensure:
            mapping = self.load_mapping(lang, ensure)
            self.mappings[lang] = mapping
            self.size_mappings[lang] = ensure

        else:
            mapping = self.mappings[lang]

        return mapping[word]


    def iso639map(self, iso639_3_code):
        fields = iso639_3_code.split('_')

        if iso639_3_code in self.map639.values():
            code = iso639_3_code
        else:
            fields[0] = self.map639[fields[0]]
            code = '_'.join(fields)
            code = code

        return code


    def load_mapping(self, language, ensure_value):
        return create_mapping(language, ensure_value)


