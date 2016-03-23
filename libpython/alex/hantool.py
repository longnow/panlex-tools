#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# Convert/confirm traditional/simplified Han character text,
# using Google Translate API.

import regex as re
from translator import translator
from time import sleep

ambi_chars = '苧斗台板杯辟表卜布才彩虫丑仇出村粗酬党淀吊冬范丰谷雇刮广哄后伙几机奸姜借据卷克困夸累厘漓梁了霉蔑么麽苹仆朴确舍沈胜松他你体同涂喂咸弦熏腌叶佣涌游于余吁郁欲御愿岳云扎占折征志制致种周注准冢庄蚕忏吨赶构柜怀坏极茧家价洁惊腊蜡帘怜岭扑秋千确扰洒晒适听洼网旋踊优症朱荐离气圣万与虮篱泞托咽曲升系胡划回里向只它并采厂干蒙面复斗台著兒乾夥藉瞭摺徵'

# weird additional ones
ambi_chars += '内'

# variants
VARIANTS = {
  '衆' : '眾',
}


class HanText:
  def __init__(self, string):
    self.string = string.strip().replace(' ','')
    # replace all variants
    self.string = ''.join([VARIANTS[c] if c in VARIANTS else c for c in self.string])
    # check for ambiguous (s+t) single character
    if len(self.string) == 1 and self.string in ambi_chars:
      self.simp = self.string
      self.trad = self.string
      self.scripts = ['Hans', 'Hant']
    else:
      tl_s = translator('zh', 'zh-CN', self.string)
      sleep(0.5)
      tl_t = translator('zh', 'zh-TW', self.string)
      sleep(0.5)
      self.simp = re.sub(r'\u200b', '', tl_s[0][0][0].strip())
      self.trad = re.sub(r'\u200b', '', tl_t[0][0][0].strip())
      self.scripts = []
      if self.simp == self.string:
        self.scripts.append('Hans')
      if self.trad == self.string:
        self.scripts.append('Hant')
      if not self.scripts:
        # if no scripts, there is an ambiguous character problem, remove them and try again
        degraded_string = re.sub(r'['+ambi_chars+r']', '', self.string)
        tl_s_d = translator('zh', 'zh-CN', degraded_string)
        sleep(0.5)
        tl_t_d = translator('zh', 'zh-TW', degraded_string)
        sleep(0.5)
        simp_d = re.sub(r'\u200b', '', tl_s_d[0][0][0].strip())
        trad_d = re.sub(r'\u200b', '', tl_t_d[0][0][0].strip())
        if simp_d == degraded_string:
          self.simp = self.string
          self.scripts.append('Hans')
        if trad_d == degraded_string:
          self.trad = self.string
          self.scripts.append('Hant')
    
  def original_string(self):
    return self.string

  def scripts(self):
    return self.scripts

  def is_simp_only(self):
    return 'Hans' in self.scripts and 'Hant' not in self.scripts

  def is_trad_only(self):
    return 'Hans' not in self.scripts and 'Hant' in self.scripts

  def is_simp_and_trad(self):
    return 'Hans' in self.scripts and 'Hant' in self.scripts

  def __len__(self):
    return len(self.string)
