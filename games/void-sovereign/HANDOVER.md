# Void Sovereign — Handover
_Last updated: S0021 · 2026-10-27 11:30 UTC · mode: BUILD (QA verify only)_

## TL;DR
S0021 ran independent QA on VS-029 (The Breach): everything passes except the passive 40-min gate (HQ-lost median 36.0 min vs target 20-35). VS-029 is blocked pending a decision; code is committed and check.sh is PASS. Studio lock released.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false …`). Next id S0022. builds_since_review = 3.
2. Check INBOX for Daniel's answer on VS-029. If he accepts 36.0 as in tolerance -> `backlog.py set … VS-029 status done`. If not, or no answer: one small Developer retune (BREACH_DPS/BREACH_HULL in defs.gd, plus a harness `--nobreach` flag to get a passive baseline), then fresh QA re-run of passive 40 (`GATE_OFFSETS="0 3" bash scripts/studio/balance_gate.sh void-sovereign passive 40`, then `GATE_OFFSETS="6" …`) and economic 20 incl. `--perturb=1`.
3. Otherwise BUILD `backlog.py next` (VS-026 save data layer, M; then VS-027, VS-028; also VS-030 First Sortie, VS-031, VS-032). Give the Developer a hard 45-minute cap; run gates in parallel batches within each 170 s device call.
4. Parked: deterred-raid redirect, RAID_DETER_RANGE 3800 trial, raid map label clamp, "raid succeeded" outcome, VS-006 Hive count guard, on-screen "The Breach" cue, active-raid --shot scenario.

## Last session
- Did: QA verify of VS-029 (9-seed breach probe x3 modes, econ20, econ20 --perturb=1, passive 40). Spawn at 360 s 9/9; defended HQ min hull 0.90-0.99; idle 0.72-0.87; bare 0.39-0.76; econ20 nw20 min 98k med 110.5k HQ 9/9; perturbed med 127k (seeds 118=37k, 169=81k under 90k); passive: lost at 27.7-37.5 in 6 seeds, 3 survive, median 36.0.
- Check: PASS · Git: committed this session · Roles collapsed: none

## In-flight / uncommitted work
None from this session. Unrelated uncommitted, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/` (QA also saw modified .claude/skills, CLAUDE.md — Daniel's).

## Build health
- check.sh: PASS (selftest ~2.5 min; use `timeout 170`) · known noise: ObjectDB leak at exit, ALSA.
- Latest metrics: econ20 nw20 min 98k / med 110.5k; HQ 9/9; passive40 median 36.0.

## Backlog snapshot
todo 6 · in-progress 0 · done 21 · blocked 2 (VS-029 + 1 older) · split 3 · Top ready: VS-026, VS-027, VS-030

## Watch out for
- nw20 gate is chaos-fragile: Breach spawn draws global RNG; any RNG-order change swings median 10-30k.
- Stale `.tools/balance_gate/*/first_*.txt` summaries can mislead — always re-run.
- Background jobs do not survive past one device_bash call; run foreground with `timeout 175`.
- RaidTracker must stay RNG-free. Credits via `Universe.add_credits(amount, "<category>")`. PauseGate stays main's first child. Sounds via `Sfx.play()`.
- Git writes leave stale .lock files; mv them aside.

## Open questions for Daniel
- VS-029: accept passive-40 HQ-lost median 36.0 min (ceiling 35) as fine, or retune?
- Is it acceptable that a fortified HQ is nearly raid-free after minute 20? Bare-HQ breach only drops hull to 0.39-0.76 — want it nastier?
- HUD income: gross vs net? Target session length? over.png Net worth 45,000 vs 30,000 credits — confirm formula.

## Answers to Daniel
- None (INBOX empty).

## Session history (newest first, keep 10)
- S0021 2026-10-27 BUILD — VS-029 QA: FAIL on passive median 36.0 (gate 35) -> blocked pending decision
- S0020 2026-10-27 BUILD — VS-029 Breach implemented, QA pending
- S0019 2026-10-27 PLANNING+BUILD — review round (critic 6.1) -> VS-029..032; VS-025 raid reports done (QA PASS)
- S0018 2026-10-27 BUILD — VS-009 split into VS-026..028; VS-023 raid deterrent range done (QA PASS)
- S0016 2026-10-27 BUILD — VS-007 wing commands done (QA FAIL touch overlap → fix → PASS)
- S0017 2026-10-27 SKIPPED — lock held by S0016
- S0015 2026-10-27 BUILD — VS-010 NPC traders vs broke player station done
- S0014 2026-10-27 BUILD — VS-005 marker declutter + VS-022 surface freeze done
- S0013 2026-10-27 BUILD — VS-024 credit ledger done
- S0012 2026-10-27 PLANNING — review round 2 (critic 5.5/10)
