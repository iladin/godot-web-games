# Studio log (append-only, newest at the bottom)

## S0000 — 2026-10-25 — SETUP
- Built Void Sovereign v1 (flight, command map, FPS surface, 7-sector simulation) and the AI studio (roles, studio-cycle skill, tooling).
- Seeded BACKLOG with VS-001…VS-009 (two from the first balance-harness run). Baseline metrics row in metrics.csv.
- Check: PASS · Git: not committed (repo has no commits for this game yet — first writable session makes the baseline commit).

## S0001 — 2026-10-26 00:05 — BUILD
- Task(s): baseline commit d1397ee; VS-002 Player auto-traders keep a credit reserve — done (6dc9767); VS-008 Selftest coverage for ship AI journeys — done (incl. start-stock balance change); new VS-010 (QA bug, P2).
- Check: PASS · Git: committed (see HANDOVER / git log)
- Notes: Both tasks QA-verified independently (QA mutation-tested VS-008 asserts). HQ survival 3-seed metric is noisy (0/3 vs 3/6 over 6 seeds) — use 6 seeds for VS-001.

## S0003-skip — 2026-10-26 01:22 — SKIPPED (lock held)
- Lock held by S0002 since 00:12Z (<4 h, files still being edited, last 01:18Z); VS-001 in progress. No work done, HANDOVER and state.json untouched.

## S0002 — 2026-10-26 00:12 — ABORTED (hung, cancelled by Daniel)
- Task: VS-001 started, never finished; no handover written. Uncommitted diff (7 files, ~190 lines) saved to studio/salvage/S0002-VS-001-abandoned.patch and code reverted to HEAD aaee72c by S0003.

## S0003 — 2026-10-26 02:12 — BUILD
- Task(s): cleanup of hung S0002 (diff saved to studio/salvage/, code reverted to aaee72c); VS-001 Rebalance mid-game — done (QA PASS); new VS-011 (late-game slide, P1 M) + 4 QA P3 items to parking lot.
- Check: PASS · Git: committed (see git log, studio(S0003))
- Notes: econ 6 seeds nw20 139k (was 8k), HQ 5/6; passive HQ lost 25.4 min. Net worth still collapses 20->30 min in 4/6 seeds -> VS-011. 6-seed run takes ~174 s (near 180 s device cap).

## S0005 — 2026-10-26 07:34 — BUILD
- Task(s): took over stale S0004 lock (03:32Z, no other trace); VS-003 Procedural sound effects — done (QA PASS); new VS-012 (P2 S, audio/touch follow-ups) + 3 parking-lot items.
- Check: PASS · Git: committed studio(S0005) (see git log)
- Notes: wall clock ran to ~11:50Z (≈4h15m, mostly tool/subagent latency), so no second build. sfx: 6 AudioStreamWAVs in ~5 ms; autoplay played 15, blocked 63 before first input. Not yet heard in a real browser.

## S0004 — 2026-10-26 03:32 — SUPERSEDED (late)
- Took the lock at 03:32Z, then its device calls stalled for ~8 h; S0005 rightly took the stale lock. The same run resumed at 11:49Z, found the lock free and continued as S0006. No S0004 file changes.

## S0006 — 2026-10-26 11:49 — BUILD
- Task(s): VS-004 Guided first 10 minutes — done (QA PASS, commit 77a703a); VS-012 Audio/touch follow-ups — done (QA PASS); new VS-013 (P2 S tip box steals steer touches + H docs), VS-014 (P2 S pause-screen tap/click bugs) + 8 parking-lot items.
- Check: PASS · Git: committed studio(S0006) x2 (see git log)
- Notes: two S builds in ~20 min wall time. builds_since_review now 6 → next session must run PLANNING first.

## S0007 — 2026-10-26 12:36 — PLANNING + BUILD
- Task(s): review round (Critic avg 5.1/10, QA sweep 3 P1 bugs, Balance: VS-011 still failing, Scout 5 proposals) → new VS-015..VS-018, VS-013 folded into VS-017, VS-006 blocked on VS-011, VS-007/VS-009 parked (blocked) for the ≤8 todo cap. Then VS-015 title freeze + overlays on run end — done (QA PASS); VS-016 same-station buy/sell arbitrage — done (QA PASS).
- Check: PASS · Git: committed studio(S0007) review round 3fd3d72, VS-015 d16b60d, VS-016 (see git log)
- Notes: VS-016 lowers early income (econ 3 seeds credits_10 −25–50%, nw20 129k); VS-011 must re-baseline. ~55 min wall time.

## S0008 — 2026-10-26 16:52 — BUILD
- Task(s): VS-011 → split: VS-019 (harness seed offset + defending econ policy, done, QA PASS on criteria 1/3/4) + VS-020 (nw30 >= nw20, todo P1 M — QA FAIL, needs a game lever). VS-017 tutorial tips follow the world — done (1 fix round; QA PASS on re-verify).
- Check: PASS · Git: committed 03a1c16 (VS-019) + VS-017/wrap-up commit
- Notes: Harness-only fix gives HQ 6/6 and nw30 median 33.6k→74.1k but nw30 < nw20 in 6/6 seeds. Global raid nerf and Defense Platform buff both broke the passive gate (platform is shared with Union stations).
