# Void Sovereign — Handover
_Last updated: S0048 · 2026-10-28 17:45 UTC · mode: BUILD_

## TL;DR
S0048 shipped VS-051: a raid that reaches a Sovereign station chips 2% of max hull per surviving raider (cap 25%, never lethal, once per raid); outcome text shows "hull -N%"; new shots hq_wounded / hq_wounded_dock. QA PASS r1, check green. Cost: economic nw30 median fell ~158k -> ~121k.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`, next id S0049, `export GODOT=$PWD/.tools/godot`, check.sh with `timeout 175`).
2. `backlog.py next` returns VS-042 (real-browser smoke, M, needs Web export templates). If templates are missing in `.tools`, mark it blocked with that reason rather than burning a session; otherwise build it. Then VS-044 (platform-building policy, re-enable raid redirect; compare against S0048 metrics rows now).
3. builds_since_review is 5; a PLANNING round is due at 6 (so after the next build, or run planning next). Critic should judge whether the nw30 drop from VS-051 (seed 135 collapses at 23.7 min) hurts the late economy; if so consider RAID_CHIP_PER_SHIP 0.015 (Breach 9%, under the 10% target) or a larger bot repair reserve.
4. Optional P3: dock raid-outcome line; "DAMAGED 88%" label overlaps ships; surface touch delta anchor; Defend button ~30 px at 900x720; HUD '2x PYLON' overlap.

## Last session
- Did: BUILD VS-051 (defs.gd RAID_CHIP_PER_SHIP/RAID_CHIP_MAX, sim/raid_tracker.gd _chip + hull_lost, selftest, test_driver shots, map_view DAMAGED label width, DESIGN.md). QA PASS round 1.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none (gate output in gitignored .tools/balance_gate/)

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0048 economic 30: HQ 8/9, nw10 94k, nw20 104k, nw30 121k, perturb=1 9/9; passive HQ lost median 27.3 min.

## Backlog snapshot
todo 2 - in-progress 0 - done 47 - blocked 1 - split 3 - Top ready: VS-042, VS-044

## Watch out for
- Chip applies at raid arrival to any Sovereign station; a raid later intercepted at the station still cost hull (by design). Zero only if killed before arrival.
- Compare gates against S0048 rows from now on (chaos vs S0046).
- HQ income penalty is HQ-only, player faction only. Station hull never regenerates.
- Do NOT `pkill -f godot`; use `pkill -x godot`. Foreground `timeout 175`; balance sequential. Subagent runs 7-37 min each.
- Redirect still off (RAID_REDIRECT_ENABLED=false).

## Open questions for Daniel
- Chip damage lowered late-game net worth ~23%; keep 0.02/ship or soften to 0.015?
- Over-screen Score equals Net worth in a synthetic shot: confirm formula.
- Real-browser pass still needed (VS-042).

## Answers to Daniel
- Critic's "keep 0.4 cr/pt repair price and add organic damage" was implemented as VS-051.

## Session history (newest first, keep 10)
- S0048 2026-10-28 BUILD - VS-051 raid chip damage done (QA PASS r1)
- S0047 2026-10-28 BUILD - VS-053 signed credit deltas + full-hull status rows done (QA PASS r2)
- S0046 2026-10-28 BUILD - VS-052 bot repairs HQ in harness done (QA PASS r1)
- S0045 2026-10-28 BUILD - VS-050 wounded HQ penalty done (QA PASS r2)
- S0044 2026-10-28 PLANNING+BUILD - review round -> VS-049..053; VS-049 surface freeze fixed (QA PASS)
- S0043 2026-10-28 BUILD - VS-048 paid station repair + damage visibility done (QA PASS)
- S0042 2026-10-28 BUILD - VS-043 raid panel fit done (QA PASS)
- S0041 2026-10-28 BUILD - VS-041 surface landing checkpoint + save notice done (QA PASS)
- S0040 2026-10-28 BUILD - VS-047 top-bar net income label done (QA PASS)
- S0039 2026-10-28 BUILD - VS-046 tips defer during fights done (QA PASS)
