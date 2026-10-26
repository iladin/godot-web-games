# Void Sovereign — Handover
_Last updated: S0001 · 2026-10-26 00:05 UTC · mode: BUILD_

## TL;DR
Void Sovereign v1 is playable end to end and `check.sh` passes. The repo now has a baseline commit for the game and the studio, and S0001 shipped two size-S tasks: automated player assets keep a 2,000 cr reserve (VS-002), and the selftest now covers AI journeys (VS-008). VS-008 found that trading lost money on the starting universe and fixed it, which is a small balance change. The biggest design problem is still mid-game collapse (VS-001).

## Next session should
1. Preflight per `ai-studio/studio-cycle.md`. Request delete permission for the repo root (granted in S0001 → git commits worked). Use `git -c core.fileMode=false …` for add/status: the Windows mount shows almost every file as mode-changed, but that is noise.
2. BUILD `VS-001` (rebalance mid-game, size M, P1). `backlog.py next` returns it. Measure first with **6 seeds**: `bash scripts/studio/balance.sh void-sovereign 30 6 economic` (≈140 s; run in the foreground, background jobs die when the device_bash call ends; split into two calls if it exceeds 180 s). New baseline is in the VS-001 notes and the S0001 row of `studio/metrics.csv`. Levers are in `games/void-sovereign/scripts/sim/defs.gd`. Keep the VS-002 gate: credits_10 > TRADER_RESERVE (2000) in all seeds.
3. If budget remains: `VS-010` (P2, S): NPC sellers keep retrying at a player station that can't pay below the reserve. Fix in `scripts/sim/ship_ai.gd` `best_buyer()`/`plan_trade()`.
4. Then `VS-004` (guided first 10 minutes, P1 S) or `VS-003` (procedural audio, P1 M). After 6 builds, run a PLANNING round (builds_since_review is 2 now).

## Last session
- Did: baseline commit `d1397ee`. VS-002 done: `Defs.TRADER_RESERVE`, clamp in `Universe.transact()` for every automated player asset, plus selftest (`6dc9767`). VS-008 done: `_test_ai_journeys()` in `scripts/selftest.gd` covers gate travel, a miner's ore sale and `plan_trade` profit. `plan_trade` now returns `"profit"`. Start stock is now inputs 1/3 and outputs 1/2 (`Defs.START_FILL_INPUT/OUTPUT`), because `plan_trade` was empty on the starting universe. Added VS-010 and three parking-lot ideas.
- Check: PASS · Git: committed (studio(S0001) commits; see `git log`) · Roles collapsed: none

## In-flight / uncommitted work
none (only the long-standing Windows file-mode noise and Daniel's own pre-existing edits outside this game, which were not staged)

## Build health
- check.sh: PASS (~15 s) · selftest: routing, pricing, transactions, production, 8 simulated minutes, Core→Nest unlock, trader reserve, AI journeys (goto 0→3 in 82/288 s, miner sale 64/289 s, trade plan munitions x80 profit 1787)
- Known noise (not bugs): "ObjectDB instances leaked at exit" / "resources still in use at exit"; ALSA errors under xvfb.
- Latest metrics: S0001 economic 30 min, 3 seeds: HQ 0/3 (6 seeds: 3/6), nw10 46364, nw20 8022, Union collapse 21.5 min, credits_10 3716/4364/7692.

## Backlog snapshot
todo 8 · in-progress 0 · done 2 · blocked 0 · split 0 · ready 7 · Top ready: VS-001 rebalance mid-game, VS-004 guided first 10 minutes, VS-003 procedural audio

## Watch out for
- Below 2000 credits, automated player ships don't buy, and **player stations stop buying from NPCs** (`Universe.transact`). The dock panel (the pilot's own ship) can still spend to zero. VS-010 tracks the NPC retry loop this causes.
- A failed `assert` in `selftest.gd` still prints "SELFTEST OK". Only check.sh's `SCRIPT ERROR` grep catches failures, so read the whole output when running the selftest by hand.
- 3-seed balance runs are too noisy for HQ survival: 0/3 vs 2/3 turned out to be 3/6 vs 3/6 on 6 seeds. Use ≥6 seeds for survival gates.
- The whole world is one data sim (`scripts/sim/`). Views only render the current sector, so put rules in the sim. All tunables are in `scripts/sim/defs.gd` (typed consts, so cast values).
- `scripts/test_driver.gd` drives `--autoplay` (check.sh) and `--shot=` scenarios. Keep both working.
- The default font has no arrow/triangle glyphs. Only one WorldEnvironment may exist at a time (SpaceView removes its own while on the surface).
- Git on Daniel's computer needs delete permission (lock files). Reads use `git --no-optional-locks`. Never stage the `games/starfall`, `template/`, `.claude/`, `.github/` mode noise.

## Open questions for Daniel
- Do you want the studio to keep committing to `main` locally, or would you rather push the repo to GitHub so sessions can run in the cloud and open PRs instead? (S0001 committed 3 commits to local `main`, nothing pushed.)
- Target session length for a full game: the design assumes 30–40 minutes. Shorter?

## Answers to Daniel
- none (INBOX empty)

## Session history (newest first, keep 10)
- S0001 2026-10-26 BUILD — baseline commit; VS-002 trader reserve + VS-008 AI-journey selftest done; VS-010 added
- S0000 2026-10-25 SETUP — game v1 + AI studio + seeded backlog
