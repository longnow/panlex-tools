#!/usr/bin/python3

import argparse
import codecs
from collections import defaultdict
from operator import itemgetter

return_dict = {'\x01':'SOH', '\x02':'STX', '\x03':'ETX', '\x04':'EOT', '\x05':'ENQ',
               '\x06':'ACK','\x07':'BEL', '\x08':'BS', '\x09':'HT', '\n':'LF',
               '\x0B':'VT', '\x0C':'FF', '\r':'CR', '\x20':'SP', '\t':'HT'}

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--filename')
    parser.add_argument('-c', '--cutoff', type=int, default=0)
    return parser.parse_args()



def get_hist(text):
    hist = defaultdict(int)
    for c in text:
        hist[c] += 1
    return hist

    

def sort_hist(hist):
    ls = list(hist.items())
    ls.sort(key=itemgetter(1), reverse=True)
    return ls



def print_hist(hist, cutoff=False):
    ls = sort_hist(hist)
    if len(ls) == 0:
        print('no data found')
        return

    max_count = 0

    for char,count in ls:
        if cutoff:
            max_count += 1
            if max_count > cutoff:
                break
        
        if char in return_dict.keys():
            print('\t%s (U+%.4x)\t%3d' % (return_dict[char], ord(char),count))
        else:
            print('\t%s (U+%.4x)\t%3d' % (char,ord(char),count))



def read_file(filename):
    with codecs.open(filename, encoding='utf-8') as f:
        data = f.read()
        hist = get_hist(data)
        return data



def run_hist(filename, cutoff=False):
    data = read_file(args.filename)
    hist = get_hist(data)
    print_hist(hist, cutoff)



if __name__ == '__main__':
    args = get_args()
    if args.cutoff == 0:
        run_hist(args.filename)
    else:
        run_hist(args.filename, cutoff=args.cutoff)