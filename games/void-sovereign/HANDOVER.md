# Void Sovereign — Handover
_Last updated: S0068 · 2026-10-29 14:50 UTC · mode: BUILD_

## TL;DR
S0068 shipped VS-075 (Defense Platform cost 30,000 -> 24,000): economic 9 seeds HQ 9/9, nw30 median 132k (q1 116k). QA PASS r1, check green. builds_since_review is 6, so PLANNING is due next session. Todo: VS-076, VS-077.

## Next session should
1. Run PLANNING first (health rule, builds_since_review=6): Critic + QA sweep + Balance in parallel, then Feature Scout; write reviews/S0069-*.md. Fold in VS-074 P3 follow-ups (raid banner/strip duplication, banner clips on "+N" raids, selftest asserting _draw_fleet_routes, hop-by-hop routes, routes on main sector view) and seeds 101/135 weak economies (nw30 89k/71k).
2. Then BUILD VS-076 (S): move page building out of `scripts/ui/map_view.gd` into map_pages.gd; Build/Orders tab shots; 44 px order buttons. Run `RES=900x720 bash scripts/studio/shots.sh void-sovereign raid_map raid_map_damaged raid_map_touch map` after, then check.sh.
3. VS-077 (P2 balance): resolve passive gate ambiguity (no-reserve baseline loses seed 169 at 19.2 min vs ">= 22" gate); run offsets 0/3/6 with and without --reserve.
4. Run `shots.sh void-sovereign raid_hit` alone (SHOT_TIMEOUT=150) to confirm VS-072 probe left it intact.
5. Add DESIGN.md surface-section text for the collapse beat (COLLAPSE_* / EXTRACT_* in sim/defs.gd).

## Last session
- Did: BUILD VS-075 - defs.gd defense cost 24000, selftest assert, DESIGN.md note, metrics.csv S0068 row. QA PASS r1 (re-ran all 9 econ seeds, passive offset 3 bit-identical to baseline). Cheaper platforms also make player raid deterrence cheaper (not playtested).
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0068 economic HQ 9/9, nw20 median 105464, nw30 median 132396 (q1 115699).

## Backlog snapshot
todo 2 · in-progress 0 · done 67 · blocked 3 · split 5 · Top ready: VS-076, VS-077

## Watch out for
- device_bash calls cap ~120 s and background jobs die: run balance.sh / balance_gate.sh foreground, one GATE_OFFSETS per call (40-min passive does not fit).
- Strip is at the 44 px floor; fold_ok() briefly switches tabs and restores. Keys 1-3 select map tabs.
- check.sh does NOT run raid_map* shots; run them after map UI changes.
- Judge passive balance WITHOUT --reserve (but see VS-077). Do NOT `pkill -f godot`. Append new backlog tasks ABOVE "# Ideas parking lot".
- Dev subagents may mis-claim stock surface_long outcomes; QA must run it.
- Collapse timeout reuses player_died (hull loss); human players have a 22 s sprint.

## Open questions for Daniel
- VS-042 (real-browser pass, Critic's #1 problem for 10+ reviews) needs a headless browser: allow cdn.playwright.dev in egress or point to an installed chromium.
- Is the passive-balance gate meant to run with --reserve? (VS-077)

## Answers to Daniel
- Earlier question on nw30: it now reaches 132k median with VS-075, though seeds 101/135 stay weak.

## Session history (newest first, keep 10)
- S0068 2026-10-29 BUILD - VS-075 defense platform cost 24k done (QA PASS r1); VS-077 added
- S0067 2026-10-29 BUILD - VS-074 raid banner + fleet route lines done (QA PASS r1)
- S0066 2026-10-29 BUILD - VS-073 surface collapse-and-extract beat done (QA PASS r1)
- S0065 2026-10-29 BUILD - VS-072 shakedown probe done (QA r2 PASS)
- S0064 2026-10-29 BUILD - VS-065 touch/panel polish done (QA PASS r1)
- S0063 2026-10-29 BUILD - VS-068 map tabs done (QA PASS r1); VS-076 added
- S0062 2026-10-29 PLANNING - review round -> VS-072..075; VS-071 blocked (no code change)
- S0061 2026-10-29 BUILD - VS-064 Nest cap growth 145 done (QA PASS r1)
- S0060 2026-10-29 BUILD - VS-070 raid_hit hardening done (QA PASS r1)
- S0059 2026-10-29 BUILD - VS-063 raid_hit shot + raid_hit_long done (QA PASS r1); VS-070 added
