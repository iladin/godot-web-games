# Void Sovereign — Handover
_Last updated: S0019 · 2026-10-27 08:50 UTC · mode: PLANNING+BUILD_

## TL;DR
S0019 ran a review round (critic 6.1/10 up from 5.5; QA sweep clean; balance 8/8 targets met) and shipped VS-025 (RaidTracker: honest raid arrival/outcome messages, map inset raid ETA markers, turned-back throttle). Backlog now has 7 ready todos; top is VS-029 The Breach. Build is green.

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; use `git --no-optional-locks -c core.fileMode=false …`). Next session id S0020. builds_since_review = 1.
2. **BUILD VS-029** (P1, M, The Breach): scripted early raid reaching the HQ at 5:30-7:30; uses `director.tracker` (`scripts/sim/raid_tracker.gd`). Run 9-seed econ gates in foreground batches (`balance.sh void-sovereign 30 3 economic` with seed offsets) plus `--perturb=1`, and passive 40 min. Split if it turns out L.
3. Then VS-030 (First Sortie), VS-031 (surface spire/beams), VS-032 (touch/UX bundle) — all S, P2.
4. Then save chain: VS-026 → VS-027 → VS-028.
5. Parked: deterred-raid redirect (after VS-029), RAID_DETER_RANGE 3800 trial, raid map label clamp, "raid succeeded" outcome, VS-006 Hive count guard.

## Last session
- Did: review round (reviews/S0019-*.md); VS-029..032 created; VS-025 done (dev + independent QA PASS, QA forced a raid to view the inset: labels overlap slightly, parked P3).
- Check: PASS · Git: see `git log` (review round 1e49fff + VS-025 commit) · Roles collapsed: none

## In-flight / uncommitted work
None from S0019 after its commit. Unrelated working-tree edits not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, `.claude/skills` (mode bits), untracked `_to_delete/`. Stale locks moved to `.git/stale-head-lock-S0019` and `.git/stale-maintenance-lock-S0019` (safe to delete). Snapshot S0019 in `.tools/snapshots/void-sovereign/`.

## Build health
- check.sh: PASS · selftest OK (new RaidTracker assertions) · known noise: ObjectDB leak at exit, ALSA under xvfb.
- Latest metrics: econ30 9 seeds HQ 9/9 nw20 med 107685 nw30 med 142176; passive40 HQ lost med 33.6; perturbed econ nw20 126k / nw30 129k (tail thin: 4/9 seeds <90k at nw30); hive_20 q3 61 (>60).

## Backlog snapshot
todo 7 · in-progress 0 · done 21 · blocked 1 · split 3 · ready 7 · Top ready: VS-029, VS-030, VS-031

## Watch out for
- **Perturbed econ gate thin:** re-run `--perturb=1` after any raid tuning. Passive HQ-lost median 33.6 is only 1.4 min under its 35 ceiling.
- **RaidTracker draws no RNG** — keep it that way; extra draws shift sim outcomes.
- **Countdown dimming** uses `next_raid_likely_deterred()` (HQ go-chance < 0.5), a proxy, not the exact raid roll.
- **Credits:** `Universe.add_credits(amount, "<category>")`. **PauseGate must stay main's first child.** Every sound via `Sfx.play()`.
- **device_bash cap 180 s:** run gates in foreground seed batches. Git writes leave stale .lock files here; mv them aside (don't request delete permission).
- shots.sh can report success on a stale PNG (VS-032 fixes).

## Open questions for Daniel
- Is it acceptable that a fortified HQ is nearly raid-free after minute 20? (VS-029 adds one guaranteed early raid; deterred-raid redirect parked.)
- HUD income: gross vs net? Target session length?
- over.png shows Net worth 45,000 vs 30,000 credits elsewhere — confirm formula.

## Answers to Daniel
- None (INBOX empty).

## Session history (newest first, keep 10)
- S0019 2026-10-27 PLANNING+BUILD — review round (critic 6.1) -> VS-029..032; VS-025 raid reports done (QA PASS)
- S0018 2026-10-27 BUILD — VS-009 split into VS-026..028; VS-023 raid deterrent range done (QA PASS)
- S0016 2026-10-27 BUILD — VS-007 wing commands done (QA FAIL touch overlap → fix → PASS)
- S0017 2026-10-27 SKIPPED — lock held by S0016
- S0015 2026-10-27 BUILD — VS-010 NPC traders vs broke player station done
- S0014 2026-10-27 BUILD — VS-005 marker declutter + VS-022 surface freeze done
- S0013 2026-10-27 BUILD — VS-024 credit ledger done
- S0012 2026-10-27 PLANNING — review round 2 (critic 5.5/10)
- S0011 2026-10-26 BUILD — VS-020 late-game Hive pressure fix
- S0010 2026-10-26 BUILD — VS-021 9-seed gates + VS-014 pause-screen input
