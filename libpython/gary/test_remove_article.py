import unittest

from gary import english


class TestRemoveArticle(unittest.TestCase):
    def test_noun(self):
        result = english.remove_article('a horse')
        self.assertEqual(result, 'horse', 'should remove "a" before noun')


    def tet_adj(self):
        result = english.remove_article('the best man')
        self.assertEqual(result, 'best man', 'should remove "a" before adj')


    def test_embeded_article1(self):
        result = english.remove_article('belonging to a hotel or firm')
        self.assertEqual(result, 'belonging to a hotel or firm', 'unchanged')


    def test_embeded_article2(self):
        result = english.remove_article('address with the formal personal pronoun')
        self.assertEqual(result, 'address with the formal personal pronoun', 'unchanged')


    def test_fixed_phrases(self):
        result = english.remove_article('a bit')
        self.assertEqual(result, 'a bit', 'a bit should not change')

        result = english.remove_article('a lot')
        self.assertEqual(result, 'a lot', 'a lot should not change')

        result = english.remove_article('a little')
        self.assertEqual(result, 'a little', 'a little should not change')


    def test_latin1(self):
        result = english.remove_article('a priori')
        self.assertEqual(result, 'a priori', 'unchanged')


    def test_latin2(self):
        result = english.remove_article('a posteriori')
        self.assertEqual(result, 'a posteriori', 'unchanged')



if __name__ == '__main__':
    unittest.main()