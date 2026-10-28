# Void Sovereign — Handover
_Last updated: S0052 · 2026-10-28 21:55 UTC · mode: BUILD_

## TL;DR
S0052 shipped VS-056 (Hive nest cap growth 120->126, new Defs NEST_CAP_BASE/GROWTH; `--fleet-floor=N` balance-harness policy). Build green; 2 ready todos (VS-057, VS-058). VS-042 still blocked on network allowlist.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (next id S0053, `export GODOT=$PWD/.tools/godot`, check.sh with `timeout 175`). If `.git/*.lock` exists, `mv` it to `.git/stale-...`.
2. BUILD VS-057 (Fleet Reserve call-in, size M — split into S tasks first: defs tunables + spawn logic, then map/dock button UI). Baseline: passive 40 min, no floor HQ lost median 25.8; --fleet-floor=10 median 35.7 (1/9 survive) - see studio/reviews/S0052-dev-fleetfloor.md.
3. Then VS-058 (touch message lane, M; priority raid forecast > sortie > objective > trade hint > tips).
4. builds_since_review is 3; planning round due after 6. Optional P3s: raid block below fold on map at 1280x720, thousands separators overlay.gd:124, 900x720 touch label overlap.
5. Balance: run multi-seed passive-40 as single-seed calls in parallel (3 at once ~170 s); consider noting in balance_gate.sh header.

## Last session
- Did: VS-056 done (scripts/sim/defs.gd NEST_CAP_*, director.gd, scripts/tools/balance.gd --fleet-floor, selftest, DESIGN.md, metrics.csv, review S0052-dev-fleetfloor.md). QA PASS r1.
- Check: PASS · Git: committed this session (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none after the final commit.

## Build health
- check.sh: PASS · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics (S0052): economic HQ 9/9 (perturb 8/9, seed 101 lost 23.7 min), hive ships @20 median 56 econ / 60 passive (guard 60, zero margin; NEST_CAP_GROWTH 130 is next lever), economic nw30 median 168k (up from ~123k - economy may feel easy), passive HQ lost median 25.8 earliest 21.1.

## Backlog snapshot
todo 2 · in-progress 0 · done 51 · blocked 2 · split 3 · Top ready: VS-057, VS-058

## Watch out for
- Critic: bigger bot repair reserve is NOT the fix for late collapse (fleet loss is); don't retune chip again.
- Redirect stays off. Do NOT `pkill -f godot`. Balance runs sequential (or parallel single-seed), foreground `timeout 175`.
- Harness lives in scripts/tools/balance.gd (not scripts/sim).
- Economic nw30 jumped to 168k after the cap trim - watch for economy being too easy at next balance review.
- shots.sh title can time out (stale title.png).
- Git writes may leave tmp_obj/lock warnings; commits still succeed.

## Open questions for Daniel
- VS-042 needs a headless browser: allow cdn.playwright.dev in egress or point to an installed chromium.

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0052 2026-10-28 BUILD - VS-056 Hive cap trim + --fleet-floor done (QA PASS r1)
- S0051 2026-10-28 BUILD - VS-055 HQ hull readout done (QA PASS r1)
- S0050 2026-10-28 PLANNING+BUILD - review round -> VS-054..058; VS-054 raid forecast done (QA PASS r1)
- S0049 2026-10-28 BUILD - VS-044 redirect A/B done (stays off, QA PASS r1); VS-042 blocked (no export templates)
- S0048 2026-10-28 BUILD - VS-051 raid chip damage done (QA PASS r1)
- S0047 2026-10-28 BUILD - VS-053 signed credit deltas + full-hull status rows done (QA PASS r2)
- S0046 2026-10-28 BUILD - VS-052 bot repairs HQ in harness done (QA PASS r1)
- S0045 2026-10-28 BUILD - VS-050 wounded HQ penalty done (QA PASS r2)
- S0044 2026-10-28 PLANNING+BUILD - review round -> VS-049..053; VS-049 surface freeze fixed (QA PASS)
- S0043 2026-10-28 BUILD - VS-048 paid station repair + damage visibility done (QA PASS)
