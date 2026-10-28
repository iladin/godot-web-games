# Void Sovereign — Handover
_Last updated: S0054 · 2026-10-28 23:05 UTC · mode: BUILD_

## TL;DR
S0054 shipped VS-059 (Fleet Reserve sim logic: Universe.call_reserve(), RESERVE_* tunables, ledger 'reserve', save fields, selftest, harness --reserve flag). Build green; 2 ready todos (VS-060 UI, VS-061 A/B). VS-042 still blocked on network allowlist.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (next id S0055, `export GODOT=$PWD/.tools/godot`, check.sh with `timeout 175`). If `.git/*.lock` exists, `mv` it to `.git/stale-...`.
2. BUILD VS-060: map and dock 'Call Reserve (N cr)' button calling `Universe.call_reserve()` (returns "" on success, else reason string; `reserve_cooldown_left()` for the label). Touch + mouse; run `RES=1280x720 bash scripts/studio/shots.sh void-sovereign raid_map raid_map_touch map dock` and have QA look (VS-043 fold assert).
3. Then VS-061 (9-seed A/B economic 30 with --reserve; single-seed parallel calls). Tunables in defs.gd are untuned dev picks (cost 4000, count 6, linger 180 s) - retune there if A/B misses.
4. builds_since_review is 5; planning round due after 6 (so after VS-060/061 or at S0056 start). Parking lot P3: Director UNION_QUOTA counts reserve ships (director.gd ~246), map Close pin at tall viewports, sortie-on-touch shot.
5. Balance: watch economic nw30 (168k after S0052) for an economy that is too easy.

## Last session
- Did: VS-059 done (defs.gd, universe.gd, ship_data.gd expires, ledger.gd, save_game.gd, hud.gd delta word, tools/balance.gd --reserve, selftest _test_reserve). QA PASS r1. Passive seed 101 with --reserve: HQ alive at 30 min vs lost 24.4 (single seed, not a gate).
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: unchanged from S0052 (no balance run this session; HUD-only change).

## Backlog snapshot
todo 2 · in-progress 0 · done 53 · blocked 2 · split 4 · Top ready: VS-060, VS-061

## Watch out for
- check.sh does NOT run the raid_map/raid_map_touch shots; run `RES=1280x720 bash scripts/studio/shots.sh void-sovereign raid_map raid_map_touch map` after any map UI change (VS-043 fold assert).
- 900x720 window renders a virtual 1280x1024 viewport (stretch canvas_items/expand).
- Touch lane: tips yield to a fresh objective (10 s), forecast, sortie; trade hint delayed to T+90 s on touch.
- Critic: bigger bot repair reserve is NOT the fix for late collapse. Redirect stays off. Do NOT `pkill -f godot`. Balance runs sequential or parallel single-seed, foreground `timeout 175`.
- Harness lives in scripts/tools/balance.gd. Git writes may leave tmp_obj/lock warnings; commits still succeed.
- Backlog: append new tasks ABOVE the "# Ideas parking lot" heading (below it they are not parsed).

## Open questions for Daniel
- VS-042 needs a headless browser: allow cdn.playwright.dev in egress or point to an installed chromium.

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0054 2026-10-28 BUILD - VS-059 Fleet Reserve sim logic done (QA PASS r1)
- S0053 2026-10-28 BUILD - VS-057 split (059/060/061); VS-058 touch HUD lane done (QA PASS r2)
- S0052 2026-10-28 BUILD - VS-056 Hive cap trim + --fleet-floor done (QA PASS r1)
- S0051 2026-10-28 BUILD - VS-055 HQ hull readout done (QA PASS r1)
- S0050 2026-10-28 PLANNING+BUILD - review round -> VS-054..058; VS-054 raid forecast done (QA PASS r1)
- S0049 2026-10-28 BUILD - VS-044 redirect A/B done (stays off, QA PASS r1); VS-042 blocked (no export templates)
- S0048 2026-10-28 BUILD - VS-051 raid chip damage done (QA PASS r1)
- S0047 2026-10-28 BUILD - VS-053 signed credit deltas + full-hull status rows done (QA PASS r2)
- S0046 2026-10-28 BUILD - VS-052 bot repairs HQ in harness done (QA PASS r1)
- S0045 2026-10-28 BUILD - VS-050 wounded HQ penalty done (QA PASS r2)
