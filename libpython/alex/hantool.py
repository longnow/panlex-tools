#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# Convert/confirm traditional/simplified Han character text,
# using Google Translate API.

import os, glob, time, nltk
import regex as re
from random import shuffle
# from .translator import translator

SLEEPTIME = 0.15

HANDATAFOLDER = os.path.dirname(os.path.realpath(__file__)) + '/handata/'

# fill known expression lists
KNOWN_SIMP = set()
# for filename in ['melou-simp.txt', 'unihan-simp.txt', 'sayjack-simp.txt', 'cjkdi-simp.txt']:
for filename in ['melou-simp.txt', 'unihan-simp.txt', 'sayjack-simp.txt', 'cldr-simp.txt']:
  with open(os.path.join(HANDATAFOLDER, filename), 'r') as f:
    for exp in f.readlines():
      if exp.strip():
        KNOWN_SIMP.add(exp.strip())

KNOWN_TRAD = set()
# for filename in ['melou-trad.txt', 'unihan-trad.txt', 'sayjack-trad.txt', 'cjkdi-trad.txt']:
for filename in ['melou-trad.txt', 'unihan-trad.txt', 'sayjack-trad.txt', 'cldr-trad.txt']:
  with open(os.path.join(HANDATAFOLDER, filename), 'r') as f:
    for exp in f.readlines():
      if exp.strip():
        KNOWN_TRAD.add(exp.strip())

# list derived from Wikipedia and added as encountered during mul:MeloU analysis
KNOWN_AMBI_SINGLES  = '与乾体余叶吒吨咤它帘广惊摺洁离篱虫虮踊麽'
KNOWN_AMBI_SINGLES += '内凄硅捱湊繙凼昵僮褵迴眯咨茍醣於扠皁罫置'
KNOWN_AMBI_SINGLES += '采𦊕丱卝'

# add more known single chars from file
# for filename in ['melou-ambi-single.txt', 'sayjack-ambi.txt', 'cjkdi-ambi-single.txt']:
for filename in ['melou-ambi-single.txt', 'sayjack-ambi.txt']:
  with open(os.path.join(HANDATAFOLDER, filename), 'r') as f:
    KNOWN_AMBI_SINGLES += ''.join(set(f.read().replace('\n','').strip()))

# make set
KNOWN_AMBI = set([c for c in KNOWN_AMBI_SINGLES])

# add rest of ambi expressions
for filename in ['melou-ambi.txt', 'cjkdi-ambi.txt']:
# for filename in ['melou-ambi.txt']:
  with open(os.path.join(HANDATAFOLDER, filename), 'r') as f:
    for exp in f.readlines():
      KNOWN_AMBI.add(exp.strip())

# variant forms
VARIANTS = {
  '衆' : '眾',
  '擡' : '抬',
}

# read IDS sequences into dict
IDS_DICT = {}
for f in glob.glob(os.path.join(HANDATAFOLDER, 'ids/*.txt')):
  for line in open(f, 'r').readlines():
    if line.strip() and not line.startswith(';'):
      line = line.split('\t')
      if len(line) == 3:
        IDS_DICT[line[1].strip()] = line[2].strip()

# throw components in a bag instead of keeping a sequence
IDS_DICT_BAGGED = {}
for key, val in IDS_DICT.items():
  IDS_DICT_BAGGED[key] = set(filter(None, re.split(r'(\p{Han}|&[^;]+;)', re.sub(r'[⿰⿱⿲⿳⿴⿵⿶⿷⿸⿹⿺⿻]', '', val))))

SIMP_CHARS = set()
TRAD_CHARS = set()
AMBI_CHARS = set()

for exp in KNOWN_SIMP:
  for char in exp:
    SIMP_CHARS.add(char)

for exp in KNOWN_TRAD:
  for char in exp:
    TRAD_CHARS.add(char)

for exp in KNOWN_AMBI:
  for char in exp:
    AMBI_CHARS.add(char)

KNOWN_SIMP_CHARS = SIMP_CHARS - (TRAD_CHARS | AMBI_CHARS)
KNOWN_TRAD_CHARS = TRAD_CHARS - (SIMP_CHARS | AMBI_CHARS)

# allocate vars for components classification
SIMP_COMPONENTS = set()
TRAD_COMPONENTS = set()

NBCLASSIFIER = None


class HanText:
  def __init__(self, string):
    self.string = string.strip().replace(' ','')
    # replace all variants
    self.string = ''.join([VARIANTS[c] if c in VARIANTS else c for c in self.string])
    self.simp = None
    self.trad = None
    self.scripts = set()
    has_known_simp = [character in KNOWN_SIMP_CHARS for character in self.string]
    has_known_trad = [character in KNOWN_TRAD_CHARS for character in self.string]
    # known simplified exp
    if self.string in KNOWN_SIMP or (True in has_known_simp and True not in has_known_trad):
      self.simp = self.string
      self.scripts = set(['Hans'])
    # known traditional exp
    elif self.string in KNOWN_TRAD or (True not in has_known_simp and True in has_known_trad):
      self.trad = self.string
      self.scripts = set(['Hant'])
    # known ambiguous exp, or just no Han
    elif self.string in KNOWN_AMBI or not re.search(r'\p{Han}', self.string):
      self.simp = self.string
      self.trad = self.string
      self.scripts = set(['Hans', 'Hant'])

    self.idsseqs = None
    self.idscomponents = None
    
  def original_string(self):
    return self.string

  def simplified(self):
    if not self.simp:
      self.get_scripts()
    return self.simp

  def traditional(self):
    if not self.trad:
      self.get_scripts()
    return self.trad

  def get_scripts(self):
    if not self.scripts:
      # STEP 1: use unique components to decide

      # first build SIMP_COMPONENTS and TRAD_COMPONENTS if they don't exist already
      global SIMP_COMPONENTS, TRAD_COMPONENTS, NBCLASSIFIER

      if not SIMP_COMPONENTS:

        print('building component repos and training data:')

        # build component sets
        # and data for classifier model
        nbc_traindata = []

        all_simp_components = set()
        print('- simplified')
        for ht in [HanText(ks) for ks in KNOWN_SIMP]:
          all_simp_components |= ht.components(cumulative=True)
          nbc_traindata.append((ht.get_features(), 'S'))
        all_trad_components = set()
        print('- traditional')
        for ht in [HanText(ks) for ks in KNOWN_TRAD]:
          all_trad_components |= ht.components(cumulative=True)
          nbc_traindata.append((ht.get_features(), 'T'))
        all_ambi_components = set()
        print('- ambiguous')
        for ht in [HanText(ks) for ks in KNOWN_AMBI]:
          all_ambi_components |= ht.components(cumulative=True)
          nbc_traindata.append((ht.get_features(), 'B'))

        SIMP_COMPONENTS = all_simp_components - (all_trad_components | all_ambi_components)
        TRAD_COMPONENTS = all_trad_components - (all_simp_components | all_ambi_components)

        # train Naive Bayes classifier
        print('shuffling data')
        shuffle(nbc_traindata)
        print('training classifier...')
        NBCLASSIFIER = nltk.NaiveBayesClassifier.train(nbc_traindata[:int(len(nbc_traindata)*19/20)])

        # accuracy test
        print('classifier accuracy:')
        print(nltk.classify.accuracy(NBCLASSIFIER, nbc_traindata[int(len(nbc_traindata)*19/20):]))
        # NBCLASSIFIER.show_most_informative_features(80)

      # now, use the components of the present exp to make a rule-based decision
      comp = self.components(cumulative=True)

      if comp & SIMP_COMPONENTS and not (comp & TRAD_COMPONENTS):
        self.simp = self.string
        self.scripts = set(['Hans'])

      elif not (comp & SIMP_COMPONENTS) and comp & TRAD_COMPONENTS:
        self.trad = self.string
        self.scripts = set(['Hant'])

      else:
        # STEP 2: use classifier to decide
        guess = NBCLASSIFIER.classify(self.get_features())

        probdist = NBCLASSIFIER.prob_classify(self.get_features())

        # self.script_probdist = {sample : probdist.prob(sample) for sample in probdist.samples()}

        if guess == 'S':
          self.simp = self.string
          self.scripts = set(['Hans'])
        elif guess == 'T':
          self.trad = self.string
          self.scripts = set(['Hant'])
        elif guess == 'B':
          self.simp = self.string
          self.trad = self.string
          self.scripts = set(['Hans', 'Hant'])
        else:
          raise ValueError('unexpected classification {}'.format(guess))

        # # STEP 3: translate using Google Translate API and compare
        # print('(GT API call: {})'.format(self.string))
        # tl_s = translator('zh', 'zh-CN', self.string)
        # time.sleep(SLEEPTIME)
        # tl_t = translator('zh', 'zh-TW', self.string)
        # time.sleep(SLEEPTIME)
        # self.simp = re.sub(r'\u200b', '', tl_s[0][0][0].strip())
        # self.trad = re.sub(r'\u200b', '', tl_t[0][0][0].strip())
        # self.scripts = set()
        # if self.simp == self.string:
        #   self.scripts.add('Hans')
        # if self.trad == self.string:
        #   self.scripts.add('Hant')
        # if not ('Hans' in self.scripts and 'Hant' in self.scripts):
        #   # if def one or the other, add to known to reduce api calls
        #   KNOWN_SIMP.add(self.simp)
        #   KNOWN_TRAD.add(self.trad)
        # if not self.scripts:
        #   # if no scripts, there is an ambiguous character problem. remove them and try again
        #   degraded_string = re.sub(r'[^\p{Han}]', '', self.string)
        #   degraded_string = re.sub(r'['+KNOWN_AMBI_SINGLES+r']', '', degraded_string)
        #   # if the degraded string is empty, just assume the string ambiguous
        #   if not degraded_string.strip():
        #     self.simp = self.string
        #     self.trad = self.string
        #     self.scripts = set(['Hans', 'Hant'])
        #   else:
        #     print('(GT API call: {})'.format(degraded_string))
        #     tl_s_d = translator('zh', 'zh-CN', degraded_string)
        #     time.sleep(SLEEPTIME)
        #     tl_t_d = translator('zh', 'zh-TW', degraded_string)
        #     time.sleep(SLEEPTIME)
        #     simp_d = re.sub(r'\u200b', '', tl_s_d[0][0][0].strip())
        #     trad_d = re.sub(r'\u200b', '', tl_t_d[0][0][0].strip())
        #     if simp_d == degraded_string:
        #       self.simp = self.string
        #       self.scripts.add('Hans')
        #     if trad_d == degraded_string:
        #       self.trad = self.string
        #       self.scripts.add('Hant')
        #     # if there's still an issue, JUST GIVE UP
        #     if not self.scripts:
        #       raise ValueError('could not determine script: {}'.format(self.string))
    return self.scripts

  def is_simp_only(self):
    scripts = self.scripts if self.scripts else self.get_scripts()
    return 'Hans' in scripts and 'Hant' not in scripts

  def is_trad_only(self):
    scripts = self.scripts if self.scripts else self.get_scripts()
    return 'Hans' not in scripts and 'Hant' in scripts

  def is_simp_and_trad(self):
    scripts = self.scripts if self.scripts else self.get_scripts()
    return 'Hans' in scripts and 'Hant' in scripts

  def cmnvar(self):
    if self.is_simp_only():
      return '0'
    elif self.is_trad_only():
      return '1'
    elif self.is_simp_and_trad():
      return '2'
    else:
      raise Exception('this should never happen')

  def seqs(self):
    # return CHISE ideographic description sequence (IDS) for each character
    if not self.idsseqs:
      self.idsseqs = [list(filter(None, re.split(r'([⿰⿱⿲⿳⿴⿵⿶⿷⿸⿹⿺⿻\p{Han}]|&[^;]+;)', IDS_DICT[c]))) if c in IDS_DICT else '' for c in self.string]
    return self.idsseqs

  def components(self, depth=0, cumulative=False):
    # return component elements from IDS only, as a set.
    # 0 defaults to deepest
    # cumulative=True returns set of components from all levels up to given depth
    if not self.idscomponents:
      self.idscomponents = {}
      # make depth=1 set
      self.idscomponents[1] = set()
      for char in self.string:
        if char in IDS_DICT_BAGGED:
          for component in IDS_DICT_BAGGED[char]:
            self.idscomponents[1].add(component)
      # go as deep as possible
      done = False
      i = 1
      while not done:
        component_set_curr = set()
        for char in self.idscomponents[i]:
          if char in IDS_DICT_BAGGED:
            for component in IDS_DICT_BAGGED[char]:
              component_set_curr.add(component)
          else:
            component_set_curr.add(char)
        if component_set_curr == self.idscomponents[i]:
          done = True
        else:
          i += 1
          self.idscomponents[i] = component_set_curr
    if depth < 1 or depth > max(self.idscomponents.keys()):
      depth = max(self.idscomponents.keys())
    if cumulative:
      cumul = set()
      for d in range(1,depth+1):
        cumul |= self.idscomponents[d]
      return cumul
    else:
      return self.idscomponents[depth]

  def get_features(self):
    features = {}
    for char in re.sub(r'[^\p{Han}]', '', self.string):
      features["char({})".format(char)] = True
    for i in range(len(self.string)-1):
      features[ "charbigram({})".format(self.string[i:i+2])] = True
    for j in range(len(self.string)-2):
      features["chartrigram({})".format(self.string[j:j+3])] = True
    for comp in self.components(cumulative=True):
      features["comp({})".format(comp)] = True
    for seq in self.seqs():
      if seq:
        for i in range(len(seq)-1):
          features[ "seqbigram({})".format(seq[i:i+2])] = True
        for j in range(len(seq)-2):
          features["seqtrigram({})".format(seq[j:j+3])] = True
    return features

  def __len__(self):
    return len(self.string)
