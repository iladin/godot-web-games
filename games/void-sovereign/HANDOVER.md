# Void Sovereign — Handover
_Last updated: S0029 · 2026-10-27 20:10 UTC · mode: BUILD_

## TL;DR
S0029 closed VS-032 (touch ACT wording/earn hint, wing column, map fold, shots.sh stale guard); QA PASS, check.sh PASS. Backlog has 4 ready tasks, studio healthy.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0030. builds_since_review = 5. Export `GODOT=$(bash scripts/studio/ensure_godot.sh | tail -1)` for EVERY check call.
2. `backlog.py next` -> BUILD it: VS-033 atomic run save (`scripts/sim/run_save.gd`, S), then VS-035 text fit guard (S). Developer subagent -> fresh QA subagent.
3. After that BUILD, builds_since_review hits 6 -> run a PLANNING round (Critic + QA sweep + Balance + Scout) next. VS-036 and VS-037 (both M) are ready; split if size L.
4. Check INBOX (empty at S0029).

## Last session
- Did: VS-032 -> done. hud.gd (Hud.objective_for, earn_hint), dock_panel.gd (hq_hint), touch_controls.gd (layout_circles, wing column x=52), map_view.gd (fold_ok, BUY/BUILD above detail block), shots.sh stale-PNG guard, scenarios touch_wing + dock_touch, selftest _test_touch_ux. Earn hint now also shows on desktop when income is 0. 3 QA P3s parked (see parking lot).
- Check: PASS · Git: committed this session · Roles collapsed: none

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`.

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA.
- Latest metrics: see Next session #2 (post-VS-030 gate numbers).

## Backlog snapshot
todo 4 · in-progress 0 · done 29 · blocked 1 · split 3 · Top ready: VS-033, VS-035, VS-036

## Watch out for
- HUD `_txt` outline now applies to ALL HUD text (check touch readability/draw cost in a real browser). Spire is a 260 m pulsing pink pillar; some may find it intrusive. Optional: add surface_far to shots.sh list.
- Idle player drops to ~261 hull in the sortie (touch players may find it harsh); tune SORTIE_ESCORT_DELAY / OPENING_WAVE_DPS in defs.gd.
- Passive tail near the edge of the 20-35 window (seed 186 survives to 40).
- Restored runs are not bit-identical. RunSave.write non-atomic until VS-033. RaidTracker keys hard-coded in SaveGame._valid.
- nw20 gate is chaos-fragile to RNG-order changes. Re-run gates, stale `.tools/balance_gate/*` mislead.
- Do NOT `pkill -f godot` inside device_bash (kills your own shell); use `pkill -x godot`.
- Background jobs do not survive one device_bash call; foreground `timeout 175`, balance sequential.

## Open questions for Daniel
- Desktop text got slightly longer (earn hint when income is 0, HQ dock second sentence): keep, or touch-only?
- Fortified HQ nearly raid-free after minute 20: want the Breach nastier?
- HUD income gross vs net? Target session length? over.png Net worth 45,000 vs 30,000: confirm formula.
- A real-browser pass is still needed for IndexedDB persistence of the run save and audio unlock (also the new "alert" cue).

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0029 2026-10-27 BUILD — VS-032 touch/UX bundle, QA PASS -> done
- S0028 2026-10-27 BUILD — VS-031 spire + beams, QA PASS -> done
- S0027 2026-10-27 BUILD — VS-030 selftest fix, QA PASS -> done
- S0026 2026-10-27 BUILD — VS-030 First Sortie implemented, QA FAIL on dead selftest assertion -> blocked (code kept, check PASS)
- S0025 2026-10-27 PLANNING+BUILD — review round -> VS-033..037; VS-034 Breach retune done (QA PASS), VS-029 closed
- S0024 2026-10-27 BUILD — VS-028 save robustness + new-game confirm done (QA PASS)
- S0023 2026-10-27 BUILD — VS-027 autosave + Continue done (QA PASS)
- S0022 2026-10-27 BUILD — VS-026 save data layer done (QA PASS)
- S0021 2026-10-27 BUILD — VS-029 QA: FAIL on passive median 36.0 (gate 35) -> blocked pending decision
- S0020 2026-10-27 BUILD — VS-029 Breach implemented, QA pending
