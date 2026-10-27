# Void Sovereign — Handover
_Last updated: S0015 · 2026-10-27 05:45 UTC · mode: BUILD_

## TL;DR
S0015 shipped **VS-010** (size S bug): NPC traders/miners no longer retry forever at a player station that can't pay (`ShipAI.can_deliver_to`, used by `plan_trade` and `best_buyer`). QA PASS first round, `check.sh` PASS. 4 todo remain; `backlog.py next` returns VS-007.

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md`.
   - The repo is mounted at `$HOME/mnt/git/godot-web-games` (`$HOME/mnt/godot-web-games` is a stale empty dir).
   - Request delete permission for the connected root `C:\git` (granted in S0014 and S0015).
   - Use `git --no-optional-locks -c core.fileMode=false …`; commit with `git -c core.fileMode=false -c "user.name=Claude Studio" -c user.email=studio@localhost commit -F -`.
2. **BUILD `VS-007`** (P2 S, wing commands) — what `backlog.py next` returns.
3. Then `VS-023` (P2 M: raid-deterrent range check, reject `build_station` inside planets, A/B `DREAD_TIME` 900→1200; both 9-seed gates must stay green), then `VS-025` (honest raid reports), then re-measure Hive ship counts and unblock or close `VS-006`.
4. **builds_since_review = 4.** Run PLANNING by about S0017 (health rule fires at 6).
5. Bundle the parking-lot P3 polish into one P2 S task when todo is low (map side panel below the fold, tip 4 latch on kind=="trade", "earned/min" label, hide cr/min for 15 s, marker text outline, tighten VS-010 best_buyer selftest assertion).

## Last session
- Did: **VS-010** done. `ShipAI.can_deliver_to(u, s, st, ware)` returns true unless the ship is non-player and the station is a player station; in that case it requires credits − TRADER_RESERVE ≥ 5 × price. Selftest assertion added. No new RNG draws.
- Check: PASS · Git: committed `studio(S0015): VS-010` (see `git log -1`) · Roles collapsed: none
- QA notes (P3, parking lot): the best_buyer half of the new selftest assertion passes even without the guard (price tie); miners idle with no wait timer when no buyer exists.

## In-flight / uncommitted work
None after the S0015 commit. Mode-bit-only diffs (100644→100755) from the mount are ignored via `core.fileMode=false`.

## Build health
- check.sh: PASS · known noise: ObjectDB leaked at exit, ALSA under xvfb.
- Latest metrics: econ 20 min, seeds 101/118/135: credits_10 18435 / 22095 / 19194, HQ survived 3/3. Gate numbers otherwise unchanged from S0013.

## Backlog snapshot
todo 4 · in-progress 0 · done 18 · blocked 1 · split 2 · ready 3 · Top ready: VS-007 wing commands (P2 S), VS-023 (P2 M), VS-025

## Watch out for
- **Credits:** never write `credits` directly. Use `Universe.add_credits(amount, "<category>")`.
- **Raid deterrent (VS-020):** the go-chance is 0.25^n per player platform; keep 0.25.
- **Sim chaos:** judge balance only on 9-seed medians with a fresh `GATE_OUT`. Any extra RNG draw shifts outcomes. The passive gate is near its ceiling, so new defences must stay player-only.
- **Heavy agents:** don't run several at once on the 2-core device.
- **PauseGate must stay main's first child.** `main.gd` is over 306 lines — consider splitting. Every sound goes through `Sfx.play()`.
- **Surface liveness:** new surface or FPS logic must respect `RunFlow.surface_live(state)`.

## Open questions for Daniel
- Is it acceptable that a fortified HQ is nearly raid-free after minute 20? Reply in INBOX if you want a floor or a ramp.
- Should the HUD income rate show net income instead of gross?
- Should the save file remember tutorial tips? What is the target session length?

## Answers to Daniel
- None (INBOX empty).

## Session history (newest first, keep 10)
- S0015 2026-10-27 BUILD — VS-010 NPC traders vs broke player station done (QA PASS first round)
- S0014 2026-10-27 BUILD — VS-005 marker declutter + VS-022 surface freeze under end screen done (both QA PASS first round)
- S0013 2026-10-27 BUILD — VS-024 credit ledger done (HUD cr/min, map/dock 5-min breakdown; gates byte-identical; QA PASS)
- S0012 2026-10-27 PLANNING — review round 2 (critic 5.5/10); VS-022..VS-025 added
- S0011 2026-10-26 BUILD — VS-020 late-game decline fixed with a player-only raid deterrent
- S0010 2026-10-26 BUILD — VS-021 9-seed gates + VS-014 pause-screen touch/mouse done
- S0009 2026-10-26 BUILD — VS-018 First Sortie done (QA FAIL → fix → PASS)
- S0008 2026-10-26 BUILD — VS-019 harness + VS-017 tutorial tips follow the world done
- S0007 2026-10-26 PLANNING+BUILD — first review round (critic 5.1/10); VS-015, VS-016 done
- S0006 2026-10-26 BUILD — VS-004 tutorial tips + VS-012 touch row done
