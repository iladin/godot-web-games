# S0069 Balance report (HEAD 589f662: VS-075 Defense Platform 24000, NEST_CAP_GROWTH 145)

Method: balance_gate.sh, 9 seeds (101..237): economic 30 min in one call (157 s); passive 40 min as offsets "0 3" then "6". No perturb A/B (sim unchanged since S0068). Economic result is identical to the S0068 trial, so the sim is deterministic and S0068 is confirmed as HEAD state.

## 1. Measured vs targets
| Metric | Measured (median, IQR q1-q3, min/max) | Target | Status |
|---|---|---|---|
| Passive: HQ lost at | 28.4 min (23.7-31.2; 19.2 / 35.0; seed 101 survives 40) | 20-35 | OK on median; earliest 19.2 (seed 169) and 203 at 22.1 near edge |
| Economic nw10 | 97,656 (92,910-100,064; 89,726 / 107,131) | >= 45,000 | OK |
| Economic nw20 | 105,464 (94,705-114,462; 44,022 / 140,579) | >= 90,000 | OK median; seed 135 = 44,022 below |
| Economic HQ survives 30 min | 9/9 | >= 6 of 9 | OK |
| Economic nw30 | 132,396 (115,699-160,503; 70,720 / 180,075) | median >= 120k, Q1 >= 90k | OK (first time met) |
| Union collapse, economic | none in 9 seeds | not before 20 min | OK |
| First Hive raid | 3.3 min all seeds | 3-4 | OK |
| Hive ships at 20 min, economic | 48 (47-49) | <= 60 | OK |
| Hive ships at 20 min, passive | 58 (55-62) | <= 60 | OK median; q3 62 over |
| Surface L1 bot | pylons down 55.4 s (core 67.1, boarded 84.1) | <= 60 s | OK |

Targets met: 9 of 9 on medians. Extras: passive nw10 61,895, nw20 66,058, union collapse 28.9 (26.9 to >40), union ships @20 passive 10 (6-12); economic union ships @20 11 (9-13). Surface FPS run completed in 8 s wall, no script errors (only exit-time leak warnings).

## 2. Trend vs last rows (S0068 economic, S0062 passive)
- Economic: identical to S0068 (deterministic). Versus S0062 (NEST 145): nw30 median 106,269 -> 132,396, Q1 94,217 -> 115,699, HQ 8/9 -> 9/9, Hive ships @20 53 -> 48.
- Passive: HQ loss median 28.2 -> 28.4, IQR 24.8-29.4 -> 23.7-31.2 (wider), earliest 23.6 -> 19.2 (seed 169, now under the 20 min lower bound), Hive ships @20 56 -> 58. Note the platform-cost change shouldn't alter the Hive; the passive policy likely also buys platforms/ships, so passive Union defence shifted and the spread moved.

## 3. Recommendations
1. Passive earliest loss 19.2 min (seed 169) is below the 20-35 band, though the median is fine. Only act if the band is meant per-seed: trial NEST_CAP_GROWTH 140 is known to fail the earliest gate, so instead keep 145 and watch; if it recurs, lower first-wave Hive pressure by one lever only (e.g. the 20-min raid size/interval) and re-run passive 9 seeds.
2. Economic seed 135 nw20 = 44,022 (nw30 70,720, lowest): single-seed dip, HQ survives; no change, watch.
3. Passive Hive ships @20 q3 62 > 60: marginal; no change on median.
No code was edited.
