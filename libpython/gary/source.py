
from collections import OrderedDict

import io
import regex as re


class LanguageField(object):
    def __init__(self, text='', *args):
        self.text = text
        self.props = ['text']
        for prop in args:
            self.props.append(prop)
            self.__setattr__(prop,'')

        # for k,v in kwargs.items():
        #     self.__dict__[k] = v

    def format(self, props):
        self.props = props

    def __str__(self):
        fields = []
        fields.extend([self.__getattribute__(f) for f in self.props])
        return '\t'.join([str(f) for f in fields])

    def __repr__(self):
        return 'LanguageField<%s@%s>' % (';'.join(self.__dict__),self.text)


class Entry(object):
    def __init__(self, *langs):
        self.langfields = OrderedDict()
        for lang in langs:
            fields = lang.split(':')
            langid = fields[0]
            attrs = fields[1:]
            langdata = LanguageField('', *attrs)
            self.__setattr__(langid, langdata)
            self.langfields[lang] = langdata


    def __str__(self):
        return '\t'.join([str(field) for field in self.langfields.values()])

    def __repr__(self):
        return '<Entry:%s>' % ','.join([('%s:%s' % (langid,repr(lang))) for langid,lang in self.langfields.items()])


def ignore_parens(proc):
    pat = re.compile('\([^)]*\)')

    def wrapper(text):
        if not pat.search(text):
            return proc(text)

        out = io.StringIO()

        i = j = 0
        for match in pat.finditer(text):
            j = match.start()
            out.write( proc(text[i:j]))
            i = match.end()
            out.write( text[j:i])

        out.write( proc(text[i:]))
        text = out.getvalue()
        out.close()
        return text

    return wrapper


def process_synonyms(proc):
    # s = '‣'
    def wrapper(text):
        fields = text.split('‣')
        for i in range(len(fields)):
            fields[i] = proc(fields[i])
        return '‣'.join( fields)
    return wrapper


def process_method_synonyms(proc):
    # s = '‣'
    def wrapper(text):
        fields = text.split('‣')
        for i in range(len(fields)):
            fields[i] = proc(fields[i])
        return '‣'.join( fields)
    return wrapper



def process_text_synonym_extract(proc):
    def wrapper(text1,text2):
        fields1 = text1.split('‣')

        for i in range(len(fields1)):
            fields1[i],text2 = proc(fields1[i],text2)

        fields1 = [f for f in fields1 if len(f) > 0]
        text1 = '‣'.join( fields1)

        return text1,text2

    return wrapper



def increment_fileid(filename, ext=None):
    # filename of XYZ-n (optionally .ext)
    match = re.search('(.*)-(\d+)(?:\.(\w+))?$', filename)
    if match:
        version = int(match[2]) + 1
        if not ext:
            ext = 'txt'
        else:
            if match[3]:
                ext = match[3]
            else:
                ext = 'txt'

        return '%s-%d.%s' % (match[1],version,ext)

    else:
        raise ValueError('Unable to match filename pattern')


def append_synonym(text, elem):
    fields = text.split('\s*‣\s*')

    if len(fields) == 0:
        # nothing to append to
        return elem
    else:
        if len(fields) == 1 and len(fields[0]) == 0:
            return elem
        elif elem not in fields:
            # append to list
            return '%s‣%s' % (text,elem)
        else:
            # already in list, don't append
            return text
