# Void Sovereign — Handover
_Last updated: S0051 · 2026-10-28 20:10 UTC · mode: BUILD_

## TL;DR
S0051 shipped VS-055 (HQ bar shows hull % in-bar, colour steps at 80%/50%, 'WOUNDED -x% income' tag, new shots hq_wounded_hud and dock_wounded). Build green; 3 ready todos (VS-056, 057, 058). VS-042 still blocked on network allowlist.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (next id S0052, `export GODOT=$PWD/.tools/godot`, check.sh with `timeout 175`). If `.git/*.lock` exists, `mv` it to `.git/stale-...`.
2. BUILD VS-056 (Hive cap trim ~5% in scripts/sim/defs.gd + `--fleet-floor` harness flag in balance.gd; 9-seed runs, sequential, foreground `timeout 175`). Must precede VS-057.
3. Then VS-057 (Fleet Reserve call-in, M — split if needed), then VS-058 (touch message lane, M; raid forecast top priority).
4. Optional: combined wounded + raid_warn shot; touch re-shot of HQ bar; P3s from S0050 (map raid block below fold at 1280x720, Score/Best thousands separators overlay.gd:124, 900x720 touch label overlap).
5. builds_since_review is 2; planning round due after 6.

## Last session
- Did: VS-055 done (defs.gd HQ_HULL_OK_FRAC, hud.gd hq_color/wound_tag, balance.gd, test_driver.gd shots, selftest asserts). QA PASS r1.
- Check: PASS · Git: committed this session (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit (stale lock file .git/stale-head-lock-S0050 is untracked inside .git, harmless).

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics (S0050): economic HQ 8/9, nw10 94k, nw20 105k, nw30 123k (Q1 48k); passive HQ lost median 27.3 min; Hive ships @20 = 61 (guard 60 -> VS-056).

## Backlog snapshot
todo 3 · in-progress 0 · done 50 · blocked 2 · split 3 · Top ready: VS-056, VS-057, VS-058

## Watch out for
- Critic: bigger bot repair reserve is NOT the fix for late collapse (fleet loss is); don't retune chip again.
- Redirect stays off. Do NOT `pkill -f godot`. Balance runs sequential, foreground `timeout 175`.
- shots.sh title can time out (stale title.png).
- Git writes leave tmp_obj/lock warnings (no delete permission); commits still succeed.

## Open questions for Daniel
- VS-042 needs a headless browser: allow cdn.playwright.dev in egress or point to an installed chromium.

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0051 2026-10-28 BUILD - VS-055 HQ hull readout done (QA PASS r1)
- S0050 2026-10-28 PLANNING+BUILD - review round -> VS-054..058; VS-054 raid forecast done (QA PASS r1)
- S0049 2026-10-28 BUILD - VS-044 redirect A/B done (stays off, QA PASS r1); VS-042 blocked (no export templates)
- S0048 2026-10-28 BUILD - VS-051 raid chip damage done (QA PASS r1)
- S0047 2026-10-28 BUILD - VS-053 signed credit deltas + full-hull status rows done (QA PASS r2)
- S0046 2026-10-28 BUILD - VS-052 bot repairs HQ in harness done (QA PASS r1)
- S0045 2026-10-28 BUILD - VS-050 wounded HQ penalty done (QA PASS r2)
- S0044 2026-10-28 PLANNING+BUILD - review round -> VS-049..053; VS-049 surface freeze fixed (QA PASS)
- S0043 2026-10-28 BUILD - VS-048 paid station repair + damage visibility done (QA PASS)
- S0042 2026-10-28 BUILD - VS-043 raid panel fit done (QA PASS)
