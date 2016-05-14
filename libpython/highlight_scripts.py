#!/usr/bin/env python3

import argparse
import regex as re
import sys

import termcolor


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('filename', type=str, nargs='?', help='file to process')
    return parser.parse_args()


def color_cyrillic(match):
    return termcolor.colored(match[0], 'red')

def color_mathematical(match):
    return termcolor.colored(match[0], 'blue')

def color_greek(match):
    return termcolor.colored(match[0], 'green')

def color_fullwidth(match):
    return termcolor.colored(match[0], 'cyan')

def color_latin_extended(match):
    return termcolor.colored(match[0], 'magenta')

def color_ipa_extensions(match):
    return termcolor.colored(match[0], 'white', 'on_yellow', attrs=['bold'])

# {'cyan': 36, 'yellow': 33, 'grey': 30, 'magenta': 35, 'green': 32, 'white': 37, 'blue': 34, 'red': 31}
# {'underline': 4, 'bold': 1, 'blink': 5, 'reverse': 7, 'concealed': 8, 'dark': 2}

if __name__ == '__main__':
    args = get_args()
    print(termcolor.ATTRIBUTES)
    if args.filename == None:
        fin = sys.stdin
    else:
        fin = open(args.filename)

    for line in fin:
        line = re.sub(r'\p{Cyrillic}+', color_cyrillic, line)
        line = re.sub(r'\p{Mathematical_Alphanumeric_Symbols}+', color_mathematical, line)
        line = re.sub(r'\p{Greek}+', color_greek, line)
        line = re.sub(r'\p{Halfwidth_and_Fullwidth_forms}+', color_fullwidth, line)
        line = re.sub(r'\p{Latin_Extended_B}+', color_latin_extended, line)
        line = re.sub(r'\p{IPA_Extensions}+', color_ipa_extensions, line)

        print(line.rstrip('\n'))
