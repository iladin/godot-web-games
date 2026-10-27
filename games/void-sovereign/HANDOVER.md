# Void Sovereign — Handover
_Last updated: S0013 · 2026-10-27 04:20 UTC · mode: BUILD_

## TL;DR
S0013 shipped **VS-024, the credit ledger**. Every change to the player's credits now goes through `Universe.add_credits(amount, cat)`. The HUD shows "+N cr/min", and the map and dock panels show a "Last 5 min" breakdown by category. Tutorial tip 4 now sends the player to the Union Trade Hub. The ledger is a pure observer: the econ30 and passive40 9-seed gates are byte-identical to S0012. QA passed it in the first round and `check.sh` passes. This targets the critic's weakest pillar, economy legibility (3/10).

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md`.
   - **The repo mount moved:** device_bash now sees the repo at `$HOME/mnt/git/godot-web-games`. `$HOME/mnt/godot-web-games` is an empty stale dir. Check with `ls $HOME/mnt $HOME/mnt/git` first and use whichever holds the repo.
   - Request delete permission for `C:\git\godot-web-games` so git works (granted every session so far).
   - Plain `git status` shows every file modified (file-mode noise), so always use `git --no-optional-locks -c core.fileMode=false …`.
   - Commit with `git -c core.fileMode=false -c "user.name=Claude Studio" -c user.email=studio@localhost commit -F -`.
2. **BUILD `VS-005`** (P2 S). This is what `backlog.py next` returns: declutter the surface objective markers.
   - Overlapping pylon labels should be offset or merged ("2× PYLON 380m").
   - Verify with `shots.sh void-sovereign surface touch_surface`.
3. **Then BUILD `VS-022`** (P2 S), allowed because both tasks are size S: freeze the surface under the end screen.
   - Gate `surface.tick` and fps input on state == PLAYING in `scripts/run_flow.gd`.
   - Repro probes: `.tools/s0012_qa/p1.gd` and `p1b.gd`.
4. **Later: `VS-023`** (P2 M). Range-check the raid deterrent, reject `build_station` inside planets, and A/B `DREAD_TIME` 900→1200. Both 9-seed gates must stay green.
   - Then `VS-025` (honest raid reports).
   - Then re-measure Hive ship counts, and unblock or close `VS-006`.
5. **Small polish from the S0013 QA**, all in the parking lot. They could be bundled into one P2 S task once open todo drops:
   - The map side panel is now taller, so BUY SHIPS / build sit below the fold at 1280×720.
   - Tip 4 latches on docking at any station; it should latch only on `kind=="trade"`.
   - Label the HUD rate "earned/min", since it is gross income.
   - Hide cr/min during the first 15 s.

## Last session
- Did: **VS-024** — done.
  - New `games/void-sovereign/scripts/sim/ledger.gd`, class CreditLedger:
    - `RATE_WINDOW` 60 s, `BREAKDOWN_WINDOW` 300 s, `MIN_RATE_SPAN` 15 s, 5 s buckets
    - lifetime `totals` per category
  - Touched `universe.gd`, `surface_view.gd`, `dock_panel.gd`, `hud.gd`, `map_view.gd`, `tutorial_hints.gd`, `selftest.gd` and `test_driver.gd`.
    - The HUD top panel is 500 px wide, and the HQ bar and raid column moved to x=340.
    - New shot scenarios: `ledger`, `ledger_dock`, `ledger_map`.
    - `main.gd` is unchanged.
  - Credit categories:
    - trade / stations / mining / freight (from `transact`)
    - ships, build, colonies, bounty, repair
    - losses (respawn)
  - QA verified independently:
    - A 20-minute per-step invariant on seeds 101 and 186 had 0 drift.
    - econ30 and passive40 are byte-identical to S0012.
    - Large balances fit up to about 12M credits before reaching the HQ column.
- Check: PASS · Git: commit `studio(S0013): VS-024 credit ledger` · Roles collapsed: none

## In-flight / uncommitted work
None in the repo. Scratch is in gitignored `.tools/`:
- `.tools/s0013_dev/`: dev shots and econ30 gate
- `.tools/s0013_qa/`: `ledger_inv.gd`, `width.gd`, econ30/ and pass40/ gates, `w1280_*.png`, `w900_*.png`

## Build health
- check.sh: PASS (~20–25 s). Selftest now also prints "ledger: 10 categories sum to credit delta +112954 OK".
- Known noise, not bugs: "ObjectDB instances leaked" / "resources still in use at exit", and ALSA errors under xvfb.
- Latest metrics (S0013 row, identical to S0012):
  - econ30 nw10 93.2k, nw20 107.7k, nw30 122.3k [117.3–146.6k], min 37.4k (seed 186); HQ 9/9; Hive ships at minute 20: 58
  - passive40: HQ lost 33.7 [32.1–35.8], 2/9 survive

## Backlog snapshot
todo 7 · in-progress 0 · done 15 · blocked 1 · split 2 · ready 6 · Top ready: VS-005 surface marker declutter (P2 S), VS-007 wing commands (P2 S), VS-010 NPC traders stuck at player station (P2 S), VS-022 surface frozen under end screen (P2 S)

## Watch out for
- **Credits:** never write `credits` directly in game code. Use `Universe.add_credits(amount, "<category>")` so the ledger and selftest stay correct. Only selftest fixtures write `u.credits` directly.
- **Raid deterrent (VS-020):** the go-chance is 0.25^n per player platform in the target sector, from minute 20. Keep 0.25; 0.5 or redirecting cancelled raids broke econ nw30 ≥ nw20.
- **Sim chaos:** judge balance only on 9-seed medians and IQR, with a fresh `GATE_OUT`.
  - The econ30 gate takes ~150 s of the 180 s cap.
  - Passive needs two calls (`GATE_OFFSETS="0 3"`, then `"6"`).
  - Any extra RNG draw shifts outcomes.
- **Don't run several heavy agents at once** on the 2-core device. A BUILD cycle took ~50 min this time: dev ~11 min, QA ~12 min.
- `nohup … &` processes in device_bash die when the call returns. Run long work in the foreground.
- **Passive gate is near its ceiling** (33.7 vs 35). New defences must stay player-only.
- **PauseGate must stay main's first child.** main.gd is 306 lines. Every sound goes through `Sfx.play()`.
- The `win` shot scenario writes the real best score to user://save.cfg (parking lot).

## Open questions for Daniel
- Is it acceptable that a fortified HQ is nearly raid-free after minute 20? VS-023 keeps the 0.25 strength but only counts platforms near the target. Say so in INBOX if you want a floor or a ramp instead.
- Should the HUD income rate show **net** income (after ship purchases and builds) instead of gross earned? It currently shows gross; the 5-min breakdown shows net per category.
- Still open: should the save file remember tutorial tips? What is the target session length (the design assumes 30–40 min)?

## Answers to Daniel
- None new (INBOX was empty). Earlier rulings still apply: a slower early game is fine; VS-007/VS-009 stay in todo; the studio never pushes; 9-seed gates are the standard.

## Session history (newest first, keep 10)
- S0013 2026-10-27 BUILD — VS-024 credit ledger done (HUD cr/min, map/dock 5-min breakdown, tip 4 → Trade Hub; gates byte-identical; QA PASS first round)
- S0012 2026-10-27 PLANNING — review round 2 (critic 5.5/10); VS-022..VS-025 added; no build
- S0011 2026-10-26 BUILD — VS-020 late-game decline fixed with a player-only raid deterrent (econ nw30 55.9k→122.3k, HQ 9/9, passive unchanged; QA PASS first round)
- S0010 2026-10-26 BUILD — VS-021 9-seed balance gates + A/B switches done; VS-014 pause-screen touch/mouse done (both QA PASS first round)
- S0009 2026-10-26 BUILD — VS-018 First Sortie done (QA FAIL → fix round → PASS); VS-021 added (sim chaos makes 3-seed gates unreliable)
- S0008 2026-10-26 BUILD — VS-011 split → VS-019 harness done (HQ 6/6, nw30 74k) + VS-020 open; VS-017 tutorial tips follow the world done (QA PASS after 1 fix round)
- S0007 2026-10-26 PLANNING+BUILD — first review round (critic 5.1/10) → VS-015..018; VS-015 title freeze/overlay fix + VS-016 trade arbitrage fix done (both QA PASS)
- S0006 2026-10-26 BUILD — VS-004 tutorial tips + VS-012 touch row/pause-mute/sfx assert done (both QA PASS); VS-013, VS-014 added
- S0005 2026-10-26 BUILD — took over stale S0004 lock; VS-003 procedural SFX done (QA PASS); VS-012 added
- S0004 2026-10-26 SUPERSEDED — took lock 03:32Z, device calls stalled ~8 h; resumed later as S0006
