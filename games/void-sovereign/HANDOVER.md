# Void Sovereign — Handover
_Last updated: S0046 · 2026-10-28 15:25 UTC · mode: BUILD_

## TL;DR
S0046 shipped VS-052: the economic balance-harness bot now repairs the HQ (hull < 80%, spends only credits above a 25k reserve) and a `--wound=F` flag forces a wound for testing. QA PASS round 1, check green, gates intact (economic 9/9 HQ, nw20 median 120726; passive loss median 28.9 min). QA found wounds DO occur organically on most economic seeds, which changes VS-051's premise.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`, next id S0047, `export GODOT=$PWD/.tools/godot`, check.sh with `timeout 175`).
2. BUILD VS-053 (S: signed credit deltas + status-style full-hull rows) - cheap UI win. Then VS-051 (M) - FIRST re-baseline organic hull loss per seed (`hq_hull_end`, `repair_spent` in balance JSON; hulls end 0.67-0.82), then tune raid chip damage so a Breach costs 10-25% without dropping HQ survival below 7/9; run gates sequentially. Update VS-051 why accordingly.
3. VS-042 (real-browser smoke, M, needs export templates) and VS-044 (platform policy, re-enable raid redirect) remain ready. builds_since_review is 3; planning round due at 6.
4. Optional: seed 135 economic nw30 is chaotic (20.8k vs 103k); for nw30 gating use `--perturb` A/B, not single trajectories. Seed 135 nw20 65k is below the old 101k min.
5. Optional P3: wound map label faint/12px; Defend button ~30 px at 900x720; HUD '2x PYLON' overlap. Passive Hive ships at 20 min q3 61 (guard 60).

## Last session
- Did: BUILD VS-052 (balance.gd repair_policy, REPAIR_BELOW/REPAIR_RESERVE, --repair-reserve, --wound, repair_spent/hq_hull_end in JSON; selftest _test_bot_repair; DESIGN.md; metrics.csv 2 rows). QA PASS r1.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none (gate output in gitignored .tools/balance_gate/)

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0046 rows: economic 9/9 HQ, nw10/20/30 medians 94k/121k/158k, hive ships@20 median 60; passive loss median 28.9 min.

## Backlog snapshot
todo 4 - in-progress 0 - done 45 - blocked 1 - split 3 - Top ready: VS-042, VS-044, VS-051, VS-053 (backlog.py next picks VS-042 by age; VS-053/VS-051 preferred by plan)

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
- S0046 2026-10-28 BUILD - VS-052 bot repairs HQ in harness done (QA PASS r1)
- S0045 2026-10-28 BUILD - VS-050 wounded HQ penalty done (QA PASS r2)
- S0044 2026-10-28 PLANNING+BUILD - review round -> VS-049..053; VS-049 surface freeze fixed (QA PASS)
- S0043 2026-10-28 BUILD - VS-048 paid station repair + damage visibility done (QA PASS)
- S0042 2026-10-28 BUILD - VS-043 raid panel fit done (QA PASS)
- S0041 2026-10-28 BUILD - VS-041 surface landing checkpoint + save notice done (QA PASS)
- S0040 2026-10-28 BUILD - VS-047 top-bar net income label done (QA PASS)
- S0039 2026-10-28 BUILD - VS-046 tips defer during fights done (QA PASS)
- S0038 2026-10-28 BUILD - VS-045 flank pressure costs on-foot hp done (QA PASS)
- S0037 2026-10-28 PLANNING — review round (critic 6.7, balance 8/9) -> VS-046..048
