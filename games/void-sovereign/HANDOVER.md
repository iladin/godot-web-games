# Void Sovereign — Handover
_Last updated: S0034 · 2026-10-28 02:25 UTC · mode: BUILD_

## TL;DR
S0034 shipped VS-036 as bounty-only: intercepts outside the HQ sector pay 40 cr per raider (ledger "Raid intercepts"). The raid-to-Union redirect is implemented and selftested but disabled (`Defs.RAID_REDIRECT_ENABLED := false`) because it halved perturb=1 nw30 in QA. Build green; 6 ready todos.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0035. `export GODOT=$(bash scripts/studio/ensure_godot.sh | tail -1)`.
2. BUILD `backlog.py next` -> VS-037 (M, on-foot pressure). Smaller first if budget is tight: S tasks VS-040 (income empty state / net-gross), VS-043 (raid panel fit at 900/touch), VS-041 (surface autosave notice).
3. Later: VS-044 (balance harness platform policy, then re-enable redirect), VS-042 (real-browser smoke, M; before next Hive production change).
4. builds_since_review = 4; planning round due after 6.
5. Carry-over: touch@900 hint line "Need credits? Dock at the Union.Trade Hub" stray dot (find the string in hud/overlay); harness mode with pilot present for First Sortie; `--perturb=1` passive gate (HQ lost 31.9).
6. Watch perturb=1 seed 101 nw30 tail (23k) and union_ships_20 at perturb=1 in the next gate.

## Last session
- Did: BUILD VS-036 (defs.gd RAID_INTERCEPT_BOUNTY / RAID_REDIRECT_ENABLED, ledger.gd, raid_tracker.gd, director.gd nearest_union_station + gated redirect, selftest, DESIGN.md). QA round 1 FAIL (redirect worsened perturbed gates), fix round, QA round 2 PASS (bounty within noise: unperturbed nw30 167.9k vs 167.5k HEAD). Task acceptance bullet on redirect moved to VS-044.
- Check: PASS · Git: committed this session · Roles collapsed: none

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`. Scratch in `.tools/` (qa34_base, qa34b_*, balance_gate/s34_*; gitignored).

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: econ 9 seeds unperturbed nw30 median 167.9k, union ships @20 11, hive ships @20 52. Perturb=1 130k, perturb=2 135k.

## Backlog snapshot
todo 6 · in-progress 0 · done 34 · blocked 1 · split 3 · Top ready: VS-037, VS-040, VS-041

## Watch out for
- Redirect is off by default; Director reads the const into `redirect_enabled` (selftest toggles it). Redirected raids pay no bounty; a redirected raid destroying its target reads "redirected to X: SUCCEEDED".
- Bounty is judged by the lead raider's last sector (kill during a gate hop attributes to the sector it left).
- Title FLIGHT line wraps leaving an orphan line (cosmetic). Raid panel pushes BUY/BUILD to bottom edge with a raid active (VS-043).
- "Succeeded" outcome is decided at raid end. Defend with empty selection selects all armed ships incl. auto-trade/mine.
- Balance gates still hide the pilot; idle touch players take scout damage from t~12.
- Do NOT `pkill -f godot`; use `pkill -x godot`. Foreground `timeout 175`, balance sequential.

## Open questions for Daniel
- Desktop text got slightly longer (earn hint at 0 income, HQ dock second sentence): keep, or touch-only?
- Fortified HQ nearly raid-free after minute 20: want the Breach nastier? (VS-044 relates: redirect would add Union pressure.)
- HUD income gross vs net? Target session length? over.png Net worth 45,000 vs 30,000: confirm formula.
- A real-browser pass is still needed for IndexedDB persistence / .bak rename and audio unlock (VS-042).
- Is a scout fight 8 s after takeoff too aggressive for first-time touch players?

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0034 2026-10-28 BUILD — VS-036 intercept bounty done (QA PASS round 2); redirect disabled behind flag -> VS-044
- S0033 2026-10-28 BUILD — VS-035 text fit guard + map/title labels + cr/min gate done (QA PASS)
- S0032 2026-10-27 BUILD — VS-039 raid tracks + outcome history + Defend button done (QA PASS)
- S0031 2026-10-27 PLANNING+BUILD — review round -> VS-038..042; VS-038 hot opening done (QA PASS round 2)
- S0030 2026-10-27 BUILD — VS-033 atomic run save, QA PASS -> done
- S0029 2026-10-27 BUILD — VS-032 touch/UX bundle, QA PASS -> done
- S0028 2026-10-27 BUILD — VS-031 spire + beams, QA PASS -> done
- S0027 2026-10-27 BUILD — VS-030 selftest fix, QA PASS -> done
- S0026 2026-10-27 BUILD — VS-030 First Sortie implemented, QA FAIL on dead selftest assertion -> blocked (code kept, check PASS)
- S0025 2026-10-27 PLANNING+BUILD — review round -> VS-033..037; VS-034 Breach retune done (QA PASS), VS-029 closed
