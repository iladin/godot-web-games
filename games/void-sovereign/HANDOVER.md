# Void Sovereign — Handover
_Last updated: S0014 · 2026-10-27 05:15 UTC · mode: BUILD_

## TL;DR
S0014 shipped two size-S bug fixes, each passing QA in the first round: **VS-005** (surface marker labels merge/stack: "2× PYLON 366m") and **VS-022** (surface and FPS input freeze under the end screen; one click restarts). `check.sh` passes. Both changes are HUD/input-layer only, so the balance gates are unchanged from S0012/S0013. 5 todo remain; `backlog.py next` returns VS-010.

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md`.
   - The repo is mounted at `$HOME/mnt/git/godot-web-games`. `$HOME/mnt/godot-web-games` is an empty stale dir.
   - Request delete permission for the connected root `C:\git` (not `C:\git\godot-web-games`, which is rejected). It was granted in S0014.
   - Use `git --no-optional-locks -c core.fileMode=false …` for git.
   - Commit with `git -c core.fileMode=false -c "user.name=Claude Studio" -c user.email=studio@localhost commit -F -`.
2. **BUILD `VS-010`** (P2 S): NPC traders stuck at the player station. This is what `backlog.py next` returns.
   - Then `VS-007` (wing commands, P2 S) if budget allows.
3. **Later: `VS-023`** (P2 M). Range-check the raid deterrent, reject `build_station` inside planets, and A/B `DREAD_TIME` 900→1200. Both 9-seed gates must stay green.
   - Then `VS-025` (honest raid reports).
   - Then re-measure Hive ship counts, and unblock or close `VS-006`.
4. **builds_since_review = 3.** Run a PLANNING round by about S0017 (health rule fires at 6).
5. **Parking-lot polish, bundle into one P2 S task when todo is low:**
   - map side panel pushes BUY/build below the fold at 1280×720
   - tip 4 latches on any station, not only kind=="trade"
   - label the HUD rate "earned/min"
   - hide cr/min for the first 15 s
   - marker text contrast (dark outline in `Hud._txt`)

## Last session
- Did: **VS-005** done: `Hud.layout_markers` merges same-label markers within 70 px and stacks the remaining overlaps with leader lines. Constants are `MARKER_MERGE_PX`, `MARKER_LINE_H` and `MARKER_LABEL_W`. Selftest `_test_marker_layout` added.
  - **VS-022** done: `RunFlow.surface_live(state)` gates `surface.tick`, `fps.input_enabled`, the player_died handler and `_leave_surface` in `main.gd`. Selftest `_test_surface_over` and `surface_live` assertions added.
  - QA also checked finish mid-fade, then restart (no stuck fade or leaked surface), plus a normal takeoff, landing and evacuation.
  - Housekeeping: removed the stale `.git/stale-S0013-*.lock` files and 24 `tmp_obj_*` files.
- Check: PASS · Git: see LOG / `git log -1` (commit `studio(S0014): VS-005 + VS-022`) · Roles collapsed: none

## In-flight / uncommitted work
None after the S0014 commit. Scratch is in gitignored `.tools/` (`s0014_qa/q.gd` and others).

## Build health
- check.sh: PASS (~20 s) · selftest now includes marker layout and surface+finish assertions · known noise: ObjectDB leaked at exit, ALSA under xvfb.
- Latest metrics: unchanged from S0013 (econ30 nw30 122.3k, HQ 9/9; passive40 HQ lost 33.7, 2/9 survive). No balance run this session.

## Backlog snapshot
todo 5 · in-progress 0 · done 17 · blocked 1 · split 2 · ready 4 · Top ready: VS-010 NPC traders stuck at player station (P2 S), VS-007 wing commands (P2 S), VS-023 (P2 M)

## Watch out for
- **Credits:** never write `credits` directly in game code. Use `Universe.add_credits(amount, "<category>")`.
- **Raid deterrent (VS-020):** the go-chance is 0.25^n per player platform; keep 0.25.
- **Sim chaos:** judge balance only on 9-seed medians with a fresh `GATE_OUT`. Any extra RNG draw shifts outcomes. The passive gate is near its ceiling, so new defences must stay player-only.
- **Heavy agents:** don't run several at once on the 2-core device. `nohup … &` dies when the call returns.
- **PauseGate must stay main's first child.** `main.gd` is now over 306 lines (the VS-022 edit added some), so consider splitting it. Every sound goes through `Sfx.play()`.
- **Surface liveness:** new surface or FPS logic must respect `RunFlow.surface_live(state)`.

## Open questions for Daniel
- Is it acceptable that a fortified HQ is nearly raid-free after minute 20? Reply in INBOX if you want a floor or a ramp.
- Should the HUD income rate show net income instead of gross?
- Should the save file remember tutorial tips? What is the target session length?

## Answers to Daniel
- None new (INBOX empty).

## Session history (newest first, keep 10)
- S0014 2026-10-27 BUILD — VS-005 marker declutter + VS-022 surface freeze under end screen done (both QA PASS first round)
- S0013 2026-10-27 BUILD — VS-024 credit ledger done (HUD cr/min, map/dock 5-min breakdown; gates byte-identical; QA PASS)
- S0012 2026-10-27 PLANNING — review round 2 (critic 5.5/10); VS-022..VS-025 added
- S0011 2026-10-26 BUILD — VS-020 late-game decline fixed with a player-only raid deterrent
- S0010 2026-10-26 BUILD — VS-021 9-seed gates + VS-014 pause-screen touch/mouse done
- S0009 2026-10-26 BUILD — VS-018 First Sortie done (QA FAIL → fix → PASS)
- S0008 2026-10-26 BUILD — VS-019 harness + VS-017 tutorial tips follow the world done
- S0007 2026-10-26 PLANNING+BUILD — first review round (critic 5.1/10); VS-015, VS-016 done
- S0006 2026-10-26 BUILD — VS-004 tutorial tips + VS-012 touch row done
- S0005 2026-10-26 BUILD — took over stale S0004 lock; VS-003 procedural SFX done
