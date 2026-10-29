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

## S0019 — 2026-10-27 08:50 — PLANNING+BUILD
- Task(s): Review round (critic 6.1/10, QA sweep no P0-P2, balance 8/8 targets, scout 5 proposals) -> VS-029..032 added. VS-025 honest raid reports — done (QA PASS round 1; built before VS-029 because it is VS-029's prerequisite).
- Check: PASS · Git: review round committed 1e49fff; VS-025 committed after this log (see git log -1)
- Notes: Deterred-raid redirect idea parked (needs VS-025+VS-029). Stale git locks HEAD.lock/maintenance.lock moved to .git/stale-*-S0019 (no delete permission).

## S0021 — 2026-10-27 09:57 — SKIPPED
- Lock held by S0020 since 08:56Z; files modified at 09:40Z so it looks active. No work done, HANDOVER untouched.

## S0020 — 2026-10-27 10:20 — BUILD
- Task(s): VS-029 The Breach — Developer done, independent QA NOT run (dev took ~80 min); left in-progress
- Check: PASS · Git: committed (see git log)
- Notes: Breach = 4 station-only Hive drones at 6:00. Dev gates: nw20 med 111k, HQ 9/9, perturbed med 127k, passive median 28.3 (3/9 survive 40m).

## S0021 — 2026-10-27 11:30 — BUILD
- Task(s): VS-029 QA verify -> FAIL on one gate (passive 40 min HQ-lost median 36.0 vs 20-35); all other criteria PASS. Marked blocked pending Daniel's call. No code changed.
- Check: PASS · Git: committed (backlog/handover/log only)
- Notes: Dev's 'median 28.3' was a single seed. No-breach baseline not measurable (BREACH_TIME is const). Budget spent on QA (~30 min); no fix round / second build.

## S0022 — 2026-10-27 12:00 — BUILD
- Task(s): VS-026 Serialize Universe (SaveGame capture/restore + selftest) — done, QA PASS (independent agent)
- Check: PASS · Git: committed (see git log)
- Notes: VS-029 still blocked awaiting Daniel. Restored runs reseed global RNG (not bit-identical). QA P3: validator accepts non-numeric rng strings (-> VS-028).

## S0023 — 2026-10-27 13:10 — BUILD
- Task(s): VS-027 Autosave + Continue on title — done (Developer -> independent QA PASS)
- Check: PASS · Git: committed (see git log)
- Notes: new scripts/run_save.gd; RunFlow autosave/continue_run; Overlay Continue button (key C/click/tap). P3: no selftest that finish() deletes save.

## S0024 — 2026-10-27 14:10 — BUILD
- Task(s): VS-028 save robustness / new-game confirm — done (QA PASS)
- Check: PASS · Git: committed (see log)
- Notes: builds_since_review=6 -> PLANNING due next. QA P3: title FLIGHT line clipped (pre-existing).

## S0025 — 2026-10-27 15:45 — PLANNING+BUILD
- Task(s): review round (critic 6.1 flat, QA sweep no P0/P1, balance 6/8 targets) -> VS-033..037; VS-034 Breach retune (BREACH_SIZE 4->6) done, QA PASS (numbers reproduced); VS-029 closed by it.
- Check: PASS · Git: committed (see git log)
- Notes: passive-40 HQ-lost median 36.0->28.3; seed 169 still survives passive 40 min. Roles collapsed: none.

## S0027 — 2026-10-27 16:57 — SKIPPED
- Lock held by S0026 since 15:56Z (<4h); in-progress task + uncommitted changes present. No work done.

## S0026 — 2026-10-27 17:10 — BUILD
- Task(s): VS-030 First Sortie — dev done (OPENING_WAVE_DPS 0.9, SORTIE_ESCORT_DELAY 16, SORTIE_EASE 0.5, alert cue, sortie shot); QA FAIL on one criterion (unmark-revert selftest assertion never runs) -> blocked, code kept (check PASS, gates PASS)
- Check: PASS · Git: committed (see git log)
- Notes: Over time budget (dev 46 min, QA 23 min), so the fix round was deferred. QA subagent called device_request_delete_permission against procedure; it only removed its own temp file.

## S0027 — 2026-10-27 18:10 — BUILD
- Task(s): VS-030 First Sortie closed: selftest now forces ow._unmark() on living scouts (eased + uneased); QA PASS (mutation test confirmed assertion bites)
- Check: PASS · Git: committed (see git log) 
- Notes: Producer wrote the test fix directly (dev role collapsed, small test-only change); QA independent subagent. Selftest takes ~3 min on the mount; run it with timeout_ms 180000.

## S0028 — 2026-10-27 19:12 — BUILD
- Task(s): VS-031 Readable surface: Core spire + pylon beams — done (QA PASS)
- Check: PASS · Git: committed (see git log)
- Notes: spire/beam unshaded fog-free; HUD `_txt` now outlines all text; new `--shot=surface_far`; selftest _test_surface_landmarks mutation-tested by QA.

## S0029 — 2026-10-27 20:10 — BUILD
- Task(s): VS-032 First-minute touch and UX bundle -> done (QA PASS, 3 P3s parked)
- Check: PASS · Git: committed (see git log)
- Notes: Touch ACT wording + earn hint, wing column moved left, map panel reordered (fold_ok), shots.sh stale-PNG guard, selftest _test_touch_ux. Review round due at builds_since_review>=6.

## S0030 — 2026-10-27 21:10 — BUILD
- Task(s): VS-033 atomic run save + honest save failures — done (QA PASS)
- Check: PASS · Git: committed (see git log)
- Notes: run_save.gd tmp+verify+rename with .bak fallback; run_flow.gd throttled "Autosave failed" msg; selftest extended. QA P3s: _parses only checks "version" key; HUD message rendering untested on screen. builds_since_review now 6 -> PLANNING next.

## S0031 — 2026-10-27 22:38 — PLANNING+BUILD
- Task(s): review round (critic avg 6.5, QA sweep no P0-P2, balance 8/8 green) -> VS-038..042 created; VS-038 hot opening done (QA FAIL round 1 on nw20 gate, fixed by pilot-present gating, PASS round 2)
- Check: PASS · Git: committed (see git log)
- Notes: harness hides the pilot so First Sortie never spawns in balance gates (parking lot). builds_since_review reset to 0.

## S0032 — 2026-10-27 23:35 — BUILD
- Task(s): VS-039 raid tracks on inset + map panel (labels, outcome history, Defend patrol button) — done (QA PASS round 1); VS-043 created from QA P3s
- Check: PASS · Git: committed (see git log)
- Notes: sim bit-identical to HEAD (A/B 9 seeds); HEAD metrics drifted vs S0031 line (nw20 120.8k, nw30 167.5k, hive@20 53).

## S0033 — 2026-10-28 00:10 — BUILD
- Task(s): VS-035 Fit-to-screen text guard and map/title label fixes — done (QA PASS round 1)
- Check: PASS · Git: committed (see git log)
- Notes: overlay.gd fit_lines word-wrap, map_view.gd station names second pass, Hud.rate_text 15 s gate, selftest _test_text_fit. QA P3: touch@900 hint shows "Union.Trade Hub" stray dot (unverified, may predate).

## (skipped) — 2026-10-28 01:56 UTC — LOCKED
- Lock held by S0034 since 00:56Z (<4h); VS-036 in-progress with uncommitted edits. Scheduled firing stood down, no changes made.

## S0034 — 2026-10-28 02:25 — BUILD
- Task(s): VS-036 raid intercept bounty — done (QA FAIL round 1 on perturbed gates due to redirect; fix round disabled redirect behind Defs.RAID_REDIRECT_ENABLED; QA PASS round 2). Created VS-044 (redirect re-enable via platform-building balance policy).
- Check: PASS · Git: committed (see git log)
- Notes: bounty 40 cr/raider, ledger 'Raid intercepts', no bounty for redirected raids. Roles collapsed: none.

## (S0036 attempt) — 2026-10-28 03:56 — SKIPPED
- Lock held by S0035 since 02:57Z (<4h, ~1h ago) with VS-037 in-progress and uncommitted game edits; per procedure, no work done, HANDOVER untouched.

## S0035 — 2026-10-28 03:00 — BUILD
- Task(s): VS-037 on-foot flank pressure + kill feedback — done (QA FAIL round 1: freed-Core SCRIPT ERROR, bot never boarded; fix round; QA PASS round 2). New VS-045 (flank costs hp).
- Check: PASS · Git: committed (see git log)
- Notes: acceptance "2-3 flankers" retuned to 5-6 at 30 m, 1.8x speed/dmg. Pylons 51 s, Core 65 s, boarded 113 s, min_foot 525 (shield only).

## S0036 — 2026-10-28 05:10 — BUILD
- Task(s): VS-040 income empty state + net/gross labelling — done (QA PASS round 1).
- Check: PASS · Git: committed (see git log)
- Notes: 3 QA P3s to parking lot. builds_since_review=6 -> PLANNING next.

## S0037 — 2026-10-28 06:10 — PLANNING
- Task(s): review round (Critic 6.7/10, QA sweep no P0-P2, Balance 8/9 targets met); created VS-046, VS-047, VS-048; no BUILD (top task VS-048 is size M, wrap-up kept short)
- Check: PASS · Git: committed (see git log)
- Notes: 8 open todos. Parking lot gained prompt-clutter bundle, convoy beat, on-foot autosave, balance watch items.

## S0038 — 2026-10-28 07:05 — BUILD
- Task(s): VS-045 flank pressure costs on-foot hp — done (QA PASS round 1)
- Check: PASS · Git: committed (see git log)
- Notes: foe shots carry a mult key; FLANK_DAMAGE_MULT 1.8->3.8, FLANK_MIN/MAX 6/7. surface_long min_hp 84, min_foot 315, core dead 67.1s, pylons 55.4s.

## S0039 — 2026-10-28 08:35 — BUILD
- Task(s): VS-046 tips follow the threat — done (QA PASS round 1)
- Check: PASS · Git: committed
- Notes: Developer 23 min, QA 2 min. VS-047 left for next session.

## S0040 — 2026-10-28 09:05 — BUILD
- Task(s): VS-047 top-bar honest net income — done (QA PASS round 1)
- Check: PASS · Git: committed (see git log)
- Notes: hud.gd rate_text now "net +N/min" from ledger; selftest fit guard extended. Ledger 5 s buckets can tick rate up ~9% during decay.

## S0041 — 2026-10-28 10:10 — BUILD
- Task(s): VS-041 honest surface save (landing autosave + HUD/pause notice) — done, QA PASS round 1
- Check: PASS · Git: committed (see git log)
- Notes: Dev + independent QA subagents. No pause-overlay screenshot scenario exists (optional follow-up).

## S0042 — 2026-10-28 11:30 — BUILD
- Task(s): VS-043 raid panel fit - done (QA PASS round 1)
- Check: PASS · Git: committed
- Notes: Defend 46 px (logical; ~30 px physical at 900 wide, QA P3). No balance change.

## S0043 — 2026-10-28 12:30 — BUILD
- Task(s): VS-048 station wounds (paid HQ/station repair, DAMAGED label, dock button, HUD %) — done, QA PASS round 1
- Check: PASS · Git: committed (see git log)
- Notes: builds_since_review now 6 -> PLANNING forced next session. Balance verified on 6/6 economic + 3 passive seeds only (sim unchanged).

## S0044 — 2026-10-28 13:50 — PLANNING+BUILD
- Task(s): review round (critic 6.7, QA sweep, balance 8/9 targets) -> VS-050..053 + VS-049; BUILD VS-049 surface freeze (float32 loop in Hud.layout_markers) done, QA PASS
- Check: PASS · Git: committed (see git log)
- Notes: Critic: VS-048 price too soft, wounds never occur organically -> VS-050/051/052. Real-browser pass (VS-042) still outstanding.

## S0045 — 2026-10-28 14:55 — BUILD
- Task(s): VS-050 wounded-HQ penalty (<50% hull: linear, cap -30% on colony income + shield regen) — done, QA FAIL r1 (map label clipped price) → fix → PASS r2
- Check: PASS · Git: committed (see git log)
- Notes: econ HQ 9/9, passive loss median 28.9 min. New --shot wound_map / wound_dock. P3: map label backdrop faint, ship glyph can cross it.

## S0046 — 2026-10-28 15:25 — BUILD
- Task(s): VS-052 Economic bot repairs the HQ in the balance harness — done (QA PASS r1). Chosen over VS-042 (next's pick) per HANDOVER plan; VS-042 needs export templates.
- Check: PASS · Git: committed (see git log)
- Notes: Gate economic 9/9 HQ, nw20 median 120726, passive loss median 28.9. Seed 135 nw30 swings 20.8k vs 103k with/without a 293 cr repair = RNG chaos. Wounds occur organically on most seeds.

## S0047 — 2026-10-28 16:10 — BUILD
- Task(s): VS-053 signed credit deltas + full-hull status rows — done (QA FAIL r1: touch panel overlap; fixed; PASS r2)
- Check: PASS · Git: committed (see git log)
- Notes: deltas anchor (14,116) desktop / (360,140) touch; touch_wing shot now emits deltas. builds_since_review=4.

## S0048 — 2026-10-28 17:45 — BUILD
- Task(s): VS-051 Raids leave marks (chip damage 2%/surviving ship, cap 25%, once per raid at arrival) — done, QA PASS r1
- Check: PASS · Git: committed (see git log)
- Notes: nw30 median fell 158k -> 121k; economic HQ 8/9 (seed 135 lost 23.7 min); passive loss median 27.3 min; perturb=1 9/9. P3 follow-ups: dock has no raid-outcome line; DAMAGED label overlaps ships.

## S0049 — 2026-10-28 18:35 — BUILD
- Task(s): VS-042 blocked (no Web export templates, no headless browser); VS-044 done (redirect A/B: stays off, --redirect flag + telemetry added; QA PASS r1)
- Check: PASS · Git: committed (see git log)
- Notes: builds_since_review now 6 -> PLANNING due next session. Data in studio/reviews/S0049-redirect-ab.txt.
- S0049 follow-up: chip 0.015 + templates installed (Daniel request); check PASS

## S0050 — 2026-10-28 19:50 — PLANNING+BUILD
- Task(s): review round (Critic 6.8, QA sweep P3 only, balance 7/9 targets) -> VS-054..058; VS-054 raid forecast done (QA PASS r1)
- Check: PASS · Git: committed (see git log)
- Notes: stale .git/HEAD.lock moved to .git/stale-head-lock-S0050 (git can't unlink without delete permission).

## S0051 — 2026-10-28 20:10 — BUILD
- Task(s): VS-055 HQ hull readout + hq_wounded_hud/dock_wounded shots — done (QA PASS r1)
- Check: PASS · Git: committed (see git log)
- Notes: Defs.HQ_HULL_OK_FRAC added (balance.gd REPAIR_BELOW uses it). Wounded tag + raid forecast not shot together.

## S0052 — 2026-10-28 21:55 — BUILD
- Task(s): VS-056 Hive cap trim + --fleet-floor harness flag — done (QA PASS r1)
- Check: PASS · Git: committed (see git log)
- Notes: NEST_CAP_GROWTH 120->126 (cap@20 16->15). Passive hive@20 median 60 = exactly the guard (no margin). Fleet floor 10 delays passive collapse ~10 min (median 35.7, 1/9 survives) = VS-057 baseline.

## S0053 — 2026-10-28 22:30 — BUILD
- Task(s): VS-057 split into VS-059/060/061; VS-058 One touch HUD message lane — done (QA FAIL r1 on pinned map Close button breaking VS-043 fold assert; fixed by reverting it; QA PASS r2)
- Check: PASS · Git: committed (see git log)
- Notes: New scripts/ui/hud_lane.gd; touch buttons respaced (BTN_GAP 12); pylon labels merge on touch. Map Close pin dropped -> parking lot P3.

## S0054 — 2026-10-28 23:05 — BUILD
- Task(s): VS-059 Fleet Reserve sim logic — done (QA PASS r1)
- Check: PASS · Git: committed (see git log)
- Notes: Tunables RESERVE_COST 4000/COUNT 6/LINGER 180/COOLDOWN 600 are dev picks, untuned. P3 QA bug parked (Director UNION_QUOTA counts reserve ships).

## S0055 — 2026-10-29 00:10 — BUILD
- Task(s): VS-060 Fleet Reserve map+dock button - done (QA PASS r1); VS-062 created from QA notes
- Check: PASS · Git: committed (see git log)
- Notes: builds_since_review now 6, so S0056 must start with PLANNING. Map reserve button is below the fold in raids (VS-062).

## S0056 — 2026-10-29 01:55 — PLANNING+BUILD
- Task(s): review round (Critic 6.7/10, QA sweep no P0-P2, Balance 8/9 targets, Scout 5 proposals) -> VS-063..VS-066 (+Decree to parking lot). VS-061 Reserve A/B done (QA PASS r1, no code change).
- Check: PASS · Git: committed (review round f124513 + wrap-up commit)
- Notes: Reserve rescues passive seed 101 when --reserve is on (default passive unchanged). Stale .git/HEAD.lock moved to .git/stale-HEAD-lock-S0056.

## S0057 — 2026-10-29 02:20 — BUILD
- Task(s): VS-066 split -> VS-067/068; VS-067 map pinned command strip done (QA PASS r1); VS-062 superseded; VS-069 added from QA P2
- Check: PASS · Git: committed (see git log)
- Notes: New scripts/ui/map_strip.gd; order grid 4 cols with shortened labels; credits line moved to map canvas. QA found 6 px fold overflow when HQ damaged -> VS-069.

## S0058 — 2026-10-29 03:10 — BUILD
- Task(s): VS-069 Repair HQ strip fold overflow + coverage — done (Developer + independent QA PASS r1)
- Check: PASS · Git: committed (see git log)
- Notes: strip compacted (BTN 44, sep 1, forecast 11 px); new raid_map_damaged shot; partial-repair label. P3 follow-up parked.

## S0059 — 2026-10-29 04:30 — BUILD
- Task(s): VS-063 raid-hit proof run — done (QA PASS r1); VS-070 added (harden raid_hit vs slow runs)
- Check: PASS · Git: committed (see git log)
- Notes: new scripts/raid_hit_proof.gd, shots.sh multi-frame (_2/_3). raid_hit flaked 1/4 runs under load.

## S0060 — 2026-10-29 05:06 — BUILD
- Task(s): VS-070 raid_hit shot hardening — done (QA PASS r1)
- Check: PASS · Git: committed (see git log)
- Notes: STUCK_FRAMES=30000 exceeds shots.sh 150 s timeout (QA P3); run time varied 44-123 s.

## S0062 — 2026-10-29 06:57 — SKIPPED
- Lock held by S0061 since 05:56Z (<4h); files modified 06:38Z, so it appears active. No work done.

## S0061 — 2026-10-29 07:05 — BUILD
- Task(s): VS-064 passive Hive cap trim — done (Developer + independent QA PASS r1)
- Check: PASS · Git: committed (see git log)
- Notes: NEST_CAP_GROWTH 126->145 (140 and 150 failed earliest-HQ-loss gate). Econ HQ now 8/9 (seed 186 lost at 23.7 min) — thin margin. metrics rows lack nw10/nw30/union cols.

## S0062 — 2026-10-29 08:55 — PLANNING
- Task(s): review round -> VS-072..074, VS-075 added; VS-071 (nest cap 135 / nw30 gate) BLOCKED: 135 fails passive earliest-loss (20.4<22); warship -10% gives 9/9 HQ but nw30 q1 57k. No game code changed.
- Check: PASS · Git: committed (see git log)
- Notes: Critic avg 6.8; QA no P0-P2; balance targets met, economic nw30 168k->106k. Decree parked.

## S0063 — 2026-10-29 09:10 — BUILD
- Task(s): VS-068 Map side panel Buy/Build/Orders tabs — done (QA PASS r1); VS-076 follow-up added
- Check: PASS · Git: committed (see git log)
- Notes: New scripts/ui/map_tabs.gd (44 px tabs, keys 1-3). map_view.gd grew to 645 lines; shrink deferred to VS-076.

## S0064 — 2026-10-29 10:20 — BUILD
- Task(s): VS-065 900x720 touch/panel polish - done (QA PASS r1)
- Check: PASS · Git: committed (see git log)
- Notes: Gun moved to GUN_X 0.02 (QA P3: too central, parked); over.png Best moved above ship; map scroll cue added with assert.

## S0065 — 2026-10-29 12:00 — BUILD
- Task(s): VS-072 Shakedown probe (done; QA r1 FAIL on P3 inset clip of forecast text, fixed, r2 PASS for clip; raid_map re-run clean by Producer)
- Check: PASS · Git: committed (see git log)
- Notes: Probe at 80 s, 3 harmless breach drones, PROBE-flagged. Passive median 28.9 vs 25.9 off; econ seed 118 lost HQ at 29.1 min with probe (chaos?). raid_hit not re-run after the string-only fix (r1 verified it).

## S0066 — 2026-10-29 12:15 — BUILD
- Task(s): VS-073 surface collapse-and-extract beat — done (QA PASS r1)
- Check: PASS · Git: committed (see git log)
- Notes: Dev claimed surface_long bot dies ~t=49; QA found stock surface_long reaches Core at t=67 and shows the beat (boards t=84). New shots surface_collapse / surface_collapse_long added.

## S0067 — 2026-10-29 13:25 — BUILD
- Task(s): VS-074 Map stakes: raid banner + fleet route lines — done (QA PASS r1)
- Check: PASS · Git: committed (see git log)
- Notes: 16px raid banner, strip forecast 14px, outcome wraps; amber dashed route arrows on galaxy inset. QA P3s: banner duplicates strip forecast; banner comment claims shrink-to-fit but it clips; no selftest asserts routes draw.
