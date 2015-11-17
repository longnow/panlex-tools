#!/usr/bin/python3

import argparse
import json
from operator import itemgetter


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--filename')
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
                    print('%4d %-18s => _' % (score,word))
                else:
                    print('%4d %-18s => %-18s' % (score,word,degraded_form))
            else:
                print('%4d %-18s' % (score,word))
    return



def get_sorted_list(records):
    wordlist = [(k,v['tt'],int(v['score'])) for k,v in records.items()]
    return sorted(wordlist, key=itemgetter(2), reverse=True)


if __name__=="__main__":
    args = get_args()

    if not args.filename:
        print('no filename given')

    read_values(args.filename, args.min, args.max)
