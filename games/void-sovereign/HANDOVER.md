# Void Sovereign — Handover
_Last updated: S0060 · 2026-10-29 05:06 UTC · mode: BUILD_

## TL;DR
S0060 shipped VS-070: raid_hit proof now has a frame-based stuck cap and shots.sh reports FAILED on missing/stale raid_hit _2/_3 frames. Build green, QA PASS r1. Backlog: 3 todo (P2, size S): VS-064, VS-065, VS-068.

## Next session should
1. BUILD VS-064 (S): passive Hive cap trim in defs.gd; 9 single-seed passive calls WITHOUT --reserve (timeout 175 each, ~35 s/seed), economic gate HQ >= 8/9; append metrics.csv row; update DESIGN Ramp bullet.
2. BUILD VS-068 (S): Buy/Build/Orders tabs (>= 44 px) below the strip; split tab helper out of `scripts/ui/map_view.gd` (~596 lines). Then `RES=1280x720 bash scripts/studio/shots.sh void-sovereign raid_map raid_map_damaged map dock` and at 900x720, then check.sh. Then VS-065.
3. builds_since_review is 5; PLANNING round due after the next build (health rule at 6).
4. Optional tiny tweak: lower STUCK_FRAMES in `scripts/raid_hit_proof.gd` to ~7000 (or raise shots.sh raid_hit timeout) so the proof diagnostic can print before the 150 s timeout. Parking lot: Sovereign's Decree, Director UNION_QUOTA counts reserve ships, partial-repair shot.

## Last session
- Did: VS-070 done. raid_hit_proof.gd: STUCK_FRAMES=30000 frame counter replaces 80 s cap; shots.sh greps "ERROR: raid_hit" and prints FAILED (rc=1) if raid_hit _2/_3 missing or stale. QA: 3 consecutive runs gave 3 fresh frames (44-123 s), FAILED path tested via SHOT_TIMEOUT=8, frame viewed.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit. Scratch under `.tools/` is gitignored.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit; git may warn about HEAD.lock unlink.
- Latest metrics: unchanged since S0056 (economic 9/9 HQ, nw30 median 168k).

## Backlog snapshot
todo 3 · in-progress 0 · done 60 · blocked 2 · split 5 · Top ready: VS-064, VS-065, VS-068

## Watch out for
- raid_hit takes 44-123 s wall (shots.sh timeout 150 s); check.sh needs GODOT=$PWD/.tools/godot exported; QA left scratch `.tools/run1`, `.tools/run2` (gitignored).
- Strip is at the 44 px floor with 1 px spacing and an 11 px forecast; any added strip content will break the fold assert until VS-068 tabs land.
- check.sh does NOT run raid_map/raid_map_damaged/raid_map_touch shots; run them after any map UI change.
- With --reserve the bot rescues passive seed 101; judge passive balance gates WITHOUT --reserve.
- 900x720 window renders virtual 1280x1024 viewport. /tmp not writable from device shell; logs under .tools/. Do NOT `pkill -f godot`. Append new backlog tasks ABOVE "# Ideas parking lot".

## Open questions for Daniel
- VS-042 needs a headless browser: allow cdn.playwright.dev in egress or point to an installed chromium (real-browser pass still unverified).

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0060 2026-10-29 BUILD - VS-070 raid_hit hardening done (QA PASS r1)
- S0059 2026-10-29 BUILD - VS-063 raid_hit shot + raid_hit_long done (QA PASS r1); VS-070 added
- S0058 2026-10-29 BUILD - VS-069 damaged-HQ strip compaction + raid_map_damaged shot done (QA PASS r1)
- S0057 2026-10-29 BUILD - VS-066 split; VS-067 pinned map command strip done (QA PASS r1); VS-069 added
- S0056 2026-10-29 PLANNING+BUILD - review round -> VS-063..066; VS-061 Reserve A/B done (QA PASS r1)
- S0055 2026-10-29 BUILD - VS-060 Reserve button done (QA PASS r1); VS-062 added
- S0054 2026-10-28 BUILD - VS-059 Fleet Reserve sim logic done (QA PASS r1)
- S0053 2026-10-28 BUILD - VS-057 split (059/060/061); VS-058 touch HUD lane done (QA PASS r2)
- S0052 2026-10-28 BUILD - VS-056 Hive cap trim + --fleet-floor done (QA PASS r1)
- S0051 2026-10-28 BUILD - VS-055 HQ hull readout done (QA PASS r1)
