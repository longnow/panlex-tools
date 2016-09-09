
from collections import OrderedDict

import io
import logging
import regex as re
import time


SYNDELIM = '‣'
MNDELIM = '⁋'

log_file = 'filter.log'

def log_results(text, debug=False):
    if debug:
        logging.debug(text)


def join_synonyms_list(syn_list):
    return SYNDELIM.join([s for s in syn_list if s])


def join_meaning_list(mn_list):
    return MNDELIM.join([s for s in mn_list if s])


def default_str(text):
    return text or ''


def run_filters(filters, entry, is_logged=False, **kwargs):
    if is_logged:
        logging.basicConfig(filename=log_file,level=logging.DEBUG)
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


    def __split_fields(self, label):
        fields = label.split('.')
        langId = fields[0]
        if len(fields) == 1:
            columnId = 'text'
        else:
            columnId = fields[1]

        return langId,columnId


    def __getitem__(self, key):
        langId,fieldId = self.__split_fields(key)
        langObj = self.__getattribute__(langId)
        return langObj.__getattribute__(fieldId)


    def __setitem__(self, key, value):
        langId,fieldId = self.__split_fields(key)
        langObj = self.__getattribute__(langId)
        langObj.__setattr__(fieldId, value)


    def __str__(self):
        return '\t'.join([str(field) for field in self.langfields.values()])


    def __repr__(self):
        return '<Entry:%s>' % ','.join([('%s:%s' % (langid,repr(lang))) for langid,lang in self.langfields.items()])


def ignore_parens(proc):
    pat = re.compile('(\([^)]*\))|(\[[^\]]*\])')

    def parens_wrapper(text, *args, **kwargs):
        if not pat.search(text):
            return proc(text, *args, **kwargs)

        out = io.StringIO()

        i = j = 0
        for match in pat.finditer(text):
            j = match.start()
            out.write( proc(text[i:j], *args, **kwargs))
            i = match.end()
            out.write( text[j:i])

        out.write( proc(text[i:], *args, **kwargs))
        text = out.getvalue()
        out.close()

        if len(args) > 0:
            ls = [text]
            ls.extend(args)
            return tuple(ls)
        else:
            return text

    parens_wrapper.__name__ = 'ignore_parens(%s)' % proc.__name__
    return parens_wrapper


def process_parens(proc):
    def process_section(match):
        return '(%s)' % proc(match[1])
    
    pat = re.compile('\(([^()]*)\)')

    def parens_wrapper(text, *args, **kwargs):
        return pat.sub(process_section, text)

    parens_wrapper.__name__ = 'process_parens(%s)' % proc.__name__
    return parens_wrapper


def ignore_parens_list(proc):
    pat = re.compile('(\([^)]*\))|(\[[^\]]*\])')

    def parens_wrapper(text):
        if not pat.search(text):
            return proc(text)

        outlist = []
        i = j = 0

        for match in pat.finditer(text):
            j = match.start()
            results = proc(text[i:j])
            i = match.end()
            results[-1] += text[j:i]
            if len(results) > 0:
                outlist.extend(results)

        final = proc(text[i:])
        if len(final) > 0:
            outlist.extend( final)

        return [item for item in outlist if len(item) > 0]

    parens_wrapper.__name__ = 'ignore_parens_list(%s)' % proc.__name__
    return parens_wrapper


def filter_unique_meanings(items_list):
    new_list = []

    for item in items_list:
        if len(item.strip()) > 0 and item.strip() not in new_list:
            new_list.append(item.strip())

    return new_list


def filter_unique_synonyms(fields:list) -> list:
    result_fields = []

    for field in fields:
        if len(field.strip()) > 0 and field not in result_fields:
            result_fields.append(field)

    return result_fields


def process_synonyms(proc):
    # s = '‣'
    def syn_wrapper(text):
        mn_fields = text.split('⁋')

        for i in range(len(mn_fields)):
            syn_fields = mn_fields[i].split('‣')

            for j in range(len(syn_fields)):
                syn_fields[j] = proc(syn_fields[j])

            mn_fields[i] = '‣'.join( filter_unique_synonyms( syn_fields))

        mn_fields = filter_unique_meanings(mn_fields)
        return '⁋'.join(mn_fields)

    return syn_wrapper


def get_plx_fields(text):
    match = re.search('(⫷(?:ex|df)(?::\w{1,4}-\d{1,3})?⫸)([^⫷]*)(⫷.*)?', text)
    if match:
        new_text = match[2] or ''
        attributes = match[3] or ''
        return (match[1],new_text,attributes)
    else:
        return ('⫷ex⫸',text,'')


def process_plx_synonyms(proc):
    # s = '‣'
    def plx_wrapper(text):
        before = text
        text = delimToPanlex(text)
        idx_list = [ex_match.start() for ex_match in re.finditer('⫷(?:ex|df)(?::\w{1,4}-\d{1,3})?⫸', text)]
        if len(idx_list) == 0:
            return process_synonyms(proc)(text)

        idx_list.append( len(text))
        if len(text[ 0:idx_list[0] ].strip()) > 0:
            idx_list.insert(0,0)
        final_exp = []

        for idx in range(len(idx_list) - 1):
            ex = text[ idx_list[idx] : idx_list[idx+1]]

            tag,ex_text,attributes = get_plx_fields(ex)
            result = proc(ex_text)
            result_match = re.search('(⫷(?:ex|df)(?::\w{1,4}-\d{1,3})?⫸)(.*)', result)
            if result_match:
                if len(result_match[3].strip()) > 0:
                    final_exp.append('%s%s' % (result,attributes))
            else:
                if len(result.strip()) > 0:
                    final_exp.append('%s%s%s' % (tag,result,attributes))

        final_exp = filter_unique_meanings(final_exp)
        text = ''.join(final_exp)
        return text

    return plx_wrapper


def process_plx_dual_synonyms(proc):
    # s = '‣'
    def plx_dual_wrapper(text,metadata):
        idx_list = [ex_match.start() for ex_match in re.finditer('⫷(?:ex|df)(?::\w{1,4}-\d{1,3})?⫸', text)]

        if len(idx_list) == 0:
            return process_text_synonym_extract(proc)(text,metadata)

        idx_list.append( len(text))
        final_exp = []

        for idx in range(len(idx_list) - 1):
            ex = text[ idx_list[idx] : idx_list[idx+1]]
            match = re.search('(⫷(?:ex|df)(?::\w{1,4}-\d{1,3})?⫸)([^⫷]*)(⫷.*)?', ex)
            if match:
                new_text,new_metadata = proc(match[2], metadata)
                metadata = append_synonym(metadata, new_metadata)
                if len(match[2].strip()) > 0:
                    final_exp.append('%s%s%s' % (match[1],new_text,default_str(match[3])) )

        final_exp = filter_unique_meanings(final_exp)
        text = ''.join(final_exp)
        return text,metadata

    return plx_dual_wrapper


def process_method_synonyms(proc):
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
            fields1[i],new_text2 = proc(fields1[i],text2)
            text2 = append_synonym(text2, new_text2)

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


def append_plx_synonym(text, elem):
    fields = []
    for match in re.finditer('(⫷(?:ex|df)(?::\w{3}-\d{3})?⫸)([^⫷]*)', text):
        curr = match[2].strip()
        if curr not in fields and len(curr) > 0:
            fields.append('%s%s' % (match[1],curr))

    new_match = re.search('^(⫷(?:ex|df)(?::\w{3}-\d{3})?⫸)?\s*([^⫷]*?)\s*$', elem)
    if new_match:
        if new_match[2] not in fields and len(new_match[2].strip()) > 0:
            if new_match[1]:
                fields.append('%s%s' % (new_match[1],new_match[2]))
            else:
                fields.append('⫷ex⫸%s' % new_match[2])

    return ''.join(fields)


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
    before = text
    if len(text.strip()) == 0:
        return ''
    match = re.search('^(?:⫷[^⫸]*⫸)?(.*)$', text)
    text = '⫷df⫸%s' % match[1]
    return text


def pretag_ex(text, langid=None):
    if len(text.strip()) == 0:
        # do not add tag if empty, causes problems in serialization
        return ''

    match = re.search('^(?:⫷(?:ex|df)(:\w{3}-\d{3})?⫸)?(.*)$', text)

    if langid and re.search('^\w{3}-\d{3}$', langid):
        text = '⫷ex:%s⫸%s' % (langid,match[2])
    elif langid == None and match[1] != None:
        text = '⫷ex%s⫸%s' % (match[1],match[2])
    else:
        text = '⫷ex⫸%s' % match[2]

    return text


# TODO: handle each case
# 1) lang given, no lang in field -> add lang to field
# 2) lang given, lang in field -> update lang in field?
# 3) no lang given -> no change
def delimToPanlex(text, lang=None):
    fields = text.split('‣')
    for i in range(len(fields)):
        plx_match = re.search('^⫷(?:ex|df)(:\w{2,}-\d{3,})?⫸', fields[i])
        if plx_match:
            if lang != None:
                if len(fields[i][plx_match.end():].strip()) > 0:
                    fields[i] = '⫷ex:%s⫸%s' % (lang,fields[i][plx_match.end():])
        else:
            if lang != None and len(fields[i].strip()) > 0:
                fields[i] = '⫷ex:%s⫸%s' % (lang,fields[i])
            elif len(fields[i].strip()) > 0:
                fields[i] = '⫷ex⫸%s' % (fields[i])

    text = ''.join(fields)

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
        return ''.join([self.mapping[k] for k in key.split('‣')])


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


def make_phonetic_rep(text):
    if len(text.strip()) > 0:
        return '⫷dpp:art-303⫸phoneticRep⫷dpp⫸%s' % text
    else:
        return ''


def make_phonemic_rep(text):
    return '⫷dpp:art-303⫸phonemicRep⫷dpp⫸%s' % text

