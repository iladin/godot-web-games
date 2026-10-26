# Void Sovereign — Handover
_Last updated: S0009 · 2026-10-26 18:52 UTC · mode: BUILD_

## TL;DR
S0009 shipped **VS-018 First Sortie**: at t=60 s of play, 3 Hive "sortie" scouts drop in ~1.3 km ahead of the player and hunt only the player's wing, so the first minute now has a real fight (15–17 s, won by the player's escorts in seeds 7/101/118) and the "lock a Hive ship" tip has a target. QA showed the balance sim is **chaotic** (one extra random draw moves results as much as a feature does), so the next balance work should start with **VS-021** (9-seed gates + A/B control). `check.sh` passes.

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md`. Request delete permission for the repo root (granted S0001/3/5/6/7/8/9 → git works). Use `git -c core.fileMode=false …` for status/add; commit with `git -c "user.name=Claude Studio" -c user.email=studio@localhost commit -F - <<'EOF2'`.
2. `backlog.py next` will return **VS-020** (P1 M, late-game Hive pressure). Recommended order instead (Producer may choose): build **VS-021** (P2 S) first — it makes the VS-020 gates trustworthy. Starting point: QA's `.tools/s0009_qa2/balance_nw.gd` (balance.gd copy with a no-wave switch and `--perturb=N`; reproduces the VS-019 baseline exactly). First measure whether passive 40 min × 9 seeds fits one 180 s device call (`& … & wait`).
3. Then **VS-020** against the new 9-seed baseline. Read its notes: no global raid nerf, no shared Defense Platform buff. Current 6-seed econ: nw20 105.1k, nw30 58.0k, HQ 6/6.
4. P2 S queue: VS-014 (pause-screen touch/mouse), VS-005 (surface marker declutter), VS-010 (traders stuck at a player station), VS-007 (wing commands). VS-009 is L — split before building. VS-006 blocked until VS-020.
5. Cheap P3s now in the parking lot from S0009: fix the misleading RNG comment in `scripts/sim/opening_wave.gd`; revert scout hull to 1x when the 240 s linger ends; add `--shot=sortie`.
6. Health rule: builds_since_review = 3; a review round is due at 6.

## Last session
- Did: **VS-018 done.** New `scripts/sim/opening_wave.gd` (owned/stepped by `director.gd`; play time only), `OPENING_WAVE_*` constants in `defs.gd` (time 60, size 3, hull 3x, dps 0.5x, range 1300, orbit, linger 240), `ship_data.gd` `sortie` flag, `universe.gd valid_target` calls `OpeningWave.allows` (scouts ↔ only the player + Sovereign combat ships; stations, Union, miner ignore them), HUD "HIVE SCOUTS inbound from Ember…" and "Scouts destroyed! … land to strike the Hive Core", selftest once-only + targeting-matrix asserts, DESIGN.md. Raid timer untouched (first raid 3.3 min). QA FAIL round 1 (scouts died to HQ/Union guns in 4–7 s; player not involved) → fix → QA PASS.
- Check: PASS · Git: `studio(S0009): VS-018 …` commit · Roles collapsed: none

## In-flight / uncommitted work
none from this session. Left uncommitted on purpose: Windows mount mode noise, Daniel's edits outside this game. Scratch: `.tools/s0009_*` (balance runs), `.tools/s0009_qa/`, `.tools/s0009_qa2/` (probe.gd fight probe, shot61.gd t≈60 s renders, balance_nw.gd A/B harness); `.tools/snapshots/void-sovereign/S0009` (pre-task snapshot); device-VM probes in `$HOME/probe/` (not in the repo).

## Build health
- check.sh: PASS (~20 s). Selftest: opening wave spawns once, nothing before 60 s, raid timer unchanged, targeting matrix (mutation-tested: respawn → SCRIPT ERROR).
- Known noise (not bugs): "ObjectDB instances leaked" / "resources still in use at exit"; ALSA errors under xvfb.
- Latest metrics: S0009 economic 30 min 6 seeds: HQ 6/6, nw20 105.1k, nw30 58.0k; passive 40 min seeds 101/118/135 HQ lost 33.7 / not lost / 32.1.

## Backlog snapshot
todo 7 · in-progress 0 · done 11 · blocked 1 · split 2 · ready 6 · Top ready: VS-020 late-game Hive pressure (P1 M), VS-021 balance gates robust to chaos (P2 S), VS-014 pause-screen input (P2 S)

## Watch out for
- **Sim chaos**: the global `randf()` (seeded at universe.gd:30; used by director, ShipData.setup, retarget) is the chaotic stream — `u.rng` is not. Any spawn shifts it. 12 no-wave perturbations put passive HQ-lost at 24.4–39.0 min. Don't read a single seed as a regression.
- **Passive gate is at its ceiling** (median 33.7 vs 35). Any change that adds defence will likely push it over — another reason for VS-021.
- **Sortie scouts** are invisible to stations/Union/miner until the 240 s linger ends; then they are normal (3x hull) drones. If the player is docked they patrol the home sector vs escorts.
- check.sh autoplay (15 s) never reaches t=60 — the wave is covered only by selftest and probes.
- Defense Platform stats are shared with Union stations. Background jobs die when a device call returns — `& … & wait` in one call. Fixed econ seeds 101,118,135 (first=0) + 152,169,186 (first=3).
- Tips: `TutorialHints.on_screen` is a static read by hud.gd; target tip becomes current when a Hive entity is in the player's sector (now at t=60 via the wave). Touch SKIP TIPS chip ~13 px from THR- at 1280x720.
- main.gd is 306 lines — split before adding. universe.gd 454 lines. Every sound via `Sfx.play()`. Default font has no arrow glyphs.

## Open questions for Daniel
- VS-020: if no clean lever is found, is a mild late decline acceptable (e.g. nw30 ≥ 0.7 × nw20 with HQ ≥ 5/6) instead of strict growth?
- OK to switch balance gates to 9-seed medians (VS-021)? It costs ~2 extra minutes per balance run but makes gates meaningful.
- Still open: remember tutorial tips in the save file? Target session length (design assumes 30–40 min)?

## Answers to Daniel
- none new this session (INBOX was empty). Earlier rulings still apply: slower early game after VS-016 is fine; VS-007/VS-009 restored to todo; studio never pushes unless asked.

## Session history (newest first, keep 10)
- S0009 2026-10-26 BUILD — VS-018 First Sortie done (QA FAIL → fix round → PASS); VS-021 added (sim chaos makes 3-seed gates unreliable)
- S0008 2026-10-26 BUILD — VS-011 split → VS-019 harness done (HQ 6/6, nw30 74k) + VS-020 open; VS-017 tutorial tips follow the world done (QA PASS after 1 fix round)
- S0007 2026-10-26 PLANNING+BUILD — first review round (critic 5.1/10) → VS-015..018; VS-015 title freeze/overlay fix + VS-016 trade arbitrage fix done (both QA PASS)
- S0006 2026-10-26 BUILD — VS-004 tutorial tips + VS-012 touch row/pause-mute/sfx assert done (both QA PASS); VS-013, VS-014 added
- S0005 2026-10-26 BUILD — took over stale S0004 lock; VS-003 procedural SFX done (QA PASS); VS-012 added
- S0004 2026-10-26 SUPERSEDED — took lock 03:32Z, device calls stalled ~8 h; resumed later as S0006
- S0003 2026-10-26 BUILD — cleaned up hung S0002; VS-001 mid-game rebalance done (nw20 8k→139k, HQ 5/6); VS-011 added
- S0002 2026-10-26 ABORTED — hung during VS-001, cancelled by Daniel; diff salvaged, no handover
- S0001 2026-10-26 BUILD — baseline commit; VS-002 trader reserve + VS-008 AI-journey selftest done; VS-010 added
- S0000 2026-10-25 SETUP — game v1 + AI studio + seeded backlog
