# Studio log (append-only, newest at the bottom)

## S0000 — 2026-10-25 — SETUP
- Built Void Sovereign v1 (flight, command map, FPS surface, 7-sector simulation) and the AI studio (roles, studio-cycle skill, tooling).
- Seeded BACKLOG with VS-001…VS-009 (two from the first balance-harness run). Baseline metrics row in metrics.csv.
- Check: PASS · Git: not committed (repo has no commits for this game yet — first writable session makes the baseline commit).

## S0001 — 2026-10-26 00:05 — BUILD
- Task(s): baseline commit d1397ee; VS-002 Player auto-traders keep a credit reserve — done (6dc9767); VS-008 Selftest coverage for ship AI journeys — done (incl. start-stock balance change); new VS-010 (QA bug, P2).
- Check: PASS · Git: committed (see HANDOVER / git log)
- Notes: Both tasks QA-verified independently (QA mutation-tested VS-008 asserts). HQ survival 3-seed metric is noisy (0/3 vs 3/6 over 6 seeds) — use 6 seeds for VS-001.
