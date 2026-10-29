# S0062 Balance report (HEAD with NEST_CAP_GROWTH 145, VS-064)

Method: balance_gate.sh, 9 seeds (101..237), economic 30 min and passive 40 min, run one offset per call (device slower than S0010: ~100 s per 3 economic seeds). Perturb A/B not run (sim unchanged since S0061).

## 1. Measured vs targets
| Metric | Measured (median, IQR q1-q3, min/max) | Target | Status |
|---|---|---|---|
| Passive: HQ lost at | 28.2 min (24.8-29.4; 23.6 / 31.9; 0/9 survive) | 20-35 | OK |
| Economic nw10 | 93,427 (86,624-94,035; 78,462 / 102,174) | >= 45,000 | OK |
| Economic nw20 | 104,590 (83,512-140,708; 63,373 / 173,939) | >= 90,000 | OK on median; q1 and 2/9 seeds below |
| Economic HQ survives 30 min | 8/9 (seed 186 lost at 23.7) | >= 6 of 9 | OK (thin) |
| Economic nw30 (no target) | 106,269 (94,217-144,914; 0 [HQ lost] / 257,293) | n/a | info, see trend |
| Union collapse, economic | seed 220 at 26.7; other 8 never; median > 30 | not before 20 min | OK |
| First Hive raid | 3.3 min all seeds | 3-4 | OK |
| Hive ships at 20 min, economic | 53 (50-59; 45 / 69) | <= 60 | OK median; seed 135 = 69, seed 152 = 63 over |
| Hive ships at 20 min, passive | 56 (49-60) | <= 60 | OK (q3 at limit) |
| Surface L1 bot | pylons down 56 s, core exposed at 56 s | <= 60 s | OK |

Targets met: 9 of 9 on medians. Passive extras: nw10 61,863 (60,241-63,352), nw20 64,550 (63,208-70,866), union collapse 31.0 (27.7 to >40), union ships @20 8 (8-13). Economic union ships @20: 12 (10-14; 7 / 17). FPS/surface_long run completed with no script errors.

## 2. Seed 186 re-check (economic)
Reproduced exactly: HQ lost at 23.7 min (deterministic, same as S0061). nw10 78,462 (lowest of 9), nw20 63,373 (lowest of 9), nw30 0; Union ships @20 = 9, Hive ships @20 = 55 (normal). So it is not a Hive over-cap; the player economy in 186 is the weakest from the start (nw10 -16% vs median) and cannot field enough defense when the cap-145 raids land. Passive seed 186 lasts longest (31.9), so the loss is player-policy-specific, not a Hive-strength outlier. It is the only economic seed lost, so 8/9 leaves a 2-seed margin over the >= 6 target.

## 3. Trend (vs S0056 / S0052 economic, 9-seed)
- HQ survived 9/9 -> 8/9.
- nw10 median 97,689 -> 93,427; nw20 median 120,755 -> 104,590 (q1 110,891 -> 83,512).
- nw30 median 168,407 -> 106,269 (-37%); q1 146,057 -> 94,217; 4 of 9 seeds are below 107k. This is a large economic regression from the larger Hive cap growth (126 -> 145) that the target table does not capture (no nw30 target), but it is the biggest change.
- Hive ships @20 56 -> 53 (economic), passive 60 -> 56; passive HQ loss median 25.8 -> 28.2, earliest 21.1 -> 23.6 (more margin above 20; this was the goal of VS-064).
- Union ships @20 economic 11 -> 12.

## 4. Recommendations
1. Economic nw30 collapse (168k -> 106k) and seed 186 loss: this is the cost of NEST_CAP_GROWTH 145. Try 135 (between 126 and 140; 140 failed the earliest-HQ-loss gate per S0061 notes, so test 135 first and also check passive earliest >= 22). Expected: economic HQ back toward 9/9, nw30 median rising toward ~130k, passive median ~27.
2. If 135 fails the passive gate, keep 145 and instead raise the economic-side defense rather than weakening the Hive: e.g. Union/Sovereign warship cost down ~10% (defs.gd ship cost for the Sovereign warship) so the weak-economy seeds (186: nw10 78k) can afford a fleet before 20 min.
3. Add a nw30 target (suggest median >= 120,000, Q1 >= 90,000) to the role table so this regression is visible to the gate.
4. Hive ships @20: seed 135 reaches 69; no change needed on the median, watch only.
