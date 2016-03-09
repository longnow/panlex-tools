
import regex as re
from nltk import WordNetLemmatizer, PerceptronTagger, RegexpParser, TreebankWordTokenizer
from nltk.tree import Tree
from gary.source import ignore_parens

from gary.source import process_synonyms



def get_words(node):
    if not node:
        return ''
    else:
        return  ' '.join([w for w, t in node.leaves()])


class VerbAdjChunker(object):
    def __init__(self):
        # self.lemmatizer = WordNetLemmatizer()
        self.tokenizer = TreebankWordTokenizer()
        self.tagger = PerceptronTagger()
        self.det_exceptions = ['bit', 'lot', 'little', 'priori', 'posteriori']
        pattern = """
            VP: {(<IN>|<TO>)<VB>(<VB>|<VBN>)*<NP>*}
            AP: {<RB>?<JJ>}
          """
        self.chunker = RegexpParser(pattern)


    def getChunks(self, text):
        tagged_tokens = self.tagger.tag( self.tokenizer.tokenize(text))
        tree = self.chunker.parse(tagged_tokens)
        return tree

    def get_tree_words(self, node):
        return ' '.join([w for w,t in node.leaves()])


    def walkTree(self, tree):
        pos = set()

        for node in tree:
            if type(node) == Tree:
                if node.label() == 'VP':
                    self.handle_verbs(node, pos)

                elif node.label() == 'AP':
                    pos.add('adj')

                elif node.label() == 'NP':
                    self.handle_np(node, pos)

            elif type(node) != tuple:
                msg = 'Unknown node type: %s' % type(node)
                raise Exception(msg)

        return get_words(tree),list(pos)


    def handle_np(self, node, pos):
        if node.leaves()[0][0] in ['a', 'an', 'the']:
            if len(node.leaves()) > 2 or node.leaves()[0][0] in ['a','an']:
                if node.leaves()[1][0] not in self.det_exceptions:
                    node.pop(0)
                    pos.add('noun')


    def handle_verbs(self, node, pos):
        words = get_words(node)
        if words == 'to be':
            node.clear()
        elif words.startswith('to be '):
            node.pop(0)
            node.pop(0)
            pos.add('v')
        elif node.leaves()[0][0] == 'to':
            node.pop(0)
            pos.add('v')



class NPChunker(object):
    def __init__(self):
        # self.lemmatizer = WordNetLemmatizer()
        self.tokenizer = TreebankWordTokenizer()
        self.tagger = PerceptronTagger()
        self.det_exceptions = ['bit', 'lot', 'little', 'priori', 'posteriori']
        pattern = """
            PP: {<IN><JJ>*<NN><NN>*}
            NP: {(<DT>*<JJ>*<NN(P?)>*<NN(S?)>(<PP>)*)|(<DT><JJ>)}
            VP: {(<IN>|<TO>)<VB>(<VB>|<VBN>)*<NP>*}
            AP: {<RB>?<JJ>}
            PN: {((<NNP>*)<NNP(S?)>)}
          """
        self.chunker = RegexpParser(pattern)


    def getChunks(self, text):
        tagged_tokens = self.tagger.tag( self.tokenizer.tokenize(text))
        tree = self.chunker.parse(tagged_tokens)
        return tree

    def get_tree_words(self, node):
        return ' '.join([w for w,t in node.leaves()])


    def walkTree(self, tree):
        pos = set()

        for node in tree:
            if type(node) == Tree:
                if node.label() == 'VP':
                    self.handle_verbs(node, pos)

                elif node.label() == 'AP':
                    pos.add('adj')

                elif node.label() == 'NP':
                    self.handle_np(node, pos)

            elif type(node) != tuple:
                msg = 'Unknown node type: %s' % type(node)
                raise Exception(msg)

        return get_words(tree),list(pos)


    def handle_np(self, node, pos):
        if node.leaves()[0][0] in ['a', 'an', 'the']:
            if len(node.leaves()) > 2 or node.leaves()[0][0] in ['a','an']:
                if node.leaves()[1][0] not in self.det_exceptions:
                    node.pop(0)
                    pos.add('noun')


    def handle_verbs(self, node, pos):
        words = get_words(node)
        if words == 'to be':
            node.clear()
        elif words.startswith('to be '):
            node.pop(0)
            node.pop(0)
            pos.add('v')
        elif node.leaves()[0][0] == 'to':
            node.pop(0)
            pos.add('v')



@ignore_parens
def simplify_phrase(text, **kwargs):
    if len(text.strip()) == 0:
        return text
    if not re.search('\m(to|be|a|an|the)\M', text):
        return text

    chunker = VerbAdjChunker()
    chunked_phrase = chunker.getChunks(text)
    sentence,pos_list = chunker.walkTree(chunked_phrase)
    sentence = remove_extra_spaces(sentence)
    if len(pos_list) > 0:
        return '%s' % (sentence)
    else:
        return sentence


def remove_extra_spaces(text):
    text = re.sub('([[(])\s+', r'\1', text)
    text = re.sub('\s+([\])])', r'\1', text)
    text = re.sub("\s+'s", "'s", text)
    text = re.sub("['`]{2}", '"', text)
    text = re.sub('"\s*([^"]*?)\s*"', r'\1', text)
    text = re.sub('\s+([!?.,])', r'\1', text)
    text = re.sub('([$])\s+', 'r\1', text)
    text = re.sub('\s+\(s\)', '(s)', text)

    return text


def remove_article(text, **kwargs):
    match = re.search('^(?:a|an|the)\s+(\w+)', text)
    if match:
        if match[1].lower() not in ['lot', 'little', 'priori', 'posteriori', 'bit']:
            text = re.sub('^(?:a|an|the)\s+', '', text)

    match_end = re.search('^(.*?)\s+(?:a|an|the)', text)
    if match_end:
        text = match_end[1]

    return text


tokenizer = TreebankWordTokenizer()
tagger = PerceptronTagger()
exclude_list = ['boot']

def remove_inf_to(text:str) -> str:
    global tokenizer,tagger
    if text == 'to':
        return "to"

    text = re.sub('^to be ', '', text)

    tokens = tokenizer.tokenize(text)
    tagged_tokens = tagger.tag(tokens)
    if tagged_tokens[0][1] == 'TO' and re.search('^(V|B)', tagged_tokens[1][1]):
        if not re.search("(everybody|somebody)", tagged_tokens[1][0]):
            if tagged_tokens[1][0] not in exclude_list:
                text = re.sub('^to\s+', '', text)

    return text