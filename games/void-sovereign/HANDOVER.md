# Void Sovereign — Handover
_Last updated: S0005 · 2026-10-26 11:50 UTC · mode: BUILD_

## TL;DR
Void Sovereign is playable end to end, `check.sh` passes, and it now has sound. S0005 shipped VS-003: six procedural sound effects made in code, silent until the first input, with N / SND to mute. The sounds haven't been heard in a real browser yet. The open balance problem is still the slide from minute 20 to 30 (VS-011).

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md`.
   - Request delete permission for the repo root (granted in S0001/S0003/S0005, so git commits work).
   - Use `git -c core.fileMode=false …` for status/add; the Windows mount shows mode-change noise.
   - **Check the wall clock (`date -u`) after each subagent returns.** S0005 took ≈4h15m of wall time for one build, so the 4 h stale-lock rule is close to misfiring. Refresh `lock.since` in state.json if a session runs long.
2. **BUILD `VS-004`** (guided first 10 minutes, P1 S). It is what `backlog.py next` returns.
   - Hints live in the HUD/overlay (`scripts/ui/hud.gd`, `overlay.gd`).
   - Touch wording via `touch_controls.gd`.
   - Add a `--shot=` scenario in `scripts/test_driver.gd` for two hint states.
3. **Then `VS-011`** (P1 M: the economic player keeps growing from minute 20 to 30).
   - Its first acceptance item is a seed-offset option for `scripts/studio/balance.sh` / `scripts/tools/balance.gd`, so the 6-seed run can be split across two device_bash calls.
   - `balance.sh void-sovereign 30 6 economic` takes ~174 s against the 180 s cap. Use 3-seed runs (~70 s) for exploration, timeout_ms=180000, one Godot run per call, and never background processes.
4. **`VS-012`** (P2 S): SND button overlap, N while paused, and the autoplay sfx guard that check.sh doesn't catch.
5. A **PLANNING round** is due at builds_since_review ≥ 6 (now 4).

## Last session
- Did:
  - S0004 took the lock at 03:32Z and left no other trace: no LOG entry, no file changes. S0005 took over the stale lock.
  - **VS-003 done.** Developer and QA ran as independent subagents; QA PASS on all 4 criteria, with its own probes.
  - New `games/void-sovereign/scripts/audio/sfx.gd` (class Sfx):
    - Synthesises laser, rifle, hit, explosion, gate and click into AudioStreamWAV (22050 Hz, mono, 16-bit, ~5 ms at startup).
    - Pool of 10 players, `MIN_INTERVAL` 0.045 s, `MASTER_DB` / `VOLUME_DB` / `PITCH_JITTER` 0.08.
    - `play()` refuses until `unlock()`, which the first key, mouse button or touch press calls. N is the "mute" action.
  - Edits:
    - The views emit `sfx` signals (space_view.gd, surface_view.gd), and main.gd wires them.
    - SND touch button added in touch_controls.gd.
    - test_driver.gd gets `_exercise_audio()` and prints an `sfx:` stats line; selftest.gd gets `_test_sfx()`.
    - DESIGN.md has a new Audio section; overlay.gd and game.json list the controls.
  - Added VS-012, plus 3 items in the parking lot.
- Check: PASS · Git: committed `studio(S0005)` (see git log) · Roles collapsed: none

## In-flight / uncommitted work
none. Left uncommitted on purpose: Windows file-mode noise and Daniel's edits outside this game.

## Build health
- check.sh: PASS (~15 s).
- selftest: SELFTEST OK, no assertion lines; "sfx: 6 streams generated"; credits after 8 min 43684, the same as S0003. Sfx uses its own RNG, so the sim is unaffected.
- autoplay: "sfx: played 15, blocked before first input 63, muted false".
- Known noise (not bugs): "ObjectDB instances leaked at exit" / "resources still in use", which now includes AudioStreamPlaybackWAV entries; ALSA errors under xvfb.
- Latest metrics: no balance change this session. S0003 economic 30 min, 6 seeds: HQ 5/6, nw20 139k; net worth falls from minute 20 to 30 in 4/6 seeds.

## Backlog snapshot
todo 8 · in-progress 0 · done 4 · blocked 0 · split 0 · ready 7 · Top ready: VS-004 guided first 10 minutes, VS-011 grow from minute 20 to 30, VS-012 audio/touch follow-ups

## Watch out for
- **Audio**
  - Headless Godot uses a dummy audio driver, so loudness and harshness are untested by ear.
  - Every sound must go through `Sfx.play()` so the first-input gate holds.
  - touch_controls marks button taps as handled before Sfx `_input` sees them. This is fine today: the title tap unlocks, and SND calls `unlock()` itself.
- `check.sh` doesn't fail on `push_error` lines, only on "SCRIPT ERROR" (asserts). Use `assert` for guards (VS-012).
- **Patrol in the HQ sector means "guard HQ"** (`ship_ai.gd` `_home_guard`). The UI doesn't explain this.
- Dock repair is free for any automated Sovereign ship near the HQ.
- Below 2000 credits, automated player ships don't buy (VS-010).
- A failed `assert` in `selftest.gd` still prints "SELFTEST OK". Read the whole output.
- Use ≥ 6 seeds for survival gates. The world is one data sim in `scripts/sim/`. Keep `--autoplay` / `--shot=` working.
- main.gd is ~325 lines (over the ~300 guideline); split it before adding more.
- The default font has no arrow glyphs. Only one WorldEnvironment may exist at a time.
- Git needs delete permission (lock files). Never stage the `games/starfall`, `template/`, `.claude/`, `.github/` mode noise.

## Open questions for Daniel
- Please listen to the new sound effects in a browser build (press N to mute). Are they too loud or harsh? The explosion is the loudest.
- After VS-001 the economy may be too generous early (credits at 10 min are 10–27k). Is a faster early game OK?
- Keep committing to local `main`, or push to GitHub so sessions can open PRs?
- Target session length: the design assumes 30–40 minutes. Shorter?

## Answers to Daniel
- none (INBOX empty)

## Session history (newest first, keep 10)
- S0005 2026-10-26 BUILD — took over stale S0004 lock; VS-003 procedural SFX done (QA PASS); VS-012 added
- S0004 2026-10-26 ABORTED — took the lock at 03:32Z, then nothing; no log, no handover
- S0003 2026-10-26 BUILD — cleaned up hung S0002; VS-001 mid-game rebalance done (nw20 8k→139k, HQ 5/6); VS-011 added
- S0002 2026-10-26 ABORTED — hung during VS-001, cancelled by Daniel; diff salvaged, no handover
- S0001 2026-10-26 BUILD — baseline commit; VS-002 trader reserve + VS-008 AI-journey selftest done; VS-010 added
- S0000 2026-10-25 SETUP — game v1 + AI studio + seeded backlog
