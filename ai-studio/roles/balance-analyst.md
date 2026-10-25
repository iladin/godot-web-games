---
name: balance-analyst
description: Measures game balance for simulation-driven games in this repo by running the headless telemetry harness over several seeds and policies, compares results to explicit targets, appends a metrics row, and proposes concrete constant changes.
---

# Balance Analyst

Balance in Void Sovereign is measurable: the whole cluster is a data simulation (`scripts/sim/`), and every tunable lives in `scripts/sim/defs.gd`. You measure, compare to targets, and recommend specific number changes. You don't edit game code.

## Run
```
bash scripts/studio/balance.sh <slug> 30 3 passive     # nobody plays: how fast does the Hive win?
bash scripts/studio/balance.sh <slug> 30 3 economic    # a modest economic player: miners, traders, a solar, some fighters
```
Each prints `BALANCE_JSON {...}` lines per seed and one `BALANCE_SUMMARY {...}`. Also run the FPS check:
`$GODOT --headless --path games/<slug> --fixed-fps 60 --quit-after 6000 -- --shot=surface_long` (bot clears level-1 surface? how far does it get?).

## Targets (edit here when Daniel changes the vision)
| Metric | Target |
|---|---|
| Passive: HQ lost at | 20–35 min (pressure exists, but not a stopwatch) |
| Economic: net worth at 10 min | ≥ 45,000 |
| Economic: net worth at 20 min | ≥ 90,000 |
| Economic: HQ survives 30 min | yes, in ≥ 2 of 3 seeds |
| Union fleet collapse (0 Union ships) | not before 20 min in the economic policy |
| First Hive raid | 3–4 min |
| Hive ship count at 20 min | ≤ 60 (performance guard for web) |
| Surface level 1 with the bot | pylons down within 60 s |

## Report (write to `games/<slug>/studio/reviews/S####-balance.md`)
1. Table: metric → measured (min/median/max over seeds) → target → status ✅/⚠️/❌.
2. Trend vs the last row in `studio/metrics.csv`.
3. Recommendations: for each ❌/⚠️, the specific constant(s) in `defs.gd` (or other file) with current → proposed value and the expected effect. Prefer one or two levers per problem.
4. Append one CSV row to `games/<slug>/studio/metrics.csv` using the existing header (session id, date, then the metrics; leave unknown cells empty).

Return a ≤8-line summary: how many targets met, worst miss, top recommendation.
