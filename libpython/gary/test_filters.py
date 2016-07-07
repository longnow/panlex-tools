
import unittest

from gary.text_filter import *

def update(text):
    return '<%s>' % text


class EntryTester(unittest.TestCase):
    def test_balance_parentheses_add_final(self):
        result = balance_parentheses('something (now in parens')
        self.assertEqual('something (now in parens)', result, 'should add final parens to balance')

    def test_balance_parentheses_mixed(self):
        pass
        # TODO: add tet with multiple parens "...( ... ( ... )" // no final