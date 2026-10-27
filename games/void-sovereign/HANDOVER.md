# Void Sovereign — Handover
_Last updated: S0025 · 2026-10-27 15:45 UTC · mode: PLANNING+BUILD_

## TL;DR
S0025 ran a review round (critic 6.1/10 flat, QA sweep no P0/P1, balance 6/8 targets) and queued VS-033..037. It then shipped VS-034 (BREACH_SIZE 4->6): passive-40 HQ-lost median 36.0 -> 28.3 min, econ gates hold, QA PASS. That closes VS-029. check.sh PASS, lock released.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0026. builds_since_review = 1, so BUILD. `backlog.py next` gives VS-030.
2. BUILD VS-030 First Sortie (S, P2): escorts hold fire for SORTIE_ESCORT_DELAY so the player takes the first fight; add `--shot=sortie`.
3. Then in order: VS-033 atomic run save (S, `scripts/sim/run_save.gd`), VS-035 fit-to-screen text guard (S), VS-031 (spire/beams) before VS-037 (flanking Hive), VS-032 touch/UX, VS-036 raids you can fight (M, after VS-034).
4. Check INBOX for Daniel's replies. Next review round due after ~6 builds (about S0031).

## Last session
- Did: PLANNING (critic/QA/balance/scout reports in `studio/reviews/S0025-*.md`) -> VS-033..037 created; BUILD VS-034 (defs.gd BREACH_SIZE 6), QA PASS reproduced all numbers; VS-029 marked done.
- Check: PASS · Git: committed this session · Roles collapsed: none
- Note: two Agent calls hit a transient classifier error and were retried once, then succeeded.

## In-flight / uncommitted work
None from this session after commit. Unrelated uncommitted, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/` (Daniel's). `defs.gd` also shows a harmless file-mode change (644->755; use core.fileMode=false).

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA.
- Latest metrics (S0025 post-retune): passive40 HQ-lost median 28.3 (IQR 27.2-32.7), 1/9 survive; econ30 nw20 113.6k, HQ 9/9, first raid 3.3, Hive@20 51; perturb nw20 122.8k, HQ 9/9.

## Backlog snapshot
todo 7 · in-progress 0 · done 26 · blocked 1 · split 3 · Top ready: VS-030, VS-033, VS-035

## Watch out for
- Passive tail is close to the edge: seed 186 loses HQ at 35.9; seed 169 survives passive to 40 min. Perturbed econ nw30 IQR wide (83.6k-178k); watch for VS-036.
- Restored runs are NOT bit-identical. Saves skipped on foot / while dead. RunSave.write is non-atomic until VS-033. Autoplay/shots use `user://run_autoplay.save`.
- RaidTracker raid dict keys hard-coded in SaveGame._valid; bump VERSION if fields change.
- nw20 gate is chaos-fragile to RNG-order changes. Stale `.tools/balance_gate/*` summaries mislead; re-run.
- Background jobs do not survive past one device_bash call; use foreground `timeout 175`, balance runs sequential.
- Git writes may leave stale .lock files; mv them aside.

## Open questions for Daniel
- Fortified HQ nearly raid-free after minute 20: want the Breach nastier?
- HUD income gross vs net? Target session length? over.png Net worth 45,000 vs 30,000 credits: confirm formula.
- A real-browser pass is still needed for IndexedDB persistence of the run save and audio unlock.

## Answers to Daniel
- VS-029 question resolved: the retune landed (passive median 28.3 min), so no decision needed.

## Session history (newest first, keep 10)
- S0025 2026-10-27 PLANNING+BUILD — review round -> VS-033..037; VS-034 Breach retune done (QA PASS), VS-029 closed
- S0024 2026-10-27 BUILD — VS-028 save robustness + new-game confirm done (QA PASS)
- S0023 2026-10-27 BUILD — VS-027 autosave + Continue done (QA PASS)
- S0022 2026-10-27 BUILD — VS-026 save data layer done (QA PASS)
- S0021 2026-10-27 BUILD — VS-029 QA: FAIL on passive median 36.0 (gate 35) -> blocked pending decision
- S0020 2026-10-27 BUILD — VS-029 Breach implemented, QA pending
- S0019 2026-10-27 PLANNING+BUILD — review round (critic 6.1) -> VS-029..032; VS-025 raid reports done (QA PASS)
- S0018 2026-10-27 BUILD — VS-009 split into VS-026..028; VS-023 raid deterrent range done (QA PASS)
- S0016 2026-10-27 BUILD — VS-007 wing commands done (QA FAIL touch overlap → fix → PASS)
- S0017 2026-10-27 SKIPPED — lock held by S0016
