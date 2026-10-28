# S0037 Balance report (void-sovereign, 9-seed gate, seeds 101..237)

| Metric | Measured (median, IQR q1-q3, min/max) | Target | Status |
|---|---|---|---|
| Passive: HQ lost at | 28.9 min, IQR 28.6-35.8, min 27.8 / max 38.5 (0/9 survive 40 min) | 20-35 | OK |
| Economic: nw10 | 94,229, IQR 92,673-103,159, min 88,377 / max 109,211 | >= 45,000 | OK |
| Economic: nw20 | 120,726, IQR 107,023-143,673, min 101,622 / max 177,952 | >= 90,000 | OK |
| Economic: HQ survives 30 min | 9/9 | >= 6/9 | OK |
| Economic: Union collapse | never (9/9 keep ships); union ships@20 median 11 (IQR 9-15) | not before 20 min | OK |
| First Hive raid | 3.3 min (all seeds) | 3-4 | OK |
| Hive ships @20 (economic) | 52, IQR 51-60 | <= 60 | OK (q3 at limit) |
| Hive ships @20 (passive) | 59, IQR 53-61 | <= 60 | Warn (q3 61, over guard) |
| Surface L1 bot | pylons down at ~51 s (pylon1 45 s, core 64.7 s) | <= 60 s | OK |

Extra: economic nw30 median 167,939, IQR 106,586-183,894, min 88,091 (seed 203) / max 240,063; nw30 < nw20 in 3/9 seeds (135, 186, 203). Perturb not run.

## Trend vs last rows (S0031)
- Economic: nw10 94,243 -> 94,229 (flat); nw20 104,020 -> 120,726 (+16%); hive ships@20 50 -> 52; union ships@20 11 -> 11; nw30 122,357 -> 167,939 (high variance, IQR overlaps).
- Passive: HQ lost 31.9 -> 28.9 (earlier, still inside 20-35 band; 0/9 survive vs 1/9); hive ships@20 53 -> 59; nw10 62,509 -> 62,130; nw20 65,736 -> 67,408.
- The passive Hive is somewhat stronger than S0031 (3 min faster median kill, +6 ships@20), and a passive median of 28.9 is now close to the lower-middle of the band, with q1 28.6 still above 20.

## Recommendations
No target is missed (8 OK, 1 warning), so no change is required. Watch items:
1. Passive Hive ships@20 (59, q3 61) sits on the 60 web-performance guard. If it creeps further, lower the Hive ship cap or spawn-rate constant in `scripts/sim/defs.gd` (the Hive reinforcement/cap constant) by about 5% (for example the per-wave size or cap -5%), expected -2 to -3 ships@20 with a small effect on HQ-loss time (about +1 min). Do not touch it while passive HQ loss trends earlier than 28 min.
2. Economic nw30 < nw20 in 3/9 seeds (late-game attrition erodes net worth); not a target, but monitor. A single lever would be Union ship repair/replacement cost in `defs.gd`.
Note: a combined 3-offset economic call hit the device timeout (offsets 0/3 died, 6 finished); ran "0 3" (113 s) then re-summarised. Passive was split 0 3 / 6 as documented.
