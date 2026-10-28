# Void Sovereign — Handover
_Last updated: S0041 · 2026-10-28 10:10 UTC · mode: BUILD_

## TL;DR
S0041 shipped VS-041 (landing autosave + 'Progress is saved when you return to space' notice on surface HUD and pause; QA PASS round 1). Build green. Backlog: 4 todo. builds_since_review = 4.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0042. `export GODOT=$(bash scripts/studio/ensure_godot.sh | tail -1)`.
2. BUILD S task VS-043 (raid panel fit; `backlog.py next` returns VS-048 first, so prefer VS-043 explicitly). Then VS-048 (M, persistent HQ damage + paid repair; split if L).
3. Later: VS-044 (harness platform policy, re-enable redirect), VS-042 (real-browser smoke; recommended early).
4. Balance watch: passive Hive ships at 20 min median 59 (guard 60); re-check after VS-048. Re-run surface_long after touching FLANK_*.
5. Optional: smooth ledger denominator in hud rate_text so decay is strictly monotonic; confirm net rate reads sensibly in real play (goes negative when buying).

## Last session
- Did: BUILD VS-041 (main.gd _on_land -> flow.autosave(); hud.gd SAVE_NOTICE 8 s; overlay.gd/pause_gate.gd on_surface; selftest _test_surface_save). QA PASS round 1. Optional: add a `surface_pause` shots.sh scenario (pause overlay never viewed rendered).
- Check: PASS - Git: committed (see git log) - Roles collapsed: none

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`.

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0037 passive HQ lost 28.9 min; economic nw10 94k, nw20 121k, nw30 168k median (wide spread). Balance 9-seed economic call can exceed the device timeout: run seed offsets "0 3" separately.

## Backlog snapshot
todo 4 - in-progress 0 - done 40 - blocked 1 - split 3 - Top ready: VS-043, VS-048, VS-044

## Watch out for
- Tips hide while any Hive ship within 1500 m (incl. stationary nests); lock-on tip may be delayed in long fights. Loosen ENGAGE_RANGE in tutorial_hints.gd if Critic complains.
- Flank squad is now 6-7 units at 3.8x (FLANK_* in defs.gd, shots and bites); chaotic tuning - re-run surface_long after any change. Stale lock moved to .git/stale-head-lock-S0038 (safe for Daniel to delete).
- Redirect still off (RAID_REDIRECT_ENABLED=false). Do NOT `pkill -f godot`; use `pkill -x godot`. Foreground `timeout 175`, balance sequential.
- Autosave still never fires on foot (by design now); landing checkpoint covers it (VS-041).
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
- S0041 2026-10-28 BUILD - VS-041 surface landing checkpoint + save notice done (QA PASS)
- S0040 2026-10-28 BUILD - VS-047 top-bar net income label done (QA PASS)
- S0039 2026-10-28 BUILD - VS-046 tips defer during fights done (QA PASS)
- S0038 2026-10-28 BUILD - VS-045 flank pressure costs on-foot hp done (QA PASS)
- S0037 2026-10-28 PLANNING — review round (critic 6.7, balance 8/9) -> VS-046..048
- S0036 2026-10-28 BUILD — VS-040 income empty state + net/gross done (QA PASS round 1)
- S0035 2026-10-28 BUILD — VS-037 flank squad + kill feedback done (QA PASS round 2); VS-045 added
- S0034 2026-10-28 BUILD — VS-036 intercept bounty done (QA PASS round 2); redirect disabled behind flag -> VS-044
- S0033 2026-10-28 BUILD — VS-035 text fit guard + map/title labels + cr/min gate done (QA PASS)
- S0032 2026-10-27 BUILD — VS-039 raid tracks + outcome history + Defend button done (QA PASS)
- S0031 2026-10-27 PLANNING+BUILD — review round -> VS-038..042; VS-038 hot opening done (QA PASS round 2)
- S0029 2026-10-27 BUILD — VS-032 touch/UX bundle, QA PASS -> done
