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
