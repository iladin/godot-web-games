# Void Sovereign — Handover
_Last updated: S0003 · 2026-10-26 02:15 UTC · mode: BUILD_

## TL;DR
Void Sovereign is playable end to end and `check.sh` passes. S0003 cleaned up after the hung S0002 and shipped VS-001: an economic player now reaches about 139k net worth at minute 20 (was 8k), and the HQ survives in 5 of 6 seeds. The open balance problem is the slide from minute 20 to 30 (VS-011).

## Next session should
1. Preflight per `ai-studio/studio-cycle.md`. Request delete permission for the repo root (granted in S0001/S0003 → git commits work). Use `git -c core.fileMode=false …` for add/status (the Windows mount shows mode-change noise on almost every file).
2. BUILD the task `backlog.py next` returns. Today that is `VS-003` (procedural audio, P1 M). If Daniel prefers to keep the balance momentum, do `VS-011` first (P1 M, economic player keeps growing from minute 20 to 30). Its first acceptance item is adding a seed-offset option to `scripts/studio/balance.sh` / `scripts/tools/balance.gd`, so the 6-seed run can be split across two device_bash calls.
3. **Time safety:** `balance.sh void-sovereign 30 6 economic` takes ~174 s against the 180 s device_bash cap. Use 3-seed runs (~70 s) for exploration, pass timeout_ms=180000, one Godot run per call, and never background processes. S0002 hung during this kind of work.
4. Then `VS-004` (guided first 10 minutes, P1 S). A PLANNING round is due after 6 builds (builds_since_review = 3).

## Last session
- Did:
  - Cleaned up S0002, which hung and was cancelled by Daniel: saved its uncommitted 7-file diff to `studio/salvage/S0002-VS-001-abandoned.patch` and restored the files from HEAD `aaee72c`.
  - VS-001 done. Developer and QA ran as independent subagents; QA PASS on all 4 criteria with its own runs.
  - Changes, all tunables in `scripts/sim/defs.gd`:
    - Trade Hub export sink (`TRADE_HUB_EXPORT` 80 above `TRADE_HUB_TARGET_FILL` 0.1)
    - Civilians skip sectors with ≥ `CIVILIAN_AVOID_HIVE` (2) Hive warships (`hive_presence` / `sector_unsafe` in universe.gd)
    - `CROSS_SECTOR_SELL_PENALTY` 2.5→6
    - Home guard: player warships patrolling the HQ sector stay within HQ range + `GUARD_LEASH` (400)
    - Free dock repair near the HQ (`REPAIR_RANGE` 2000, `REPAIR_RATE` 2 %/s)
    - Raiders withdraw to the nearest Nest when their target is gone
    - Fighter hull/shield/dps 180/90/26 → 320/180/36; HQ hull/shield 14000/5000 → 30000/6000
    - Raid size formula moved into constants (behaviour unchanged)
  - DESIGN.md Ramp/Economy updated; new selftest asserts for the hub export and `sector_unsafe`.
  - Added VS-011, plus 4 QA P3 items in the parking lot.
- Check: PASS · Git: committed `studio(S0003)` (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none. Not committed (left alone on purpose): Windows file-mode noise and Daniel's own edits outside this game. `studio/salvage/S0002-VS-001-abandoned.patch` is committed for reference only; don't apply it, since VS-001 was redone.

## Build health
- check.sh: PASS (~15 s) · selftest: SELFTEST OK, no assertion lines; raids 2 within 8 min; credits after 8 min 43684.
- Known noise (not bugs): "ObjectDB instances leaked at exit" / "N resources still in use at exit"; ALSA errors under xvfb.
- Latest metrics (S0003):
  - Economic 30 min, 6 seeds: HQ 5/6, nw10 101k, nw20 139k, Union collapse median 24.3, credits_10 min 9994.
  - Passive 40 min, 3 seeds: HQ lost at 25.4 min (median).
  - Net worth at 30 min falls in 4 of 6 seeds (e.g. 106k → 6k).

## Backlog snapshot
todo 8 · in-progress 0 · done 3 · blocked 0 · split 0 · ready 7 · Top ready: VS-003 procedural audio, VS-004 guided first 10 minutes, VS-011 grow from minute 20 to 30

## Watch out for
- **Patrol in the HQ sector now means "guard HQ".** Player warships there engage only within HQ range + 400 and hold near the HQ (`ship_ai.gd` `_home_guard`). The UI doesn't explain this (parking lot).
- Dock repair is free and heals any automated Sovereign ship near the HQ, including ships on manual orders (parking lot).
- Civilians avoid raided sectors as *destinations*, but `route(..., avoid_hive)` still only avoids Nest sectors on the way.
- Below 2000 credits, automated player ships don't buy and player stations stop buying from NPCs (`Universe.transact`). VS-010 tracks the NPC retry loop this causes.
- A failed `assert` in `selftest.gd` still prints "SELFTEST OK". Read the whole output.
- Use ≥ 6 seeds for survival gates (3 seeds is noisy). The whole world is one data sim in `scripts/sim/`; views only render it. Keep `--autoplay` and `--shot=` in `scripts/test_driver.gd` working.
- The default font has no arrow glyphs. Only one WorldEnvironment may exist at a time.
- Git needs delete permission (lock files). Never stage the `games/starfall`, `template/`, `.claude/`, `.github/` mode noise.

## Open questions for Daniel
- After VS-001 the economy may be too generous early (credits at 10 min are 10–27k). VS-011 trims it. Is a faster early game OK, or should the early game stay tight?
- Keep committing to local `main`, or push to GitHub so sessions can open PRs? (Still only local commits, nothing pushed.)
- Target session length: the design assumes 30–40 minutes. Shorter?

## Answers to Daniel
- none (INBOX empty)

## Session history (newest first, keep 10)
- S0003 2026-10-26 BUILD — cleaned up hung S0002; VS-001 mid-game rebalance done (nw20 8k→139k, HQ 5/6); VS-011 added
- S0002 2026-10-26 ABORTED — hung during VS-001, cancelled by Daniel; diff salvaged, no handover
- S0001 2026-10-26 BUILD — baseline commit; VS-002 trader reserve + VS-008 AI-journey selftest done; VS-010 added
- S0000 2026-10-25 SETUP — game v1 + AI studio + seeded backlog
