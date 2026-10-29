# Void Sovereign — Handover
_Last updated: S0064 · 2026-10-29 10:20 UTC · mode: BUILD_

## TL;DR
S0064 shipped VS-065 (gun clear of touch cluster, game-over Best line clear of ship, map scroll cue). Build green; 5 todo tasks ready. PLANNING due when builds_since_review reaches 6 (now 2).

## Next session should
1. BUILD VS-074 (S): map stakes - raid banner >= 14 px + fleet route lines. Run `RES=900x720 bash scripts/studio/shots.sh void-sovereign raid_map raid_map_damaged map` after, then check.sh.
2. VS-076 (S): move page building out of `scripts/ui/map_view.gd` (now ~660 lines) into map_pages.gd; add Build/Orders tab shots; 44 px order buttons.
3. VS-075 (P2 balance): lift weak-economy seeds 101/152/186/118; read `studio/reviews/S0062-balance.md` and VS-071 notes first.
4. VS-072 shakedown probe (S), VS-073 surface collapse/extract beat (M, split if needed).
5. Optional tiny tweak (parking lot): fps_player.gd GUN_X 0.02 is near-centre and hides the "Click to capture mouse" hint at 1280x720; try 0.10-0.15 or touch-only offset (re-check touch_surface at 900x720 so gun stays clear of ACT/FIRE).
6. builds_since_review is 2; PLANNING due at 6.

## Last session
- Did: BUILD VS-065 - fps_player.gd GUN_X, overlay.gd game-over Score/Best layout, map_view.gd scroll_clipped()/_update_scroll_cue() "more - scroll" label, test_driver.gd cue assert. QA PASS r1 (cue only verified in a forced-clip copy; no shipped shot clips the panel).
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit. Stale QA scratch in .tools/ (gitignored).

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0062 economic HQ 8/9, nw20 median 104590, nw30 106269; passive HQ lost median 28.2, earliest 23.6.

## Backlog snapshot
todo 5 · in-progress 0 · done 63 · blocked 3 · split 5 · Top ready: VS-074, VS-076, VS-075

## Watch out for
- device_bash calls cap ~120 s and background jobs die: run balance.sh / balance_gate.sh foreground, one GATE_OFFSETS per call.
- Strip is at the 44 px floor; fold_ok() briefly switches tabs and restores. Keys 1-3 select map tabs.
- check.sh does NOT run raid_map/raid_map_damaged/raid_map_touch shots; run them after map UI changes.
- shots.sh layout scales with window, so shorter RES does not force panel clipping.
- Judge passive balance WITHOUT --reserve. Do NOT `pkill -f godot`. Append new backlog tasks ABOVE "# Ideas parking lot".

## Open questions for Daniel
- VS-042 (real-browser pass, Critic's #1 problem for 10+ reviews) needs a headless browser: allow cdn.playwright.dev in egress or point to an installed chromium.
- Accept nw30 as aspirational, or keep chasing it (VS-075)?

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0064 2026-10-29 BUILD - VS-065 touch/panel polish done (QA PASS r1)
- S0063 2026-10-29 BUILD - VS-068 map tabs done (QA PASS r1); VS-076 added
- S0062 2026-10-29 PLANNING - review round -> VS-072..075; VS-071 blocked (no code change)
- S0061 2026-10-29 BUILD - VS-064 Nest cap growth 145 done (QA PASS r1)
- S0060 2026-10-29 BUILD - VS-070 raid_hit hardening done (QA PASS r1)
- S0059 2026-10-29 BUILD - VS-063 raid_hit shot + raid_hit_long done (QA PASS r1); VS-070 added
- S0058 2026-10-29 BUILD - VS-069 damaged-HQ strip compaction + raid_map_damaged shot done (QA PASS r1)
- S0057 2026-10-29 BUILD - VS-066 split; VS-067 pinned map command strip done (QA PASS r1); VS-069 added
- S0056 2026-10-29 PLANNING+BUILD - review round -> VS-063..066; VS-061 Reserve A/B done (QA PASS r1)
- S0055 2026-10-29 BUILD - VS-060 Reserve button done (QA PASS r1); VS-062 added
