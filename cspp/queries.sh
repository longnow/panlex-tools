#!/bin/bash

psql -A -t -F $'\t' plx << 'EOQ'

\o mcs.txt

SELECT lcvc(lv0.lc, lv0.vc), ex0.tt, lcvc(lv1.lc, lv1.vc), ex1.tt, count(*)
FROM mcs
JOIN ex ex0 ON (ex0.ex = mcs.ex0)
JOIN lv lv0 ON (lv0.lv = ex0.lv)
JOIN ex ex1 ON (ex1.ex = mcs.ex1)
JOIN lv lv1 ON (lv1.lv = ex1.lv)
WHERE ex0.tt NOT IN ('HasContext', 'IsA', 'RelatedTo', 'antonym', 'Causative_of', 'Inchoative_of')
    AND lcvc(lv0.lc, lv0.vc) NOT IN ('art-331')
GROUP BY lcvc(lv0.lc, lv0.vc), ex0.tt, lcvc(lv1.lc, lv1.vc), ex1.tt
ORDER BY lcvc(lv0.lc, lv0.vc), ex0.tt, lcvc(lv1.lc, lv1.vc), ex1.tt
;

\o dcs.txt

SELECT lcvc(lv0.lc, lv0.vc), ex0.tt, lcvc(lv1.lc, lv1.vc), ex1.tt, count(*)
FROM dcs
JOIN ex ex0 ON (ex0.ex = dcs.ex0)
JOIN lv lv0 ON (lv0.lv = ex0.lv)
JOIN ex ex1 ON (ex1.ex = dcs.ex1)
JOIN lv lv1 ON (lv1.lv = ex1.lv)
WHERE ex0.tt NOT IN ('etymology(icl>linguistics>thing)', 'BoundMorpheme', 'Stem', 'derivedForm', 'idiom', 'reduplication')
GROUP BY lcvc(lv0.lc, lv0.vc), ex0.tt, lcvc(lv1.lc, lv1.vc), ex1.tt
ORDER BY lcvc(lv0.lc, lv0.vc), ex0.tt, lcvc(lv1.lc, lv1.vc), ex1.tt
;

\o dpp.txt

SELECT lcvc(lv0.lc, lv0.vc), ex0.tt, count(*)
FROM dpp
JOIN ex ex0 ON (ex0.ex = dpp.ex)
JOIN lv lv0 ON (lv0.lv = ex0.lv)
GROUP BY lcvc(lv0.lc, lv0.vc), ex0.tt
ORDER BY lcvc(lv0.lc, lv0.vc), ex0.tt
;

\o mpp.txt

SELECT lcvc(lv0.lc, lv0.vc), ex0.tt, count(*)
FROM mpp
JOIN ex ex0 ON (ex0.ex = mpp.ex)
JOIN lv lv0 ON (lv0.lv = ex0.lv)
GROUP BY lcvc(lv0.lc, lv0.vc), ex0.tt
ORDER BY lcvc(lv0.lc, lv0.vc), ex0.tt
;

EOQ
