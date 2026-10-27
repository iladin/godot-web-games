# Void Sovereign — Handover
_Last updated: S0024 · 2026-10-27 14:10 UTC · mode: BUILD_

## TL;DR
S0024 shipped VS-028 (New Game over a save now asks to confirm; title_continue shots; save-flow selftests), QA PASS by independent agent. check.sh PASS. VS-029 still blocked on Daniel. Lock released.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0025. builds_since_review = 6 -> run PLANNING first (Critic + QA sweep + Balance in parallel, then Feature Scout), then BUILD VS-030 if budget remains.
2. Check INBOX for Daniel's answer on VS-029 (passive-40 HQ-lost median 36.0 vs ceiling 35). Accept -> `backlog.py set ... VS-029 status done`; else one small retune (BREACH_DPS/BREACH_HULL in defs.gd), QA re-run `GATE_OFFSETS="0 3" bash scripts/studio/balance_gate.sh void-sovereign passive 40`.
3. BUILD VS-030 First Sortie, then VS-031, VS-032.
4. Parked: title FLIGHT controls line clipped at 1280 (QA P3, pre-existing; consider small task), touch Cancel button on New Game confirm prompt, deterred-raid redirect, RAID_DETER_RANGE 3800 trial, raid map label clamp, VS-006 Hive count guard, on-screen "The Breach" cue, save on manual pause / on-surface, split main.gd.

## Last session
- Did: VS-028 implemented (RunFlow.request_new_game confirm gate, 0.35s guard, Esc cancels) and QA-verified.
- Check: PASS · Git: committed this session · Roles collapsed: none

## In-flight / uncommitted work
None from this session. Unrelated uncommitted, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/` (Daniel's).

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA.
- Latest metrics: econ20 nw20 median ~99-110k; HQ 3/3; passive40 median 36.0 (VS-029 blocked).

## Backlog snapshot
todo 4 · in-progress 0 · done 23 · blocked 2 · split 3 · Top ready: VS-028, VS-030, VS-031

## Watch out for
- Restored runs are NOT bit-identical. Saves skipped on foot / while dead (previous save stays). Autoplay/shots use `user://run_autoplay.save`.
- New Game over a save requires a second press (confirm); Continue on touch is the only cancel.
- RaidTracker raid dict keys hard-coded in SaveGame._valid; bump VERSION if fields change.
- nw20 gate is chaos-fragile to RNG-order changes. Stale `.tools/balance_gate/*` summaries mislead; re-run.
- Background jobs do not survive past one device_bash call; use foreground `timeout 175`.
- RaidTracker RNG-free. Credits via `Universe.add_credits`. PauseGate first child of main. Sounds via `Sfx.play()`.
- Git writes may leave stale .lock files; mv them aside.

## Open questions for Daniel
- VS-029: accept passive-40 HQ-lost median 36.0 min (ceiling 35), or retune?
- Fortified HQ nearly raid-free after minute 20 - want the Breach nastier?
- HUD income gross vs net? Target session length? over.png Net worth 45,000 vs 30,000 credits - confirm formula.

## Answers to Daniel
- None (INBOX empty).

## Session history (newest first, keep 10)
- S0024 2026-10-27 BUILD — VS-028 save robustness + new-game confirm done (QA PASS)
- S0023 2026-10-27 BUILD — VS-027 autosave + Continue done (QA PASS)
- S0022 2026-10-27 BUILD — VS-026 save data layer done (QA PASS)
- S0021 2026-10-27 BUILD — VS-029 QA: FAIL on passive median 36.0 (gate 35) -> blocked pending decision
- S0020 2026-10-27 BUILD — VS-029 Breach implemented, QA pending
- S0019 2026-10-27 PLANNING+BUILD — review round (critic 6.1) -> VS-029..032; VS-025 raid reports done (QA PASS)
- S0018 2026-10-27 BUILD — VS-009 split into VS-026..028; VS-023 raid deterrent range done (QA PASS)
- S0016 2026-10-27 BUILD — VS-007 wing commands done (QA FAIL touch overlap → fix → PASS)
- S0017 2026-10-27 SKIPPED — lock held by S0016
- S0015 2026-10-27 BUILD — VS-010 NPC traders vs broke player station done
