# Void Sovereign — Handover
_Last updated: S0042 · 2026-10-28 11:30 UTC · mode: BUILD_

## TL;DR
S0042 shipped VS-043 (raid panel fit: Defend button 46 px under status, outcome line below BUILD, inset raid label a fixed strip; QA PASS round 1). Build green. Backlog: 3 todo. builds_since_review = 5 (PLANNING is forced after the next BUILD at 6).

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0043. `export GODOT=$(bash scripts/studio/ensure_godot.sh | tail -1)`.
2. BUILD VS-048 (M, persistent HQ damage + paid repair; split if L; Daniel has not yet OK'd the design change - see open questions; if INBOX has no veto proceed). `backlog.py next` returns it.
3. Then VS-042 (real-browser smoke, recommended early) and VS-044 (harness platform policy, re-enable redirect).
4. After that build, builds_since_review hits 6 -> run PLANNING (Critic, QA sweep, Balance, Scout).
5. Optional small task: Defend button renders ~30 px physical at 900x720 due to content scale (QA P3); raid_map_touch shot is identical to raid_map (no separate touch layout). Consider a min-height or scale tweak.
6. Balance watch: passive Hive ships at 20 min median 59 (guard 60); re-check after VS-048.

## Last session
- Did: BUILD VS-043 (map_view.gd: Defend row + outcome label below BUILD + side separation 6->4 + 3-col order buttons, "Warships" label; test_driver raid_map_touch scenario + asserts; selftest _test_raid_panel_fit). QA PASS round 1.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`. Scratch `.tools/shots/vs900/` (gitignored) can be deleted.

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0037 passive HQ lost 28.9 min; economic nw10 94k, nw20 121k, nw30 168k median. Balance 9-seed economic call can exceed device timeout: run seed offsets "0 3" separately.

## Backlog snapshot
todo 3 - in-progress 0 - done 41 - blocked 1 - split 3 - Top ready: VS-048, VS-044, VS-042

## Watch out for
- Raid panel: only first raid gets a Defend button; Defend with empty selection still orders all armed ships incl. auto-traders (tooltip only). Outcome line ellipsised, full text in tooltip, below fold at 1280.
- Tips hide while any Hive ship within 1500 m; loosen ENGAGE_RANGE in tutorial_hints.gd if Critic complains.
- Flank squad tuning chaotic (FLANK_* in defs.gd); re-run surface_long after any change.
- Redirect still off (RAID_REDIRECT_ENABLED=false). Do NOT `pkill -f godot`; use `pkill -x godot`. Foreground `timeout 175`, balance sequential.
- Subagent runs are slow (2-40 min each). `over` and `win` shots timed out for the Critic earlier; not re-verified.

## Open questions for Daniel
- Persistent war damage (VS-048) is a bigger design change: OK? (Studio will proceed next session unless vetoed in INBOX.)
- Critic recommendations (VS-045/047 done; Breach nastier) - veto via INBOX if disagree.
- Over screen Score equals Net worth 45,000 in a synthetic shot: confirm formula.
- Real-browser pass still needed (VS-042).

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0042 2026-10-28 BUILD - VS-043 raid panel fit done (QA PASS)
- S0041 2026-10-28 BUILD - VS-041 surface landing checkpoint + save notice done (QA PASS)
- S0040 2026-10-28 BUILD - VS-047 top-bar net income label done (QA PASS)
- S0039 2026-10-28 BUILD - VS-046 tips defer during fights done (QA PASS)
- S0038 2026-10-28 BUILD - VS-045 flank pressure costs on-foot hp done (QA PASS)
- S0037 2026-10-28 PLANNING — review round (critic 6.7, balance 8/9) -> VS-046..048
- S0036 2026-10-28 BUILD — VS-040 income empty state + net/gross done (QA PASS round 1)
- S0035 2026-10-28 BUILD — VS-037 flank squad + kill feedback done (QA PASS round 2); VS-045 added
- S0034 2026-10-28 BUILD — VS-036 intercept bounty done (QA PASS round 2); redirect disabled behind flag -> VS-044
- S0033 2026-10-28 BUILD — VS-035 text fit guard + map/title labels + cr/min gate done (QA PASS)
