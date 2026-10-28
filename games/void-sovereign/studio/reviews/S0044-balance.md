# S0044 Balance report (void-sovereign, 9 seeds 101..237, sim unchanged vs S0037)

| Metric | Median (IQR q1-q3; min/max) | Target | Status |
|---|---|---|---|
| Passive: HQ lost at | 28.9 min (28.6-35.8; 27.8/38.5), 0/9 survived | 20-35 | OK (q3 35.8 slightly over) |
| Economic NW @10 | 94,229 (92,673-103,159) | >=45,000 | OK |
| Economic NW @20 | 120,726 (107,023-143,673; min 101,622) | >=90,000 | OK |
| Economic HQ survives 30 min | 9/9 | >=6/9 | OK |
| Union collapse (economic) | never in 30 min (9/9) | not before 20 | OK |
| First Hive raid | 3.3 min | 3-4 | OK |
| Hive ships @20 (economic) | 52 (51-60) | <=60 | OK |
| Hive ships @20 (passive) | 59 (53-61) | <=60 | WARN: q3 61 over guard, median 1 under |
| Surface L1 bot | pylons down ~55 s (core 67 s) | <=60 s | OK (thin margin) |

Extra: economic nw30 median 167,939 (IQR 106,586-183,894; min 88,091, max 240,063). Passive union collapse median 31.7.

## Trend
Economic and passive results are identical to S0037 (same seeds, sim unchanged; S0043 was a non-sim session). Surface pylons 51 s -> 55 s (S0037 -> now), margin to 60 s shrinking.

## Recommendations
1. Passive hive ships @20 (59, q3 61): no change needed for the targets, but to get margin lower the Hive passive spawn cap/rate in defs.gd (one lever: the Hive ship-cap or spawn interval; propose cap -5%, e.g. ~-3 ships at t=20). Verify with 9-seed passive run and --perturb=1 before accepting. Only act if the web performance guard is actually hit in play; the economic player stays at 52.
2. Surface pylon time creeping (51 -> 55 s): watch; if it passes 60 s, reduce pylon HP or bot-visible defender count on level 1.
No other misses.
