# Void Sovereign — Handover
_Last updated: S0070 · 2026-10-29 16:25 UTC · mode: BUILD_

## TL;DR
S0070 shipped VS-076 (map page building moved to map_pages.gd, map_view.gd 582 lines, Build/Orders shots, 44 px order buttons; QA PASS r1). Build green; builds_since_review = 1.

## Next session should
1. BUILD VS-078 (S, touch cluster rehome) or VS-079 (S, payback labels); `python3 scripts/studio/backlog.py next` picks.
2. VS-077 (P2 balance): passive gate ambiguity (seed 169 loses at 19.2 min). Run offsets 0/3/6 with and without --reserve, one per call.
3. Then M tasks: VS-080 Core Defenders, VS-081 Standing orders on sector view, VS-082 Sovereign's Decree (run balance after).
4. Add DESIGN.md surface text for the collapse beat; run `shots.sh void-sovereign raid_hit` alone (SHOT_TIMEOUT=150).
5. P3 parked: Orders-tab scroll cue overlaps info text at 1280x720; raid_map_touch doesn't enable touch mode.

## Last session
- Did: BUILD VS-076 (Dev -> independent QA PASS r1). New map_pages.gd, map_overlay_draw.gd; test_driver tab check now runs once.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0069 economic HQ 9/9, nw30 median 132396; passive HQ lost median 28.4 min (earliest 19.2, seed 169).

## Backlog snapshot
todo 6 · in-progress 0 · done 68 · blocked 3 · split 5 · Top ready: VS-077, VS-078, VS-079

## Watch out for
- device_bash calls cap ~120 s and background jobs die: run balance.sh / shots foreground, one GATE_OFFSETS per call.
- Strip is at the 44 px floor; keys 1-3 select map tabs. check.sh does NOT run raid_map* shots.
- Judge passive balance WITHOUT --reserve (see VS-077). Do NOT `pkill -f godot`. Append new backlog tasks ABOVE "# Ideas parking lot".
- NEST_CAP_GROWTH 140 fails the earliest-loss gate; don't use. Shot runs share a user:// save, so Best score varies.
- Dev subagents may mis-claim surface_long outcomes; QA must run it.

## Open questions for Daniel
- VS-042 (real-browser pass, Critic's #1 for 11 reviews): please play the exported build once in a real browser, or allow cdn.playwright.dev / point to an installed chromium.
- Is the passive-balance gate meant to run with --reserve? (VS-077)

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0070 2026-10-29 BUILD - VS-076 map pages split + Build/Orders shots + 44 px buttons done (QA PASS r1)
- S0069 2026-10-29 PLANNING - review round -> VS-078..082; no build
- S0068 2026-10-29 BUILD - VS-075 defense platform cost 24k done (QA PASS r1); VS-077 added
- S0067 2026-10-29 BUILD - VS-074 raid banner + fleet route lines done (QA PASS r1)
- S0066 2026-10-29 BUILD - VS-073 surface collapse-and-extract beat done (QA PASS r1)
- S0065 2026-10-29 BUILD - VS-072 shakedown probe done (QA r2 PASS)
- S0064 2026-10-29 BUILD - VS-065 touch/panel polish done (QA PASS r1)
- S0063 2026-10-29 BUILD - VS-068 map tabs done (QA PASS r1); VS-076 added
- S0062 2026-10-29 PLANNING - review round -> VS-072..075; VS-071 blocked (no code change)
- S0061 2026-10-29 BUILD - VS-064 Nest cap growth 145 done (QA PASS r1)
