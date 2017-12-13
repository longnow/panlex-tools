#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from tqdm import tqdm
import pickle
import os
data_directory = os.path.dirname(__file__) + '/data/'
test_ex_list = pickle.load(open(data_directory + 'eng-000_ex_list.pickle', 'rb'))

def len_map(ex_list):
    output = [set() for _ in range(len(max(ex_list, key=len)) + 1)]
    for ex in ex_list:
        output[len(ex)].add(ex)
    return output

def parse(text, ex_list_len_map, min_len=1):
    if not text: return []
    output = []
    for l in range(len(text), min_len - 1, -1):
        text_to_check = text[:l]
        if text_to_check in ex_list_len_map[l]:
            output.append([text_to_check])
    for parsing in output:
        ex = parsing[0]
        new_text = text[len(ex):]
        p = parse(new_text, ex_list_len_map, min_len)
        if p:
            parsing.append(p)
    if not output:
        return parse(text[1:], ex_list_len_map, min_len)
    else:
        return output

def mid_parse(parse, output):
    try:
        mp = [parse[:-1] + e for e in parse[-1]]
    except TypeError:
        return None
    return mp

def l1_parse(parse):
    if len(parse) == 1:
        return [parse[0]]
    output = []
    for p in parse[-1]:
        output.append(parse[:-1] + p)
    return output

def l2_parse(parse):
    print("l2_parse len: " + str(len(parse)))
    output = []
    for p in parse[1]:
        for lp in l1_parse(p):
            output.append([parse[0]] + lp)
    return output

def l3_parse(parse):
    output = []
    for p in parse:
        for lp in l2_parse(p):
            output.append(lp)
    return output

def flatten_parse(parse):
    output = []
    for p in parse:
        output.append(mid_parse(parse, output))

def tokenize(text, ex_list, min_len=1):
    ex_list_len_map = len_map(ex_list)
    result = parse(text, ex_list_len_map, min_len)
    return result