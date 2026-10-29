# S0056 Balance report (void-sovereign, 9 seeds 101..237, HEAD c73659a: VS-059/VS-060 Fleet Reserve)

Device note: runs were slower than in S0010 (3 seeds economic 30 = ~105 s), so each seed offset was run in its own call (GATE_OFFSETS 0 / 3 / 6; passive: 0, then "3 6"). Results are identical to S0052 per seed, i.e. Fleet Reserve (VS-059/060) does not change default-policy sim outcomes.

| Metric | Median (IQR q1-q3; min/max) | Target | Status |
|---|---|---|---|
| Passive: HQ lost at | 25.8 min (23.1-27.7; 21.1/30.9), 0/9 survived | 20-35 | OK |
| Economic NW @10 | 97,689 (95,083-102,104; 89,760/106,932) | >=45,000 | OK |
| Economic NW @20 | 120,755 (110,891-123,911; 95,747/140,648) | >=90,000 | OK |
| Economic HQ survives 30 min | 9/9 | >=6/9 | OK |
| Union collapse (economic) | never in 30 min (9/9) | not before 20 | OK |
| First Hive raid | 3.3 min (all seeds) | 3-4 | OK |
| Hive ships @20 (economic) | 56 (51-60) | <=60 | OK (q3 at limit) |
| Hive ships @20 (passive) | 60 (56-65) | <=60 | WARN: median at limit, q3 65 |
| Surface L1 bot | pylons down 55.4 s, core 67.1 s | <=60 s | OK (unchanged) |

Extra: economic nw30 median 168,407 (IQR 146,057-174,636; min 116,462 seed 101, max 196,653). Economic union ships @20: 11 (7-13). Passive nw10 59,653, nw20 69,152; passive union collapse > 40 min. Perturb A/B not run (sim unchanged vs S0052, which ran --perturb=1: HQ 8/9).
FPS check: surface_long headless ran to completion; no script errors (only a Godot shutdown leak warning at exit).

## Trend (vs S0052 and S0050)
- Economic: identical to S0052 (nw30 168,407; HQ 9/9). Versus S0050 (nw30 122,997, HQ 8/9) the Hive cap (VS-056) improved Q1 (48k -> 146k) and removed the lost seed; hive_ships_20 61 -> 56.
- Passive: HQ lost median 27.3 (S0050) -> 25.8 (S0052, now); IQR 24.7-27.6 -> 23.1-27.7; earliest 21.1 (margin 1.1 min above the 20 floor).
- Passive hive_ships_20 median 59 -> 60, q3 61 -> 65: creeping up with earlier collapse (more time for Hive growth).
- Surface pylon time 55 s unchanged.

## Recommendations
1. Passive Hive ships @20 (q3 65, median 60): the cap lowered economic ships but passive is above guard in the upper half. Lever: Hive t/126 cap in defs.gd (VS-056 value) - lower the cap ~5-8% (about -4 ships at t=20) or slow Hive spawn rate once player fleet is under 3 ships. Verify with 9-seed passive and economic; economic must keep HQ >= 8/9.
2. Passive earliest HQ loss 21.1 min is close to the 20 floor: do not strengthen Hive raid damage; recommendation 1 also helps here.
3. Surface pylon 55 s: watch, no change. No change needed for economic targets.
