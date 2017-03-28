#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from collections import Counter
import ben.iso15924 as iso15924
import ben.unicode as unicode
import ben.fontmaps as fontmaps
from ben.panlex import *
import regex as re

def most_common_script(string, skip=[], soft_skip=[]):
    skip = set(skip)
    soft_skip = set(soft_skip)
    if not string:
        raise ValueError('string is empty')
    c = Counter(list(map(lambda x: unicode.get_property(x, 'Script'), string)))
    most_common = [sc for sc in c.most_common() if sc[0] not in skip]
    try:
        if most_common[0][1] == most_common[1][1]:
            tied_scripts = set()
            for sc in most_common:
                if sc[1] == most_common[0][1]: tied_scripts.add(sc[0])
            if len(tied_scripts - soft_skip) == 1:
                return list(tied_scripts - soft_skip)[0]
            raise ValueError('{} are equally common in {}'.format(tied_scripts, string))
    except IndexError:
        pass
    try:
        return most_common[0][0]
    except IndexError:
        raise ValueError('string only contains characters in skipped scripts')
    # for sc in c.most_common():
    #     script = sc[0]
    #     if script not in skip:
    #         return script
    # return c.most_common(1)[0][0]

def get_tables(a, cont=True):
    output = []
    for element in a.next_elements:
        if element.name == 'a': break
        if element.name == 'table': output.append(element)
    if cont:
        if not output:
            next_a = a.find_next('a')
            if next_a.has_attr('href'):
                output.extend(get_tables(a.parent.find('a', {'name' : next_a['href'][1:]})))
                output.extend(get_tables(next_a, cont=False))
                return output
            else:
                return get_tables(a.find_next('a'))
        else:
            return output
    else:
        return output

def get_next_table(a, min_trs=0):
    for element in a.next_elements:
        if element.name == 'table':
            try:
                assert(element['border'] == '1')
            except (KeyError, AssertionError) as e:
                continue
            if len(element('tr')) >= min_trs:
                return element
        if element.name == 'a' and element.has_attr('name'):
            raise TypeError('went too far')

def text_after_a(a):
    output = ''
    for element in a.next_siblings:
        if element.name in ['table', 'a']: break
        else:
            try:
                out = element.text
            except AttributeError:
                out = element.string
            output += out
    return output

def text_before_table(table):
    output = []
    for element in table.previous_siblings:
        if element.name in ['table', 'a']: break
        else:
            try:
                out = element.text
            except AttributeError:
                out = element.string
            output.append(out)
    return ''.join(reversed(output))


def merge_table(table, columns):
    for tr in table('tr'):
        i = 0
        while tr.name and len(tr('td')) < columns:
            try:
                for td in tr.find_next('tr')('td')[:columns - len(tr('td'))]:
                    tr.append(td)
                tr.find_next('tr').decompose()
            except TypeError:
                pass

def vert_table(table, lv_dict):
    ap = Ap([Mn() for i in range(len(table.tr('td')) - 1)])
    for tr in table('tr'):
        lv_tag_set = set()
        if not tr.td: continue
        try:
            for acronym in tr.td('acronym'):
                lv_tag_set.add(acronym.text.strip(' |'))
        except TypeError:
            raise TypeError('problem with {}'.format(tr.text))
        for i, td in enumerate(tr('td')[1:]):
            t = re.sub(r'\s\(.*?\)', '', clean_str(td.text))
            for split_text in re.split(r';\s', t):
                for split_by_script in re.split(r'\s/\s', split_text):
                    if clean_str(split_by_script) == '?': continue
                    if not clean_str(split_by_script): continue
                    try:
                        script = most_common_script(clean_str(split_by_script), {'Zyyy', 'Zinh'}, {'Hani'})
                    except ValueError:
                        raise TypeError('problem with {}'.format(lv_tag_set))
                    if script == 'Zzzz': script = 'Hmng'
                    for lv_tag in lv_tag_set:
                        if not lv_tag: continue
                        try:
                            lv = lv_dict[lv_tag][0][script]
                        except (IndexError, KeyError) as e:
                            raise TypeError('problem with {} {} {}'.format(split_by_script, lv_tag, script))
                        if script == 'Hmng':
                            text = clean_str(fontmaps.decode(split_by_script, 'JG_Pahawh_Third_Version.ttf'))
                        elif script == 'Mymr':
                            text = clean_str(fontmaps.decode(split_by_script, 'Myanmar1.ttf'))
                        else:
                            text = clean_str(split_by_script)
                        try:
                            ap[i].dn_list.append(Dn(Ex(text, lv)))
                        except IndexError:
                            raise TypeError('problem with {}'.format(lv_tag))
    return ap

def horz_table(a, lv_dict, ap, title_mn=None):
    lv_tag = a['name']
    for i, table in enumerate(get_tables(a)):
        if title_mn is not None:
            title_text = re.sub(r'\(.*?\)', '', clean_str(text_before_table(table)))
            try:
                title_text = title_text.split(':')[1]
            except IndexError:
                title_text = ''
            for text in re.split(r'\s/\s', title_text):
                text = clean_str(text)
                if not text: continue
                script = most_common_script(text, {'Zyyy'})
                if script == 'Zzzz': script = 'Hmng'
                try:
                    lv = lv_dict[lv_tag][i][script]
                except (IndexError, KeyError) as e:
                    raise TypeError('problem with "{}" ({})'.format(text, lv_tag))
                title_mn.dn_list.append(Dn(Ex(text, lv)))
        merge_table(table, len(ap))
        for tr in table('tr'):
            script = most_common_script(tr.text, {'Zyyy'})
            if script == 'Zzzz': script = 'Hmng'
            try:
                lv = lv_dict[lv_tag][i][script]
            except (IndexError, KeyError) as e:
                raise TypeError('problem with {}'.format(lv_tag))
            for j, td in enumerate(tr('td')):
                if clean_str(td.text) == '?': continue
                if script == 'Hmng':
                    text = clean_str(fontmaps.decode(td.text, 'JG_Pahawh_Third_Version.ttf'))
                elif script == 'Mymr':
                    text = clean_str(fontmaps.decode(td.text, 'Myanmar1.ttf'))
                else:
                    text = clean_str(td.text)
                ap[j].dn_list.append(Dn(Ex(text, lv)))

def write_lvs(ap, base_file_name):
    import panlex, requests, os
    lv_code_list = [l['langvar'] for l in panlex.query_all('/langvar', {'uid': sorted(ap.lv_set())})['result']]
    ap_code = panlex.query('/source/' + re.sub(r'^([a-z]{3}(?:-[a-z]{3})*)-(.+?)$', '\g<1>:\g<2>', base_file_name), {})['source']['id']
    r = requests.post('https://panlex.org/panlem/api', data = {
        'us': os.environ['PANLEX_PANLEM_USER'],
        'pwd': os.environ['PANLEX_PANLEM_PASSWORD'],
        'sr': 'apred4',
        'ap': ap_code,
        'uslv': 187,
        'lvs': lv_code_list,
        'mod': 'lvs'
        })

def soup_sub(rx, replacement, soup):
    for s in soup.find_all(text = re.compile(rx)):
        s.replace_with(re.sub(rx, replacement, s))