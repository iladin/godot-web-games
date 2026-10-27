# Void Sovereign — Handover
_Last updated: S0022 · 2026-10-27 12:15 UTC · mode: BUILD_

## TL;DR
S0022 shipped VS-026 (save data layer: `scripts/sim/save_game.gd` capture/restore + selftest), QA PASS by an independent agent. check.sh PASS. VS-029 (Breach) remains blocked on Daniel's decision. Studio lock released.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0023. builds_since_review = 4.
2. Check INBOX for Daniel's answer on VS-029 (passive-40 HQ-lost median 36.0 vs ceiling 35). Accept -> `backlog.py set ... VS-029 status done`; else one small retune (BREACH_DPS/BREACH_HULL in defs.gd + harness `--nobreach`), QA re-run `GATE_OFFSETS="0 3" bash scripts/studio/balance_gate.sh void-sovereign passive 40` etc.
3. BUILD VS-027 (autosave + Continue on title, S): use `SaveGame.capture/restore`; file I/O `user://run.save`; must reconnect signals/messages after restore and rebind main view to restored Universe; keep PauseGate as main's first child; update DESIGN.md. 45-minute Developer cap.
4. Then VS-028 (add: validator should reject non-numeric rng strings), VS-030 First Sortie, VS-031, VS-032. builds_since_review reaches 6 soon -> PLANNING round.
5. Parked: deterred-raid redirect, RAID_DETER_RANGE 3800 trial, raid map label clamp, "raid succeeded" outcome, VS-006 Hive count guard, on-screen "The Breach" cue, active-raid --shot scenario.

## Last session
- Did: VS-026 implemented (Developer) and verified (QA): round-trip net_worth/credits/entity count match; 60 s further stepping OK; bad dicts return null; capture RNG-free and read-only; economic-20 gate 3/3 HQ, median 99k.
- Check: PASS · Git: committed this session · Roles collapsed: none

## In-flight / uncommitted work
None from this session. Unrelated uncommitted, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/` (Daniel's).

## Build health
- check.sh: PASS (selftest ~2.5 min; use `timeout 170`) · known noise: ObjectDB leak at exit, ALSA.
- Latest metrics: econ20 nw20 median ~99-110k; HQ 3/3; passive40 median 36.0 (VS-029 blocked).

## Backlog snapshot
todo 5 · in-progress 0 · done 22 · blocked 2 · split 3 · Top ready: VS-027, VS-028, VS-030

## Watch out for
- Restored runs are NOT bit-identical (global RNG reseeded from sim rng); don't promise deterministic resume.
- RaidTracker raid dict keys hard-coded in SaveGame._valid; bump VERSION if fields change.
- nw20 gate is chaos-fragile to RNG-order changes. Stale `.tools/balance_gate/*` summaries mislead; re-run.
- Background jobs do not survive past one device_bash call; use foreground `timeout 175`.
- RaidTracker must stay RNG-free. Credits via `Universe.add_credits`. PauseGate first child of main. Sounds via `Sfx.play()`.
- Git writes may leave stale .lock files; mv them aside.

## Open questions for Daniel
- VS-029: accept passive-40 HQ-lost median 36.0 min (ceiling 35), or retune?
- Fortified HQ nearly raid-free after minute 20 - want the Breach nastier?
- HUD income gross vs net? Target session length? over.png Net worth 45,000 vs 30,000 credits - confirm formula.

## Answers to Daniel
- None (INBOX empty).

## Session history (newest first, keep 10)
- S0022 2026-10-27 BUILD — VS-026 save data layer done (QA PASS)
- S0021 2026-10-27 BUILD — VS-029 QA: FAIL on passive median 36.0 (gate 35) -> blocked pending decision
- S0020 2026-10-27 BUILD — VS-029 Breach implemented, QA pending
- S0019 2026-10-27 PLANNING+BUILD — review round (critic 6.1) -> VS-029..032; VS-025 raid reports done (QA PASS)
- S0018 2026-10-27 BUILD — VS-009 split into VS-026..028; VS-023 raid deterrent range done (QA PASS)
- S0016 2026-10-27 BUILD — VS-007 wing commands done (QA FAIL touch overlap → fix → PASS)
- S0017 2026-10-27 SKIPPED — lock held by S0016
- S0015 2026-10-27 BUILD — VS-010 NPC traders vs broke player station done
- S0014 2026-10-27 BUILD — VS-005 marker declutter + VS-022 surface freeze done
- S0013 2026-10-27 BUILD — VS-024 credit ledger done
