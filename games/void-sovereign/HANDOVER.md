# Void Sovereign — Handover
_Last updated: S0020 · 2026-10-27 10:20 UTC · mode: BUILD_

## TL;DR
S0020 implemented VS-029 The Breach (Developer done, check.sh PASS) but ran out of budget before independent QA. VS-029 is in-progress and committed; QA verify is the first thing to do. Build is green.

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false …`). Next id S0021. builds_since_review = 2.
2. **QA-verify VS-029** with a fresh QA subagent (verify mode; `backlog.py next` returns it as in-progress). Give it the dev summary below. Specifically: re-run 9-seed econ gates, `--perturb=1`, passive 40 min (ideally also a no-breach passive baseline, since 3/9 seeds survive 40 min), `scripts/tools/breach_probe.gd` (idle/bare/defended), and check the Breach does not clash with the 60 s wave in HUD/messages. On PASS mark done; on FAIL one fix round.
3. Then VS-030 (First Sortie), VS-031 (spire/beams), VS-032 (touch/UX bundle), then save chain VS-026 → VS-027 → VS-028.
4. Parked: deterred-raid redirect, RAID_DETER_RANGE 3800 trial, raid map label clamp, "raid succeeded" outcome, VS-006 Hive count guard, on-screen "The Breach" cue, active-raid --shot scenario.

## Last session
- Did: VS-029 dev. defs.gd BREACH_TIME 360 / SIZE 4 / RANGE 2600 / HULL 24 / DPS 5; director.gd `_breach()` (breach_t, breach_count; own counter, not raid_count); ship_data.gd `breach` flag; universe.gd `valid_target` makes breach raiders attack stations only (ship-fighting variants crashed nw20 to 6-26k); selftest breach assertions + `dir.tracker.raids.clear()` fix; new probe `scripts/tools/breach_probe.gd`. Uses tracker.add (single RAID ARRIVING line); RaidTracker unchanged.
- Dev numbers: probe spawn at 360 s in 9/9; HQ min hull idle 0.72-0.87, bare 0.39-0.76, defended 0.90-0.99. Econ20 9 seeds nw20 min 98k med ~111k, HQ 9/9. Perturbed med 127k (seeds 37k and 81k below 90k). Passive 40: HQ lost 27.7-37.5 min in 6 seeds, 3 survive; harness median 28.3.
- Check: PASS · Git: committed on this session (see `git log`) · Roles collapsed: QA not run

## In-flight / uncommitted work
Committed. Unrelated uncommitted, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/` (includes dbg_tmp.gd.txt from the dev). Stale git locks aside in `.git/stale-*` (safe to delete).

## Build health
- check.sh: PASS (selftest ~2.5 min; hit the 180 s device cap twice — run with `timeout 170` and retry, or split) · known noise: ObjectDB leak at exit, ALSA.
- Latest metrics: see Dev numbers above.

## Backlog snapshot
todo 6 · in-progress 1 (VS-029) · done 21 · blocked 1 · split 3 · Top ready: VS-029 (QA), VS-030, VS-031

## Watch out for
- nw20 gate is chaos-fragile: Breach spawn draws global RNG; tuning was picked from several variants (some overfitting). Any RNG-order change swings median 10-30k.
- Dev took ~80 min alone: for the next BUILD, tell the Developer a hard 45-minute cap and to run gates in parallel batches.
- RaidTracker must stay RNG-free. Credits via `Universe.add_credits(amount, "<category>")`. PauseGate stays main's first child. Sounds via `Sfx.play()`.
- Git writes leave stale .lock files; mv them aside.

## Open questions for Daniel
- Is it acceptable that a fortified HQ is nearly raid-free after minute 20?
- HUD income: gross vs net? Target session length?
- over.png shows Net worth 45,000 vs 30,000 credits elsewhere — confirm formula.

## Answers to Daniel
- None (INBOX empty).

## Session history (newest first, keep 10)
- S0020 2026-10-27 BUILD — VS-029 Breach implemented, QA pending
- S0019 2026-10-27 PLANNING+BUILD — review round (critic 6.1) -> VS-029..032; VS-025 raid reports done (QA PASS)
- S0018 2026-10-27 BUILD — VS-009 split into VS-026..028; VS-023 raid deterrent range done (QA PASS)
- S0016 2026-10-27 BUILD — VS-007 wing commands done (QA FAIL touch overlap → fix → PASS)
- S0017 2026-10-27 SKIPPED — lock held by S0016
- S0015 2026-10-27 BUILD — VS-010 NPC traders vs broke player station done
- S0014 2026-10-27 BUILD — VS-005 marker declutter + VS-022 surface freeze done
- S0013 2026-10-27 BUILD — VS-024 credit ledger done
- S0012 2026-10-27 PLANNING — review round 2 (critic 5.5/10)
- S0011 2026-10-26 BUILD — VS-020 late-game Hive pressure fix
