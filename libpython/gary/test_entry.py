
import unittest

from gary import Entry
from gary.entry_filter import *

def update(text):
    return '<%s>' % text

myfilter = SimpleFilter(update, 'eng.pos')


class EntryTester(unittest.TestCase):
    def testSimple(self):
        entry = Entry('eng:pos','deu')
        entry.eng.text = 'text'
        entry.eng.pos = 'hello'
        myfilter(entry)
        self.assertEqual(entry.eng.pos, '<hello>', 'should update text field')
        print('ENTRY: %s' % entry)



class ToFilterTester(unittest.TestCase):

    def basic_verb_filter(self):
        result = english.remove_inf_to('to work')
        self.assertEqual(result, 'work', 'remove "to" on verbs')

    def quantifier_filter(self):
        result = english.remove_inf_to('to no avail')
        self.assertEqual(result, 'to no avail', 'leave unchanged')

    def adj_phrase_filter(self):
        result = english.remove_inf_to('to be on the safe side')
        self.assertEqual(result, 'work', 'remove "to" on adj phrases')

    def basic_adj_filter(self):
        result = english.remove_inf_to('to be happy')
        self.assertEqual(result, 'work', 'remove "to" on adjectives')

    def alt_quantifier_filter(self):
        result = english.remove_inf_to('to everybody’s amusement')
        self.assertEqual(result, 'to everybody’s amusement', 'leave unchanged')

