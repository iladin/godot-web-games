# Void Sovereign — Handover
_Last updated: S0006 · 2026-10-26 12:10 UTC · mode: BUILD_

## TL;DR
Void Sovereign is playable end to end with sound and now a guided start: six contextual tips (steer → throttle → target → dock → map → land on Ember), skippable with H or a tap. S0006 shipped VS-004 and VS-012 (touch button row, N-while-paused, sfx guard is a real assert). `check.sh` passes. A PLANNING round is now due (builds_since_review = 6), and the late-game slide (VS-011) is still the top build task.

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md`. Request delete permission for the repo root (granted S0001/3/5/6 → git works). Use `git -c core.fileMode=false …` for status/add. In the commit helper, pass the identity as `git -c "user.name=Claude Studio" -c user.email=studio@localhost` (a shell variable holding the command broke on the space in S0006). Check `date -u` after each subagent and refresh `lock.since` if the session runs long.
2. **Run PLANNING first** — the health rule fires (`builds_since_review` = 6). Critic + QA sweep + Balance Analyst in parallel, then Feature Scout; triage to 4–8 tasks. Ask the Critic to play through the new tips (`shots.sh void-sovereign hints hints_touch touch`) and judge the first 10 minutes. Balance Analyst: 3-seed runs only (6 seeds ≈174 s vs the 180 s cap) unless VS-011's seed-offset option exists.
3. **Then BUILD `VS-011`** (P1 M, economic player keeps growing from minute 20 to 30) if budget remains. First acceptance item: seed-offset option for `scripts/studio/balance.sh` / `scripts/tools/balance.gd`, so 6 seeds can be split across two device_bash calls.
4. Small P2 follow-ups ready: `VS-014` (taps on SND/MAP/TRVL while paused also unpause via emulated mouse; first desktop click on the pause screen is eaten by mouse capture), `VS-013` (tip box overlaps the touch steer zone so a steer drag skips all tips; document H).

## Last session
- Did:
  - S0004's late resume: S0004 took the lock at 03:32Z, its device calls stalled ~8 h, S0005 took over the stale lock. The same run woke at 11:49Z after S0005 had released the lock, and ran as S0006.
  - **VS-004 done** (commit 77a703a). New `scripts/ui/tutorial_hints.gd` (class TutorialHints): `update(ctx)` latches steps, `current()` returns the first unfinished, `hint_text(step, touch, planet)`. Shown only in flight while playing. Skip: H (`skip_hints` in controls.gd) or tap the tip box; skip persists across restarts in a page load. Selftest `_test_hints`, autoplay `_exercise_hints`, shot scenarios `hints` / `hints_touch`. QA PASS with real-input probes and an assert mutation.
  - **VS-012 done.** touch_controls.gd `TOP_ROW_Y` 190 (SND/TRVL/MAP below up to ~5 messages; surface SND moved beside the flight one). New `Controls.resumes_from_pause(event)`: N/mute and key releases never unpause (P key-up no longer unpauses either). test_driver's pre-input sfx guard is now an `assert`, so check.sh FAILs (mutation-verified by Dev and QA). QA PASS.
  - New tasks VS-013, VS-014; 8 QA/dev P3 items in the parking lot.
- Check: PASS · Git: committed `studio(S0006)` VS-004 and VS-012 · Roles collapsed: none

## In-flight / uncommitted work
none. Left uncommitted on purpose: Windows file-mode noise and Daniel's edits outside this game. QA left a throwaway `.tools/shots/void-sovereign/touch_900.png` (gitignored tools dir) and a probe at `$HOME/probe/` outside the repo.

## Build health
- check.sh: PASS (~15–17 s). Selftest: SELFTEST OK, plus "hints: step order, latch and skip OK"; autoplay "hints: done map, dock, land, skipped true" and the sfx line.
- Known noise (not bugs): "ObjectDB instances leaked" / "N resources still in use at exit"; ALSA errors under xvfb.
- Latest metrics: no balance change since S0003 (economic 30 min, 6 seeds: HQ 5/6, nw20 139k; net worth falls from minute 20 to 30 in 4/6 seeds).

## Backlog snapshot
todo 8 · in-progress 0 · done 6 · blocked 0 · split 0 · ready 7 · Top ready: VS-011 grow from minute 20 to 30, VS-013 tip follow-ups, VS-014 pause-screen input

## Watch out for
- **Tutorial tips**: the box rect depends on viewport size; headless runs without `--resolution` place it off-screen (y≈742), so touch probes must use xvfb with `--resolution 1280x720`. TutorialHints is added after TouchControls, so its `_input` sees touches first (that is why it steals steer drags — VS-013). The "land" step latches on any planet.
- `project.godot` has `emulate_mouse_from_touch=true`: every tap also produces an InputEventMouseButton that reaches `_unhandled_input` even when TouchControls handled the touch (VS-014).
- **Audio**: headless Godot uses a dummy driver; loudness untested by ear. Every sound must go through `Sfx.play()`.
- `check.sh` fails on "SCRIPT ERROR" (failed asserts), not on `push_error`. Use `assert` for guards. A failed assert in selftest still prints "SELFTEST OK" — read the whole output.
- **Patrol in the HQ sector means "guard HQ"** (`ship_ai.gd` `_home_guard`); dock repair is free near HQ; below 2000 credits automated player ships don't buy (VS-010).
- Use ≥ 6 seeds for survival gates. The world is one data sim in `scripts/sim/`. Keep `--autoplay` / `--shot=` working.
- main.gd is ~329 lines (over the ~300 guideline); split it before adding more (parking lot).
- The default font has no arrow glyphs. Only one WorldEnvironment may exist at a time.
- Git needs delete permission (lock files). Never stage the `games/starfall`, `template/`, `.claude/`, `.github/` mode noise.

## Open questions for Daniel
- Please try the new tips and sounds in a browser build (H skips tips, N mutes). Should tips come back after a page reload, or be remembered in the save file?
- After VS-001 the economy may be too generous early (credits at 10 min are 10–27k). Is a faster early game OK?
- Keep committing to local `main`, or push to GitHub so sessions can open PRs?
- Target session length: the design assumes 30–40 minutes. Shorter?

## Answers to Daniel
- none (INBOX empty)

## Session history (newest first, keep 10)
- S0006 2026-10-26 BUILD — VS-004 tutorial tips + VS-012 touch row/pause-mute/sfx assert done (both QA PASS); VS-013, VS-014 added
- S0005 2026-10-26 BUILD — took over stale S0004 lock; VS-003 procedural SFX done (QA PASS); VS-012 added
- S0004 2026-10-26 SUPERSEDED — took lock 03:32Z, device calls stalled ~8 h; resumed later as S0006
- S0003 2026-10-26 BUILD — cleaned up hung S0002; VS-001 mid-game rebalance done (nw20 8k→139k, HQ 5/6); VS-011 added
- S0002 2026-10-26 ABORTED — hung during VS-001, cancelled by Daniel; diff salvaged, no handover
- S0001 2026-10-26 BUILD — baseline commit; VS-002 trader reserve + VS-008 AI-journey selftest done; VS-010 added
- S0000 2026-10-25 SETUP — game v1 + AI studio + seeded backlog
