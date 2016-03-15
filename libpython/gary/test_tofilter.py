import unittest

from gary import english


class TestToFilter(unittest.TestCase):

    def test_basic_verb_filter(self):
        result = english.remove_inf_to('to work')
        self.assertEqual(result, 'work', 'remove "to" on verbs')

    def test_quantifier_filter(self):
        result = english.remove_inf_to('to no avail')
        self.assertEqual(result, 'to no avail', 'leave unchanged')

    def test_adj_phrase_filter(self):
        result = english.remove_inf_to('to be on the safe side')
        self.assertEqual(result, 'on the safe side', 'remove "to" on adj phrases')

    def test_basic_adj_filter(self):
        result = english.remove_inf_to('to be happy')
        self.assertEqual(result, 'happy', 'remove "to" on adjectives')

    def test_alt_quantifier_filter(self):
        result = english.remove_inf_to("to somebody’s disappointment")
        self.assertEqual(result, "to somebody’s disappointment", 'leave unchanged')

    def test_boot(self):
        result = english.remove_inf_to('to boot')
        self.assertEqual(result, 'to boot', 'leave fixed phrase unchanged')

    def test_just_to(self):
        result = english.remove_inf_to('to')
        self.assertEqual(result, 'to', 'leave unchanged if just single word')

    def test_boot(self):
        result = english.remove_inf_to('to boot')
        self.assertEqual(result, 'to boot', 'leave fixed phrase unchanged')


if __name__ == '__main__':
    unittest.main()