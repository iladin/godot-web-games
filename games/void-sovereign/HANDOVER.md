# Void Sovereign — Handover
_Last updated: S0000 · 2026-10-25 16:30 PDT · mode: SETUP_

## TL;DR
Void Sovereign v1 is playable end to end (flight + trading, command map RTS, FPS planet surfaces, 7-sector living simulation) and `check.sh` passes. The AI studio is set up: a scheduled session runs every 5 hours, follows `ai-studio/studio-cycle.md`, and works the backlog. The first balance-harness run shows the mid-game is too punishing for an economic player — that's the most important design problem right now.

## Next session should
1. Preflight per the skill. Git: request delete permission; if granted, make the baseline commit `Add Void Sovereign + AI studio (baseline)` (the game folder, studio files, `ai-studio/roles`, `ai-studio/studio-cycle.md`, `scripts/studio`, `docs/AI_STUDIO.md`, CLAUDE.md, .gitignore) **before** any task work.
2. BUILD `VS-002` (player traders drain credits — size S bug, `scripts/sim/ship_ai.gd` `_trade` + `scripts/sim/universe.gd` `transact`). Then, if budget allows, `VS-008` (selftest coverage, size S).
3. Leave `VS-001` (rebalance) for its own session — it needs before/after balance runs (`bash scripts/studio/balance.sh void-sovereign 30 3 economic`, about 25 s per 30-minute seed on the device).

## Last session
- Did: built the game v1, wrote `docs/AI_STUDIO.md`, five role files in `ai-studio/roles/`, the `studio-cycle` skill, tooling in `scripts/studio/`, the balance harness `games/void-sovereign/scripts/tools/balance.gd`, and seeded BACKLOG (VS-001…VS-009).
- Check: PASS (on Daniel's computer, Godot 4.7.2 at `.tools/godot`) · Git: nothing committed yet · Roles collapsed: n/a

## In-flight / uncommitted work
Everything is uncommitted: `games/void-sovereign/` is untracked, plus the new studio files. `games/starfall/*` shows mode-only changes (Windows file mode) — that's Daniel's working copy, don't stage it.

## Build health
- check.sh: PASS · selftest: routing, pricing, transactions, production, 8 simulated minutes, Core→Nest unlock
- Known noise (not bugs): "N ObjectDB instances leaked at exit" / "resources still in use at exit" after headless runs; ALSA errors under xvfb.
- Latest metrics: see the S0000 row in `studio/metrics.csv`.

## Backlog snapshot
todo 9 · in-progress 0 · done 0 · ready 8 · Top ready: VS-002 player traders drain credits, VS-008 selftest AI journeys, VS-001 rebalance mid-game

## Watch out for
- The whole world is one data sim (`scripts/sim/`); views only render the current sector. Put gameplay rules in the sim, not in the views.
- All tunables live in `scripts/sim/defs.gd`. Typed const dictionaries — cast values (`float(Defs.SHIP[c]["hull"])`).
- `scripts/test_driver.gd` drives `--autoplay` (used by check.sh) and `--shot=` scenarios. Keep both working when changing modes or UI.
- On Daniel's computer, never run git write commands without delete permission (lock files). Use `git --no-optional-locks` for reads.
- The default font has no arrows/triangles (→ ▲ ▶ render as boxes on web). Use ASCII or draw shapes.
- Only one WorldEnvironment may be in the tree: SpaceView removes its env while the surface is active.

## Open questions for Daniel
- Do you want the studio to keep committing to `main` locally, or would you rather push the repo to GitHub so sessions can run in the cloud and open PRs instead?
- Target session length for a full game: the design assumes 30–40 minutes. Shorter?

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0000 2026-10-25 SETUP — game v1 + AI studio + seeded backlog
