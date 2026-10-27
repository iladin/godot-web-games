# Void Sovereign — Handover
_Last updated: S0016 · 2026-10-27 06:10 UTC · mode: BUILD_

## TL;DR
S0016 shipped **VS-007** (wing commands from the cockpit): G attack, C escort, V hold, touch ATK/ESC/HOLD, HUD line "WING n · ORDER". QA failed once (ACT/ATK touch overlap), fixed, then passed. `check.sh` PASS. 3 todo remain; `backlog.py next` returns VS-009.

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md`. Repo mounts at `$HOME/mnt/godot-web-games` (also `$HOME/mnt/git/godot-web-games`). Use `git --no-optional-locks -c core.fileMode=false …`.
   - Note: the working tree has Daniel's/S0017's uncommitted edits to `ai-studio/studio-cycle.md` and `docs/AI_STUDIO.md` (Git section now says git writes are always allowed, don't request delete permission) and an untracked `_to_delete/`. They are not S0016's; don't stage them unless asked. Read the new Git section before committing.
2. **BUILD `VS-009`** (what `backlog.py next` returns; read its block first).
3. Then `VS-023` (P2 M: raid-deterrent range check, reject `build_station` inside planets, A/B `DREAD_TIME` 900→1200; both 9-seed gates green), `VS-025` (honest raid reports), then re-measure Hive counts and unblock/close `VS-006`.
4. **builds_since_review = 5.** Run PLANNING next session (health rule fires at 6).
5. Bundle parking-lot P3 polish into one P2 S task (see parking lot, incl. S0016 wing P3s: move the wing touch row off mid-screen at 1280x720, map HOLD label, wing `--shot` scenario).

## Last session
- Did: **VS-007** done. New `scripts/sim/wing.gd` (members/command/status); `hold` order in `ship_ai.gd`; keys in `controls.gd`/`space_view.gd`; buttons in `touch_controls.gd` (wing row at x −400/−520/−640, y TOP_ROW_Y+80); HUD line in `hud.gd`; title text in `overlay.gd`; DESIGN.md controls updated; selftest "wing commands OK". No RNG.
- Check: PASS · Git: see `git log -1` (game paths only) · Roles collapsed: none
- Daniel mid-run asked to stop needing permission to open the connected folders; that is an app/task permission setting a session can't change — see Open questions.

## In-flight / uncommitted work
None from S0016 after its commit. Unrelated pre-existing edits listed above (studio-cycle.md, docs/AI_STUDIO.md, LOG.md S0017 entry, `_to_delete/stray_touch_probe_S0017`). Snapshot `S0016` exists in `.tools/snapshots/`.

## Build health
- check.sh: PASS · selftest OK · known noise: ObjectDB leaked at exit, ALSA under xvfb.
- Latest metrics: unchanged from S0015 (no balance-affecting change this session).

## Backlog snapshot
todo 3 · in-progress 0 · done 19 · blocked 1 · split 2 · ready 2 · Top ready: VS-009, VS-023, VS-025

## Watch out for
- **Credits:** use `Universe.add_credits(amount, "<category>")`, never write `credits`.
- **Raid deterrent (VS-020):** keep 0.25^n go-chance.
- **Sim chaos:** judge balance on 9-seed medians with fresh `GATE_OUT`; extra RNG draws shift outcomes; new defences player-only.
- **Heavy agents:** don't run several at once; run `shots.sh` and `check.sh` in separate calls (chaining once timed out).
- **PauseGate must stay main's first child.** `main.gd` is over 306 lines. Every sound through `Sfx.play()`.
- **Surface liveness:** respect `RunFlow.surface_live(state)`.
- **Touch layout:** ACT sits at (1160,300) at 1280x720; keep new buttons ≥ ~1.15×radius apart.

## Open questions for Daniel
- You asked me to change things so sessions don't need permission to open the connected folders. I can't change that from inside a run; it's a Claude desktop app setting (folder connections / the task's approval mode, "Automatically approve"). Tell me if you want the procedure edited instead.
- Is it acceptable that a fortified HQ is nearly raid-free after minute 20?
- Should the HUD income rate show net income instead of gross? Should the save remember tutorial tips? Target session length?

## Answers to Daniel
- None (INBOX empty).

## Session history (newest first, keep 10)
- S0016 2026-10-27 BUILD — VS-007 wing commands done (QA FAIL touch overlap → fix → PASS)
- S0017 2026-10-27 SKIPPED — lock held by S0016
- S0015 2026-10-27 BUILD — VS-010 NPC traders vs broke player station done (QA PASS first round)
- S0014 2026-10-27 BUILD — VS-005 marker declutter + VS-022 surface freeze under end screen done (both QA PASS first round)
- S0013 2026-10-27 BUILD — VS-024 credit ledger done (HUD cr/min, map/dock 5-min breakdown; gates byte-identical; QA PASS)
- S0012 2026-10-27 PLANNING — review round 2 (critic 5.5/10); VS-022..VS-025 added
- S0011 2026-10-26 BUILD — VS-020 late-game decline fixed with a player-only raid deterrent
- S0010 2026-10-26 BUILD — VS-021 9-seed gates + VS-014 pause-screen touch/mouse done
- S0009 2026-10-26 BUILD — VS-018 First Sortie done (QA FAIL → fix → PASS)
- S0008 2026-10-26 BUILD — VS-019 harness + VS-017 tutorial tips follow the world done
- S0007 2026-10-26 PLANNING+BUILD — first review round (critic 5.1/10); VS-015, VS-016 done
