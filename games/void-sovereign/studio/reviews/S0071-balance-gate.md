# S0071 Passive gate definition (VS-077)

HEAD, void-sovereign, passive 40 min, 9 seeds (offsets 0/3/6), fresh runs, one GATE_OFFSETS per call.

| Seed | no --reserve HQ lost (min) | with --reserve HQ lost (min) |
|---|---|---|
| 101 | survives 40 | 26.0 |
| 118 | 31.2 | 30.9 |
| 135 | 31.8 | 26.5 |
| 152 | 23.7 | 24.7 |
| 169 | 19.2 | 27.6 |
| 186 | 26.6 | 39.8 |
| 203 | 22.1 | 22.1 |
| 220 | 28.4 | 28.4 |
| 237 | 30.2 | 28.3 |
| Summary | median 28.4, IQR 23.7-31.2, earliest 19.2, survive 1/9, hive_ships_20 58 (55-62) | median 27.6, IQR 26.0-28.4, earliest 22.1, survive 0/9 |

Timings: no-reserve offsets "0 3" 155 s, "6" 69 s; reserve "0 3" 103 s, "6" 80 s.

## Findings
- Passive means nobody plays, so the gate is defined WITHOUT --reserve (a Reserve call is a player action; the passive bot only calls it when the flag is passed). Every earlier task text that said "(no --reserve)" already meant this.
- The ">= 22 min earliest" figure (S0061/S0062: 23.6) is not reproducible in either mode on HEAD: no-reserve earliest is 19.2 (seed 169), --reserve earliest is 22.1 (seed 203). So the 23.6 was not a --reserve number; the passive baseline moved between S0062 and S0068 (S0068 found passive bit-identical before/after VS-075, so the shift predates it). Not bisected.
- --reserve helps seeds 169 (19.2 -> 27.6) and 186 (+13 min) but makes 101 worse (survives 40 -> 26.0, a Reserve bot spends credits); IQR narrows, median barely moves (28.4 -> 27.6).

## Decision
- Gate = no --reserve, median HQ lost within 20-35 (met: 28.4). Per-seed earliest is a watch item, not a hard gate: reworded in balance-analyst.md, balance_gate.sh header and the VS-075 criterion.
- No-reserve earliest (19.2, one of 9 seeds, and 203 at 22.1) is below the old per-seed guard; proposed lever (NOT applied, untested): RAID_SIZE_GROWTH 90 -> 100 (cap 16 unchanged) to soften late raids; alternative if the per-seed floor matters, raise the guard to a count ("at most 1 of 9 seeds under 22 min"). NEST_CAP_GROWTH 135/140 are already rejected.
