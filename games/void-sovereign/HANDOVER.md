# Void Sovereign — Handover
_Last updated: S0032 · 2026-10-27 23:40 UTC · mode: BUILD_

## TL;DR
S0032 shipped VS-039 (raid tracks on the galaxy inset with sector name + ETA, one-outcome history in the map panel, Defend patrol button); QA PASS, sim bit-identical to HEAD. Build green; 7 ready todos.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0033. Export `GODOT=$(bash scripts/studio/ensure_godot.sh | tail -1)`.
2. BUILD `backlog.py next` -> VS-035 (text fit guard, S) with VS-040 (income empty state / net-gross, S); VS-035 owns hiding cr/min for the first 15 s.
3. Then VS-043 (raid panel fit at 900-wide/touch, S, new from QA), VS-041 (surface autosave notice, S), VS-036 (now only bounty + redirect), VS-037, VS-042 (real-browser smoke, M; before next Hive production change).
4. builds_since_review = 2; planning round due after 6.
5. Consider a harness mode with the pilot present so balance gates include the First Sortie; run `--perturb=1` on the passive gate (HQ lost 31.9).

## Last session
- Did: BUILD VS-039 (raid_tracker.gd history/recent/label_for/target_id; map_view.gd inset labels + panel block + Defend button; save_game history; selftest + autoplay `_exercise_raid_ui`; `--shot=raid_map`). QA PASS round 1. Created VS-043 from QA P3s; trimmed VS-036 note.
- Check: PASS · Git: committed this session · Roles collapsed: none

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`. QA left scratch `.tools/qa_base` (gitignored, harmless).

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics (QA, HEAD, 9 seeds economic): HQ 9/9, nw10 93k, nw20 120.8k, nw30 167.5k, hive ships @20 median 53 (q3 61). Passive gate unchanged from S0031 (HQ lost 31.9). S0031 metrics.csv line for econ is slightly stale (nw20 104k).

## Backlog snapshot
todo 7 · in-progress 0 · done 32 · blocked 1 · split 3 · Top ready: VS-035, VS-036, VS-037

## Watch out for
- Raid panel pushes BUY/BUILD to the bottom edge with a raid active (VS-043). Inset label overlaps "Cinder Belt".
- "Succeeded" outcome is decided at raid end, not when the target dies.
- Defend with empty selection selects all armed ships incl. auto-trade/mine.
- Balance gates still hide the pilot (no First Sortie); idle touch players take scout damage from t~12.
- Do NOT `pkill -f godot`; use `pkill -x godot`. Foreground `timeout 175`, balance sequential.

## Open questions for Daniel
- Desktop text got slightly longer (earn hint at 0 income, HQ dock second sentence): keep, or touch-only?
- Fortified HQ nearly raid-free after minute 20: want the Breach nastier?
- HUD income gross vs net? Target session length? over.png Net worth 45,000 vs 30,000: confirm formula.
- A real-browser pass is still needed for IndexedDB persistence / .bak rename and audio unlock (VS-042).
- Is a scout fight 8 s after takeoff too aggressive for first-time touch players?

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0032 2026-10-27 BUILD — VS-039 raid tracks + outcome history + Defend button done (QA PASS)
- S0031 2026-10-27 PLANNING+BUILD — review round -> VS-038..042; VS-038 hot opening done (QA PASS round 2)
- S0030 2026-10-27 BUILD — VS-033 atomic run save, QA PASS -> done
- S0029 2026-10-27 BUILD — VS-032 touch/UX bundle, QA PASS -> done
- S0028 2026-10-27 BUILD — VS-031 spire + beams, QA PASS -> done
- S0027 2026-10-27 BUILD — VS-030 selftest fix, QA PASS -> done
- S0026 2026-10-27 BUILD — VS-030 First Sortie implemented, QA FAIL on dead selftest assertion -> blocked (code kept, check PASS)
- S0025 2026-10-27 PLANNING+BUILD — review round -> VS-033..037; VS-034 Breach retune done (QA PASS), VS-029 closed
- S0024 2026-10-27 BUILD — VS-028 save robustness + new-game confirm done (QA PASS)
- S0023 2026-10-27 BUILD — VS-027 autosave + Continue done (QA PASS)
