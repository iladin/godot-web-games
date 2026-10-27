# S0012 Balance report: void-sovereign

Balance Analyst, 2026-10-27. Build: the current tree, with VS-020 raid deterrent (`RAID_DETER_PER_PLATFORM` 0.25, `RAID_DETER_FROM` 1200 s).
Gates: `balance_gate.sh` with economic 30 min (one call, 159 s) and passive 40 min (two calls, `"0 3"` 135 s and `"6"`). Seeds 101..237, wave on, no perturbation. Output went to `.tools/s0012_bal/{econ30,pass40}`.
Diagnostics used a telemetry copy of the harness, `.tools/s0012_bal/probe/probe.gd`. It hooks `message`/`destroyed` only, makes no RNG draws, and reproduces the gate numbers exactly. A/B variants ran in scratch copies `.tools/s0012_bal/vs_{a,b,c}`. No game code was edited.

## 1. Targets (9-seed median, IQR q1–q3, min/max)

| Metric | Measured | Target | Status |
|---|---|---|---|
| Passive: HQ lost at | **33.7** (32.1–35.8; 27.3 / never ×2) | 20–35 | ✅ (q3 above the ceiling, so there is no headroom) |
| Econ: net worth 10 min | **93,194** (87,045–101,947; 80,858/113,548) | ≥ 45,000 | ✅ |
| Econ: net worth 20 min | **107,685** (103,498–126,954; 93,266/165,264) | ≥ 90,000 | ✅ |
| Econ: HQ survives 30 min | **9/9** | ≥ 6/9 | ✅ |
| Econ: Union collapse | **> 30** (one seed, 220, at 24.5) | not before 20 | ✅ |
| First Hive raid | **3.3** (3.3–3.3) | 3–4 | ✅ |
| Hive ships at 20 min (econ) | **58** (53–61; 48/75) | ≤ 60 | ⚠️ q3 61 and max 75 are over the guard (passive: 53) |
| Surface L1 bot (`surface_long`) | pylons down by about t=50 s, core killed by t=60 | ≤ 60 s | ✅ |
| (curve) Econ: net worth 30 min | 122,300 (117,295–146,565; **37,372**/185,476); nw30 < nw20 in 2/9 (186, 203) | ≥ nw20 | ⚠️ tail |

**Score: 8 of 8 targets met.** One performance-guard warning: the hive_ships_20 tail.

## 2. Trend vs last rows
- Econ matches **S0011** in every cell (VS-020 build, deterministic): nw10/20 and HQ 9/9 unchanged, nw30 122,300. The S0010 nw30 was 55,869.
- Passive matches **S0010/S0011**: 33.7 (32.1–35.8), 2/9 survive. The deterrent cannot act in passive play because there are no platforms.

## 3. Focus questions

### Q1: Is the VS-020 deterrent too strong?
Raid accounting in econ runs, from the probe, after minute 20:
- About 8 raid rolls happen per run (the interval is 75–80 s).
- Cancelled: **median 5 per run (range 2–7), 41 of 72 rolls (57%)**.
- Launched: 31, of which **12 went into the HQ sector (median 1 per run)** and the rest went at Union targets elsewhere.
- Hive-ship-minutes in the HQ sector over minutes 21–30: median **4** (0–14).
- After the last pre-deterrent raid clears (about minute 25), the HQ sector holds 0 Hive ships in 8 of 9 seeds.

So **the HQ itself is close to pressure-free for the last ~5 minutes**. Player losses do continue: freighters and miners die in lanes to Union-bound raids, about 2–4 per run after minute 25.

Softening the deterrent breaks the HANDOVER guardrail (econ nw30 ≥ nw20). Both 9-seed A/B tests failed:

| Variant | nw30 median (IQR) | nw30 < nw20 | Other |
|---|---|---|---|
| Base 0.25 | 122,300 (117,295–146,565) | 2/9 | |
| `RAID_DETER_PER_PLATFORM` 0.5 | 93,330 (86,495–146,565) | 4/9 | **below nw20** |
| Redirect cancelled raids to a random Union station | 98,314 (67,278–123,519) | 6/9 | **Union collapse median 27.5** (5/9 seeds collapse by 30) |

**Verdict:** the deterrent is strong, and from minute 25 the late game is pressure-free at the HQ. The economy does not survive the obvious softenings, though. **Keep 0.25 for now.** If more late pressure is wanted, it has to come with an economy buffer. Don't soften the multiplier and don't redirect raids.

### Q2: What causes the tail collapses?
All four cases (econ 186; `--perturb=1` seeds 118, 169, 220) follow the same pattern:
1. The raid launched at about 18–19.7 min is the **dreadnought raid**: every 3rd launched raid after `DREAD_TIME` 900 carries one. It is rolled before `RAID_DETER_FROM`, so the deterrent never sees it.
2. Its ravagers arrive at about 20–22 and the dreadnought (speed 90) at **about 22.5–25**. In the HQ sector they kill the patrol wing and every miner, which work outside the platform's cover. In 186: 8 fighters, 7 miners and 4 freighters were lost between 20.0 and 25.2, with dreadnought kills from 23.6 on. 118p had **no platform at all** (never reached 33k), so its later raids also landed.
3. There is **no comeback**. With 0 miners and 0–1 fighters, credits sit at 5–7k, and nw stays flat (186: 37k from 25 to 30 min).

Harness check: lowering the bot's miner reserve to 0 when it has fewer than 2 miners (`.tools/s0012_bal/rebuy/probe2.gd`) recovered only 220p (161k). 186 got worse (27k) and 118p/169p stayed at 12k and 53k. So this is mostly a real game effect, not just a quirk of the bot.

### Q3: Other curve problems
- **Late-game net worth swings come from a single raid.** The 20–30 min segment depends on whether the one dreadnought raid catches the miners. nw30 spans 37k–185k against an nw20 spread of 93k–165k.
- **Hive ship count:** the q3/max tail at 20 min (61/75) exceeds the web performance guard in 3 of 9 econ seeds.
- **Second platform rarely affordable:** the econ bot gets its 2nd platform in only 3 of 9 seeds (169, 220, 237), so most runs sit at 1 platform, a 25% go-chance.

## 4. Recommendations
1. **Tail collapse (⚠️ nw30):** `defs.gd` `DREAD_TIME` **900 → 1200**. The first dreadnought then rides a raid that is rolled inside the deterrent window, so it is deterrable. 9-seed A/B (`vs_c`):
   - Econ nw30 median 122.3k → **142.2k** (IQR 107.1–161.2k). This is a small gain inside the noise.
   - Econ min 37.4k → **60.3k**. nw30 < nw20 stays at 2/9 (135, 186). nw10/nw20 are unchanged.
   - **Passive HQ lost 33.7 → 33.6** (IQR 29.5–37.1, 2/9 never lost), so passive is unaffected and stays under the ceiling.
   - Under `--perturb=1` the three tail seeds came out mixed: 118 9.9k → 72.8k, 169 71.9k → 46.1k, 220 45.5k → 65.8k.

   Adopt only after a full 9-seed `--perturb=1` gate. Expected effect: a softer econ floor and fewer zero-income endings. It also takes some late HQ pressure away, which makes Q1's quiet late game slightly quieter.
2. **Late-game pressure (Q1):** no change to `RAID_DETER_PER_PLATFORM` (0.25) or `RAID_DETER_FROM` (1200). The 0.5 and redirect variants both break nw30 ≥ nw20. If Daniel wants late pressure, the next lever to try is a cap: deterrence stops at the 1-platform level (go-chance ≥ 0.25) and needs a code change (`director.gd raid_go_chance`, `maxf(go, 0.25)`). It would only bite in the 3/9 seeds with 2 platforms. It needs a new A/B.
3. **Hive ships at 20 min (⚠️):** no change this session. Watch the max. If it creeps up, the lever is `NEST_SPAWN_MIN` 12 → 14 s.
