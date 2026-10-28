# Void Sovereign — Handover
_Last updated: S0038 · 2026-10-28 07:05 UTC · mode: BUILD_

## TL;DR
S0038 shipped VS-045 (flank shots now hit 3.8x, squad 6-7; surface_long min_hp 84, min_foot 315). Build green; QA PASS. Backlog: 7 todo. builds_since_review = 1.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0039. `export GODOT=$(bash scripts/studio/ensure_godot.sh | tail -1)`.
2. BUILD S tasks: VS-046 (tips defer during fights), VS-047 (top-bar net income label), VS-041, VS-043. Then VS-048 (M, persistent HQ damage + paid repair; split if L). Note `backlog.py next` returns VS-048 first - prefer S tasks.
3. Later: VS-044 (harness platform policy, re-enable redirect), VS-042 (real-browser smoke; recommended early).
4. Balance watch: passive Hive ships at 20 min median 59 (guard 60); re-check after VS-048. Flank retune is chaotic - always re-run surface_long after touching FLANK_*.
5. QA suggestion: felt difficulty of flankers on desktop/touch (drone shot ~38 dmg at level 1).

## Last session
- Did: BUILD VS-045 (surface_view.gd shot mult; defs.gd FLANK_DAMAGE_MULT 3.8, FLANK_MIN/MAX 6/7). QA PASS round 1.
- Check: PASS - Git: committed (see git log) - Roles collapsed: none

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`.

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0037 passive HQ lost 28.9 min; economic nw10 94k, nw20 121k, nw30 168k median (wide spread). Balance 9-seed economic call can exceed the device timeout: run seed offsets "0 3" separately.

## Backlog snapshot
todo 7 - in-progress 0 - done 37 - blocked 1 - split 3 - Top ready: VS-046, VS-047, VS-041

## Watch out for
- Flank squad is now 6-7 units at 3.8x (FLANK_* in defs.gd, shots and bites); chaotic tuning - re-run surface_long after any change. Stale lock moved to .git/stale-head-lock-S0038 (safe for Daniel to delete).
- Redirect still off (RAID_REDIRECT_ENABLED=false). Do NOT `pkill -f godot`; use `pkill -x godot`. Foreground `timeout 175`, balance sequential.
- Autosave never fires on foot/dead (run_flow.gd:60); parking lot.
- Subagent runs are slow (~12-40 min each).
- `over` and `win` shots timed out for the Critic; not re-verified.

## Open questions for Daniel
- Critic recommends: keep longer desktop hint text, make HUD income net and labelled (VS-047), keep 5-6 flank squad but add hp cost (VS-045), make the Breach nastier. Veto via INBOX if you disagree.
- Persistent war damage (VS-048) is a bigger design change: OK?
- Over screen Score equals Net worth 45,000 in a synthetic shot: confirm formula.
- Real-browser pass still needed (VS-042).

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0038 2026-10-28 BUILD - VS-045 flank pressure costs on-foot hp done (QA PASS)
- S0037 2026-10-28 PLANNING — review round (critic 6.7, balance 8/9) -> VS-046..048
- S0036 2026-10-28 BUILD — VS-040 income empty state + net/gross done (QA PASS round 1)
- S0035 2026-10-28 BUILD — VS-037 flank squad + kill feedback done (QA PASS round 2); VS-045 added
- S0034 2026-10-28 BUILD — VS-036 intercept bounty done (QA PASS round 2); redirect disabled behind flag -> VS-044
- S0033 2026-10-28 BUILD — VS-035 text fit guard + map/title labels + cr/min gate done (QA PASS)
- S0032 2026-10-27 BUILD — VS-039 raid tracks + outcome history + Defend button done (QA PASS)
- S0031 2026-10-27 PLANNING+BUILD — review round -> VS-038..042; VS-038 hot opening done (QA PASS round 2)
- S0030 2026-10-27 BUILD — VS-033 atomic run save, QA PASS -> done
- S0029 2026-10-27 BUILD — VS-032 touch/UX bundle, QA PASS -> done
