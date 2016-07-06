#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import regex as re
from collections import defaultdict
from collections.abc import Iterable
from progress.bar import Bar
from ben.string_manipulation import *
from os import environ

class Ex:

    def __init__(self, text, lv=None, lc=None, vc=None):
        if isinstance(text, Ex):
            self._text = text.text
            self._lc = text.lc
            self._vc = text.vc
        else:
            self._text = text
            if lv:
                if re.match(r'^[a-z]{3}-[0-9]{3,}$', lv):
                    self._lc = lv[:3]
                    self._vc = int(lv[4:])
                else: raise ValueError("lv must be in the format xxx-000")
            elif lc and (vc != None):
                lc = lc.lower()
                if re.match(r'^[a-z]{3}$', lc):
                    self._lc = lc
                else: raise ValueError("lc must be a 3-letter ISO 639 code")
                try:
                    vc = int(vc)
                    if vc < 0: raise ValueError("vc must be a positive integer")
                    self._vc = vc
                except ValueError: raise ValueError("vc must be a positive integer")
            else:
                self._lc = lc
                self._vc = vc

    def __repr__(self):
        return "{cls}({string}, lv={lv})".format(cls=self.__class__.__name__, string=repr(str(self)), lv=repr(self.lv))

    def __getattr__(self, attr):
        f = str.__getattribute__(str(self), attr)
        def outfunc(*args, **kwargs):
            out = f(*args, **kwargs)
            if isinstance(out, str):
                return self.__class__(out, self.lv)
            elif isinstance(out, Iterable):
                t = type(out)
                return t([self.__class__(text, self.lv) for text in out])
            else:
                return out
        return outfunc

    def __bool__(self):
        if str(self): return True
        else: return False

    def __len__(self):
        return len(str(self))

    def __iter__(self):
        for char in str(self):
            yield self.__class__(char, self.lv)

    def __getitem__(self, key):
        return self.__class__(str.__getitem__(str(self), key), self.lv)

    def __str__(self):
        return self.text

    def __hash__(self):
        return hash((str(self), self.lc, self.vc))

    def __eq__(self, item):
        try:
            if str(self) == str(item) and self.lv == item.lv: return True
            else: return False
        except AttributeError:
            if str(self) == str(item): return True
            else: return False

    def __contains__(self, item):
        if str(item) in str(self): return True
        else: return False

    @property
    def text(self):
        return self._text

    @property
    def lc(self):
        return self._lc

    @property
    def vc(self):
        return self._vc

    @property
    def lv(self):
        try:
            return '-'.join((self.lc, str(self.vc).zfill(3)))
        except TypeError:
            return None

    def example():
        return Ex('cat', 'eng-000')

    def pretty(self, indent=0):
        ind = '  ' * indent
        out = ""
        out += ind + self.lv + '\n'
        out += ind + self.text + '\n'
        return out

    def copy(self, string=None):
        if string == None: string = self.text
        return self.__class__(string, self.lv)

    def copy_list(self, iter_of_strings):
        t = type(iter_of_strings)
        return t([self.copy(string) for string in iter_of_strings])

    def sub(self, pattern, repl, count=0, flags=0):
        return self.copy(re.sub(pattern, repl, str(self), count, flags))

    def split(self, pattern, maxsplit=0, flags=0):
        split_list = re.split(pattern, str(self), maxsplit, flags)
        return [self.copy(split_string) for split_string in split_list]

class Df(Ex):
    def pretty(self, indent=0):
        ind = '  ' * indent
        out = ""
        out += ind + self.__class__.__name__.lower() + '\n'
        out += ind + '  ' + self.lv + '\n'
        out += ind + '  ' + self.text + '\n'
        return out

    def example():
        return Df('a feline animal', 'eng-000')

class Pp(str):
    def __new__(cls, value, attribute):
        return super().__new__(cls, value)

    def __init__(self, value, attribute):
        self.attribute = attribute

    def __repr__(self):
        return "Pp('{string}', attribute={attribute})".format(string=self, attribute=repr(self.attribute))

    def __hash__(self):
        return hash((str(self), self.attribute))

    def __eq__(self, item):
        try: return str(self) == str(item) and self.attribute == item.attribute
        except AttributeError: return False

    @property
    def attribute(self):
        return self._attribute
    @attribute.setter
    def attribute(self, new_value):
        self._attribute = Ex(new_value)

    def example():
        return Pp('4', Ex('number of legs', 'eng-000'))

    def pretty(self, indent=0):
        ind = '  ' * indent
        out = ""
        out += self.attribute.pretty(indent)
        out += ind + self + '\n'
        return out

class Cs:
    def __init__(self, class_ex, superclass_ex=None):
        self.class_ex = class_ex
        self.superclass_ex = superclass_ex

    def __repr__(self):
        return "Cs(class_ex={class_ex}, superclass_ex={superclass_ex})".format(class_ex=repr(self.class_ex), superclass_ex=repr(self.superclass_ex))

    def __getattr__(self, attr):
        f = getattr(self.class_ex, attr)
        if callable(f):
            def outfunc(*args, **kwargs):
                out = f(*args, **kwargs)
                if isinstance(out, Ex):
                    return self.__class__(out, self.superclass_ex)
                elif isinstance(out, Iterable):
                    t = type(out)
                    return t([self.__class__(ex, self.superclass_ex) for ex in out])
                else:
                    return out
            return outfunc
        else: return f

    def __hash__(self):
        return hash((self.class_ex, self.superclass_ex))

    def __eq__(self, item):
        try: return self.class_ex == item.class_ex and self.superclass_ex == item.superclass_ex
        except AttributeError: return False

    @property
    def class_ex(self):
        return self._class_ex
    @class_ex.setter
    def class_ex(self, new_value):
        self._class_ex = Ex(new_value)

    @property
    def superclass_ex(self):
        return self._superclass_ex
    @superclass_ex.setter
    def superclass_ex(self, new_value):
        if new_value: self._superclass_ex = Ex(new_value)
        else: self._superclass_ex = None

    def example(ub=2):
        if ub == 1: return Cs(Ex('animal', 'eng-000'))
        else: return Cs(Ex('Noun', 'art-303'), Ex('PartOfSpeechProperty', 'art-303'))

    def pretty(self, indent=0):
        out = ""
        if self.superclass_ex: out += self.superclass_ex.pretty(indent)
        out += self.class_ex.pretty(indent)
        return out

class Dn:
    def __init__(self, ex, pp_list=[], cs_list=[]):
        self.ex = ex
        self.pp_list = pp_list[:]
        self.cs_list = cs_list[:]

    def __repr__(self):
        return "Dn(ex={ex}, pp_list={pp_list}, cs_list={cs_list})".format(ex=repr(self.ex), pp_list=self.pp_list, cs_list=self.cs_list)

    def __str__(self):
        return str(self.ex)

    def __contains__(self, string):
        return string in self.ex

    def __eq__(self, item):
        try: return self.ex == item.ex and set(self.pp_list) == set(item.pp_list) and set(self.cs_list) == set(item.cs_list)
        except AttributeError: return False

    def __getattr__(self, attr):
        f = getattr(self.ex, attr)
        if callable(f):
            def outfunc(*args, **kwargs):
                out = f(*args, **kwargs)
                if isinstance(out, Ex):
                    return self.__class__(out, self.pp_list[:], self.cs_list[:])
                elif isinstance(out, Iterable):
                    t = type(out)
                    return t([self.__class__(ex, self.pp_list[:], self.cs_list[:]) for ex in out])
                else:
                    return out
            return outfunc
        else: return f

    def __bool__(self):
        if self.ex: return True
        else: return False

    def __hash__(self):
        return hash((self.ex,) + tuple(set(self.pp_list)) + tuple(set(self.cs_list)))

    @property
    def ex(self):
        return self._ex
    @ex.setter
    def ex(self, new_value):
        self._ex = Ex(new_value)

    @property
    def pp_list(self):
        return self._pp_list
    @pp_list.setter
    def pp_list(self, new_value):
        self._pp_list = new_value

    @property
    def cs_list(self):
        return self._cs_list
    @cs_list.setter
    def cs_list(self, new_value):
        self._cs_list = new_value

    def clean(self):
        self.cs_list = list(set(self.cs_list))
        self.pp_list = list(set(self.pp_list))

    def example():
        return Dn(Ex.example(), pp_list=[Pp.example()], cs_list=[Cs.example(1), Cs.example(2)])

    def pretty(self, indent=0):
        ind = '  ' * indent
        out = ""
        out += ind + self.__class__.__name__.lower() + '\n'
        out += self.ex.pretty(indent + 1)
        for pp in self.pp_list:
            out += ind + '  d' + pp.__class__.__name__.lower() + '\n'
            out += pp.pretty(indent + 2)
        for cs in self.cs_list:
            if cs.superclass_ex: out += ind + '  d' + cs.__class__.__name__.lower() + '2\n'
            else: out += ind + '  d' + cs.__class__.__name__.lower() + '1\n'
            out += cs.pretty(indent + 2)
        return out

    def extract_cs(self, cs_map, remove=True, replace_with=''):
        ex = str(self.ex)
        cs_list = []
        for key in sorted(cs_map, key=len, reverse=True):
            rx = re.compile(key)
            match = rx.search(ex)
            if match:
                if remove: ex = rx.sub(replace_with.format(*match.groups()), ex)
                if isinstance(cs_map[key], Cs):
                    cs_list.append(cs_map[key].format(*match.groups()))
                else:
                    cs_list.extend([cs.format(*match.groups()) for cs in cs_map[key]])
        self.ex = self.ex.copy(ex)
        return cs_list


class Mn:
    def __init__(self, dn_list=[], df_list=[], pp_list=[], cs_list=[]):
        self.dn_list = dn_list[:]
        self.df_list = df_list[:]
        self.pp_list = pp_list[:]
        self.cs_list = cs_list[:]

    def __repr__(self):
        return "Mn(dn_list={dn_list}, df_list={df_list}, pp_list={pp_list}, cs_list={cs_list})".format(
            dn_list=repr(self.dn_list), df_list=repr(self.df_list), pp_list=self.pp_list, cs_list=self.cs_list)

    def __bool__(self):
        if any([any(self.dn_list), any(self.df_list), any(self.pp_list), any(self.cs_list)]): return True
        else: return False

    def __contains__(self, obj):
        if obj in self.dn_list:
            return True
        else:
            for dn in self.dn_list:
                if obj == dn.ex: return True
        return False

    def __eq__(self, item):
        return \
            self.dn_list == item.dn_list and \
            self.df_list == item.df_list and \
            self.pp_list == item.pp_list and \
            self.cs_list == item.cs_list

    def __call__(self, lv_list):
        if isinstance(lv_list, str): lv_list = [lv_list]
        return [dn for dn in self.dn_list if dn.lv in lv_list]

    @property
    def dn_list(self):
        return self._dn_list
    @dn_list.setter
    def dn_list(self, new_value):
        self._dn_list = new_value

    @property
    def df_list(self):
        return self._df_list
    @df_list.setter
    def df_list(self, new_value):
        self._df_list = new_value

    @property
    def pp_list(self):
        return self._pp_list
    @pp_list.setter
    def pp_list(self, new_value):
        self._pp_list = new_value

    @property
    def cs_list(self):
        return self._cs_list
    @cs_list.setter
    def cs_list(self, new_value):
        self._cs_list = new_value

    def lv_list(self):
        return [dn.lv for dn in self.dn_list]

    def ex_list(self, lv=None):
        if lv:
            return [dn.ex for dn in self.dn_list if dn.lv == lv ]
        else:
            return [dn.ex for dn in self.dn_list]

    def clean(self):
        for dn in self.dn_list:
            dn.clean()
        self.dn_list = list(set(self.dn_list))
        self.df_list = list(set(self.df_list))
        self.pp_list = list(set(self.pp_list))
        self.cs_list = list(set(self.cs_list))

    def pretty(self, indent=0):
        ind = '  ' * indent
        out = ""
        out += ind + self.__class__.__name__.lower() + '\n'
        for dn in self.dn_list:
            out += dn.pretty(indent + 1)
        for df in self.df_list:
            out += df.pretty(indent + 1)
        for pp in self.pp_list:
            out += ind + '  m' + pp.__class__.__name__.lower() + '\n'
            out += pp.pretty(indent + 2)
        for cs in self.cs_list:
            if cs.superclass_ex: out += ind + '  m' + cs.__class__.__name__.lower() + '2\n'
            else: out += ind + '  m' + cs.__class__.__name__.lower() + '1\n'
            out += cs.pretty(indent + 2)
        return out

    def wipe(self):
        self.dn_list = []
        self.df_list = []
        self.pp_list = []
        self.cs_list = []

    def copy(self, dn_list=[], df_list=[], pp_list=[], cs_list=[]):
        if not dn_list: dn_list = self.dn_list[:]
        if not df_list: df_list = self.df_list[:]
        if not pp_list: pp_list = self.pp_list[:]
        if not cs_list: cs_list = self.cs_list[:]
        return Mn(dn_list, df_list, pp_list, cs_list)        

    def split(self, split_re, dn_to_split, dn_copy_lists=[], max_splits=0):
        mn_list = []
        rx = re.compile(split_re)
        string_list = rx.split(str(dn_to_split.ex), max_splits)
        dn_copy_lists += [[]] * (len(string_list) - len(dn_copy_lists))
        for string, dn_copy_list in zip(string_list, dn_copy_lists):
            mn = self.copy(dn_list=[dn_to_split.copy(string)])
            for dn in self.dn_list:
                if dn == dn_to_split:
                    continue
                elif dn_copy_list:
                    if dn in dn_copy_list: mn.dn_list.append(dn.copy())
                else:
                    mn.dn_list.append(dn.copy())
            mn_list.append(mn)
        return mn_list

    def sub(self, pattern, repl, count=0, flags=0, dn_list=[]):
        if not dn_list: dn_list = self.dn_list
        for i, dn in enumerate(self.dn_list):
            if dn in dn_list:
                if re.search(pattern, str(dn)):
                    self.dn_list[i] = dn.sub(pattern, repl, count, flags)


def tabularize(data, output_file, match_re_lv_list=None, lv_list=None, tagged=False, tag_types=set(), inc_df=False):
    if not lv_list:
        lv_list = sorted(set(flatten([mn.lv_list() for mn in data])))
    try:
        if isinstance(match_re_lv_list[0], str):
            match_re_lv_list = [match_re_lv_list]
    except TypeError: pass
    for mn in Bar().iter(data):
        line = tab_line(mn, lv_list, tagged, tag_types)
        if match_re_lv_list:
            match = False
            for rx, match_lv in match_re_lv_list:
                for ex in [dn.ex for dn in mn.dn_list if dn.lv == match_lv]:
                    if re.search(rx, clean_str(str(ex))): match = True
                if inc_df:
                    for df in [df for df in mn.df_list if df.lv == match_lv]:
                        if re.search(rx, clean_str(str(df))): match = True
            if match and clean_str(line): print(line, file=output_file)
        elif clean_str(line):
            print(line, file=output_file)
        else: pass

def tab_log(data, match_re_lv_list=None, lv_list=None, tagged=False, tag_types=set(), inc_df=False):
    with open("tab_log.txt", 'w', encoding='utf-8') as output_log:
        tabularize(data, output_log, match_re_lv_list, lv_list, tagged, tag_types, inc_df)

def tag(tag, lv=None):
    if lv: return '⫷{tag}:{lv}⫸'.format(tag=tag, lv=lv)
    else: return '⫷{tag}⫸'.format(tag=tag)

def tag_list(list_to_tag, tag_type):
    output = []
    if tag_type == 'ex':
        for ex in list_to_tag:
            if ex: output.append(tag('ex', ex.lv) + clean_str(str(ex)))
    elif tag_type == 'df':
        for df in list_to_tag:
            if df: output.append(tag('df', df.lv) + clean_str(str(df)))
    elif tag_type == 'dn':
        for dn in list_to_tag:
            if dn:
                out_str = ''.join([tag('ex', dn.ex.lv), clean_str(str(dn.ex)), ''.join(tag_list(dn.cs_list, 'dcs')), ''.join(tag_list(dn.pp_list, 'dpp'))])
                output.append(clean_str(out_str))
    else:
        if 'cs' in tag_type:
            for cs in list_to_tag:
                if cs.superclass_ex:
                    output.append(''.join([
                        tag(tag_type + '2', cs.superclass_ex.lv), clean_str(str(cs.superclass_ex)),
                        tag(tag_type, cs.class_ex.lv), clean_str(str(cs.class_ex))]))
                else:
                    output.append(''.join([
                        tag(tag_type + '1', cs.class_ex.lv), clean_str(str(cs.class_ex))]))
        elif 'pp' in tag_type:
            for pp in list_to_tag:
                output.append(''.join([
                    tag(tag_type, pp.attribute.lv), clean_str(str(pp.attribute)),
                    tag(tag_type), clean_str(str(pp))]))
    return output

def tab_line(mn, lv_list, tagged=False, tag_types=set()):
    mn_line = []
    if tagged:
        for lv in lv_list:
            mn_line.append(clean_str(''.join(tag_list(mn(lv), 'dn'))))
            mn_line.append(clean_str(''.join(tag_list([df for df in mn.df_list if df.lv == lv], 'df'))))
        mn_line.append(clean_str(''.join(tag_list(mn.cs_list, 'mcs'))))
        mn_line.append(clean_str(''.join(tag_list(mn.pp_list, 'mpp'))))
    else:
        tag_types = set(tag_types)
        if {'ex', 'dcs', 'dpp'} <= tag_types: tag_types.add('dn')
        if 'cs' in tag_types: tag_types.update({'dcs', 'mcs'})
        if 'pp' in tag_types: tag_types.update({'dpp', 'mpp'})
        for lv in lv_list:
            if 'dn' in tag_types:
                mn_line.append(clean_str(''.join(tag_list(mn(lv), 'dn'))))
            else:
                if 'ex' in tag_types:
                    mn_line.append(clean_str(''.join(tag_list(mn.ex_list(lv), 'ex'))))
                else:
                    mn_line.append(clean_str('‣'.join([str(dn.ex) for dn in mn(lv)])))
                dcs_list = flatten([dn.cs_list for dn in mn(lv)])
                if 'dcs' in tag_types:
                    mn_line.append(clean_str(''.join(tag_list(dcs_list, 'dcs'))))
                else:
                    mn_line.append(clean_str('‣'.join([str(cs.class_ex) for cs in dcs_list])))
                dpp_list = flatten([dn.pp_list for dn in mn(lv)])
                if 'dpp' in tag_types:
                    mn_line.append(clean_str(''.join(tag_list(dpp_list, 'dpp'))))
                else:
                    mn_line.append(clean_str('‣'.join([str(pp) for pp in dpp_list])))
            if 'df' in tag_types:
                mn_line.append(clean_str(''.join(tag_list([df for df in mn.df_list if df.lv == lv], 'df'))))
        if 'mcs' in tag_types:
            mn_line.append(clean_str(''.join(tag_list(mn.cs_list, 'mcs'))))
        else:
            mn_line.append(clean_str('‣'.join([clean_str(str(cs.class_ex)) for cs in mn.cs_list])))
        if 'mpp' in tag_types:
            mn_line.append(clean_str(''.join(tag_list(mn.pp_list, 'mpp'))))
        else:
            mn_line.append(clean_str('‣'.join([clean_str(str(pp)) for pp in mn.pp_list])))

    line = '\t'.join(mn_line)
    return line

def flatten(x):
    result = []
    for el in x:
        if hasattr(el, "__iter__") and not isinstance(el, (str, Ex, Dn)):
            result.extend(flatten(el))
        else:
            result.append(el)
    return result

def parenthesizer(text, plist, parens="()"):
    output = text
    for p in list(sorted(plist, key=len, reverse=True)):
        output = output.replace(p, parens[0] + p + parens[1])
    return output

def parenthesizer_re(text, plist, parens="()"):
    output = text
    for p in list(sorted(plist, key=len, reverse=True)):
        output = re.sub(p, parens[0] + '\g<0>' + parens[1], text)
    return output

independants = [
    'Vowel_Independent',
    'Vowel',
    'Consonant_Placeholder',
    'Consonant',
    'Number',
    'Brahmi_Joining_Number',
    'Other',
]

non_ind_re = '[^' + ''.join(['\p{{Indic_Syllabic_Category={}}}'.format(i) for i in independants]) + ']'

def indic_ordering_check(text):
    if re.search(r'\b' + non_ind_re, text): return False
    return True

def exdftag(ex, rx=r'(?:\([^()]+\)|（[^（）]+）)', subrx=r'[][/,;?!~]', maxchar=0, maxword=0):
    lv = ex.lv
    if \
        re.search(subrx, str(ex)) or \
        (maxchar and len(str(ex)) > maxchar) or \
        (maxword and len(str(ex).split()) > maxword):
            return Ex('', lv), Df(str(ex), lv)

    elif re.search(rx, str(ex)):
        return ex.copy(re.sub(rx, '', str(ex))), Df(str(ex), lv)

    else:
        return ex, Df('', lv)

def mnsplit(data, split_re, lv_list=None, dn_filter=None, max_splits=0):
    if lv_list:
        dn_filter = lambda dn: dn.lv in lv_list
    elif not dn_filter:
        raise TypeError('must pass either lv_list or filter_function')
    for i, mn in enumerate(data):
        for dn in mn.dn_list:
            if dn_filter(dn):
                new_mns = mn.split(split_re, dn, max_splits=max_splits)
                data[i] = new_mns[0]
                try:
                    for new_mn in new_mns[1:]:
                        data.insert(i + 1, new_mn)
                except IndexError: pass


def charset(data, lv_list):
    """Returns a set of all of the characters found in all of the expressions in
    the given language varieties in all of the denotations in all of the
    meanings in the data set.
    
    Args:
        data: data set. a list of Mns
        
        lv_list: a list of lvs (as str in the format xxx-###). can also consist
        of a single lv, which is automatically converted to a list of length 1

    Returns:
        Returns a set of single characters. 
        
    Examples:
        >>> charset(data, ['eng-000', 'hye-000'])
        {'a', 'b', ..., 'z', '-', ..., 'ա', 'բ', ..., 'օ', 'ֆ', ...}
        >>> charset(data, 'eng-000')
        {'a', 'b', ..., 'z', '-', ...}
    """

    if isinstance(lv_list, str):
        lv_list = [lv_list]
    outset = set()
    for mn in data:
        for lv in lv_list:
            for dn in mn(lv):
                for c in str(dn.ex):
                    outset.add(c)
    return outset

def build_csppmap(mapfile=None):
    if not mapfile:
        # try:
        mapfile = open('csppmap.txt')
        # except FileNotFoundError:
            # mapfile = open(environ['PANLEX_TOOLDIR'] + '/serialize/data/csppmap.txt')
    try:
        mapfile = open(mapfile)
    except TypeError:
        pass
    output = defaultdict(list)
    for line in mapfile:
        splitline = line.split('\t')
        if len(splitline) < 2: continue
        key = splitline[0]
        cs_str_list = splitline[1].split('‣')
        for cs_str in cs_str_list:
            split_cs = cs_str.split(':')
            cs = None
            if len(split_cs) == 2:
                cs = Cs(class_ex=Ex(split_cs[1], split_cs[0]))
            if len(split_cs) == 4:
                cs = Cs(class_ex=Ex(split_cs[3], split_cs[2]), superclass_ex=Ex(split_cs[1], split_cs[0]))
            if cs: output[key].append(cs)
    return dict(output)