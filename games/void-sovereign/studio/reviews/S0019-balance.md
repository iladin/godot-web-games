# S0019 Balance report (void-sovereign)

No game code changed since S0018; all results are byte-identical to S0018 (determinism check passed). 9 seeds (101..237, offsets 0/3/6).

## 1. Targets
| Metric | Measured (median, IQR q1-q3, min/max) | Target | Status |
|---|---|---|---|
| Passive: HQ lost at | 33.6 min, 29.5-37.1 (survived 2/9; lost-at seeds min 28.1) | 20-35 | OK |
| Econ: nw at 10 min | 93,194, 87,045-101,947 (min 80,858 / max 113,548) | >= 45,000 | OK |
| Econ: nw at 20 min | 107,685, 103,498-126,954 (min 93,266 / max 165,264) | >= 90,000 | OK (all 9 seeds >= 93k) |
| Econ: HQ survives 30 min | 9/9 | >= 6/9 | OK |
| Union collapse in econ | none in 30 min (>30), 0/9 | not before 20 min | OK |
| First Hive raid | 3.3 min (q1=q3=3.3) | 3-4 | OK |
| Hive ships at 20 min (econ) | 58, 53-61 (passive 53, 51-58) | <= 60 | OK (median; q3 61, S0012 max 75 -> thin) |
| Surface L1 with bot (surface_long) | pylons down by ~50 s, core dead ~58 s | pylons within 60 s | OK |

Econ nw30: median 142,176, IQR 107,115-161,232, min 60,319 (seed 186), max 227,978. Union ships at 20 min: 12 (11-15).

## --perturb=1 econ re-run (robustness)
| Metric | Perturbed | Unperturbed |
|---|---|---|
| nw10 | 102,809 (91,295-105,018) | 93,194 |
| nw20 | 126,353 (89,889-136,592), min 52,126 (seed 118) | 107,685 |
| nw30 | 129,014 (65,783-179,319), min 46,089 (seed 169) | 142,176 |
| HQ survived | 9/9 | 9/9 |
| Hive ships @20 | 56 (52-60) | 58 |
| Union ships @20 | 10 (9-11) | 12 |

Medians still pass every target, but the spread is wide: nw20 < 90,000 in 3/9 seeds (52,126; 89,889; 89,374), and nw30 < 90,000 in 4/9 (72,798; 46,089; 65,783; 59,035). nw30 < nw20 in 3/9. The margin is thin in the tail, not in the median; economic collapses mid-game are chaos-driven (late raids on the player economy), consistent with S0018.

## 2. Trend vs last rows (S0018)
Identical in every metric (econ nw10 93,194 / nw20 107,685, hive 58, union 12; passive HQ lost 33.6, IQR 29.5-37.1, 2/9). Passive first/hive ship counts unchanged. No regression.

## 3. Recommendations
No target is red, so no constant change is required. Optional, for tail robustness only (do not apply without A/B vs 9-seed IQR and --perturb=1):
- Perturbed nw20/nw30 floor: the lever is `RAID_DETER_RANGE` (currently 3400) or late-raid pressure (`DREAD_TIME` 1200 already applied); try a small RAID_DETER_RANGE bump (3400 -> 3800) and check that perturbed nw30 <90k seeds fall from 4/9 to <=3/9 without pushing passive HQ-lost past 35 min.
- Hive ships @20 q3 is 61 (limit 60): watch only; if a future change lifts it, lower the Hive production cap before the 20-minute mark rather than touching raid timing.
- Passive HQ-lost median 33.6 sits 1.4 min under the 35 ceiling; do not slow Hive pressure further.

Method: GATE_OUT fresh dirs `.tools/balance_gate/s19_econ`, `s19_pert`, `s19_pas`. FPS check run as `--shot=surface_long` (headless, no crash, ~6.6 s wall for 6000 frames).
