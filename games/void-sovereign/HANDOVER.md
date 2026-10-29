# Void Sovereign — Handover
_Last updated: S0063 · 2026-10-29 09:15 UTC · mode: BUILD_

## TL;DR
S0063 shipped VS-068 (Buy/Build/Orders tabs on the map side panel, QA PASS). Build is green; 6 todo tasks ready (VS-076 follow-up added). Next PLANNING due after 5 more builds.

## Next session should
1. BUILD VS-065 (S): 900x720 touch spacing / panel polish. Now that tabs exist, re-check the map panel at 900x720: `RES=900x720 bash scripts/studio/shots.sh void-sovereign raid_map raid_map_damaged map dock`, then check.sh.
2. VS-074 (S): map stakes - raid banner >= 14 px + fleet route lines (tabs from VS-068 are in place).
3. VS-076 (S): move page building out of `scripts/ui/map_view.gd` (645 lines) into a map_pages.gd; add Build/Orders tab shots; 44 px order buttons.
4. VS-075 (P2 balance): lift weak-economy seeds 101/152/186/118; read `studio/reviews/S0062-balance.md` and VS-071 notes first.
5. VS-072 shakedown probe (S), VS-073 surface collapse/extract beat (M, split if needed).
6. builds_since_review is 1; PLANNING due at 6.

## Last session
- Did: BUILD VS-068 - new `scripts/ui/map_tabs.gd` (MapTabs: 44 px tabs, keys 1-3), `map_view.gd` side panel = pinned strip, tabs, scroll (Defend + raid label always shown), pinned Close map; `test_driver.gd` asserts tabs/fold. QA PASS r1 (P3 notes: Orders info text scrolls at 1280x720, order buttons 34 px, raid_map_touch identical to raid_map, raid outcome line ellipsis-trimmed).
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0062 economic HQ 8/9, nw20 median 104590, nw30 106269; passive HQ lost median 28.2, earliest 23.6.

## Backlog snapshot
todo 6 · in-progress 0 · done 62 · blocked 3 · split 5 · Top ready: VS-065, VS-074, VS-076

## Watch out for
- Earliest HQ loss is very seed-sensitive; economic HQ 8/9 has no margin; the new nw30 target currently reads red at baseline.
- device_bash calls cap ~120 s and background jobs die: run balance.sh / balance_gate.sh foreground, one GATE_OFFSETS per call (all three in one call times out).
- Strip is at the 44 px floor; fold_ok() briefly switches tabs and restores. Keys 1-3 select map tabs while the map is open.
- check.sh does NOT run raid_map/raid_map_damaged/raid_map_touch shots; run them after map UI changes.
- Judge passive balance WITHOUT --reserve. Do NOT `pkill -f godot`. Append new backlog tasks ABOVE "# Ideas parking lot".
- Parking lot: Sovereign's Decree (needs VS-068), UNION_QUOTA counts reserve ships, partial-repair shot.

## Open questions for Daniel
- VS-042 (real-browser pass, Critic's #1 problem for 10 reviews) needs a headless browser: allow cdn.playwright.dev in egress or point to an installed chromium.
- Accept nw30 as aspirational, or keep chasing it (VS-075)?

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0063 2026-10-29 BUILD - VS-068 map tabs done (QA PASS r1); VS-076 added
- S0062 2026-10-29 PLANNING - review round -> VS-072..075; VS-071 blocked (no code change)
- S0061 2026-10-29 BUILD - VS-064 Nest cap growth 145 done (QA PASS r1)
- S0060 2026-10-29 BUILD - VS-070 raid_hit hardening done (QA PASS r1)
- S0059 2026-10-29 BUILD - VS-063 raid_hit shot + raid_hit_long done (QA PASS r1); VS-070 added
- S0058 2026-10-29 BUILD - VS-069 damaged-HQ strip compaction + raid_map_damaged shot done (QA PASS r1)
- S0057 2026-10-29 BUILD - VS-066 split; VS-067 pinned map command strip done (QA PASS r1); VS-069 added
- S0056 2026-10-29 PLANNING+BUILD - review round -> VS-063..066; VS-061 Reserve A/B done (QA PASS r1)
- S0055 2026-10-29 BUILD - VS-060 Reserve button done (QA PASS r1); VS-062 added
- S0054 2026-10-28 BUILD - VS-059 Fleet Reserve sim logic done (QA PASS r1)
