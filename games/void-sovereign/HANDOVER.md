# Void Sovereign — Handover
_Last updated: S0061 · 2026-10-29 07:05 UTC · mode: BUILD_

## TL;DR
S0061 shipped VS-064: NEST_CAP_GROWTH 126->145 in defs.gd (Hive cap at 20 min 15->14). Passive and economic gates met, QA PASS r1, check PASS. builds_since_review is now 6, so the health rule requires a PLANNING round next. Backlog: 2 todo (P2, size S): VS-065, VS-068.

## Next session should
1. Run PLANNING first (health rule, builds_since_review=6): Critic + QA sweep + Balance Analyst in parallel, then Feature Scout; create 4-8 tasks. Balance Analyst: re-check economic seed 186 (HQ lost 23.7 min, economic HQ 8/9 is at the gate floor) and fill the nw10/nw30/union columns in metrics.csv that the S0061 rows left blank.
2. Then BUILD VS-068 (S): Buy/Build/Orders tabs (>= 44 px) below the strip; split tab helper out of `scripts/ui/map_view.gd` (~596 lines). Then `RES=1280x720 bash scripts/studio/shots.sh void-sovereign raid_map raid_map_damaged map dock` and at 900x720, then check.sh.
3. Then VS-065 (900x720 touch/panel polish; do the map-panel part after VS-068).
4. Optional tiny tweak: lower STUCK_FRAMES in `scripts/raid_hit_proof.gd` to ~7000 (or raise shots.sh raid_hit timeout). Parking lot: Sovereign's Decree, Director UNION_QUOTA counts reserve ships, partial-repair shot.

## Last session
- Did: VS-064 done. defs.gd NEST_CAP_GROWTH 145 (140 -> earliest passive HQ loss 19.1 min, 150 -> 20.6, both fail); selftest nest cap assert 15->14; DESIGN.md Ramp bullet; 2 metrics.csv rows. Passive 9 seeds: hive_ships_20 median 56 / q3 60, HQ lost median 28.2, earliest 23.6. Economic 9 seeds: HQ 8/9, nw20 median 104590, hive_ships_20 median 53. QA re-ran all seeds, same numbers.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit. Scratch under `.tools/` is gitignored.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit; git may warn about HEAD.lock unlink.
- Latest metrics: S0061 passive hive_ships_20 median 56, economic nw20 median 104590, HQ 8/9.

## Backlog snapshot
todo 2 · in-progress 0 · done 61 · blocked 2 · split 5 · Top ready: VS-068, VS-065

## Watch out for
- Earliest HQ loss is very seed-sensitive; any sim change can move it. Economic HQ 8/9 has no spare margin.
- device_bash calls cap ~120 s and background jobs die when the call returns: run balance.sh foreground, 3-4 seeds per call.
- raid_hit takes 44-123 s wall (shots.sh timeout 150 s); check.sh needs GODOT=$PWD/.tools/godot exported.
- Strip is at the 44 px floor with 1 px spacing and an 11 px forecast; any added strip content will break the fold assert until VS-068 tabs land.
- check.sh does NOT run raid_map/raid_map_damaged/raid_map_touch shots; run them after any map UI change.
- With --reserve the bot rescues passive seed 101; judge passive balance gates WITHOUT --reserve.
- 900x720 window renders virtual 1280x1024 viewport. /tmp not writable from device shell; logs under .tools/. Do NOT `pkill -f godot`. Append new backlog tasks ABOVE "# Ideas parking lot".

## Open questions for Daniel
- VS-042 needs a headless browser: allow cdn.playwright.dev in egress or point to an installed chromium (real-browser pass still unverified).

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0061 2026-10-29 BUILD - VS-064 Nest cap growth 145 done (QA PASS r1)
- S0060 2026-10-29 BUILD - VS-070 raid_hit hardening done (QA PASS r1)
- S0059 2026-10-29 BUILD - VS-063 raid_hit shot + raid_hit_long done (QA PASS r1); VS-070 added
- S0058 2026-10-29 BUILD - VS-069 damaged-HQ strip compaction + raid_map_damaged shot done (QA PASS r1)
- S0057 2026-10-29 BUILD - VS-066 split; VS-067 pinned map command strip done (QA PASS r1); VS-069 added
- S0056 2026-10-29 PLANNING+BUILD - review round -> VS-063..066; VS-061 Reserve A/B done (QA PASS r1)
- S0055 2026-10-29 BUILD - VS-060 Reserve button done (QA PASS r1); VS-062 added
- S0054 2026-10-28 BUILD - VS-059 Fleet Reserve sim logic done (QA PASS r1)
- S0053 2026-10-28 BUILD - VS-057 split (059/060/061); VS-058 touch HUD lane done (QA PASS r2)
- S0052 2026-10-28 BUILD - VS-056 Hive cap trim + --fleet-floor done (QA PASS r1)
