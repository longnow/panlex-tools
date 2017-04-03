#!/usr/bin/env python3
# Yacc example
from time import sleep

import ply.yacc as yacc

# Get the token map from the lexer.  This is required.
from text_lex import tokens

DEBUG = False

def print_err(s):
    if DEBUG:
        print(s)

class Text:
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return str(self.value)

    def __repr__(self):
        return 'Text( %s)' % repr(self.value)


class Parens:
    def __init__(self, value):
        self.value = value
    
    def __str__(self):
        return '(%s)' % str(self.value)
    
    def __repr__(self):
        return 'Parens( %s)' % repr(self.value)


class Brackets:
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return '[%s]' % str(self.value)
    
    def __repr__(self):
        return 'Brackets( %s)' % repr(self.value)


class BasicList:
    def __init__(self, value):
        self.value_list = [value]
        self.DELIMCHAR = '|'
    
    def append(self, value):
        if (type(self.value_list[-1]) == Text) and  type(value) == Text:
            value = Text( str(self.value_list.pop()) + str(value))
        
        self.value_list.append(value)
        return self
    
    def __iter__(self):
        self.i = 0
        return self
    
    def __next__(self):
        if self.i >= len(self.value_list):
            raise StopIteration
        result = self.value_list[self.i]
        self.i += 1
        return result
    
    def __str__(self):
        return '%s' % self.DELIMCHAR.join([str(s) for s in self.value_list])
    
    def __repr__(self):
        return '( %s)' % self.DELIMCHAR.join([repr(s) for s in self.value_list])


class TextList(BasicList):
    def __init__(self, value):
        BasicList.__init__(self, value)
        self.DELIMCHAR = ''
    
    def __repr__(self):
        return 'TextList( %s)' % self.DELIMCHAR.join([repr(s) for s in self.value_list])


class SynonymList(BasicList):
    def __init__(self, value):
        BasicList.__init__(self, value)
        self.DELIMCHAR = '‣'
    
    def __repr__(self):
        return 'SynonymList( %s)' % self.DELIMCHAR.join([repr(s) for s in self.value_list])


class SenseList(BasicList):
    def __init__(self, value):
        BasicList.__init__(self, value)
        self.DELIMCHAR = ' ⁋ '
    
    def __repr__(self):
        return 'SenseList( %s)' % self.DELIMCHAR.join([repr(s) for s in self.value_list])


def p_inner_text_basic(p):
    'inner_text : TEXT'
    p[0] = Text(p[1])
    print_err('INNER TEXT: {!r} -> {!r}'.format(p[1],p[0]))
    

def p_inner_text_comma(p):
    'inner_text : COMMA'
    p[0] = Text(',')
    print_err('INNER TEXT: {!r} -> {!r}'.format(p[1],p[0]))


def p_inner_text_semicolon(p):
    'inner_text : SEMICOLON'
    p[0] = Text(';')
    print_err('INNER TEXT: {!r} -> {!r}'.format(p[1],p[0]))


def p_inner_text_list(p):
    """
    inner_text_list : inner_text
    inner_text_list : inner_text_list inner_text
    """
    if len(p) == 2:
        p[0] = TextList(p[1])
        print_err('TEXTLIST1: {!r} -> {!r}'.format(p[1],p[0]))
    else:
        p[0] = p[1].append(p[2])
        print_err('TEXTLIST1: {!r} {!r} -> {!r}'.format(p[1],p[2],p[0]))


def p_parens(p):
    """
    text : LPAREN RPAREN
    text : LPAREN inner_text_list RPAREN
    """
    if len(p) == 4:
        p[0] = Parens(p[2])
    else:
        p[0] = Text('')
        print_err('EMPTY PARENS')
    print_err('PARENS: {!r} -> {!r}'.format(p[2],p[0]))


def p_inner_parens(p):
    """
    inner_text : LPAREN RPAREN
    inner_text : LPAREN inner_text_list RPAREN
    """
    if len(p) == 4:
        p[0] = Parens(p[2])
        print_err('INNER PARENS: {!r} -> {!r}'.format(p[2],p[0]))
    else:
        p[0] = Text('')
    


def p_brackets(p):
    """
    text : LBRACK RBRACK
    text : LBRACK inner_text_list RBRACK
    """
    if len(p) == 4:
        p[0] = Brackets(p[2])
        print_err('OUTER BRACKETS: {!r} -> {!r}'.format(p[2],p[0]))
    else:
        p[0] = Text('')


def p_inner_brackets(p):
    """
    inner_text : LBRACK RBRACK
    inner_text : LBRACK inner_text_list RBRACK
    """
    if len(p) == 4:
        p[0] = Brackets(p[2])
        print_err('INNER BRACKETS: {!r} -> {!r}'.format(p[2],p[0]))
    else:
        p[0] = Text('')
    


def p_text(p):
    'text : TEXT'
    p[0] = Text(p[1])
    print_err('TEXT: {!r} -> {!r}'.format(p[1],p[0]))


def p_text_list(p):
    """
    text_list : text
    text_list : text_list text
    """
    if len(p) == 2:
        p[0] = TextList(p[1])
        print_err('TEXTLIST1: {!r} -> {!r}'.format(p[1],p[0]))
    else:
        p[0] = p[1].append(p[2])
        print_err('TEXTLIST2: {!r} {!r} -> {!r}'.format(p[1],p[2],p[0]))


def p_syn_list(p):
    """
    syn_list : text_list
    syn_list : syn_list COMMA text_list
    """
    if len(p) == 2:
        p[0] = SynonymList(p[1])
        print_err('SYNLIST1: {!r} -> {!r}'.format(p[1],p[0]))
    else:
        p[0] = p[1].append(p[3])
        print_err('SYNLIST2: {!r} {!r} -> {!r}'.format(p[1],p[3],p[0]))


def p_sense_list(p):
    """
    sense_list : syn_list
    sense_list : sense_list SEMICOLON syn_list
    """
    if len(p) == 2:
        p[0] = SenseList(p[1])
        print_err('SENSELIST1: {!r} -> {!r}'.format(p[1],p[0]))
    else:
        p[0] = p[1].append(p[3])
        print_err('SENSELIST2: {!r} {!r} -> {!r}'.format(p[1],p[3],p[0]))


# Error rule for syntax errors
def p_error(p):
    print('Parse error')


# Build the parser
parser = yacc.yacc(start='sense_list')

if __name__ == '__main__':
    sleep(0.1)
    while True:
       try:
           s = input('text: ')
       except EOFError:
           break
       if not s: continue
       result = parser.parse(s)
       print('RESULT: %s' % repr(result))
       print('RESULT: %s' % result)
       