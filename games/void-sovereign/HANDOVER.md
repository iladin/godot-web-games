# Void Sovereign — Handover
_Last updated: S0026 · 2026-10-27 17:10 UTC · mode: BUILD_

## TL;DR
S0026 implemented VS-030 (First Sortie: escorts hold fire 16 s so the player takes the first fight). Gameplay and balance gates all pass and check.sh is PASS, but QA failed one criterion: the selftest "unmark reverts scouts to 1x" assertion never executes. VS-030 is `blocked` pending a tiny test-only fix; the code is committed.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0027. builds_since_review = 2.
2. Finish VS-030: set it back to `in-progress`. In `games/void-sovereign/scripts/selftest.gd` make the revert test force `ow._unmark()` on a living scout (both eased and uneased paths), assert hull/dps return to 1x, and `assert(revert_checked)` after. Dev + fresh QA; re-run only selftest + check.sh (gates already PASS: econ30 nw20 median 104k, HQ 9/9; passive40 median 31.9 min, 1/9 survive; perturb nw20 100.6k). Touch only test code unless QA finds more.
3. Then: VS-033 atomic run save (S, `scripts/sim/run_save.gd`), VS-035 fit-to-screen text guard (S), VS-031 before VS-037, VS-032, VS-036 (M).
4. Check INBOX. Next review round about S0031.

## Last session
- Did: BUILD VS-030. Files: sim/defs.gd, sim/opening_wave.gd, sim/universe.gd, sim/save_game.gd (optional keys engaged/eased, VERSION unchanged), space/space_view.gd, main.gd, audio/sfx.gd ("alert"), test_driver.gd (combat_long now in home sector; new `sortie` shot), selftest.gd, scripts/studio/shots.sh. QA: combat_long bot min hull 492 (deterministic), idle selftest min hull 261.
- Check: PASS · Git: committed · Roles collapsed: none
- Process note: session exceeded the 90 min budget (dev 46 min, QA 23 min). The QA subagent called device_request_delete_permission contrary to the procedure; it was only for its own temp file. Subagents should be told not to.

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`.

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA.
- Latest metrics: see Next session #2 (post-VS-030 gate numbers).

## Backlog snapshot
todo 6 · in-progress 0 · done 26 · blocked 2 (VS-030 test gap, plus one older) · split 3 · Top ready: VS-033, VS-035, VS-031

## Watch out for
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
- S0026 2026-10-27 BUILD — VS-030 First Sortie implemented, QA FAIL on dead selftest assertion -> blocked (code kept, check PASS)
- S0025 2026-10-27 PLANNING+BUILD — review round -> VS-033..037; VS-034 Breach retune done (QA PASS), VS-029 closed
- S0024 2026-10-27 BUILD — VS-028 save robustness + new-game confirm done (QA PASS)
- S0023 2026-10-27 BUILD — VS-027 autosave + Continue done (QA PASS)
- S0022 2026-10-27 BUILD — VS-026 save data layer done (QA PASS)
- S0021 2026-10-27 BUILD — VS-029 QA: FAIL on passive median 36.0 (gate 35) -> blocked pending decision
- S0020 2026-10-27 BUILD — VS-029 Breach implemented, QA pending
- S0019 2026-10-27 PLANNING+BUILD — review round (critic 6.1) -> VS-029..032; VS-025 raid reports done (QA PASS)
- S0018 2026-10-27 BUILD — VS-009 split into VS-026..028; VS-023 raid deterrent range done (QA PASS)
- S0016 2026-10-27 BUILD — VS-007 wing commands done (QA FAIL touch overlap → fix → PASS)
