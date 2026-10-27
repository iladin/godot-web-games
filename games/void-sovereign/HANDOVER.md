# Void Sovereign — Handover
_Last updated: S0012 · 2026-10-27 03:05 UTC · mode: PLANNING_

## TL;DR
S0012 ran the second review round. The Critic scored **5.5/10**, up from 5.1 in S0007. The first 10 minutes, readability, pacing and web/touch all improved. Economy legibility (3) and on-foot FPS (4) are still the weakest pillars. The planning round produced four new tasks (VS-022..VS-025). Balance gates are unchanged from S0011 and all targets are met. QA found that the VS-020 raid deterrent counts platforms anywhere in a sector, even ones built inside planets. No code changed this session and `check.sh` passes.

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md`. Request delete permission for the repo root (granted every session so far), so git works. Use `git -c core.fileMode=false …` for status and add. Commit with `git -c "user.name=Claude Studio" -c user.email=studio@localhost commit -F -`.
2. **BUILD `VS-024` credit ledger** (P1 M). This is what `backlog.py next` returns.
   - Put the ledger in its own script; main.gd is ~306 lines.
   - Route every credit change through one categorised function, then add cr/min to the HUD and a "last 5 min" breakdown.
   - Point tip 4 at a Union Trade Hub.
   - It must be a pure observer: the econ30 9-seed numbers must stay identical (nw20 107,685 / nw30 122,300), and the RNG stream must not change.
3. **If budget remains, BUILD `VS-022`** (P2 S): freeze the surface under the end screen.
   - Gate `surface.tick` and fps input on state == PLAYING in `scripts/run_flow.gd`.
   - Repro probes: `.tools/s0012_qa/p1.gd` and `p1b.gd`.
4. **Then `VS-023`** (deterrent range check, reject `build_station` inside planets, `DREAD_TIME` 900→1200 A/B). Then `VS-025` (honest raid reports; do it after VS-023).
   - After VS-023 lands, re-measure Hive ship counts and unblock or close **VS-006**.
5. Next candidates when open todo drops below 8: First Sortie belongs to the player, and the readable-surface extension of VS-005. Both are in the parking lot under S0012.

## Last session
- Did:
  - PLANNING round. Reports are in `studio/reviews/S0012-{critic,qa,balance,scout}.md`.
  - Critic: 5.5/10. Top problems:
    - the economy is invisible;
    - raid warnings are false alarms;
    - escorts win the first fight;
    - the surface hasn't changed since S0007;
    - the HQ is almost raid-proof.
  - QA sweep: two P2 bugs (the surface stays live under the end screen; the deterrent has no range check) and five P3s. All S0007 bugs are confirmed fixed.
  - Balance: all 8 targets met. Hive ships at minute 20 are over the guard in 3/9 seeds (max 75). After minute 20, 57% of raid rolls are cancelled. Keep the per-platform factor at 0.25. Tail collapses come from the dreadnought raid at 18–19.7 min; the analyst recommends `DREAD_TIME` 1200.
  - Scout: five proposals; four became tasks or task notes.
  - Backlog: added VS-022, VS-023, VS-024 and VS-025. Updated the VS-005 and VS-006 notes. VS-006 stays blocked until VS-023 because the DREAD_TIME change moves Hive counts. Added seven parking-lot items.
  - No BUILD. The review agents took 15–35 min each on the 2-core device, so the session used ~3 h 50 min of wall time in total.
- Check: PASS · Git: commit `studio(S0012): review round` · Roles collapsed: none

## In-flight / uncommitted work
None in the repo. Scratch is in gitignored `.tools/`:
- `.tools/s0012_qa/` (probes p1/p1b/p2/p3, shots)
- `.tools/s0012_bal/` (gates, the DREAD_TIME A/B)
- `.tools/s0012_critic/shots/`

The critic's probe script is outside the repo, at `$HOME/critic/probe12.gd` on the device VM.

## Build health
- check.sh: PASS (~20–25 s). Selftest covers the raid deterrent, the opening wave and the tutorial.
- Known noise, not bugs: "ObjectDB instances leaked" / "resources still in use at exit", and ALSA errors under xvfb.
- Latest metrics (S0012 rows, identical to S0011):
  - econ30 nw10 93.2k, nw20 107.7k, nw30 122.3k [117.3–146.6k], min 37.4k (seed 186); HQ 9/9; Hive ships at minute 20: 58 (max 75)
  - passive40: HQ lost 33.7 [32.1–35.8], 2/9 survive

## Backlog snapshot
todo 8 · in-progress 0 · done 14 · blocked 1 · split 2 · ready 7 · Top ready: VS-024 credit ledger (P1 M), VS-022 surface frozen under end screen (P2 S), VS-005 surface marker declutter (P2 S)

## Watch out for
- **Raid deterrent (VS-020):** the go-chance is 0.25^n per player platform in the target sector, from minute 20.
  - The balance analyst found that 0.5 per platform, or redirecting cancelled raids, breaks econ nw30 ≥ nw20. Keep 0.25.
  - Making it range-based (VS-023) must keep both 9-seed gates green.
- **Sim chaos:** judge balance only on 9-seed medians and IQR, with a fresh `GATE_OUT`. The econ 30 gate takes ~155 s of the 180 s cap. Passive needs two calls (`GATE_OFFSETS="0 3"`, then `"6"`).
- **Don't run several heavy agents at once.** In a PLANNING round the three parallel agents share 2 cores, which is why this round took hours. Next time, consider sequencing the Balance Analyst first, or limit the critic and QA to short runs.
- `nohup … &` processes in device_bash die when the call returns. Long shot batches have to run in the foreground (about 40 s per 6 shots).
- **Passive gate is near its ceiling** (33.7 vs 35). New defences must stay player-only.
- **PauseGate must stay main's first child.** main.gd is ~306 lines. Every sound goes through `Sfx.play()`.
- The `win` shot scenario writes the real best score to user://save.cfg. It pollutes the dev machine's save (parking lot).

## Open questions for Daniel
- Is it acceptable that a fortified HQ is nearly raid-free after minute 20? VS-023 keeps the 0.25 strength but only counts platforms near the target. Say so in INBOX if you want a floor or a ramp instead.
- Still open: should the save file remember tutorial tips? What is the target session length (the design assumes 30–40 min)?

## Answers to Daniel
- None new (INBOX was empty). Earlier rulings still apply: a slower early game is fine; VS-007/VS-009 stay in todo; the studio never pushes; 9-seed gates are the standard.

## Session history (newest first, keep 10)
- S0012 2026-10-27 PLANNING — review round 2 (critic 5.5/10); VS-022..VS-025 added; no build
- S0011 2026-10-26 BUILD — VS-020 late-game decline fixed with a player-only raid deterrent (econ nw30 55.9k→122.3k, HQ 9/9, passive unchanged; QA PASS first round)
- S0010 2026-10-26 BUILD — VS-021 9-seed balance gates + A/B switches done; VS-014 pause-screen touch/mouse done (both QA PASS first round)
- S0009 2026-10-26 BUILD — VS-018 First Sortie done (QA FAIL → fix round → PASS); VS-021 added (sim chaos makes 3-seed gates unreliable)
- S0008 2026-10-26 BUILD — VS-011 split → VS-019 harness done (HQ 6/6, nw30 74k) + VS-020 open; VS-017 tutorial tips follow the world done (QA PASS after 1 fix round)
- S0007 2026-10-26 PLANNING+BUILD — first review round (critic 5.1/10) → VS-015..018; VS-015 title freeze/overlay fix + VS-016 trade arbitrage fix done (both QA PASS)
- S0006 2026-10-26 BUILD — VS-004 tutorial tips + VS-012 touch row/pause-mute/sfx assert done (both QA PASS); VS-013, VS-014 added
- S0005 2026-10-26 BUILD — took over stale S0004 lock; VS-003 procedural SFX done (QA PASS); VS-012 added
- S0004 2026-10-26 SUPERSEDED — took lock 03:32Z, device calls stalled ~8 h; resumed later as S0006
- S0003 2026-10-26 BUILD — cleaned up hung S0002; VS-001 mid-game rebalance done (nw20 8k→139k, HQ 5/6); VS-011 added
