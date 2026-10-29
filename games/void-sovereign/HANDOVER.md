# Void Sovereign — Handover
_Last updated: S0059 · 2026-10-29 04:35 UTC · mode: BUILD_

## TL;DR
S0059 shipped VS-063: `raid_hit` shot (3 frames: forecast, impact HQ ~95%, Reserve arrived) and headless `raid_hit_long` log, both via new `scripts/raid_hit_proof.gd`. Build green, QA PASS r1. Backlog: 4 todo (all P2, size S); VS-070 added for a flakiness fix.

## Next session should
1. BUILD VS-070 (S): harden raid_hit (raise 80 s stuck cap in `scripts/raid_hit_proof.gd`, grep "ERROR: raid_hit" and fail on missing _2/_3 in `scripts/studio/shots.sh`); 3 consecutive runs must give 3 frames.
2. BUILD VS-068 (S): Buy/Build/Orders tabs (>= 44 px) below the strip; split tab helper out of `scripts/ui/map_view.gd` (~596 lines). Then `RES=1280x720 bash scripts/studio/shots.sh void-sovereign raid_map raid_map_damaged map dock` and at 900x720, then check.sh.
3. BUILD VS-064 (S): passive Hive cap trim in defs.gd; 9 single-seed passive calls WITHOUT --reserve, economic gate HQ >= 8/9; append metrics.csv row. Then VS-065 (after VS-068).
4. builds_since_review is 4; PLANNING round due after ~6 builds. Parking lot: Sovereign's Decree, Director UNION_QUOTA counts reserve ships, partial-repair shot.

## Last session
- Did: VS-063 done. raid_hit: 4 Hive drones (hull x12, scenario only) raid the HQ sector, real RaidTracker + Universe.call_reserve(); frames `raid_hit.png`, `raid_hit_2.png`, `raid_hit_3.png` (shots.sh now reports extras). raid_hit_long prints hq%/reserve/credits every 30 s (HQ 94% from t=60). QA viewed all frames.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit. Scratch under `.tools/` is gitignored.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit; git may warn about HEAD.lock unlink.
- Latest metrics: unchanged since S0056 (economic 9/9 HQ, nw30 median 168k).

## Backlog snapshot
todo 4 · in-progress 0 · done 59 · blocked 2 · split 5 · Top ready: VS-064, VS-065, VS-068, VS-070

## Watch out for
- raid_hit takes 45-85 s wall and flaked once in 4 QA runs (VS-070); QA left scratch `.tools/run1`, `.tools/run2` (gitignored).
- Strip is at the 44 px floor with 1 px spacing and an 11 px forecast; any added strip content will break the fold assert until VS-068 tabs land.
- check.sh does NOT run raid_map/raid_map_damaged/raid_map_touch shots; run them after any map UI change.
- With --reserve the bot rescues passive seed 101; judge passive balance gates WITHOUT --reserve.
- 900x720 window renders virtual 1280x1024 viewport. /tmp not writable from device shell; logs under .tools/. Do NOT `pkill -f godot`. Append new backlog tasks ABOVE "# Ideas parking lot".

## Open questions for Daniel
- VS-042 needs a headless browser: allow cdn.playwright.dev in egress or point to an installed chromium (real-browser pass still unverified).

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0059 2026-10-29 BUILD - VS-063 raid_hit shot + raid_hit_long done (QA PASS r1); VS-070 added
- S0058 2026-10-29 BUILD - VS-069 damaged-HQ strip compaction + raid_map_damaged shot done (QA PASS r1)
- S0057 2026-10-29 BUILD - VS-066 split; VS-067 pinned map command strip done (QA PASS r1); VS-069 added
- S0056 2026-10-29 PLANNING+BUILD - review round -> VS-063..066; VS-061 Reserve A/B done (QA PASS r1)
- S0055 2026-10-29 BUILD - VS-060 Reserve button done (QA PASS r1); VS-062 added
- S0054 2026-10-28 BUILD - VS-059 Fleet Reserve sim logic done (QA PASS r1)
- S0053 2026-10-28 BUILD - VS-057 split (059/060/061); VS-058 touch HUD lane done (QA PASS r2)
- S0052 2026-10-28 BUILD - VS-056 Hive cap trim + --fleet-floor done (QA PASS r1)
- S0051 2026-10-28 BUILD - VS-055 HQ hull readout done (QA PASS r1)
- S0050 2026-10-28 PLANNING+BUILD - review round -> VS-054..058; VS-054 raid forecast done (QA PASS r1)
