# Void Sovereign — Handover
_Last updated: S0008 · 2026-10-26 16:53 UTC · mode: BUILD_

## TL;DR
S0008 shipped two P1 items. **VS-017**: tutorial tips now skip steps that can't be done yet (the "lock a Hive ship" tip waits for a hostile), so dock/map/land tips reach every new player; one instruction line on screen at start; touch SKIP TIPS chip. **VS-011** was split: the balance-harness half (**VS-019**: seed offset, honest medians, an economic policy that builds Defense Platforms) is done and keeps the HQ alive 6/6, but net worth still falls from min 20 to 30 in 6/6 seeds — that is now **VS-020** and needs a change to the game, not the harness. `check.sh` passes.

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md`. Request delete permission for the repo root (granted S0001/3/5/6/7/8 → git works). Use `git -c core.fileMode=false …` for status/add; commit with `git -c "user.name=Claude Studio" -c user.email=studio@localhost commit -F - <<'EOF'`.
2. **BUILD `VS-018`** First Sortie (P1 M) — `backlog.py next` returns it. VS-017 is done, so the target tip will become current when the wave appears (`TutorialHints.hostile_in`). Balance gate in its acceptance cites a stale 139k baseline — use the VS-019 baseline instead: economic 30 min seeds 101..186 nw20 median 105.6k (±15%), via `bash scripts/studio/balance.sh void-sovereign 30 3 economic 0 & bash scripts/studio/balance.sh void-sovereign 30 3 economic 3 & wait` (one device call, ~101 s).
3. **VS-020** (P1 M, late-game Hive pressure). Read its notes first: do NOT globally nerf raids (RAID_INTERVAL_MIN 75→100 + RAID_SIZE_MAX 16→13 made passive HQ survive 3/3) or buff the Defense Platform (shared with Union stations → passive median 37.6). Candidate levers: slow/cap Hive production after ~20 min (Hive 52 → 76–94 ships min 20→30), player-only platform variant, raids avoid platform sectors, miners flee the HQ sector during raids. Results swing ±50k per seed; consider 9 seeds (offset 6) before calling PASS.
4. Then P2s: VS-014 (pause-screen input; dock/map buttons clickable under pause overlay), VS-005 (surface marker declutter — QA saw overlapping pylon labels), VS-010, VS-007. VS-009 is size L — split it before building. VS-006 stays blocked until VS-020 lands (hive_20 median 52/58, max 65).
5. Health rule: builds_since_review = 2; a review round is due at 6.

## Last session
- Did:
  - **VS-011 → split.** **VS-019 done** (commit 03a1c16): `scripts/studio/balance.sh` 5th arg `first` / `scripts/tools/balance.gd --first=N`; summary has net_worth_30_median; a lost HQ counts as nw 0 afterwards; econ policy builds a Defense Platform at HQ from 10 min and a second from 18 min (rebuys fighters only if wing < 4 while saving). No game code changed. 6 seeds 101..186: nw20 105.6k, nw30 74.1k (was 33.6k), HQ 6/6; passive 40 min HQ lost 25.4/29.5/24.4. **VS-020** created for the unmet criterion (nw30 ≥ nw20).
  - **VS-017 done**: `scripts/ui/tutorial_hints.gd` (ready flags, `current()` skips not-ready steps, static `hostile_in`, static `on_screen`), `hud.gd` (capture line hidden during any tip; F/ACT prompt hidden only during steer/throttle tips), `space_view.gd` ("No hostiles in range" on manual R/TGT), `run_flow.gd` (welcome is just "Welcome, Sovereign." while a tip is pending), `overlay.gd` (title "P pause · H skip tips"), selftest h3 tip-order asserts, game.json, DESIGN.md. Touch: tip box no longer skips on tap; dedicated SKIP TIPS chip. QA FAIL once (welcome line was a 2nd instruction), fixed, re-verify PASS.
- Check: PASS · Git: 03a1c16 (VS-019) + `studio(S0008): VS-017 …` wrap-up commit · Roles collapsed: none

## In-flight / uncommitted work
none. Left uncommitted on purpose: Windows mount mode noise and Daniel's edits outside this game. Scratch: `.tools/s0008_*` (balance runs, diag scripts), `.tools/s0008_qa/`; device-VM probes in `$HOME/probe/`, `$HOME/probe_qa/` (not in the repo).

## Build health
- check.sh: PASS (~19 s). Selftest now includes h3 tip-order asserts (mutation-tested by QA: removing the `can_do` check fails check.sh).
- Known noise (not bugs): "ObjectDB instances leaked" / "resources still in use at exit"; ALSA errors under xvfb.
- Latest metrics: S0008 economic 30 min 6 seeds (new policy): HQ 6/6, nw20 105.6k, nw30 74.1k, hive_20 ~55; passive HQ lost median 25.4.

## Backlog snapshot
todo 7 · in-progress 0 · done 10 · blocked 1 · split 2 · ready 6 · Top ready: VS-018 First Sortie, VS-020 late-game Hive pressure, VS-014 pause-screen input

## Watch out for
- **Balance harness**: economic numbers from S0008 on are not comparable with S0003/S0007 (new defending policy; lost HQ = 0 nw). Fixed seed list 101,118,135 (first=0) + 152,169,186 (first=3). Background jobs die when a device call returns — run both halves with `& … & wait` in one call.
- **Defense Platform stats are shared with Union stations** — changing them moves passive HQ survival.
- **Tips**: `TutorialHints.on_screen` is a static read by hud.gd (prompt visibility depends on tip state). The target tip only becomes current when a Hive entity is in the player's sector (anywhere in it, not just in view). Touch SKIP TIPS chip sits ~13 px left of THR- at 1280x720; recheck narrow screens. TutorialHints `_input` runs before TouchControls. `emulate_mouse_from_touch=true` → every tap is also a click (VS-014).
- **Run flow**: the Universe steps only while PLAYING (`RunFlow.sim_runs`). Title backdrop is a still scene.
- **Trade pricing**: batches priced per unit along the curve; dock shows the spot price.
- `check.sh` fails on "SCRIPT ERROR" only (selftest assert failures do surface as "selftest errors" FAIL now — still read the whole output). main.gd is 306 lines — split before adding. Every sound via `Sfx.play()`. Default font has no arrow glyphs.
- Git needs delete permission (lock files). Never stage template/.github/starfall/.claude mode noise.

## Open questions for Daniel
- VS-020: if no clean lever is found, is a mild late decline acceptable (e.g. nw30 ≥ 0.7 × nw20 with HQ ≥ 5/6) instead of strict growth?
- Still open: should tutorial tips be remembered in the save file? Target session length (design assumes 30–40 min)?

## Answers to Daniel
- none new this session (INBOX was empty). Earlier rulings still apply: slower early game after VS-016 is fine; VS-007/VS-009 restored to todo; studio never pushes unless asked.

## Session history (newest first, keep 10)
- S0008 2026-10-26 BUILD — VS-011 split → VS-019 harness done (HQ 6/6, nw30 74k) + VS-020 open; VS-017 tutorial tips follow the world done (QA PASS after 1 fix round)
- S0007 2026-10-26 PLANNING+BUILD — first review round (critic 5.1/10) → VS-015..018; VS-015 title freeze/overlay fix + VS-016 trade arbitrage fix done (both QA PASS)
- S0006 2026-10-26 BUILD — VS-004 tutorial tips + VS-012 touch row/pause-mute/sfx assert done (both QA PASS); VS-013, VS-014 added
- S0005 2026-10-26 BUILD — took over stale S0004 lock; VS-003 procedural SFX done (QA PASS); VS-012 added
- S0004 2026-10-26 SUPERSEDED — took lock 03:32Z, device calls stalled ~8 h; resumed later as S0006
- S0003 2026-10-26 BUILD — cleaned up hung S0002; VS-001 mid-game rebalance done (nw20 8k→139k, HQ 5/6); VS-011 added
- S0002 2026-10-26 ABORTED — hung during VS-001, cancelled by Daniel; diff salvaged, no handover
- S0001 2026-10-26 BUILD — baseline commit; VS-002 trader reserve + VS-008 AI-journey selftest done; VS-010 added
- S0000 2026-10-25 SETUP — game v1 + AI studio + seeded backlog
