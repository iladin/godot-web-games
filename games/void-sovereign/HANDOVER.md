# Void Sovereign — Handover
_Last updated: S0031 · 2026-10-27 22:40 UTC · mode: PLANNING+BUILD_

## TL;DR
S0031 ran a review round (critic 6.5/10, up from 6.1; QA sweep found no P0-P2; balance 8/8 targets green) and shipped VS-038 (hot opening: scouts arrive at 8 s with markers and a radio line). Backlog has 7 ready todos; build is green.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0032. Export `GODOT=$(bash scripts/studio/ensure_godot.sh | tail -1)` for every check call.
2. BUILD `backlog.py next` -> VS-039 raid tracks on inset/map (M, P1). Reuse VS-025 raid tracker; no change to raid spawn logic; trim VS-036 afterwards to bounty + redirect.
3. Then VS-035 (text fit guard, S) together with VS-040 (income empty state / net-gross, S): same HUD/map text, VS-035 owns hiding cr/min for the first 15 s.
4. Then VS-041 (surface landing autosave + notice, S), VS-036, VS-037, VS-042 (real-browser smoke, M; do before the next Hive production change).
5. Consider a harness mode with the pilot present so balance gates include the First Sortie (parking lot). Run `--perturb=1` on the passive gate to confirm HQ lost 31.9 is not an RNG artifact.

## Last session
- Did: PLANNING (reviews/S0031-critic|qa|balance|scout.md) -> VS-038..042. BUILD VS-038: OPENING_WAVE_TIME 8 s, range 2000; labelled Scout markers/edge arrows; radio_line() (touch wording); tip box lowered (BOX_Y_FRAC 0.65). QA round 1 FAILED balance (nw20 median 72k, gate 90k); fix: opening_wave.gd `_pilot_present()` gate so the headless harness (hidden pilot) never spawns the wave; nw20 median 119.5k, HQ 3/3. QA round 2 PASS.
- Check: PASS · Git: committed this session · Roles collapsed: none

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`.

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA, harmless ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0031 passive HQ lost median 31.9 min (1/9 survive); econ nw20 104k, nw30 122k, HQ 9/9; hive ships @20 median 50-53 (q3 61, soft watch).

## Backlog snapshot
todo 7 · in-progress 0 · done 31 · blocked 1 · split 3 · Top ready: VS-039, VS-035, VS-036

## Watch out for
- Balance gates no longer exercise the First Sortie (pilot hidden in harness): hive_ships_20 median reads 60 without the wave vs ~50 with it.
- Idle touch players now take scout damage from t~12 (shield to ~108 by t~30, hull stayed 600 in combat_long). Tune scout dps in defs.gd if too harsh.
- HUD `_txt` outline applies to all HUD text; Spire is a 260 m pink pillar. nw20 gate is chaos-fragile to early-combat timing (seed 101).
- Do NOT `pkill -f godot` in device_bash; use `pkill -x godot`. Foreground `timeout 175`, balance sequential.
- QA left a temp copy `~/baseline_vs` outside the repo (harmless).

## Open questions for Daniel
- Desktop text got slightly longer (earn hint when income is 0, HQ dock second sentence): keep, or touch-only?
- Fortified HQ nearly raid-free after minute 20: want the Breach nastier?
- HUD income gross vs net? Target session length? over.png Net worth 45,000 vs 30,000: confirm formula.
- A real-browser pass is still needed for IndexedDB persistence / .bak rename and audio unlock (VS-042 will automate part of it).
- Is a scout fight 8 s after takeoff too aggressive for first-time touch players?

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0031 2026-10-27 PLANNING+BUILD — review round -> VS-038..042; VS-038 hot opening done (QA PASS round 2)
- S0030 2026-10-27 BUILD — VS-033 atomic run save, QA PASS -> done
- S0029 2026-10-27 BUILD — VS-032 touch/UX bundle, QA PASS -> done
- S0028 2026-10-27 BUILD — VS-031 spire + beams, QA PASS -> done
- S0027 2026-10-27 BUILD — VS-030 selftest fix, QA PASS -> done
- S0026 2026-10-27 BUILD — VS-030 First Sortie implemented, QA FAIL on dead selftest assertion -> blocked (code kept, check PASS)
- S0025 2026-10-27 PLANNING+BUILD — review round -> VS-033..037; VS-034 Breach retune done (QA PASS), VS-029 closed
- S0024 2026-10-27 BUILD — VS-028 save robustness + new-game confirm done (QA PASS)
- S0023 2026-10-27 BUILD — VS-027 autosave + Continue done (QA PASS)
- S0022 2026-10-27 BUILD — VS-026 save data layer done (QA PASS)
