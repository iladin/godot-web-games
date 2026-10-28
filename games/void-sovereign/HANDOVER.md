# Void Sovereign — Handover
_Last updated: S0035 · 2026-10-28 04:10 UTC · mode: BUILD_

## TL;DR
S0035 shipped VS-037: first pylon kill spawns a 5-6 unit Hive flank squad, plus kill X/flash and kill blip, autoplay bot now strafes and boards the ship. Also fixed a pre-existing per-frame SCRIPT ERROR on the freed Core node. Build green; 6 ready todos (incl. new VS-045).

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0036. `export GODOT=$(bash scripts/studio/ensure_godot.sh | tail -1)`.
2. BUILD `backlog.py next`. Small first: VS-045 (flank should cost on-foot hp; defs.gd FLANK_* constants; test with `$GODOT --headless --fixed-fps 60 --quit-after 9000 --path games/void-sovereign -- --shot=surface_long`, ~20 s, deterministic), VS-040, VS-043, VS-041.
3. Later: VS-044 (balance harness platform policy, then re-enable redirect), VS-042 (real-browser smoke; also check kill blip + explosion don't sound muddy and look at the kill X visually).
4. builds_since_review = 5; planning round due after 6 (so run PLANNING next-next session, or first thing if one more build lands).
5. Carry-over: touch@900 hint line stray dot ("Dock at the Union.Trade Hub"); harness mode with pilot present; `--perturb=1` passive gate (HQ lost 31.9); perturb=1 seed 101 nw30 tail.

## Last session
- Did: BUILD VS-037 (defs.gd FLANK_*, surface_view.gd spawn_flank/kill_confirmed/bot, sfx.gd kill, hud.gd kill X, main.gd, test_driver.gd, selftest.gd _test_surface_flank, DESIGN.md). QA round 1 FAIL -> fix round -> round 2 PASS.
- Check: PASS · Git: committed this session · Roles collapsed: none

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`.

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- surface_long: pylon1 45 s, pylons down 51 s, Core dead 65 s, boarded 113 s, min_foot 525, 0 SCRIPT ERROR. Latest balance metrics unchanged from S0034 (sim layer untouched).

## Backlog snapshot
todo 6 · in-progress 0 · done 35 · blocked 1 · split 3 · Top ready: VS-040, VS-041, VS-043 (VS-045 also ready)

## Watch out for
- Acceptance "2-3 flankers" was deliberately retuned to 5-6 at 30 m, 1.8x speed/damage (FLANK_* in defs.gd); 2-3 never hurt the player. Flank only drains shield (60->40); hp stays 100 -> VS-045.
- "min_foot" in surface_long = on-foot hp+shield scaled x600/160; ship hull is untouched on foot (accepted reading).
- Bot priority bonus applies only to flankers; boarding walk is ~420 m so ~48 s after Core death.
- Redirect still off (RAID_REDIRECT_ENABLED=false). Raid panel fit (VS-043). Do NOT `pkill -f godot`; use `pkill -x godot`. Foreground `timeout 175`, balance sequential.
- Subagent runs are slow (~25-40 min each); one BUILD took most of the budget.

## Open questions for Daniel
- Desktop text got slightly longer (earn hint at 0 income, HQ dock second sentence): keep, or touch-only?
- Fortified HQ nearly raid-free after minute 20: want the Breach nastier?
- HUD income gross vs net? Target session length? over.png Net worth 45,000 vs 30,000: confirm formula.
- Real-browser pass still needed (IndexedDB, .bak rename, audio unlock) — VS-042.
- Is a scout fight 8 s after takeoff too aggressive for first-time touch players?
- VS-037: OK that the flank squad is 5-6 units rather than 2-3?

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0035 2026-10-28 BUILD — VS-037 flank squad + kill feedback done (QA PASS round 2); VS-045 added
- S0034 2026-10-28 BUILD — VS-036 intercept bounty done (QA PASS round 2); redirect disabled behind flag -> VS-044
- S0033 2026-10-28 BUILD — VS-035 text fit guard + map/title labels + cr/min gate done (QA PASS)
- S0032 2026-10-27 BUILD — VS-039 raid tracks + outcome history + Defend button done (QA PASS)
- S0031 2026-10-27 PLANNING+BUILD — review round -> VS-038..042; VS-038 hot opening done (QA PASS round 2)
- S0030 2026-10-27 BUILD — VS-033 atomic run save, QA PASS -> done
- S0029 2026-10-27 BUILD — VS-032 touch/UX bundle, QA PASS -> done
- S0028 2026-10-27 BUILD — VS-031 spire + beams, QA PASS -> done
- S0027 2026-10-27 BUILD — VS-030 selftest fix, QA PASS -> done
- S0026 2026-10-27 BUILD — VS-030 First Sortie implemented, QA FAIL on dead selftest assertion -> blocked (code kept, check PASS)
