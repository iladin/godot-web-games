# Void Sovereign — Handover
_Last updated: S0047 · 2026-10-28 16:10 UTC · mode: BUILD_

## TL;DR
S0047 shipped VS-053: HUD shows signed credit deltas ("+150 cr bounty", "-420 cr repair", >100 cr, 2 lines, 2 s fade; touch anchor right of the SHIELD/HULL panel) and the dock shows full-hull rows as green status labels. QA FAIL r1 (touch overlap) then PASS r2; check green.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`, next id S0048, `export GODOT=$PWD/.tools/godot`, check.sh with `timeout 175`).
2. BUILD VS-051 (M): FIRST re-baseline organic hull loss per seed (`hq_hull_end`, `repair_spent` in balance JSON; hulls end 0.67-0.82), then tune raid chip damage so a Breach costs 10-25% without dropping HQ survival below 7/9; run gates sequentially. Update VS-051 why accordingly (wounds already occur organically). If it is size M and heavy, split it.
3. VS-042 (real-browser smoke, M, needs export templates; backlog.py next picks it by age - may need to be skipped/blocked) and VS-044 (platform policy, re-enable raid redirect) remain ready. builds_since_review is 4; planning round due at 6.
4. Optional P3: desktop shots have no delta visual coverage (add forced delta to dock/combat shot); surface touch delta anchor (360,140) would overlap objective text if a >100 cr surface gain is ever added; wound map label faint; Defend button ~30 px at 900x720; HUD '2x PYLON' overlap.

## Last session
- Did: BUILD VS-053 (universe.gd credits_changed signal; hud.gd delta_text/delta_origin/delta_rect; dock_panel.gd status labels; selftest + test_driver touch_wing deltas). QA FAIL r1 -> fix -> PASS r2.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none (gate output in gitignored .tools/balance_gate/)

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0046 rows: economic 9/9 HQ, nw10/20/30 medians 94k/121k/158k, hive ships@20 median 60; passive loss median 28.9 min.

## Backlog snapshot
todo 3 - in-progress 0 - done 46 - blocked 1 - split 3 - Top ready: VS-042, VS-044, VS-051 (plan prefers VS-051)

## Watch out for
- Repair-enabled economic runs diverge from pre-S0046 gate rows (RNG chaos); compare against S0046 rows from now on.
- HQ income penalty is HQ-only, player faction only. Station hull never regenerates.
- Do NOT `pkill -f godot`; use `pkill -x godot`. Foreground `timeout 175`; balance sequential. Subagent runs 9-12 min each.
- Redirect still off (RAID_REDIRECT_ENABLED=false).

## Open questions for Daniel
- Critic says keep 0.4 cr/pt repair price and add organic damage (VS-051): OK to proceed?
- Over-screen Score equals Net worth in a synthetic shot: confirm formula.
- Real-browser pass still needed (VS-042).

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0047 2026-10-28 BUILD - VS-053 signed credit deltas + full-hull status rows done (QA PASS r2)
- S0046 2026-10-28 BUILD - VS-052 bot repairs HQ in harness done (QA PASS r1)
- S0045 2026-10-28 BUILD - VS-050 wounded HQ penalty done (QA PASS r2)
- S0044 2026-10-28 PLANNING+BUILD - review round -> VS-049..053; VS-049 surface freeze fixed (QA PASS)
- S0043 2026-10-28 BUILD - VS-048 paid station repair + damage visibility done (QA PASS)
- S0042 2026-10-28 BUILD - VS-043 raid panel fit done (QA PASS)
- S0041 2026-10-28 BUILD - VS-041 surface landing checkpoint + save notice done (QA PASS)
- S0040 2026-10-28 BUILD - VS-047 top-bar net income label done (QA PASS)
- S0039 2026-10-28 BUILD - VS-046 tips defer during fights done (QA PASS)
- S0038 2026-10-28 BUILD - VS-045 flank pressure costs on-foot hp done (QA PASS)
