#!/usr/bin/python3

import argparse
import codecs
from collections import defaultdict
from operator import itemgetter
import sys
import unicodedata

control_character_map = {'\x01': '␁', '\x02': '␂', '\x03': '␃', '\x04': '␄', '\x05': '␅',
               '\x06':'␆','\x07':'␇', '\x08':'␈', '\x09':'␉', '\n':'␊',
               '\x0B':'␋', '\x0C':'␌', '\r':'␍', '\x20':'␠', '\t':'␉'}

control_character_name_map = {'\x09':'CHARACTER TABULATION', '\x0A':'LINE FEED', '\x0D':'CARRIAGE RETURN'}


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('filename', type=str, nargs='?', help='file to process')
    parser.add_argument('-c', '--cutoff', type=int, default=0)
    parser.add_argument('-m', '--mincount', type=int, default=1)
    return parser.parse_args()



def get_hist(fin):
    hist = defaultdict(int)
    text = fin.read()

    for c in text:
        hist[c] += 1

    return hist



def get_unicode_name(ch):
    try:
        name = unicodedata.name(ch)
    except:
        name = ''

    if ch in control_character_name_map:
        name = control_character_name_map[ch]

    return name



def sort_hist(hist:dict) -> list:
    ls = list(hist.items())
    ls.sort(key=itemgetter(1), reverse=True)
    return ls



def print_hist(hist:dict, mincount=1, cutoff=False):
    total = sum(hist.values())
    sorted_hist = sort_hist(hist)
    if len(sorted_hist) == 0:
        print('no data found')
        return

    max_count = 0

    for char,count in sorted_hist:
        if cutoff:
            max_count += 1
            if max_count > cutoff:
                print('max rows found, bailing')
                break
        elif mincount > count:
            print('count below minimum of %d for {%s}' % (mincount,char))
            break

        name = get_unicode_name(char)
        fraction = count / total
        
        if ord(char) <= 0xFFFF: 
            num = '  (U+%.4X)' % ord(char)
        else:
            num = '(U+%.6X)' % ord(char)

        print(' %-3s %s  %5d\t%.8f    %s' % (char, num, count, fraction, name))



def read_file(filename):
    with codecs.open(filename, encoding='utf-8') as f:
        data = f.read()
        hist = get_hist(data)
        return data



def run_hist(filename, mincount, cutoff=False):
    if filename == None:
        source = sys.stdin
    else:
       source = open(filename)
    hist = get_hist(source)
    print_hist(hist, mincount, cutoff)



if __name__ == '__main__':
    args = get_args()

    if args.cutoff == 0:
        run_hist(args.filename, args.mincount)
    else:
        run_hist(args.filename, args.mincount, cutoff=args.cutoff)
