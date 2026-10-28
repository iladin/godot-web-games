# Void Sovereign — Handover
_Last updated: S0044 · 2026-10-28 13:50 UTC · mode: PLANNING+BUILD_

## TL;DR
S0044 ran a review round (critic avg 6.7 unchanged; QA sweep; balance 8/9 targets, identical to S0037) and shipped VS-049: a real freeze bug at ~900-940 px window widths (float32 infinite loop in Hud.layout_markers) is fixed, QA PASS, check green. Key critic finding: VS-048 repair price is fine but damage never occurs organically and has no consequence, so VS-050/051/052 were queued.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`, next id S0045, `export GODOT=$PWD/.tools/godot`, check.sh with `timeout 175`).
2. BUILD VS-052 (size S: economic bot repairs HQ in harness; needed so the gate covers repair sink) — or VS-053 (S: signed credit deltas + status-style 100% hull rows). Then VS-050 (M, low hull penalty, cap -30%) and VS-051 (M, raid chip damage); tune 050/051 together and run the 9-seed gate sequentially.
3. VS-042 (real-browser smoke: save round trip, frame time, audio unlock, focus pause) and VS-044 (harness platform policy, re-enable raid redirect) remain ready.
4. Optional P3: surface HUD '2x PYLON' label overlaps pylon ring at 1280x720; Defend button ~30 px at 900x720.
5. Balance watch: passive Hive ships at 20 min q3 61 (guard 60); surface L1 pylons down at ~55 s (was 51); if needed lower Hive passive spawn ~5% in defs.gd.

## Last session
- Did: PLANNING (reviews/S0044-{critic,qa,balance,scout}.md; metrics rows added) -> tasks VS-049..053; BUILD VS-049 (hud.gd MARKER_EPS + bounded loop, selftest dense-marker case, shots.sh SHOT_TIMEOUT default 60).
- Check: PASS · Git: committed (see git log) · Roles collapsed: none

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit. surface_long core dead 67.1 s.
- Latest metrics: S0044 economic/passive rows (HQ 9/9 economic, passive lost 28.9 min median).

## Backlog snapshot
todo 6 - in-progress 0 - done 43 - blocked 1 - split 3 - Top ready: VS-042, VS-044, VS-050, VS-051, VS-052, VS-053

## Watch out for
- Bots never repair; station hull never regenerates. Wounds never occur in normal play yet (VS-051).
- Do NOT `pkill -f godot`; use `pkill -x godot`. Foreground `timeout 175`; backgrounded processes die when a device_bash call returns. Balance sequential.
- Redirect still off (RAID_REDIRECT_ENABLED=false). Tips hide near Hive ships (ENGAGE_RANGE). Subagent runs 2-30 min each.
- QA noted: marker push-down loop bounded at size+1 passes; last label can overlap in extreme stacks.

## Open questions for Daniel
- Critic says keep 0.4 cr/pt (12k HQ rebuild) but add consequences (VS-050) and organic damage (VS-051): OK to proceed?
- Over-screen Score equals Net worth in a synthetic shot: confirm formula.
- Real-browser pass still needed (VS-042).

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0044 2026-10-28 PLANNING+BUILD - review round -> VS-049..053; VS-049 surface freeze fixed (QA PASS)
- S0043 2026-10-28 BUILD - VS-048 paid station repair + damage visibility done (QA PASS)
- S0042 2026-10-28 BUILD - VS-043 raid panel fit done (QA PASS)
- S0041 2026-10-28 BUILD - VS-041 surface landing checkpoint + save notice done (QA PASS)
- S0040 2026-10-28 BUILD - VS-047 top-bar net income label done (QA PASS)
- S0039 2026-10-28 BUILD - VS-046 tips defer during fights done (QA PASS)
- S0038 2026-10-28 BUILD - VS-045 flank pressure costs on-foot hp done (QA PASS)
- S0037 2026-10-28 PLANNING — review round (critic 6.7, balance 8/9) -> VS-046..048
- S0036 2026-10-28 BUILD — VS-040 income empty state + net/gross done (QA PASS round 1)
- S0035 2026-10-28 BUILD — VS-037 flank squad + kill feedback done (QA PASS round 2); VS-045 added
