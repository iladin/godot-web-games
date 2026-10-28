# Void Sovereign — Handover
_Last updated: S0045 · 2026-10-28 14:57 UTC · mode: BUILD_

## TL;DR
S0045 shipped VS-050: a player HQ below 50% hull now loses up to 30% (linear) of colony income and shield regen, quoted in dock and map text next to the repair price. QA PASS on round 2, check green, gates unchanged (economic HQ 9/9, passive loss median 28.9 min). Wounds still never occur organically, so VS-051 is the natural next step.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`, next id S0046, `export GODOT=$PWD/.tools/godot`, check.sh with `timeout 175`).
2. BUILD VS-052 (S: economic bot repairs HQ in the harness so the gate covers the repair sink and the new penalty). Then VS-051 (M: raid chip damage, tune with VS-050; run the 9-seed gate sequentially, passive median must stay 20-35).
3. VS-053 (S: signed credit deltas + status-style 100% hull rows), VS-042 (real-browser smoke), VS-044 (harness platform policy, re-enable raid redirect) remain ready. builds_since_review is 2; planning round due at 6.
4. Optional P3: wound map label (map_view.gd) backdrop is faint / 12px, a ship glyph can cross it; Defend button ~30 px at 900x720; HUD '2x PYLON' label overlap.
5. Balance watch: passive Hive ships at 20 min q3 61 (guard 60); if needed lower Hive passive spawn ~5% in defs.gd.

## Last session
- Did: BUILD VS-050 (defs.gd WOUND_PENALTY_START/MAX + wound_penalty(), station_data.gd, entity.gd regen_mult(), universe.gd colony income, dock_panel.gd, map_view.gd two-line label, selftest _test_wound_penalty, test_driver wound_map/wound_dock shots, DESIGN.md). QA r1 FAIL (map label clipped price) -> fixed -> r2 PASS.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none (QA left screenshots in gitignored .tools/qa_vs/ and .tools/shots/; safe to delete manually)

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0044 rows (no new review this session). Gate re-run S0045: economic 9/9 HQ survive, nw medians 94k/121k/168k at 10/20/30 min; passive loss median 28.9 min (QA measured 28.6 on 7 seeds).

## Backlog snapshot
todo 5 - in-progress 0 - done 44 - blocked 1 - split 3 - Top ready: VS-052, VS-051, VS-053, VS-042, VS-044

## Watch out for
- "HQ station income" implemented as colony income (HQ has no trade stock). Penalty is HQ-only, player faction only.
- Bots never repair; station hull never regenerates; wounds don't occur organically until VS-051, so the death-spiral risk is untested.
- Do NOT `pkill -f godot`; use `pkill -x godot`. Foreground `timeout 175`; balance sequential. Subagent runs 2-30 min each.
- Redirect still off (RAID_REDIRECT_ENABLED=false).

## Open questions for Daniel
- Critic says keep 0.4 cr/pt (12k HQ rebuild) but add consequences (VS-050 done) and organic damage (VS-051): OK to proceed?
- Over-screen Score equals Net worth in a synthetic shot: confirm formula.
- Real-browser pass still needed (VS-042).

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0045 2026-10-28 BUILD - VS-050 wounded HQ penalty done (QA PASS r2)
- S0044 2026-10-28 PLANNING+BUILD - review round -> VS-049..053; VS-049 surface freeze fixed (QA PASS)
- S0043 2026-10-28 BUILD - VS-048 paid station repair + damage visibility done (QA PASS)
- S0042 2026-10-28 BUILD - VS-043 raid panel fit done (QA PASS)
- S0041 2026-10-28 BUILD - VS-041 surface landing checkpoint + save notice done (QA PASS)
- S0040 2026-10-28 BUILD - VS-047 top-bar net income label done (QA PASS)
- S0039 2026-10-28 BUILD - VS-046 tips defer during fights done (QA PASS)
- S0038 2026-10-28 BUILD - VS-045 flank pressure costs on-foot hp done (QA PASS)
- S0037 2026-10-28 PLANNING — review round (critic 6.7, balance 8/9) -> VS-046..048
- S0036 2026-10-28 BUILD — VS-040 income empty state + net/gross done (QA PASS round 1)
