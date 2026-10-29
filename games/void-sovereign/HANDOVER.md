# Void Sovereign — Handover
_Last updated: S0072 · 2026-10-29 18:10 UTC · mode: BUILD_

## TL;DR
S0072 closed VS-078: touch THR+/THR- moved inboard and wing buttons rehomed to a bottom-left column; selftest now asserts >=44 px buttons at 1280x720 and 900x720. Build green; builds_since_review = 3.

## Next session should
1. BUILD VS-079 (S, payback labels on Buy/Build/Reserve buttons + first-spend hint); `python3 scripts/studio/backlog.py next games/void-sovereign/studio/BACKLOG.md` picks.
2. Then M tasks: VS-080 Core Defenders, VS-081 Standing orders on sector view, VS-082 Sovereign's Decree (run balance after each).
3. Optional P3 VS-083: trial RAID_SIZE_GROWTH 100 (passive seed 169 loses at 19.2 min), then economic 9 seeds.
4. Add DESIGN.md surface text for the collapse beat; run `shots.sh void-sovereign raid_hit` alone (SHOT_TIMEOUT=150).
5. P3 parked: Orders-tab scroll cue overlaps 'Ways to earn:' line at 1280x720; raid_map_touch doesn't enable touch mode. builds_since_review=3; PLANNING due at 6.

## Last session
- Did: BUILD VS-078 (Dev -> independent QA PASS r1). Files: scripts/ui/touch_controls.gd, scripts/selftest.gd.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit.

## Build health
- check.sh: PASS (export GODOT=$PWD/.tools/godot first or it reports "godot not found") · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0069 economic HQ 9/9, nw30 median 132396; passive (S0071, no reserve) HQ lost median 28.4 min.

## Backlog snapshot
todo 5 · in-progress 0 · done 70 · blocked 3 · split 5 · Top ready: VS-079, VS-080, VS-081

## Watch out for
- device_bash calls cap ~120 s and background jobs die: run balance.sh / shots foreground, one GATE_OFFSETS per call.
- Strip is at the 44 px floor; keys 1-3 select map tabs. check.sh does NOT run raid_map* shots.
- Passive balance = NO --reserve (decided S0071). Do NOT `pkill -f godot`. Append new backlog tasks ABOVE "# Ideas parking lot".
- NEST_CAP_GROWTH 135/140 rejected. Shot runs share a user:// save, so Best score varies.
- Dev subagents may mis-claim surface_long outcomes; QA must run it.

## Open questions for Daniel
- VS-042 (real-browser pass, Critic's #1 for 11 reviews): please play the exported build once in a real browser, or allow cdn.playwright.dev / point to an installed chromium.
- OK that the passive earliest-loss guard (>= 22 min) is now advisory rather than a hard gate? (VS-077)

## Answers to Daniel
- Passive gate runs without --reserve (nobody plays); see S0071-balance-gate.md.

## Session history (newest first, keep 10)
- S0072 2026-10-29 BUILD - VS-078 touch cluster rehome done (QA PASS r1)
- S0071 2026-10-29 BUILD - VS-077 passive gate defined (no --reserve), docs only (QA PASS r1); VS-083 added
- S0070 2026-10-29 BUILD - VS-076 map pages split + Build/Orders shots + 44 px buttons done (QA PASS r1)
- S0069 2026-10-29 PLANNING - review round -> VS-078..082; no build
- S0068 2026-10-29 BUILD - VS-075 defense platform cost 24k done (QA PASS r1); VS-077 added
- S0067 2026-10-29 BUILD - VS-074 raid banner + fleet route lines done (QA PASS r1)
- S0066 2026-10-29 BUILD - VS-073 surface collapse-and-extract beat done (QA PASS r1)
- S0065 2026-10-29 BUILD - VS-072 shakedown probe done (QA r2 PASS)
- S0064 2026-10-29 BUILD - VS-065 touch/panel polish done (QA PASS r1)
- S0063 2026-10-29 BUILD - VS-068 map tabs done (QA PASS r1); VS-076 added
