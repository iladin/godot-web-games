# Void Sovereign — Handover
_Last updated: S0056 · 2026-10-29 01:55 UTC · mode: PLANNING+BUILD_

## TL;DR
S0056 ran a full review round (Critic 6.7/10, QA sweep found only P3s, Balance 8/9 targets met) and finished VS-061 (Reserve A/B: HQ 9/9, nw30 median 170k, QA PASS). Build green; 5 todo tasks ready (VS-062..066). VS-042 still blocked on network allowlist.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (next id S0057, `export GODOT=$PWD/.tools/godot`, check.sh with `timeout 175`). If `.git/*.lock` exists, `mv` it to `.git/stale-...` (never rm).
2. BUILD VS-066 first as two S tasks (it absorbs VS-062): (a) pinned strip on the map with forecast + Call Reserve (>=44 px, on-screen at 1280x720 and 900x720 in map/raid_map/raid_map_touch), (b) Buy/Build/Orders tabs. Split via `backlog.py`, mark VS-062 done/superseded when (a) lands. Run `RES=1280x720 bash scripts/studio/shots.sh void-sovereign raid_map raid_map_touch map dock`.
3. BUILD VS-064 (passive Hive cap trim, defs.gd Hive t/126 cap -5..8%): 9 single-seed passive calls without --reserve (`balance.sh void-sovereign 40 1 passive <0..8>`), then economic gate (HQ >= 8/9). Append metrics.csv row.
4. BUILD VS-063 (raid_hit shot + raid_hit_long log; must not touch gameplay RNG), then VS-065 (900x720 touch/panel polish, after VS-066).
5. Parking lot: Sovereign's Decree (credit sink), Director UNION_QUOTA counts reserve ships. builds_since_review is 1; next review round after ~6 builds.

## Last session
- Did: PLANNING (reports in studio/reviews/S0056-*.md; tasks VS-063..066) then BUILD VS-061 (no code change; results in reviews/S0056-balance.md + BACKLOG). QA PASS r1.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit. git commits warn about unlink of tmp_obj/HEAD.lock (commit still succeeds; move HEAD.lock aside).
- Latest metrics: S0056 economic 9/9 HQ, nw30 median 168k (170k with --reserve); passive HQ lost median 25.8 min, hive_ships_20 60 (WARN at guard).

## Backlog snapshot
todo 5 · in-progress 0 · done 55 · blocked 2 · split 4 · Top ready: VS-062, VS-063, VS-064, VS-065, VS-066

## Watch out for
- With --reserve the bot rescues passive seed 101 (survives 30 min vs HQ lost 24.4); judge passive balance gates WITHOUT --reserve. Consider a passive 9-seed --reserve run before retuning Reserve (cost 4000/count 6/linger 180).
- Critic: active player never feels raids (hull 600, HQ 100% in scripted runs) -> VS-063. Economy generous at top (nw30 168k).
- check.sh does NOT run raid_map/raid_map_touch shots; run them after any map UI change (VS-043 fold assert).
- 900x720 window renders virtual 1280x1024 viewport. /tmp not writable from device shell; write logs under .tools/. Long Godot runs must be foreground; do NOT `pkill -f godot`. Machine ~36 s per seed 30-min run.
- Harness: scripts/tools/balance.gd. Append new backlog tasks ABOVE the "# Ideas parking lot" heading.

## Open questions for Daniel
- VS-042 needs a headless browser: allow cdn.playwright.dev in egress or point to an installed chromium (real-browser pass is the ninth review running unverified).

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0056 2026-10-29 PLANNING+BUILD - review round -> VS-063..066; VS-061 Reserve A/B done (QA PASS r1)
- S0055 2026-10-29 BUILD - VS-060 Reserve button done (QA PASS r1); VS-062 added
- S0054 2026-10-28 BUILD - VS-059 Fleet Reserve sim logic done (QA PASS r1)
- S0053 2026-10-28 BUILD - VS-057 split (059/060/061); VS-058 touch HUD lane done (QA PASS r2)
- S0052 2026-10-28 BUILD - VS-056 Hive cap trim + --fleet-floor done (QA PASS r1)
- S0051 2026-10-28 BUILD - VS-055 HQ hull readout done (QA PASS r1)
- S0050 2026-10-28 PLANNING+BUILD - review round -> VS-054..058; VS-054 raid forecast done (QA PASS r1)
- S0049 2026-10-28 BUILD - VS-044 redirect A/B done (stays off, QA PASS r1); VS-042 blocked (no export templates)
- S0048 2026-10-28 BUILD - VS-051 raid chip damage done (QA PASS r1)
- S0047 2026-10-28 BUILD - VS-053 signed credit deltas + full-hull status rows done (QA PASS r2)
