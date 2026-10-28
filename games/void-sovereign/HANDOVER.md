# Void Sovereign — Handover
_Last updated: S0053 · 2026-10-28 22:30 UTC · mode: BUILD_

## TL;DR
S0053 split VS-057 (Fleet Reserve) into three S tasks and shipped VS-058 (single bottom message lane on touch HUD, respaced touch buttons, merged pylon labels, thousands separators). Build green; 3 ready todos (VS-059, 060, 061). VS-042 still blocked on network allowlist.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (next id S0054, `export GODOT=$PWD/.tools/godot`, check.sh with `timeout 175`). If `.git/*.lock` exists, `mv` it to `.git/stale-...`.
2. BUILD VS-059 (Reserve sim logic: Defs RESERVE_COST/COUNT/LINGER/COOLDOWN, call_reserve(), ledger entry, selftest, `--reserve` flag in scripts/tools/balance.gd). Baseline for later A/B: passive 40 min no floor HQ lost median 25.8; see studio/reviews/S0052-dev-fleetfloor.md.
3. Then VS-060 (map/dock button UI), then VS-061 (9-seed A/B; run seeds as parallel single-seed calls).
4. builds_since_review is 4; planning round due after 6. Parking-lot P3: map Close pin at tall viewports only, sortie-on-touch shot, raid_map_touch fold check in selftest.
5. Balance: watch economic nw30 (168k after S0052) for an economy that is too easy.

## Last session
- Did: VS-057 split; VS-058 done (hud_lane.gd new; hud.gd, tutorial_hints.gd, touch_controls.gd, overlay.gd, selftest.gd, test_driver.gd). QA r1 FAIL (pinned Close broke 1280x720 fold assert) -> reverted map pin -> QA r2 PASS.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: unchanged from S0052 (no balance run this session; HUD-only change).

## Backlog snapshot
todo 3 · in-progress 0 · done 52 · blocked 2 · split 4 · Top ready: VS-059, VS-060, VS-061

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
- S0053 2026-10-28 BUILD - VS-057 split (059/060/061); VS-058 touch HUD lane done (QA PASS r2)
- S0052 2026-10-28 BUILD - VS-056 Hive cap trim + --fleet-floor done (QA PASS r1)
- S0051 2026-10-28 BUILD - VS-055 HQ hull readout done (QA PASS r1)
- S0050 2026-10-28 PLANNING+BUILD - review round -> VS-054..058; VS-054 raid forecast done (QA PASS r1)
- S0049 2026-10-28 BUILD - VS-044 redirect A/B done (stays off, QA PASS r1); VS-042 blocked (no export templates)
- S0048 2026-10-28 BUILD - VS-051 raid chip damage done (QA PASS r1)
- S0047 2026-10-28 BUILD - VS-053 signed credit deltas + full-hull status rows done (QA PASS r2)
- S0046 2026-10-28 BUILD - VS-052 bot repairs HQ in harness done (QA PASS r1)
- S0045 2026-10-28 BUILD - VS-050 wounded HQ penalty done (QA PASS r2)
- S0044 2026-10-28 PLANNING+BUILD - review round -> VS-049..053; VS-049 surface freeze fixed (QA PASS)
