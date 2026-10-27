QA REPORT — verify:VS-034 — S0025
Verdict: PASS
Criteria:
- [x] BREACH_SIZE 4->6 only; DREAD_TIME untouched — git diff of defs.gd shows only that line (plus file-mode change 644->755, harmless).
- [x] 9-seed passive median HQ-lost in 20-35 — passive 40, fresh GATE_OUT qa25_pas40, seeds 101..237: median 28.3 (Q1 27.2, Q3 32.7), HQ survived 1/9, range 24.2-35.9 (one survivor, one at 35.9).
- [x] Econ gates — economic 30, 9 seeds fresh: nw20 median 113,629 (>=90k), HQ 9/9 (>=6/9), first raid 3.3 min (3-4), Hive ships@20 median 51 (<=60).
- [x] --perturb=1 reported — economic 20 perturb=1, 9 seeds: nw20 median 122,770, HQ 9/9, first raid 3.3, Hive ships@20 median 54 (Q3 61).
Regression: bash scripts/check.sh void-sovereign -> PASS. combat_long headless 6000 frames: 0 SCRIPT ERROR/Parse/Invalid lines (only the usual exit-time "resources still in use" engine note). No screenshots taken: change is one sim constant, no UI/rendering touched.
Bugs: none.
Notes for Producer:
- All developer numbers reproduced exactly (28.3, 113.6k, 3.3, 51, 122.8k).
- Passive survivors/tail: 1/9 survives to 40 min and seed 186 dies at 35.9, so the upper tail sits right at the 35 edge; the median criterion is met but margin on Q3 is thin only in the sense of the max.
- Passive Hive ships@20 median is 61 (not gated; econ gate is 51).
- VS-029 gap: the "every run sees a raid reach HQ" intent is met by the breach; the passive 1/9 survivor (seed 169) is a remaining gap if strict.
