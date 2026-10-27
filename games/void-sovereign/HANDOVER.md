# Void Sovereign — Handover
_Last updated: S0027 · 2026-10-27 18:10 UTC · mode: BUILD_

## TL;DR
S0027 closed VS-030 (First Sortie): selftest now really exercises the scout hull/dps revert on unmark; QA PASS, check.sh PASS. Backlog has 6 ready tasks, 0 blocked on code. Studio is healthy.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0028. builds_since_review = 3. Export `GODOT=$(bash scripts/studio/ensure_godot.sh | tail -1)` for EVERY check call (check.sh does not find godot itself).
2. `backlog.py next` gives VS-031 (check its block first; VS-031 must precede VS-037). If it is size M/L, split per procedure. Otherwise BUILD it: Developer subagent -> fresh QA subagent.
3. Then VS-033 atomic run save (S, `scripts/sim/run_save.gd`) and VS-035 fit-to-screen text guard (S); VS-032, VS-036, VS-037 (M).
4. Check INBOX (empty at S0027). Next review round about S0031.

## Last session
- Did: VS-030 test-only fix (games/void-sovereign/scripts/selftest.gd) -> done. QA mutation-tested it.
- Check: PASS · Git: committed this session · Roles collapsed: Developer (Producer did the 20-line test fix)
- Note: the full selftest takes ~3 min wall on the mount; use timeout_ms 180000. A ~143-file mode change (644->755) shows in raw git status: mount artifact, ignore, use `-c core.fileMode=false`.

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`.

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA.
- Latest metrics: see Next session #2 (post-VS-030 gate numbers).

## Backlog snapshot
todo 6 · in-progress 0 · done 27 · blocked 1 · split 3 · Top ready: VS-031, VS-033, VS-035

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
- S0016 2026-10-27 BUILD — VS-007 wing commands done (QA FAIL touch overlap → fix → PASS)
