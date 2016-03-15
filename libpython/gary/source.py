
from collections import OrderedDict

import io
import logging
import regex as re
import time



def log_results(text, debug=False):
    if debug:
        logging.debug(text)


def run_filters(filters, entry, is_logged=False, **kwargs):
    if is_logged:
        logging.basicConfig(filename='filter.log',level=logging.DEBUG)
        log_results('UNFILTERED:%s' % entry, debug=is_logged)

    # TODO: add preprocess filter for all language fields

    for f in filters:
        before = str(entry)
        f(entry, **kwargs)
        after = str(entry)
        if before != after:
            log_results('%s: %s' % (f.name,after), debug=is_logged)

    return entry


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
        mn_fields = text.split('⁋')

        for i in range(len(mn_fields)):
            syn_fields = mn_fields[i].split('‣')

            for j in range(len(syn_fields)):
                syn_fields[j] = proc(syn_fields[j])

            mn_fields[i] = '‣'.join( syn_fields)

        return '⁋'.join(mn_fields)

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


def append_meaning(text, elem):
    fields = text.split('\s*⁋\s*')

    if len(fields) == 0:
        # nothing to append to
        return elem
    else:
        if len(fields) == 1 and len(fields[0]) == 0:
            return elem
        elif elem not in fields:
            # append to list
            return '%s⁋%s' % (text,elem)
        else:
            # already in list, don't append
            return text

def join_synonyms(syn_ls):
    syn_ls = [syn for syn in syn_ls if syn != None and len(syn) > 0]
    return '‣'.join(syn_ls)

def pretag_df(text):
    match = re.search('^(?:⫷[^⫸]*⫸)?(.*)$', text)
    text = '⫷df⫸%s' % match[1]
    return text


def pretag_ex(text):
    match = re.search('^(?:⫷[^⫸]*⫸)?(.*)$', text)
    text = '⫷ex⫸%s' % match[1]
    return text


class SourceProcessor(object):
    def __init(self):
        self.filters = []
        self.pred_filters = []


    def setInputFiles(self, filelist):
        self.inputfiles = filelist


    def setOutputFile(self, filename):
        self.outputfile = filename


    def setFilters(self, filter_list:list):
        self.filters = filter_list


    def setPredicateFilters(self, pred_filter_list):
        self.pred_filters = pred_filter_list


    def setEntryFormatter(self, func):
        self.formatter = func


    def filtered_out(self, entry):
        fail = False
        for filt in self.pred_filters:
            if filt(entry):
                fail = True

        return fail


    def run(self, parser):
        start_time = time.time()
        with open(self.outputfile, 'w') as fout:
            for inputfile in self.inputfiles:

                count = 0
                for record in parser.getRecords(inputfile):
                    entry = self.formatter(record)

                    for entry_filter in self.filters:
                        entry_filter(entry)

                    if not self.filtered_out(entry):
                        fout.write('%s\n' % entry)

                    count += 1

        endtime = time.time()
        span = endtime - start_time

        print('processed %d records in %.3fs (%.3f rec/s)' % (count,span,count / span))


class DcsMapper(object):
    def __init__(self):
        self.mapping = {}
        with open('csppmap.txt') as fin:
            for line in fin:
                fields = line.split('\t')
                if len(fields) >= 2:
                    self.mapping[fields[0]] = self.__standardize(fields[1])


    def __getitem__(self, key):
        return self.mapping[key]


    def __setitem__(self, key, value):
        self.mapping[key] = value


    def __standardize(self, text):
        fields = text.split('‣')
        results = []
        for field in fields:
            match = re.search('\s*(\w{3}-\d{1,3}):([^:]+):(\w{3}-\d{1,3}):([^:]+)\s*$', field)
            if match:
                tag = '⫷dcs2:%s⫸%s⫷dcs:%s⫸%s' % match.groups()
                results.append(tag)

        return ''.join(results)


