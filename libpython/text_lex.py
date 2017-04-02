#!/usr/bin/env python3
# ------------------------------------------------------------
# calclex.py
#
# tokenizer for a simple expression evaluator for
# numbers and +,-,*,/
# ------------------------------------------------------------
import ply.lex as lex

# List of token names.   This is always required
tokens = (
    'LPAREN',
    'RPAREN',
    'LBRACK',
    'RBRACK',
    'TEXT',
    'COMMA',
    'SEMICOLON'
)

# Regular expression rules for simple tokens
t_LPAREN    = r'\('
t_RPAREN    = r'\)'
t_LBRACK    = r'\['
t_RBRACK    = r'\]'
t_COMMA     = r','
t_SEMICOLON = r';'

def t_TEXT(t):
    r'[^\[\](),;]+'
    t.value = t.value
    return t

# A string containing ignored characters (spaces and tabs)
t_ignore  = ' \t'

# Error handling rule
def t_error(t):
    print("Illegal character '%s'" % t.value[0])
    t.lexer.skip(1)

# Build the lexer
lexer = lex.lex()


if __name__ == '__main__':   
    # Test it out
    data = '''
    here is some text (and more [123]) &#@$^*&! then (parens again), synonym ; another sense
    '''
    
    # Give the lexer some input
    lexer.input(data)
    
    # Tokenize
    while True:
        tok = lexer.token()
        if not tok: 
            break      # No more input
        print(tok)