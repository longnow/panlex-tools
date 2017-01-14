#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import regex as re
from collections import defaultdict
from collections.abc import Iterable
from tqdm import tqdm
from ben.string_manipulation import *
from os import environ
from functools import partialmethod
from types import FunctionType
import ben.normalize as normalize
from alex.pltk import preprocess, prepsyns

class Lv(str):
    import panlex
    _cache = defaultdict(dict)
    _include = {'cp', 'cu', 'dncount', 'excount', 'sc'}

    def __repr__(self):
        return "{cls}({string})".format(cls=self.__class__.__name__, string=repr(str(self)))

    def __getattr__(self, attr):
        if attr in ['_ipython_canary_method_should_not_exist_', '_ipython_display_']:
            return getattr(str(self), attr)
        try:
            return self._cache[self][attr]
        except KeyError:
            include = []
            if attr in self._include:
                include.append(attr)
            self._cache[self].update(self.panlex.query('/lv/{}'.format(self), {'include': include})['lv'])
            try:
                return self._cache[self][attr]
            except KeyError:
                raise AttributeError('"{attr}" is not a valid {cls} object'.format(attr=attr, cls=self.__class__.__name__))

    @classmethod
    def precache(cls, lv_list, include=[]):
        if isinstance(include, str):
            include = [include]
        include = list(set(include) & cls._include)
        result = cls.panlex.query_all('/lv', {'uid': lv_list, 'include': include})['result']
        for r in result:
            cls._cache[r['uid']].update(r)

    @classmethod
    def from_lc(cls, lc, include=[]):
        if isinstance(include, str):
            include = [include]
        include = list(set(include) & cls._include)
        output = []
        result = cls.panlex.query_all('/lv', {'lc': lc, 'include': include})['result']
        for r in result:
            cls._cache[r['uid']].update(r)
            output.append(Lv(r['uid']))
        return output

    # def ex_list(self):
    #     try:
    #         return self._cache[self]['ex_list']
    #     except KeyError:
    #         result = self.panlex.query_all('/ex', {'lv': self.lv})['result']
    #         self._cache[self]['ex_list'] = [ex['tt'] for ex in result]
    #         return self._cache[self]['ex_list']


class Ex:

    def __init__(self, text, lv=None, lc=None, vc=None):
        if isinstance(text, Ex):
            self._text = text.text
            self._lc = text.lc
            self._vc = text.vc
        elif not isinstance(text, str):
            raise TypeError("text must be string")
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
                raise TypeError("{cls} requires lv".format(cls=self.__class__.__name__))

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

    def __special_obj__(self, method, *args, **kwargs):
        f = str.__getattribute__(str(self), method)
        return self.__class__(f(*args, **kwargs), self.lv)

    def __special_cmp__(self, method, other):
        f = str.__getattribute__(str(self), method)
        if isinstance(other, str):
            return f(other)
        if self.lv == other.lv:
            return f(str(other))
        else:
            g = str.__getattribute__(self.lv, method)
            return g(other.lv)

    def __repr__(self):
        return "{cls}({string}, lv={lv})".format(cls=self.__class__.__name__, string=repr(str(self)), lv=repr(self.lv))

    def __str__(self):
        return self.text

    def __hash__(self):
        return hash((str(self), self.lc, self.vc))

    def __iter__(self):
        for char in str(self):
            yield self.__class__(char, self.lv)

    def __len__(self):
        return len(str(self))

    def __add__(self, other):
        try:
            if self.lv != other.lv:
                raise TypeError('{} can only be added to {} with same lv'.format(self.__class__.__name__, other.__class__.__name__))
        except AttributeError: pass
        return self.__class__(str(self) + str(other), self.lv)

    def __radd__(self, other):
        return Ex(other, self.lv).__add__(self)

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
        if string is None: string = self.text
        return self.__class__(string, self.lv)

    def map(self, func):
        return self.copy(func(str(self)))

    def copy_list(self, iter_of_strings):
        t = type(iter_of_strings)
        return t([self.copy(string) for string in iter_of_strings])

    def sub(self, pattern, repl, count=0, flags=0):
        return self.copy(re.sub(pattern, repl, str(self), count, flags))

    def split(self, pattern, maxsplit=0, flags=0, out_lvs=[''], dupe=False):
        split_list = re.split(pattern, str(self), maxsplit, flags)
        out_lvs = [out_lv if out_lv else self.lv for out_lv in out_lvs]
        out_lvs += [out_lvs[-1]] * (len(split_list) - len(out_lvs))
        if dupe:
            split_list += [split_list[-1]] * (len(out_lvs) - len(split_list))
        # return [self.copy(split_string) for split_string in split_list]
        return [Ex(split_string, lv) for split_string, lv in zip(split_list, out_lvs)]

    def score(self, as_lv=None, ui=[]):
        if not as_lv: as_lv = self.lv
        return normalize.get_scores([str(self)], as_lv, ui)[str(self)]

    def degraded_scores(self, as_lv=None, deg_func=None, include_std_deg=True, ui=[]):
        import panlex
        if not as_lv: as_lv = self.lv
        if deg_func:
            return normalize.get_custom_deg_scores([str(self)], as_lv, deg_func, include_std_deg, ui)[str(self)]
        else:
            return normalize.get_degraded_scores([str(self)], as_lv, ui)[str(self)]

for i in ['__getitem__', '__mul__', '__rmul__', '__mod__', '__rmod__']:
    setattr(Ex, i, partialmethod(Ex.__special_obj__, i))

for i in ['__eq__', '__lt__', '__gt__', '__le__', '__ge__', '__ne__', '__contains__']:
    setattr(Ex, i, partialmethod(Ex.__special_cmp__, i))


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

    def __eq__(self, other):
        try: return str(self) == str(other) and self.attribute == other.attribute
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

    def __eq__(self, other):
        try: return self.class_ex == other.class_ex and self.superclass_ex == other.superclass_ex
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
        self.pp_list = pp_list
        self.cs_list = cs_list

    def __repr__(self):
        return "Dn(ex={ex}, pp_list={pp_list}, cs_list={cs_list})".format(ex=repr(self.ex), pp_list=self.pp_list, cs_list=self.cs_list)

    def __str__(self):
        return str(self.ex)

    def __contains__(self, string):
        return string in self.ex

    def __eq__(self, other):
        try: return self.ex == other.ex and set(self.pp_list) == set(other.pp_list) and set(self.cs_list) == set(other.cs_list)
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
        return bool(self.ex)

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
        if not all([isinstance(pp, Pp) for pp in new_value]):
            raise TypeError("pp_list must be a list containing only Pp objects")
        self._pp_list = new_value[:]

    @property
    def cs_list(self):
        return self._cs_list
    @cs_list.setter
    def cs_list(self, new_value):
        if not all([isinstance(cs, Cs) for cs in new_value]):
            raise TypeError("cs_list must be a list containing only Cs objects")
        self._cs_list = new_value[:]

    def clean(self):
        self.cs_list = list(set([cs for cs in self.cs_list if cs]))
        self.pp_list = list(set([pp for pp in self.pp_list if pp]))

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

    def merge(self, dn):
        return Dn(dn.ex, pp_list=self.pp_list + dn.pp_list, cs_list=self.cs_list + dn.cs_list)

class Mn:
    def __init__(self, dn_list=[], df_list=[], pp_list=[], cs_list=[]):
        self.dn_list = dn_list
        self.df_list = df_list
        self.pp_list = pp_list
        self.cs_list = cs_list

    def __repr__(self):
        return "Mn(dn_list={dn_list}, df_list={df_list}, pp_list={pp_list}, cs_list={cs_list})".format(
            dn_list=repr(self.dn_list), df_list=repr(self.df_list), pp_list=self.pp_list, cs_list=self.cs_list)

    def __bool__(self):
        return any([any(self.dn_list), any(self.df_list), any(self.pp_list), any(self.cs_list)])

    def __contains__(self, obj):
        if obj in self.dn_list:
            return True
        else:
            for dn in self.dn_list:
                if obj == dn.ex: return True
        return False

    def __eq__(self, other):
        return \
            self.dn_list == other.dn_list and \
            self.df_list == other.df_list and \
            self.pp_list == other.pp_list and \
            self.cs_list == other.cs_list

    def __call__(self, lv_list):
        lv_list = normalize_list(lv_list, 'lv_list', str)
        output = [dn for dn in self.dn_list if dn.lv in lv_list]
        if not output: output = [dn for dn in self.dn_list if dn.lc in lv_list]
        return output

    @property
    def dn_list(self):
        return self._dn_list
    @dn_list.setter
    def dn_list(self, new_value):
        if not all([isinstance(dn, Dn) for dn in new_value]):
            raise TypeError("dn_list must be a list containing only Dn objects")
        self._dn_list = new_value[:]

    @property
    def df_list(self):
        return self._df_list
    @df_list.setter
    def df_list(self, new_value):
        if not all([isinstance(df, Df) for df in new_value]):
            raise TypeError("df_list must be a list containing only Df objects")
        self._df_list = new_value[:]

    @property
    def pp_list(self):
        return self._pp_list
    @pp_list.setter
    def pp_list(self, new_value):
        if not all([isinstance(pp, Pp) for pp in new_value]):
            raise TypeError("pp_list must be a list containing only Pp objects")
        self._pp_list = new_value[:]

    @property
    def cs_list(self):
        return self._cs_list
    @cs_list.setter
    def cs_list(self, new_value):
        if not all([isinstance(cs, Cs) for cs in new_value]):
            raise TypeError("cs_list must be a list containing only Cs objects")
        self._cs_list = new_value[:]

    def lv_set(self):
        return {dn.lv for dn in self.dn_list}

    def lv_list(self):
        return sorted(self.lv_set())

    def ex_list(self, lv=None):
        if lv:
            return [dn.ex for dn in self.dn_list if dn.lv == lv]
        else:
            return [dn.ex for dn in self.dn_list]

    def clean(self):
        for dn in self.dn_list:
            dn.clean()
        self.dn_list = list(set([dn for dn in self.dn_list if dn]))
        self.df_list = list(set([df for df in self.df_list if df]))
        self.pp_list = list(set([pp for pp in self.pp_list if pp]))
        self.cs_list = list(set([cs for cs in self.cs_list if cs]))

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

    def split_even(self, split_re, dns_to_split=[], max_splits=0):
        mn_list = []
        if not dns_to_split:
            dns_to_split = self.dn_list[:]
        if not set(dns_to_split) <= set(self.dn_list):
            raise ValueError("all Dns in dns_to_split must be in self.dn_list")
        remaining_dns = list(filter(lambda dn: dn not in dns_to_split, self.dn_list))
        split_dns = list(map(lambda dn: dn.split(split_re, max_splits), dns_to_split))
        if len(set(map(len, split_dns))) > 1:
            raise ValueError('uneven number of splits. consider setting max_splits')
        for dn_list in zip(*split_dns):
            mn = Mn()
            mn.dn_list.extend(list(dn_list) + remaining_dns)
            mn_list.append(mn)
        return mn_list

    def sub(self, pattern, repl, count=0, flags=0, dn_list=[]):
        if not dn_list: dn_list = self.dn_list
        for i, dn in enumerate(self.dn_list):
            if dn in dn_list:
                self.dn_list[i] = dn.sub(pattern, repl, count, flags)

    def replace(self, *args, **kwargs):
        for i, dn in enumerate(self.dn_list):
            self.dn_list[i] = dn.replace(*args, **kwargs)

    def merge(self, mn):
        return Mn(
            dn_list=self.dn_list + mn.dn_list,
            df_list=self.df_list + mn.df_list,
            pp_list=self.pp_list + mn.pp_list,
            cs_list=self.cs_list + mn.cs_list,)

    def alex_process(self, re_delim, lv_set=None):
        if not lv_set: lv_set = self.lv_set()
        dn_list = []
        for i, dn in enumerate(self.dn_list):
            if dn.lv in lv_set:
                output = preprocess([[str(dn.ex)]])
                output = prepsyns(output, [0], re_delim, dn.lv)[0][0]
                out_ap = untag(output, dn.lv)
                for out_mn in out_ap:
                    for out_dn in out_mn.dn_list:
                        dn_list.append(dn.merge(out_dn))
                    self.df_list.extend(out_mn.df_list)
                    self.pp_list.extend(out_mn.pp_list)
                    self.cs_list.extend(out_mn.cs_list)
                self.dn_list[i] = None
        self.dn_list.extend(dn_list)
        self.dn_list = [dn for dn in self.dn_list if dn is not None]

    def tag(self, lv_list, tagged=False, tag_types=set()):
        mn_line = []
        if tagged:
            for lv in lv_list:
                mn_line.append(clean_str(''.join(tag_list(self(lv), 'dn'))))
                mn_line.append(clean_str(''.join(tag_list([df for df in self.df_list if df.lv == lv], 'df'))))
            mn_line.append(clean_str(''.join(tag_list(self.cs_list, 'mcs'))))
            mn_line.append(clean_str(''.join(tag_list(self.pp_list, 'mpp'))))
        else:
            tag_types = set(tag_types)
            if {'ex', 'dcs', 'dpp'} <= tag_types: tag_types.add('dn')
            if 'cs' in tag_types: tag_types.update({'dcs', 'mcs'})
            if 'pp' in tag_types: tag_types.update({'dpp', 'mpp'})
            for lv in lv_list:
                if 'dn' in tag_types:
                    mn_line.append(clean_str(''.join(tag_list(self(lv), 'dn'))))
                else:
                    if 'ex' in tag_types:
                        mn_line.append(clean_str(''.join(tag_list(self.ex_list(lv), 'ex'))))
                    else:
                        mn_line.append(clean_str('‣'.join([str(dn.ex) for dn in self(lv)])))
                    dcs_list = flatten([dn.cs_list for dn in self(lv)])
                    if 'dcs' in tag_types:
                        mn_line.append(clean_str(''.join(tag_list(dcs_list, 'dcs'))))
                    else:
                        mn_line.append(clean_str('‣'.join([str(cs.class_ex) for cs in dcs_list])))
                    dpp_list = flatten([dn.pp_list for dn in self(lv)])
                    if 'dpp' in tag_types:
                        mn_line.append(clean_str(''.join(tag_list(dpp_list, 'dpp'))))
                    else:
                        mn_line.append(clean_str('‣'.join([str(pp) for pp in dpp_list])))
                if 'df' in tag_types:
                    mn_line.append(clean_str(''.join(tag_list([df for df in self.df_list if df.lv == lv], 'df'))))
            if 'mcs' in tag_types:
                mn_line.append(clean_str(''.join(tag_list(self.cs_list, 'mcs'))))
            else:
                mn_line.append(clean_str('‣'.join([clean_str(str(cs.class_ex)) for cs in self.cs_list])))
            if 'mpp' in tag_types:
                mn_line.append(clean_str(''.join(tag_list(self.pp_list, 'mpp'))))
            else:
                mn_line.append(clean_str('‣'.join([clean_str(str(pp)) for pp in self.pp_list])))

        line = '\t'.join(mn_line)
        return line


class Ap(list):
    def tabularize(self, output_file, match_re_lv_list=None, lv_list=None, tagged=False, tag_types=set(), inc_df=False):
        if not lv_list:
            lv_list = sorted(set(flatten([mn.lv_list() for mn in self])))
        try:
            if isinstance(match_re_lv_list[0], str):
                match_re_lv_list = [match_re_lv_list]
        except TypeError: pass
        for mn in tqdm(self):
            line = mn.tag(lv_list, tagged, tag_types)
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

    def pretty(self, indent=0):
        ind = '  ' * indent
        out = ":\n0\n\n"
        for mn in tqdm(self):
            out += mn.pretty(indent) + '\n'
        return out.strip()

    def lv_set(self):
        lv_set = set()
        for mn in self:
            lv_set.update(mn.lv_list())
        return lv_set

    def dn_set(self, lv_set=set()):
        if not lv_set: lv_set = self.lv_set()
        elif isinstance(lv_set, str): lv_set = {lv_set}
        dn_set = set()
        for mn in self:
            for dn in mn.dn_list:
                if dn.lv in lv_set or dn.lc in lv_set:
                    dn_set.add(dn)
        return dn_set

    def ex_set(self, lv_set=set()):
        if isinstance(lv_set, str):
            lv_set = {lv_set}
        return {dn.ex for dn in self.dn_set(lv_set)}

    def sub(self, pattern, repl, count=0, flags=0, lv_set=None):
        if not lv_set: lv_set = self.lv_set()
        for mn in self:
            mn.sub(pattern, repl, count, flags, mn(lv_set))

    def get_scores(self, lv, as_lv=None, ui=[]):
        if not as_lv: as_lv = lv
        result = normalize.get_scores(map(str, self.ex_set(lv)), as_lv, ui)
        return {ex : result[str(ex)] for ex in self.ex_set(lv)}

    def get_degraded_scores(self, lv, as_lv=None, deg_func=None, include_std_deg=True, ui=[]):
        if not as_lv: as_lv = lv
        if deg_func:
            result = normalize.get_custom_deg_scores(map(str, self.ex_set(lv)), as_lv, deg_func, include_std_deg, ui)
        else:
            result = normalize.get_degraded_scores(map(str, self.ex_set(lv)), as_lv, ui)
        output = {}
        for ex in self.ex_set(lv):
            output[ex] = {Ex(s, lv) : result[str(ex)][s] for s in result[str(ex)]}
        return output

    def get_redeg_scores(self, lv, in_re, out, as_lv=None, ui=[]):
        if not as_lv: as_lv = lv
        result = normalize.get_redeg_scores(map(str, self.ex_set(lv)), as_lv, in_re, out, ui)
        output = {}
        for ex in self.ex_set(lv):
            output[ex] = {Ex(s, lv) : result[str(ex)][s] for s in result[str(ex)]}
        return output

    def apostrophe(self, lv_set=None, progress=False):
        if lv_set: lv_set = normalize_list(lv_set, 'lv_set', str)
        else: lv_set = self.lv_set()
        if progress:
            lv_apos = {}
            for lv in lv_set:
                print("Getting apostrophe for {}".format(lv), end='\r')
                lv_apos[lv] = normalize.apostrophe(lv)
            print("Performing replacements...    ")
        else:
            lv_apos = {lv : normalize.apostrophe(lv) for lv in lv_set}
        if progress: l = tqdm(self)
        else: l = self
        for mn in l:
            for lv in lv_set:
                mn.sub(r"'", lv_apos[lv], dn_list=mn(lv))

def untag(string, default_lv='und-000'):
    ap = Ap()
    string = string.replace('⁋⫷mn', '⫷mn')
    string = string.replace('⁋', '⫷mn⫸')
    string = string.replace('‣⫷ex', '⫷ex')
    string = string.replace('‣', '⫷ex⫸')
    mn = None
    dn = None
    superclass_ex = None
    attribute = None
    tag_split = [s for s in re.split(r'(⫷.*?⫸[^⫷]+)', string) if s]
    if not tag_split: return ap
    if tag_split[0] != '⫷mn⫸':
        tag_split.insert(0, '⫷mn⫸')
    if not tag_split[1].startswith('⫷'):
        tag_split[1] = '⫷ex⫸' + tag_split[1]
    for s in tag_split:
        obj, lv, text = re.search(r'⫷(.+?)(?::([a-z]{3}-\d{3}))?⫸(.*)', s).groups()
        if not lv: lv = default_lv
        if obj == 'mn':
            if mn: ap.append(mn)
            mn = Mn()
        if obj == 'ex':
            if dn: mn.dn_list.append(dn)
            dn = Dn(Ex(text, lv))
        if obj == 'df':
            mn.df_list.append(Df(text, lv))
        if re.match(r'[dm]cs[12]?', obj):
            if obj[-1] == '2':
                superclass_ex = Ex(text, lv)
            else:
                if obj.startswith('m'):
                    mn.cs_list.append(Cs(Ex(text, lv), superclass_ex))
                if obj.startswith('d'):
                    dn.cs_list.append(Cs(Ex(text, lv), superclass_ex))
                superclass_ex = None
        if re.match(r'[dm]pp', obj):
            if attribute is None:
                attribute = Ex(text, lv)
            else:
                if obj.startswith('m'):
                    mn.pp_list.append(Pp(text, attribute))
                if obj.startswith('d'):
                    dn.pp_list.append(Pp(text, attribute))
                attribute = None
    if dn: mn.dn_list.append(dn)
    if mn: ap.append(mn)
    return ap


def tabularize(source, output_file, match_re_lv_list=None, lv_list=None, tagged=False, tag_types=set(), inc_df=False):
    if not lv_list:
        lv_list = sorted(set(flatten([mn.lv_list() for mn in source])))
    try:
        if isinstance(match_re_lv_list[0], str):
            match_re_lv_list = [match_re_lv_list]
    except TypeError: pass
    for mn in tqdm(source):
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

def tab_log(ap, match_re_lv_list=None, lv_list=None, tagged=False, tag_types=set(), inc_df=False):
    with open("tab_log.txt", 'w', encoding='utf-8') as output_log:
        ap.tabularize(output_log, match_re_lv_list, lv_list, tagged, tag_types, inc_df)

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
        (maxchar and (len(str(ex)) > maxchar)) or \
        (maxword and (len(str(ex).split()) > maxword)):
            return Ex('', lv), Df(str(ex), lv)

    elif re.search(rx, str(ex)):
        return ex.copy(re.sub(rx, '', str(ex))), Df(str(ex), lv)

    else:
        return ex, Df('', lv)

def mnsplit(ap, split_re, lv_list=None, dn_filter=None, max_splits=0, even=False):
    if lv_list:
        dn_filter = lambda dn: dn.lv in lv_list
    for i, mn in enumerate(ap):
        dn_list = list(filter(dn_filter, mn.dn_list))
        if even:
            try:
                new_mns = mn.split_even(split_re, dn_list, max_splits)
            except ValueError:
                raise ValueError('uneven number of splits in {}'.format(mn))
            ap[i] = new_mns[0]
            try:
                for new_mn in new_mns[1:]:
                    ap.insert(i + 1, new_mn)
            except IndexError:
                pass
        else:
            for dn in dn_list:
                new_mns = mn.split(split_re, dn, max_splits=max_splits)
                ap[i] = new_mns[0]
                try:
                    for new_mn in new_mns[1:]:
                        ap.insert(i + 1, new_mn)
                except IndexError: pass

def charset(source, lv_list):
    """Returns a set of all of the characters found in all of the expressions in
    the given language varieties in all of the denotations in all of the
    meanings in the source.
    
    Args:
        source: source. a list of Mns
        
        lv_list: a list of lvs (as str in the format xxx-###). can also consist
        of a single lv, which is automatically converted to a list of length 1

    Returns:
        Returns a set of single characters. 
        
    Examples:
        >>> charset(source, ['eng-000', 'hye-000'])
        {'a', 'b', ..., 'z', '-', ..., 'ա', 'բ', ..., 'օ', 'ֆ', ...}
        >>> charset(source, 'eng-000')
        {'a', 'b', ..., 'z', '-', ...}
    """

    if isinstance(lv_list, str):
        lv_list = [lv_list]
    outset = set()
    for mn in source:
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