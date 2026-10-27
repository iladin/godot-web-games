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

## S0009 — 2026-10-26 17:33 — BUILD
- Task(s): VS-018 First Sortie — done (QA FAIL round 1: HQ guns/Union killed the scouts in 4–7 s with no player involvement + balance drift; fix round: sortie-only targeting, spawn 1300 ahead of the player, hull 3x; QA PASS on re-verify). New VS-021 (P2 S, balance gates robust to sim chaos).
- Check: PASS · Git: see commit studio(S0009)
- Notes: QA proved the sim is chaotic (one extra global randf() at t=60 moves passive HQ-lost up to +14 min); 3-seed gates can't detect small shifts. Passive gate passed at median 33.7 (ceiling 35). ~80 min wall time.

## S0010 — 2026-10-26 21:40 — BUILD
- Task(s): VS-021 balance gates robust to sim chaos — done (QA PASS first round). VS-014 touch/mouse input on the pause screen — done (QA PASS first round).
- Check: PASS · Git: committed cbb8fdf (VS-021), e6126dd (VS-014) + wrap-up commit
- Notes: 9-seed baselines: econ30 nw20 107.7k / nw30 55.9k (nw30 < nw20 in 8/9), HQ 9/9; passive40 HQ lost median 33.7 [32.1–35.8]. Econ gate fits one 180 s call (154 s); passive needs two. VS-020 acceptance moved to 9-seed gates. ~40 min wall time.

## S0011 — 2026-10-26 23:08 — BUILD
- Task(s): VS-020 late-game Hive pressure — done (QA PASS first round). Lever: player-only raid deterrent after min 20 (go-chance 0.25^n per player Defense Platform in the target sector).
- Check: PASS · Git: committed 15b724b (VS-020) + wrap-up commit
- Notes: econ30 9 seeds nw20 107.7k → nw30 122.3k (was 55.9k), HQ 9/9; --perturb=1 126k → 160k; passive40 identical to baseline (33.7, 2/9). QA flags the deterrent as strong (2 platforms ≈ 6% late raids) → planning round next (builds_since_review = 6). ~35 min wall time.

## S0012 — 2026-10-27 03:05 — PLANNING
- Task(s): review round 2 (Critic 5.5/10, up from 5.1; QA sweep; Balance; Scout). New tasks: VS-022 surface frozen under end screen (P2 S), VS-023 deterrent range check + no building in planets + DREAD_TIME A/B (P2 M), VS-024 credit ledger (P1 M), VS-025 honest raid reports (P2 S). VS-005 and VS-006 notes updated; VS-006 kept blocked until VS-023. No BUILD (time budget used by review agents).
- Check: PASS · Git: see commit studio(S0012): review round
- Notes: Balance gates identical to S0011 (all 8 targets met; hive_20 max 75 over guard). 57% of late raid rolls cancelled by the deterrent; all tail collapses are the 18–19.7 min dreadnought raid. QA found far/in-planet platforms deter raids. ~3 h 50 min wall time (subagents ran 15–35 min each on the 2-core device).

## S0013 — 2026-10-27 04:20 — BUILD
- Task(s): VS-024 credit ledger — done (QA PASS first round). New `scripts/sim/ledger.gd` (CreditLedger); `Universe.add_credits(amount, cat)` is the sole writer of player credits (9 sites, 10 categories); HUD "+N cr/min", map/dock "Last 5 min" breakdown; tip 4 → Union Trade Hub.
- Check: PASS · Git: see commit studio(S0013): VS-024
- Notes: Pure observer confirmed — econ30 and passive40 BALANCE_JSON byte-identical to S0012. QA's per-step invariant (20 min, seeds 101/186) drift 0. Six P3 follow-ups to parking lot. Repo mount moved to $HOME/mnt/git/godot-web-games mid-session. ~50 min wall time.

## S0014 — 2026-10-27 05:10 — BUILD
- Task(s): VS-005 surface marker declutter (done, QA PASS round 1); VS-022 freeze surface under end screen (done, QA PASS round 1)
- Check: PASS · Git: committed (see HANDOVER) 
- Notes: Repo mount is $HOME/mnt/git/godot-web-games. Removed stale S0013 .git lock stubs and tmp_obj files after delete permission (C:\git root). HUD/input only; no balance gates needed.

## S0015 — 2026-10-27 05:30 — BUILD
- Task(s): VS-010 NPC traders stuck at broke player station — done (QA PASS round 1)
- Check: PASS · Git: committed (see git log -1) — delete permission granted for C:\git
- Notes: ShipAI.can_deliver_to guards plan_trade/best_buyer. credits_10 18.4k/22.1k/19.2k (seeds 101/118/135), HQ 3/3. QA P3: best_buyer selftest assertion not discriminating (parking lot).

## S0017 — 2026-10-27 05:57 — SKIPPED
- Lock held by S0016 since 05:45Z (11 min old, <4 h) and working tree has in-progress VS-007 edits; did not touch state, backlog or HANDOVER.
- Check: not run · Git: untouched
- Notes: left stray empty file moved to _to_delete/stray_touch_probe_S0017 (delete probe).

## S0016 — 2026-10-27 06:10 — BUILD
- Task(s): VS-007 wing commands (G attack / C escort / V hold, ATK/ESC/HOLD touch buttons, HUD "WING n · ORDER" line) — done. QA FAIL round 1 (ACT/ATK touch overlap at 1280x720) → dev fix → QA PASS round 2.
- Check: PASS · Git: committing game paths only (S0017 skipped session had left unrelated edits to ai-studio/studio-cycle.md and docs/AI_STUDIO.md — not staged)
- Notes: new scripts/sim/wing.gd (no RNG); `hold` order added to ShipAI. P3s parked (wing row mid-screen at 1280, map "hold" label, no wing shot scenario, resume-last-order).

## S0018 — 2026-10-27 07:35 — BUILD
- Task(s): VS-009 (L) split into VS-026 (serialize Universe), VS-027 (autosave + Continue), VS-028 (save robustness). VS-023 raid-deterrent range + planet build guard + DREAD_TIME 1200 — done (QA PASS round 1).
- Check: PASS · Git: committed game/studio paths only (see git log -1)
- Notes: Session id S0018 (S0017 was a skipped session). Perturbed econ gate margin thin (129k vs 126k) — re-run --perturb=1 after any raid tuning.
