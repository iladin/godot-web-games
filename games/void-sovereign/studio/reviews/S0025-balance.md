# S0025 Balance report (void-sovereign)

Game code changed since S0019 (VS-029 The Breach: 4 station-only Hive drones at 6:00, plus save work VS-026/027/028). 9 seeds (101..237, offsets 0/3/6). --perturb A/B not run this session.

## 1. Targets
| Metric | Measured (median, IQR q1-q3, min/max) | Target | Status |
|---|---|---|---|
| Passive: HQ lost at | 36.0 min, 31.9->40 (survived 3/9; lost seeds 27.7-37.5) | 20-35 | WARN (1 min over; was 33.6) |
| Econ: nw at 10 min | 94,132, 86,154-103,584 (min 81,323 / max 108,651) | >= 45,000 | OK |
| Econ: nw at 20 min | 110,509, 99,032-138,070 (min 98,289 / max 147,679) | >= 90,000 | OK |
| Econ: HQ survives 30 min | 9/9 | >= 6/9 | OK |
| Union collapse in econ | none (>30), 0/9 | not before 20 min | OK |
| First Hive raid | 3.3 min (q1=q3) | 3-4 | OK |
| Hive ships at 20 min (econ) | 61, 55-63 (passive 53, 52-59) | <= 60 | WARN (median 1 over; was 58) |
| Surface L1 with bot | pylons down ~50 s, core ~58 s, no crash | pylons within 60 s | OK |

Econ nw30: median 167,205, IQR 130,364-171,546, min 36,756 (seed 101), max 191,995. Union ships @20 econ: 13 (13-14). Passive union collapse median 35.1 (IQR 32.5->40).

## 2. Trend vs S0019
- Econ nw10 93,194 -> 94,132; nw20 107,685 -> 110,509; nw30 142,176 -> 167,205 (better), but nw30 floor is 36,756 (S0019 60,319).
- Hive ships @20 econ 58 -> 61 (over the web guard); union ships 12 -> 13.
- Passive: HQ lost 33.6 -> 36.0, survived 2/9 -> 3/9, IQR now straddles the 40-min horizon. The Breach apparently moved passive pressure the wrong way (S0020 dev's "median 28.3" was one seed, as S0021 noted).
- Passive nw20 63,766 vs 67,426.

## 3. Recommendations
1. Passive HQ-lost 36.0 (> 35): the Breach is the only new Hive pressure, and it is a one-off, so it should not slow the Hive; likely side effect is the changed RNG stream shifting later raids. Levers in `defs.gd`: `BREACH_SIZE` 4 -> 6 and/or `BREACH_TIME` 360 -> 300, to make passive play bleed earlier. Expected: passive HQ-lost median toward ~33. Do not touch DREAD_TIME (1200) first; it was tuned for this in S0018. A/B on 9 seeds, check median moves beyond IQR.
2. Hive ships @20 econ 61 (> 60): watch; if it persists, lower the Hive production cap before minute 20 rather than touching raid timing. Not worth a change on a 1-ship median overrun with q1-q3 55-63 until confirmed with --perturb=1.
3. Econ nw30 floor 36,756 (seed 101): single-seed tail collapse, median healthy; no change, re-check with --perturb=1 next session.

Method: gate dirs `.tools/balance_gate/void-sovereign_economic_30`, `void-sovereign_passive_40` (fresh runs; an initial parallel passive attempt timed out from CPU contention and was rerun sequentially). FPS check: `--shot=surface_long` ran headless to 6000 frames without script errors (only usual leak warnings at exit).
