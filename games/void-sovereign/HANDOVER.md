# Void Sovereign — Handover
_Last updated: S0062 · 2026-10-29 08:55 UTC · mode: PLANNING_

## TL;DR
S0062 ran a review round (Critic 6.8/10, QA no P0-P2, Balance all targets met but economic nw30 fell 168k->106k). VS-071 balance trial was blocked with no code change. Build is green; 6 todo tasks ready.

## Next session should
1. BUILD VS-068 (S): Buy/Build/Orders tabs (>= 44 px) below the pinned strip; split tab helper out of `scripts/ui/map_view.gd` (~596 lines). Then `RES=1280x720 bash scripts/studio/shots.sh void-sovereign raid_map raid_map_damaged map dock` and at 900x720, then check.sh. (`backlog.py next` currently says VS-065, but VS-065's map-panel part must follow VS-068: do VS-068 first.)
2. Then VS-065 (900x720 touch spacing / panel polish), then VS-074 (map stakes: raid banner + route lines, depends on VS-068).
3. VS-075 (P2 balance): lift weak-economy seeds 101/152/186/118; read `studio/reviews/S0062-balance.md` and the VS-071 notes2 first.
4. VS-072 shakedown probe (S), VS-073 surface collapse/extract beat (M, split if needed).
5. builds_since_review is 0; next PLANNING due after 6 builds.

## Last session
- Did: PLANNING round (reviews/S0062-{critic,qa,balance,scout}.md); VS-072..074 and VS-075 created; VS-071 tried and blocked (NEST_CAP_GROWTH 135: passive earliest HQ loss 20.4 min < 22 gate; warship -10%: economic HQ 9/9, nw20 107k, but nw30 median 107.6k / q1 56.8k). Added nw30 target (median >= 120k, q1 >= 90k) to ai-studio/roles/balance-analyst.md. defs.gd/balance.gd restored to original.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0062 economic HQ 8/9, nw20 median 104590, nw30 106269; passive HQ lost median 28.2, earliest 23.6.

## Backlog snapshot
todo 6 · in-progress 0 · done 61 · blocked 3 · split 5 · Top ready: VS-068, VS-065, VS-074

## Watch out for
- Earliest HQ loss is very seed-sensitive; economic HQ 8/9 has no margin; the new nw30 target currently reads red at baseline.
- device_bash calls cap ~120 s and background jobs die: run balance.sh / balance_gate.sh foreground, one GATE_OFFSETS per call (all three in one call times out).
- Strip is at the 44 px floor; added strip content breaks the fold assert until VS-068 tabs land.
- check.sh does NOT run raid_map/raid_map_damaged/raid_map_touch shots; run them after map UI changes.
- Judge passive balance WITHOUT --reserve. Do NOT `pkill -f godot`. Append new backlog tasks ABOVE "# Ideas parking lot".
- Parking lot: Sovereign's Decree (needs VS-068), UNION_QUOTA counts reserve ships, partial-repair shot.

## Open questions for Daniel
- VS-042 (real-browser pass, Critic's #1 problem for 10 reviews) needs a headless browser: allow cdn.playwright.dev in egress or point to an installed chromium.
- Accept nw30 as aspirational, or keep chasing it (VS-075)?

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0062 2026-10-29 PLANNING - review round -> VS-072..075; VS-071 blocked (no code change)
- S0061 2026-10-29 BUILD - VS-064 Nest cap growth 145 done (QA PASS r1)
- S0060 2026-10-29 BUILD - VS-070 raid_hit hardening done (QA PASS r1)
- S0059 2026-10-29 BUILD - VS-063 raid_hit shot + raid_hit_long done (QA PASS r1); VS-070 added
- S0058 2026-10-29 BUILD - VS-069 damaged-HQ strip compaction + raid_map_damaged shot done (QA PASS r1)
- S0057 2026-10-29 BUILD - VS-066 split; VS-067 pinned map command strip done (QA PASS r1); VS-069 added
- S0056 2026-10-29 PLANNING+BUILD - review round -> VS-063..066; VS-061 Reserve A/B done (QA PASS r1)
- S0055 2026-10-29 BUILD - VS-060 Reserve button done (QA PASS r1); VS-062 added
- S0054 2026-10-28 BUILD - VS-059 Fleet Reserve sim logic done (QA PASS r1)
- S0053 2026-10-28 BUILD - VS-057 split (059/060/061); VS-058 touch HUD lane done (QA PASS r2)
