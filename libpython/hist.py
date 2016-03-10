#!/usr/bin/python3

import argparse
import codecs
from collections import defaultdict
from operator import itemgetter
import sys
import unicodedata

control_character_map = {'\x01': 'SOH', '\x02': 'STX', '\x03': 'ETX', '\x04': 'EOT', '\x05': 'ENQ',
               '\x06':'ACK','\x07':'BEL', '\x08':'BS', '\x09':'HT', '\n':'LF',
               '\x0B':'VT', '\x0C':'FF', '\r':'CR', '\x20':'SP', '\t':'HT'}

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


        try:
            name = get_unicode_name(char)
        except:
            name = ''

        fraction = count / total

        if char in control_character_map.keys():
            print(' %-3s (U+%.6X)  %5d\t%.8f    %s' % (control_character_map[char], ord(char), count, fraction, name))
        else:
            print(' %-3s (U+%.6X)  %5d\t%.8f    %s' % (char,ord(char),count,fraction,name))



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
