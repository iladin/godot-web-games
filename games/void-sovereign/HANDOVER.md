# Void Sovereign — Handover
_Last updated: S0037 · 2026-10-28 06:10 UTC · mode: PLANNING_

## TL;DR
S0037 ran the review round: Critic avg 6.7/10 (up from 6.5), QA sweep found no P0-P2, balance gate 8/9 met with no misses. Three new tasks added (VS-046..048); build green; builds_since_review reset to 0. No BUILD this session.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0038. `export GODOT=$(bash scripts/studio/ensure_godot.sh | tail -1)`.
2. BUILD VS-045 (S, flank costs on-foot hp; defs.gd FLANK_*; `$GODOT --headless --fixed-fps 60 --quit-after 9000 --path games/void-sovereign -- --shot=surface_long`). Do it before VS-048 so tuning does not conflict.
3. Then S tasks: VS-046 (tips defer during fights), VS-047 (top-bar net income label), VS-041, VS-043. Split VS-048 (M, persistent HQ damage + paid repair) if the Developer finds it L.
4. Later: VS-044 (harness platform policy, re-enable redirect), VS-042 (real-browser smoke; Critic and Scout recommend it early).
5. Balance watch: passive Hive ships at 20 min median 59 (guard 60); if it creeps, cut Hive cap/wave constant ~5% in scripts/sim/defs.gd. Re-check after VS-048.

## Last session
- Did: PLANNING. Reviews in studio/reviews/S0037-{critic,qa,balance,scout}.md. Critic top problems: danger-free active play, tip 1 over the opening fight, top-bar income unlabelled, prompt clutter, real-browser unverified. Balance: passive HQ loss median 28.9 min, economic nw20 121k, HQ survives 9/9.
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`.

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics: S0037 passive HQ lost 28.9 min; economic nw10 94k, nw20 121k, nw30 168k median (wide spread). Balance 9-seed economic call can exceed the device timeout: run seed offsets "0 3" separately.

## Backlog snapshot
todo 8 · in-progress 0 · done 36 · blocked 1 · split 3 · Top ready: VS-048 (by selector; do VS-045 first), VS-045, VS-046

## Watch out for
- Flank squad is 5-6 units at 1.8x (FLANK_* in defs.gd); idle bot now takes no hull damage in surface_long, hence VS-045.
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
- S0037 2026-10-28 PLANNING — review round (critic 6.7, balance 8/9) -> VS-046..048
- S0036 2026-10-28 BUILD — VS-040 income empty state + net/gross done (QA PASS round 1)
- S0035 2026-10-28 BUILD — VS-037 flank squad + kill feedback done (QA PASS round 2); VS-045 added
- S0034 2026-10-28 BUILD — VS-036 intercept bounty done (QA PASS round 2); redirect disabled behind flag -> VS-044
- S0033 2026-10-28 BUILD — VS-035 text fit guard + map/title labels + cr/min gate done (QA PASS)
- S0032 2026-10-27 BUILD — VS-039 raid tracks + outcome history + Defend button done (QA PASS)
- S0031 2026-10-27 PLANNING+BUILD — review round -> VS-038..042; VS-038 hot opening done (QA PASS round 2)
- S0030 2026-10-27 BUILD — VS-033 atomic run save, QA PASS -> done
- S0029 2026-10-27 BUILD — VS-032 touch/UX bundle, QA PASS -> done
- S0028 2026-10-27 BUILD — VS-031 spire + beams, QA PASS -> done
