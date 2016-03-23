#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# Convert/confirm traditional/simplified Han character text,
# using Google Translate API.

from translator import translator
from time import sleep

ambi_chars = '苧斗台板杯辟表卜布才彩虫丑仇出村粗酬党淀吊冬范丰谷雇刮广哄后伙几机奸姜借据卷克困夸累厘漓梁了霉蔑么麽苹仆朴确舍沈胜松他你体同涂喂咸弦熏腌叶佣涌游于余吁郁欲御愿岳云扎占折征志制致种周注准冢庄蚕忏吨赶构柜怀坏极茧家价洁惊腊蜡帘怜岭扑秋千确扰洒晒适听洼网旋踊优症朱荐离气圣万与虮篱泞托咽曲升系胡划回里向只它并采厂干蒙面复斗台著兒乾夥藉瞭摺徵'

class HanText:
  def __init__(self, string):
    self.string = string.strip()
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
      self.simp = tl_s[0][0][0]
      self.trad = tl_t[0][0][0]
      self.scripts = []
      if self.simp == self.string:
        self.scripts.append('Hans')
      if self.trad == self.string:
        self.scripts.append('Hant')
    
  def original_string(self):
    return self.string

  def simplified(self):
    return self.simp

  def traditional(self):
    return self.trad

  def scripts(self):
    return self.scripts

  def is_simp(self):
    return 'Hans' in self.scripts

  def is_trad(self):
    return 'Hant' in self.scripts

  def is_both(self):
    return is_simp(self) and is_trad(self)

  def __len__(self):
    return len(self.string)

