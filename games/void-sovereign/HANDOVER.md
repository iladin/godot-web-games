# Void Sovereign — Handover
_Last updated: S0066 · 2026-10-29 12:15 UTC · mode: BUILD_

## TL;DR
S0066 shipped VS-073 (22 s base collapse after Core death: extraction zone 150 m toward ship, reinforcements every 6 s, auto-extract or evacuation on timeout). QA PASS r1, check green. 3 todo tasks ready; PLANNING due when builds_since_review reaches 6 (now 4).

## Next session should
1. BUILD VS-074 (S): map stakes - raid banner >= 14 px + fleet route lines. Run `RES=900x720 bash scripts/studio/shots.sh void-sovereign raid_map raid_map_damaged map` after, then check.sh.
2. VS-076 (S): move page building out of `scripts/ui/map_view.gd` (~660 lines) into map_pages.gd; add Build/Orders tab shots; 44 px order buttons.
3. Run `shots.sh void-sovereign raid_hit` alone (SHOT_TIMEOUT=150) to confirm VS-072 probe left it intact.
4. VS-075 (P2 balance): lift weak-economy seeds 101/152/186/118; read studio/reviews/S0062-balance.md first; run balance_gate.sh one GATE_OFFSETS per call.
5. Add DESIGN.md surface-section text for the collapse beat (consts COLLAPSE_* / EXTRACT_* in sim/defs.gd); optionally a shot facing the EXTRACT beacon (marker not yet visually confirmed) and check timeout message reads as evacuation not death.
6. builds_since_review is 4; PLANNING due at 6.

## Last session
- Did: BUILD VS-073 - surface_view.gd _begin_collapse(), defs.gd COLLAPSE_*/EXTRACT_* consts, selftest _test_surface_collapse, test_driver shots surface_collapse(+_long). QA PASS r1.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0062 economic HQ 8/9, nw20 median 104590, nw30 106269; passive HQ lost median 28.2, earliest 23.6.

## Backlog snapshot
todo 3 · in-progress 0 · done 65 · blocked 3 · split 5 · Top ready: VS-074, VS-076, VS-075

## Watch out for
- Dev subagent wrongly claimed stock surface_long dies at t~49; QA ran it and Core dies t=67, boards t=84. Don't skip it.
- device_bash calls cap ~120 s and background jobs die: run balance.sh / balance_gate.sh foreground, one GATE_OFFSETS per call.
- Strip is at the 44 px floor; fold_ok() briefly switches tabs and restores. Keys 1-3 select map tabs.
- check.sh does NOT run raid_map/raid_map_damaged/raid_map_touch shots; run them after map UI changes.
- Judge passive balance WITHOUT --reserve. Do NOT `pkill -f godot`. Append new backlog tasks ABOVE "# Ideas parking lot".
- Collapse timeout reuses player_died (hull loss); human players have a 22 s sprint (tune COLLAPSE_TIME/EXTRACT_DIST if harsh).

## Open questions for Daniel
- VS-042 (real-browser pass, Critic's #1 problem for 10+ reviews) needs a headless browser: allow cdn.playwright.dev in egress or point to an installed chromium.
- Accept nw30 as aspirational, or keep chasing it (VS-075)?

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0066 2026-10-29 BUILD - VS-073 surface collapse-and-extract beat done (QA PASS r1)
- S0065 2026-10-29 BUILD - VS-072 shakedown probe done (QA r2 PASS)
- S0064 2026-10-29 BUILD - VS-065 touch/panel polish done (QA PASS r1)
- S0063 2026-10-29 BUILD - VS-068 map tabs done (QA PASS r1); VS-076 added
- S0062 2026-10-29 PLANNING - review round -> VS-072..075; VS-071 blocked (no code change)
- S0061 2026-10-29 BUILD - VS-064 Nest cap growth 145 done (QA PASS r1)
- S0060 2026-10-29 BUILD - VS-070 raid_hit hardening done (QA PASS r1)
- S0059 2026-10-29 BUILD - VS-063 raid_hit shot + raid_hit_long done (QA PASS r1); VS-070 added
- S0058 2026-10-29 BUILD - VS-069 damaged-HQ strip compaction + raid_map_damaged shot done (QA PASS r1)
- S0057 2026-10-29 BUILD - VS-066 split; VS-067 pinned map command strip done (QA PASS r1); VS-069 added
