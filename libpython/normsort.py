#!/usr/bin/env python3

import argparse
import json
from operator import itemgetter
import signal
import sys

import termcolor


def get_args():
    parser = argparse.ArgumentParser(prog='normsort')
    
    parser.add_argument('filename', type=str, nargs='?', help='file to list')
    # parser.add_argument('--min', default=0, type=int, help='minimum score to show (default 0)')
    parser.add_argument('--max', default=50, type=int, help='maximum score to show (default 50)')
    
    args = parser.parse_args()
    
    if not args.filename:
        print('no filename given')
        parser.print_usage()
        sys.exit(0)
    
    return args


def get_entries(filename):
    with open(filename) as fin:
        data = json.load(fin)
        return data['stage1'],data['stage2']


def show_scores(stage1:dict,stage2:dict, maxcount=50):
    # get key list sorted by score descending
    keys = [k for k,v in sorted([(k,v['score']) for k,v in stage1.items()],key=itemgetter(1),reverse=True)]

    for key in keys:
        score1 = stage1[key]['score']
        if score1 > maxcount:
            continue
        
        if key in stage2:
            norm_text = stage2[key]['txt']
            score2 = stage2[key]['score']
            
            if norm_text:
                if norm_text == key:
                    print('%4d %-30s => %3d _' % (score1,key,score2))
                else:
                    print('%4d %-30s => %3d %s' % (score1,key,score2,norm_text))
            else:
                print('%4d %-30s =|' % (score1,key))
        else:
            print('%4d %-30s' % (score1,key))



if __name__=="__main__":
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    args = get_args()
    stage1,stage2 = get_entries(args.filename)
    try:
        show_scores(stage1,stage2, args.max)
    except BrokenPipeError:
        pass
    