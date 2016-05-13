#!/usr/bin/python3

import argparse
import json
from operator import itemgetter
import regex as re

import termcolor


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('filename', type=str, nargs='?', help='file to list')
    parser.add_argument('--min', default=0, type=int, help='minimum score to show (default 0)')
    parser.add_argument('--max', default=50, type=int, help='maximum score to show (default 50)')
    return parser.parse_args()



def read_values(filename, min_count, max_count):
    with open(filename) as fin:
        text = fin.read()
        data = json.loads(text)
        stage2 = data['stage2']
        records = get_sorted_list(stage2)
        
        for word,degraded_form,score in records:
            
            if degraded_form != None:
                if score < min_count or score > max_count:
                    continue
                
                if word == degraded_form:
                    print('%4d %-22s => _' % (score,word))
                else:
                    if re.sub('\s+', '', word) == re.sub('\s+', '', degraded_form):
                        degraded_form = termcolor.colored(degraded_form, 'red')
                        word = termcolor.colored(word, 'red')

                    print('%4d %-22s => %-18s' % (score,word,degraded_form))
            else:
                print('%4d %-22s' % (score,word))

    return



def get_sorted_list(records):
    wordlist = [(k,v['tt'],int(v['score'])) for k,v in records.items()]
    return sorted(wordlist, key=itemgetter(2), reverse=True)


if __name__=="__main__":
    args = get_args()

    if not args.filename:
        print('no filename given')

    read_values(args.filename, args.min, args.max)
