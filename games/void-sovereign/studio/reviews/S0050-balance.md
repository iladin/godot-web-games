# S0050 Balance report (void-sovereign, 9 seeds 101..237, HEAD 686060f: raid chip 0.015/ship, bot HQ repair)

Note: no S0048/S0049 balance review files exist; comparison uses metrics.csv rows (S0044/S0046/S0048) and reviews/S0049-redirect-ab.txt.

| Metric | Median (IQR q1-q3; min/max) | Target | Status |
|---|---|---|---|
| Passive: HQ lost at | 27.3 min (24.7-27.6; 22.1/32.0), 0/9 survived | 20-35 | OK |
| Economic NW @10 | 94,229 (92,673-99,324; 88,377/107,600) | >=45,000 | OK |
| Economic NW @20 | 104,952 (103,637-115,694; min 62,191 seed 135) | >=90,000 | OK |
| Economic HQ survives 30 min | 8/9 (seed 135 lost at 29.7 min) | >=6/9 | OK |
| Union collapse (economic) | never in 30 min (9/9) | not before 20 | OK |
| First Hive raid | 3.3 min (all seeds) | 3-4 | OK |
| Hive ships @20 (economic) | 61 (52-61) | <=60 | WARN: median 1 over guard |
| Hive ships @20 (passive) | 59 (53-61) | <=60 | WARN: q3 61 |
| Surface L1 bot | pylons down 55.4 s, core 67.1 s | <=60 s | OK (thin margin, unchanged) |

Extra: economic nw30 median 122,997 (IQR 48,075-152,600; min 0 = HQ lost seed 135, max 236,228). Economic union ships @20: 13 (8-14). Passive union collapse median >40 (q1 31.2). Passive nw10 62,130, nw20 67,408.
Perturb A/B not run this session (sim unchanged since S0049b; numbers reproduce S0049b exactly: 122997 / 48075 / 152600).

## Trend
- Passive: HQ lost median 28.9 (S0044/S0046) -> 27.3 (S0048 and now); IQR 28.6-35.8 -> 24.7-27.6. The raid chip damage pulls the passive loss earlier and tightens spread; earliest seed 22.1 min still above the 20 floor (margin 2 min).
- Economic nw30: 157,636 (S0046) -> 121,347 (S0048 chip 0.02) -> 122,997 (chip 0.015, now). Q1 48,075 is low (seeds 101/186 end near 43-48k); economy stalls late in some seeds. HQ 8/9 same as S0048 (seed 135 29.7 vs 23.7 min at 0.02).
- nw10/nw20 medians flat (94,229 / 104,952 vs 120,726 at S0044: nw20 median down ~13% from the chip, still 17% over target).
- Hive ships @20 economic: 52 (S0044) -> 60 (S0046) -> 61 now; creeping up past the web guard.
- Surface pylon time 55 s: unchanged since S0044.

## Recommendations
1. Economic Hive ships @20 = 61 (>60 guard): lower the Hive ship cap / spawn rate in defs.gd by ~5% (current ~ -> proposed -3 ships at t=20); one lever only. Verify 9-seed economic + passive (passive q3 61 also drops) and --perturb=1. Only urgent if web FPS suffers in play.
2. Late-game economic dispersion (nw30 Q1 48k, one HQ loss): chip damage 0.015 is acceptable; no change. If the HQ-loss seed is to be fixed, raise bot repair reserve rather than touching the chip.
3. Surface pylon 55 s: watch, no change.
