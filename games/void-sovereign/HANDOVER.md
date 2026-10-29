# Void Sovereign — Handover
_Last updated: S0057 · 2026-10-29 02:20 UTC · mode: BUILD_

## TL;DR
S0057 split VS-066 and shipped VS-067: a pinned MapStrip (raid forecast, Call Reserve 46 px, Repair HQ) above the scrolling map side panel. Build green, QA PASS r1. QA found one P2 (VS-069): with a damaged HQ the strip pushes the BUILD grid 6 px past the fold at 1280x720. Backlog: 5 todo.

## Next session should
1. BUILD VS-069 (S): compact the strip in `scripts/ui/map_strip.gd` (forecast font 13, Repair button 44 px, or Repair beside Reserve); add a damaged-HQ shot scenario (`raid_map_damaged`) in `scripts/test_driver.gd` asserting Repair visible, >=44 px, VS-043 fold ok at 1280x720 and 900x720. Run `RES=1280x720 bash scripts/studio/shots.sh void-sovereign raid_map map dock` then check.sh.
2. BUILD VS-068 (S): Buy/Build/Orders tabs below the strip; split the tab helper out of map_view.gd (now ~596 lines).
3. BUILD VS-064 (passive Hive cap trim in defs.gd; 9 single-seed passive calls without --reserve, then economic gate HQ >= 8/9; append metrics.csv row).
4. BUILD VS-063 (raid_hit shot + raid_hit_long log), then VS-065 (900x720 touch/panel polish, after VS-068).
5. builds_since_review is 2; next review round after ~6 builds. Parking lot: Sovereign's Decree, Director UNION_QUOTA counts reserve ships.

## Last session
- Did: split VS-066 -> VS-067/068; VS-067 done (Developer + independent QA PASS r1); VS-062 closed as superseded; VS-069 added.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit. Scratch dirs from QA/dev under `.tools/` (qc, q1280x720, q900x720, shots/vs067) are gitignored; may be moved to `_to_delete/`.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit. git commits may warn about HEAD.lock unlink.
- Latest metrics: unchanged since S0056 (economic 9/9 HQ, nw30 median 168k).

## Backlog snapshot
todo 5 · in-progress 0 · done 57 · blocked 2 · split 5 · Top ready: VS-069, VS-063, VS-064, VS-065, VS-068

## Watch out for
- VS-067 layout changes beyond the strip: orders grid 4 cols with short labels (Escort/Trade/Mine, "Tap: ON/OFF"), Buy/Build font 14 / 40 px, credits line now on the map canvas at (16,58).
- Repair HQ partial repair with credits < cost: label shows full cost (P3).
- With --reserve the bot rescues passive seed 101; judge passive balance gates WITHOUT --reserve.
- check.sh does NOT run raid_map/raid_map_touch shots; run them after any map UI change.
- 900x720 window renders virtual 1280x1024 viewport. /tmp not writable from device shell; logs under .tools/. Do NOT `pkill -f godot`. Append new backlog tasks ABOVE "# Ideas parking lot".

## Open questions for Daniel
- VS-042 needs a headless browser: allow cdn.playwright.dev in egress or point to an installed chromium (real-browser pass still unverified).

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0057 2026-10-29 BUILD - VS-066 split; VS-067 pinned map command strip done (QA PASS r1); VS-069 added
- S0056 2026-10-29 PLANNING+BUILD - review round -> VS-063..066; VS-061 Reserve A/B done (QA PASS r1)
- S0055 2026-10-29 BUILD - VS-060 Reserve button done (QA PASS r1); VS-062 added
- S0054 2026-10-28 BUILD - VS-059 Fleet Reserve sim logic done (QA PASS r1)
- S0053 2026-10-28 BUILD - VS-057 split (059/060/061); VS-058 touch HUD lane done (QA PASS r2)
- S0052 2026-10-28 BUILD - VS-056 Hive cap trim + --fleet-floor done (QA PASS r1)
- S0051 2026-10-28 BUILD - VS-055 HQ hull readout done (QA PASS r1)
- S0050 2026-10-28 PLANNING+BUILD - review round -> VS-054..058; VS-054 raid forecast done (QA PASS r1)
- S0049 2026-10-28 BUILD - VS-044 redirect A/B done (stays off, QA PASS r1); VS-042 blocked (no export templates)
- S0048 2026-10-28 BUILD - VS-051 raid chip damage done (QA PASS r1)
