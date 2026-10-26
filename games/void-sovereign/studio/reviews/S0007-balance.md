# S0007 · Balance review (Void Sovereign)

Build: HEAD `b8744ab` (no changes to `scripts/sim/` or `defs.gd` since S0003 `935f699`).
Runs (Godot 4.7.2 headless):
- Economic, 30 min, 6 seeds (101, 118, 135, 152, 169, 186), run as two 3-seed calls (~86 s each) so each stays under the 180 s device cap. `balance.sh` can't offset seeds, so I used a throwaway copy of the harness at `.tools/s0007/balance_offset.gd`. It adds only a `--first=N` argument (seed index start); the simulation and policy are unchanged. Raw output: `.tools/s0007/econ_a.txt`, `econ_b.txt`.
- Passive, 40 min, 3 seeds via `balance.sh` (58 s): `.tools/s0007/passive.txt`.
- Surface: `--fixed-fps 60 --quit-after 6000 -- --shot=surface_long`.

Medians use the harness convention (upper median, index n/2).

## 1. Targets

| Metric | Measured (min / median / max) | Target | Status |
|---|---|---|---|
| Passive: HQ lost at | 24.4 / 25.4 / 29.5 min | 20–35 min | ✅ |
| Economic: net worth at 10 min | 94,660 / 101,183 / 113,214 | ≥ 45,000 | ✅ (overshoots by 2.2×, see VS-011) |
| Economic: net worth at 20 min | 106,586 / 139,289 / 171,041 | ≥ 90,000 | ✅ (above the VS-011 band of 80–130k) |
| Economic: HQ survives 30 min | 5/6 (seed 118 lost at 27.4) | ≥ 2 of 3 | ✅ |
| Union fleet collapse (economic) | 24.3 / 24.8 / 27.8 in 3/6 seeds; 3/6 never collapse | not before 20 min | ✅ |
| First Hive raid | 3.3 / 3.3 / 3.3 min | 3–4 min | ✅ |
| Hive ships at 20 min (economic) | 49 / 59 / 64 (passive: 48 / 49 / 65) | ≤ 60 | ⚠️ median passes, 2/6 economic seeds and 1/3 passive seeds go over |
| Surface level 1 with bot | pylons down at ~45–50 s, core destroyed at ~60 s | pylons ≤ 60 s | ✅ (improved: in S0000 the bot died with the core at 44%) |
| VS-011: net worth 30 ≥ net worth 20 | falls in **5/6** seeds; nw30 median 42,939 (6,135 / 19,373 / 42,939 / 65,133 / 210,478; seed 118 HQ lost) | nw30 median ≥ nw20 median | ❌ |

Per seed, economic (nw10 → nw20 → nw30 · player ships at 20 → 30 · credits at 10):
- 101: 98k → 147k → 65k · 14 → 3 · 23.9k
- 118: 101k → 139k → HQ lost at 27.4 · 14 → 0 · 27.2k
- 135: 95k → 118k → 43k · 14 → 6 · 20.7k
- 152: 95k → 107k → 6k · 14 → 0 · 22.3k
- 169: 113k → 171k → 210k · 14 → 13 · 11.2k (the only seed that grows)
- 186: 112k → 125k → 19k · 14 → 2 · 10.0k

Hive ships at 30 min: 76–97 in every surviving seed.

## 2. Trend vs the last `metrics.csv` rows (S0003)
The numbers are **identical** to S0003: same seeds, same per-seed values (for example seed 118: 101,183 / 139,289 / HQ lost at 27.4), and the same medians: HQ 5/6, nw10 101k, nw20 139k, union collapse 24.3, Hive at 20 min 59, Union ships at 20 min 10. Passive matches too (25.4 / 58,243 / 64,884 / 49 / 14). The simulation is deterministic per seed, and S0005/S0006 (audio, tutorial hints, touch) did not touch `scripts/sim/`. **VS-011 is unchanged and still open.** No regression and no improvement.

## 3. Diagnosis
The losses after minute 20 are a **Hive ramp cliff** that lines up with a **saturated test policy**:
- `director.gd`: `raid_size()` reaches `RAID_SIZE_MAX` = 16 at t ≈ 19.5 min (3 + t/90). `raid_interval()` reaches `RAID_INTERVAL_MIN` = 75 s at t = 21 min (180 − t/12). Every third raid now brings a dreadnought (`DREAD_TIME` = 900 s). Nest caps keep rising (6 + t/120 per nest). Raid throughput jumps from about 0.06 ships/s at 10 min to 0.21 ships/s at 21 min, and raiders pile up: Hive ships go from about 55 to 76–97.
- The economic policy hits its cap (4 miners, 2 traders, 8 fighters = 14 ships) **before minute 10**, because early income is very high: nw10 is about 100k, of which roughly 74k is ships. After that it never builds defence and never replaces losses, so the 16-ship raids at 75 s intervals wear the 8 fighters down. In seed 169 the fleet survives and credits pile up unused (121k). The policy has no late-game sink, so the drop in net worth partly reflects how the test player is written, not only the game's tuning.
- Early overshoot: the harness reached its 14-ship cap by minute 10 in every seed. `credits_10` of 10–27k is what is left over after that.

## 4. Recommendations (proposals only; nothing changed)
1. **Smooth the late Hive ramp (main lever for VS-011 ❌ and the hive-count ⚠️).** In `scripts/sim/defs.gd`:
   - `RAID_INTERVAL_MIN` 75.0 → **100.0**
   - `RAID_SIZE_MAX` 16 → **13**
   - Effect: peak raid throughput falls from 0.21 to 0.13 ships/s (−38%), and the peak arrives later (interval floor at 16 min instead of 21 min, then holds). Hive ships at 20/30 min should drop by about 10–20%, which brings the max at 20 min under 60. Passive HQ loss should move later by about 2–4 min, to an estimated 27–30 min, still within 20–35. Re-check the passive run.
2. **Trim early income (VS-011's 80–130k band for nw20).** `TRADE_HUB_EXPORT` 80 → **60** (in `defs.gd`, as the VS-011 note suggests). Expected nw10 is about 80–90k and nw20 about 110–125k. Both stay well above the role targets of 45k and 90k. Leave `START_CREDITS` (30k) alone so the first purchases stay the same.
3. **Harness (tools, not tunables; for the developer on VS-011):**
   - Add a `--first=N` seed-offset argument to `scripts/tools/balance.gd` and pass it through `balance.sh`. The one-line change is in `.tools/s0007/balance_offset.gd` (`for i in range(first, first + seeds)`). This meets acceptance item 1 of VS-011.
   - Give the economic policy a late-game sink: replace lost fighters, and build one Defense Platform (30k) at the HQ once credits ≥ 33k. That way nw30 measures the game rather than a player who stops spending at minute 10.
   - Apply 3 before judging 1 and 2, or change one variable at a time.
4. Optional, if the hive count stays above 60 after (1): slow the nest cap in `director.gd._nests` from `6 + t/120` to `6 + t/180`.
