# S0052 VS-056 fleet-floor run (Game Developer)

Policy: `--fleet-floor=10` (passive, 40 min, 9 seeds 101..237). Every 30 s the harness buys patrol fighters at the HQ until the Sovereign fleet (pilot excluded) has 10 ships or credits run out.

| seed | HQ lost (min) | fighters rebought | nw20 | Hive ships @20 |
|---|---|---|---|---|
| 101 | 28.2 | 17 | 65318 | 51 |
| 118 | survived | 24 | 53399 | 53 |
| 135 | 32.7 | 17 | 56716 | 61 |
| 152 | 35.7 | 23 | 69114 | 57 |
| 169 | 31.0 | 22 | 81398 | 54 |
| 186 | 31.6 | 23 | 74920 | 51 |
| 203 | 36.1 | 22 | 78287 | 48 |
| 220 | 38.6 | 29 | 78779 | 65 |
| 237 | 38.9 | 22 | 74589 | 46 |

Median HQ lost 35.7 min (floor off, same code: 25.8, range 21.1-30.9). 1/9 survives to 40 min (floor off 0/9). Player ships @20 = 10 on every seed.

Reading: holding 10 ships pushes the passive collapse about 10 minutes later but does not prevent it; Hive pressure still wins by ~30-39 min. The fleet-loss cliff explains roughly the first 10 minutes of the passive collapse, not all of it. Fighters only (no platforms); the floor ignores credit reserve, so it is an upper bound on what a fleet-replacement habit buys.

## Gate for the cap change (t/120 -> t/126)
- economic 30 min, 9 seeds: HQ 9/9, hive_ships_20 median 56 (IQR 51-60), nw30 median 168407.
- economic 30 min --perturb=1: HQ 8/9, nw30 median 135264.
- passive 40 min: Hive ships @20 median 60 (IQR 56-65), HQ lost median 25.8, earliest 21.1.
Note: balance_gate runs in this environment needed splits (GATE_OFFSETS) to fit 175 s; seeds 203/220/237 of the floor run were run as three single-seed calls.
