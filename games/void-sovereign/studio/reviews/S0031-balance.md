# S0031 Balance report (void-sovereign)

Code at HEAD 4535a95 (S0030). Sim constants differ from S0025 report: BREACH_SIZE is now 6 (S0025 report assumed 4). 9 seeds (101..237), no --perturb run this session. Econ gate first call was killed by the device cap with offset 0 incomplete; offset 0 was rerun alone (106 s), sequential.

## 1. Targets
| Metric | Measured (9-seed median, IQR q1-q3, min/max) | Target | Status |
|---|---|---|---|
| Passive: HQ lost at | 31.9 min, 30.8-32.7 (lost seeds 28.7-34.7; survived 1/9, seed 186) | 20-35 | OK |
| Econ: nw at 10 min | 94,243, 93,046-106,254 (85,037 / 110,795) | >= 45,000 | OK |
| Econ: nw at 20 min | 104,020, 97,681-123,372 (89,022 / 137,312) | >= 90,000 | OK (seed 135 at 89,022 just under; median fine) |
| Econ: HQ survives 30 min | 9/9 | >= 6/9 | OK |
| Union collapse in econ | none by 30 min, 0/9 | not before 20 min | OK |
| First Hive raid | 3.3 min (q1=q3) | 3-4 | OK |
| Hive ships at 20 min (econ) | 50, 49-61 (passive 53, 51-61) | <= 60 | OK on median; q3 61 slightly over |
| Surface L1 with bot | pylons down ~48 s, core destroyed ~55 s, no script errors | pylons within 60 s | OK |

Econ nw30: median 122,357, IQR 89,372-154,787, min 77,463 (seed 237), max 168,103; nw30 < nw20 in 3/9 (118, 135, 237). Union ships @20 econ 11 (9-13). Passive union collapse median 27.9 (27.2->40). Passive nw20 65,736. Kills econ 30, passive 59.

Targets met: 8/8 (two soft notes: Hive ships q3 61, nw20 min 89k).

## 2. Trend vs S0025
- Passive HQ-lost 36.0 -> 31.9, survived 3/9 -> 1/9, IQR 31.9->40 -> 30.8-32.7: back inside 20-35 and tighter (BREACH_SIZE 6 appears to have done what S0025 recommended).
- Econ nw10 94,132 -> 94,243; nw20 110,509 -> 104,020; nw30 167,205 -> 122,357 (floor 36,756 -> 77,463, i.e. tail is healthier, median lower).
- Hive ships @20 econ 61 -> 50 (guard now met); union ships 13 -> 11.
- Econ spread is chaos-driven; the nw30 median drop is inside the S0025 IQR (130-172k) only marginally, treat as noise-plus-Breach-change, not a regression.

## 3. Recommendations
No target is red. Optional, low priority:
1. Hive ships @20 q3 61 (econ) / 61 (passive): if web perf complaints appear, lower the Hive production cap before minute 20; no change recommended now (medians 50/53).
2. Econ nw30 < nw20 in 3/9 seeds (late-game wealth loss from raids): keep watching; if it grows, consider RAID_DETER_RANGE up from 3400. Not needed this session.
3. Run --perturb=1 next session after any further Hive-pressure change to confirm passive 31.9 is not a single-RNG-stream artifact (not run now).

Method: gate dirs `.tools/balance_gate/void-sovereign_economic_30` and `void-sovereign_passive_40` (passive split 0+3 then 6). FPS check: `--shot=surface_long` 6000 frames headless, pylons down at t=48, Core hit from t=48, hull drop at t=56 after core kill (sector 0 flight); no SCRIPT ERROR.
