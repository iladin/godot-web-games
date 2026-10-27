# Void Sovereign — Handover
_Last updated: S0028 · 2026-10-27 19:12 UTC · mode: BUILD_

## TL;DR
S0028 closed VS-031 (Core spire + pylon beams, outlined HUD text); QA PASS, check.sh PASS. Backlog has 5 ready tasks, studio healthy.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0029. builds_since_review = 4. Export `GODOT=$(bash scripts/studio/ensure_godot.sh | tail -1)` for EVERY check call.
2. `backlog.py next` -> BUILD it (VS-032 first-minute touch/UX bundle, S; then VS-033 atomic run save `scripts/sim/run_save.gd`, VS-035 text fit guard). Developer subagent -> fresh QA subagent.
3. VS-037 (on-foot flanking Hive) depends on VS-031 which is now DONE, so it is unblocked; VS-036 (M) also ready. Split if size L.
4. Check INBOX (empty at S0028). Review round due at builds_since_review >= 6 (about S0030).

## Last session
- Did: VS-031 -> done. surface_view.gd (Spire + per-pylon Beam, _pulse_spire), hud.gd `_txt` outline, test_driver.gd `--shot=surface_far`, selftest `_test_surface_landmarks`. Criterion 1 wording amended (map max ~553 m on foot; visible at 511 m).
- Check: PASS · Git: committed this session · Roles collapsed: none

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`.

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA.
- Latest metrics: see Next session #2 (post-VS-030 gate numbers).

## Backlog snapshot
todo 5 · in-progress 0 · done 28 · blocked 1 · split 3 · Top ready: VS-032, VS-033, VS-035

## Watch out for
- HUD `_txt` outline now applies to ALL HUD text (check touch readability/draw cost in a real browser). Spire is a 260 m pulsing pink pillar; some may find it intrusive. Optional: add surface_far to shots.sh list.
- Idle player drops to ~261 hull in the sortie (touch players may find it harsh); tune SORTIE_ESCORT_DELAY / OPENING_WAVE_DPS in defs.gd.
- Passive tail near the edge of the 20-35 window (seed 186 survives to 40).
- Restored runs are not bit-identical. RunSave.write non-atomic until VS-033. RaidTracker keys hard-coded in SaveGame._valid.
- nw20 gate is chaos-fragile to RNG-order changes. Re-run gates, stale `.tools/balance_gate/*` mislead.
- Do NOT `pkill -f godot` inside device_bash (kills your own shell); use `pkill -x godot`.
- Background jobs do not survive one device_bash call; foreground `timeout 175`, balance sequential.

## Open questions for Daniel
- Fortified HQ nearly raid-free after minute 20: want the Breach nastier?
- HUD income gross vs net? Target session length? over.png Net worth 45,000 vs 30,000: confirm formula.
- A real-browser pass is still needed for IndexedDB persistence of the run save and audio unlock (also the new "alert" cue).

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0028 2026-10-27 BUILD — VS-031 spire + beams, QA PASS -> done
- S0027 2026-10-27 BUILD — VS-030 selftest fix, QA PASS -> done
- S0026 2026-10-27 BUILD — VS-030 First Sortie implemented, QA FAIL on dead selftest assertion -> blocked (code kept, check PASS)
- S0025 2026-10-27 PLANNING+BUILD — review round -> VS-033..037; VS-034 Breach retune done (QA PASS), VS-029 closed
- S0024 2026-10-27 BUILD — VS-028 save robustness + new-game confirm done (QA PASS)
- S0023 2026-10-27 BUILD — VS-027 autosave + Continue done (QA PASS)
- S0022 2026-10-27 BUILD — VS-026 save data layer done (QA PASS)
- S0021 2026-10-27 BUILD — VS-029 QA: FAIL on passive median 36.0 (gate 35) -> blocked pending decision
- S0020 2026-10-27 BUILD — VS-029 Breach implemented, QA pending
- S0019 2026-10-27 PLANNING+BUILD — review round (critic 6.1) -> VS-029..032; VS-025 raid reports done (QA PASS)
- S0018 2026-10-27 BUILD — VS-009 split into VS-026..028; VS-023 raid deterrent range done (QA PASS)
