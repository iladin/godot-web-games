# Void Sovereign — Handover
_Last updated: S0049 · 2026-10-28 18:40 UTC · mode: BUILD_

## TL;DR
S0049 closed VS-044: the harness already built platforms, so I added a `--redirect` A/B flag and telemetry; raid redirect ON is clearly worse (nw30 median 93.6k vs 121.3k), lighter-raid and Union-strength mitigations still lose, so RAID_REDIRECT_ENABLED stays false (recorded in DESIGN.md). VS-042 is blocked (no Web export templates / no headless browser). Backlog has 0 ready tasks and builds_since_review = 6, so PLANNING is due.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`, next id S0050, `export GODOT=$PWD/.tools/godot`, check.sh with `timeout 175`).
2. Run PLANNING (Critic + QA sweep + Balance Analyst in parallel, then Feature Scout). `backlog.py next` returns NONE. Critic: judge whether the VS-051 chip damage (nw30 121k, seed 135 HQ lost at 23.7 min) hurts the late economy; consider RAID_CHIP_PER_SHIP 0.015 or bigger bot repair reserve. Compare balance against S0048/S0049 rows (S0049 A/B in studio/reviews/S0049-redirect-ab.txt).
3. Turn findings into 4-8 tasks; if a P0/P1 size-S task results, BUILD it.
4. Optional P3: dock raid-outcome line; "DAMAGED 88%" label overlap; surface touch delta anchor; Defend button ~30 px at 900x720; HUD '2x PYLON' overlap; hive_ships_20 median 61 (> old 60 guard, pre-existing).

## Last session
- Did: VS-042 -> blocked (reason below). VS-044 done: balance.gd `--redirect` + deterred/redirected/platforms_end telemetry; director.gd counters, union_ship_count(), RAID_REDIRECT_SIZE_MULT=1.0 / RAID_REDIRECT_MIN_UNION_SHIPS=0 (neutral); selftest asserts; DESIGN.md decision. QA PASS r1 (default gate reproduces S0048 exactly).
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none (gate output in gitignored .tools/balance_gate/)

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: unchanged from S0048 (economic 30: HQ 8/9, nw10 94k, nw20 104k, nw30 121k). No new metrics.csv row; A/B in reviews/S0049-redirect-ab.txt. perturb=1/2 not run for redirect (moot).

## Backlog snapshot
todo 0 - in-progress 0 - done 48 - blocked 2 - split 3 - Top ready: none (PLANNING)

## Watch out for
- Redirect stays off; to revisit see DESIGN.md (ideas: redirect only with >=12 Union ships + cooldown, or hit a Union outpost).
- Chip damage applies at raid arrival to any Sovereign station. HQ income penalty is HQ-only, player faction only. Station hull never regenerates.
- Do NOT `pkill -f godot`; use `pkill -x godot`. Foreground `timeout 175`; balance sequential. Subagent runs 7-37 min each.
- DESIGN.md has a stale sentence "needs a platform-building balance policy" in VS-036 bullet (superseded by VS-044 paragraph).

## Open questions for Daniel
- VS-042 (real-browser smoke) needs Godot 4.7.2 Web export templates installed on your machine (and a headless browser, e.g. Playwright chromium). Install them, or allow a task that downloads them?
- Chip damage lowered late-game net worth ~23%; keep 0.02/ship or soften to 0.015?
- Over-screen Score equals Net worth in a synthetic shot: confirm formula.

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0049 2026-10-28 BUILD - VS-044 redirect A/B done (stays off, QA PASS r1); VS-042 blocked (no export templates)
- S0048 2026-10-28 BUILD - VS-051 raid chip damage done (QA PASS r1)
- S0047 2026-10-28 BUILD - VS-053 signed credit deltas + full-hull status rows done (QA PASS r2)
- S0046 2026-10-28 BUILD - VS-052 bot repairs HQ in harness done (QA PASS r1)
- S0045 2026-10-28 BUILD - VS-050 wounded HQ penalty done (QA PASS r2)
- S0044 2026-10-28 PLANNING+BUILD - review round -> VS-049..053; VS-049 surface freeze fixed (QA PASS)
- S0043 2026-10-28 BUILD - VS-048 paid station repair + damage visibility done (QA PASS)
- S0042 2026-10-28 BUILD - VS-043 raid panel fit done (QA PASS)
- S0041 2026-10-28 BUILD - VS-041 surface landing checkpoint + save notice done (QA PASS)
- S0040 2026-10-28 BUILD - VS-047 top-bar net income label done (QA PASS)
