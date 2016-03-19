#!/usr/bin/env python3

import argparse
import sys


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('filename', type=str, nargs='?', help='file to process')
    return parser.parse_args()



if __name__ == '__main__':
    args = get_args()

    if args.filename == None:
        fin = sys.stdin
    else:
        fin = open(args.filename)

    for line in fin:
        count = 0
        
        for c in line:
            if c == '(':
                count += 1
            elif c == ')':
                count -= 1

        if count < 0:
            print('<%-3d%s' % (-count,line.rstrip('\n')))
        elif count > 0:
            print('>%-3d%s' % (count,line.rstrip('\n')))
