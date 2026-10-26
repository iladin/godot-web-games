# Void Sovereign — Handover
_Last updated: S0011 · 2026-10-26 23:10 UTC · mode: BUILD_

## TL;DR
S0011 shipped **VS-020** (P1, QA PASS on the first round), which fixes the long-standing late-game decline. A new player-only raid deterrent means an economic player's net worth now grows from minute 20 to 30: the 9-seed median went from 107.7k to 122.3k (it was 55.9k before), and the HQ survives 9/9. The passive gate is unchanged. QA thinks the deterrent may be too strong, because a player who turtles with platforms is nearly raid-immune after minute 20. `check.sh` passes. The health rule now **requires a PLANNING round next** (builds_since_review = 6).

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md`. Request delete permission for the repo root (granted in S0001/3/5–11, so git works). Use `git -c core.fileMode=false …` for status/add. Commit with `git -c "user.name=Claude Studio" -c user.email=studio@localhost commit -F - <<'EOF2'`.
2. **Run a PLANNING round** (Step 3b). It is mandatory because builds_since_review = 6 and the last review was S0007. Run Critic, QA sweep and Balance Analyst in parallel, then Feature Scout. Give the critic the S0007 review to compare against (`studio/reviews/S0007-*.md`). Candidates already flagged in the parking lot:
   - **Raid deterrent tuning** (S0011 QA): add a go-chance floor, ramp it in over minutes 20–25, or redirect cancelled raids. Re-run both gates after any change; the econ nw30 ≥ nw20 margin is about 15k on plain seeds.
   - **Credit ledger / economy legibility.** The critic in S0007 scored this 3/10.
   - **Honest raid reports.** These pair well with the new "turned back" HUD message.
   - A late-game HQ reinforcement order.
   - Tail-seed collapses: econ seed 186 drops from 112k to 37k; perturbed seeds 118/169/220.
3. If budget remains after planning, BUILD the top P1/P2 **S** task. The current ready queue is VS-005 (surface marker declutter), VS-010 (traders stuck at a player station) and VS-007 (wing commands). VS-009 is size L, so split it first. VS-006 (web perf guard) has been blocked "until VS-020"; **VS-020 is done now, so unblock VS-006 during planning** and re-check that it is still relevant.
4. Cheap P3s in the parking lot (S0010/S0011):
   - selftest: assert PauseGate is child 0; clean up the 2 Defense Platforms the selftest spawns.
   - Pause screen: the mouse wheel resumes the game; the text should say "tap" on touch.
   - Surface game-over needs a double click.
   - Throttle the "turned back" HUD message.
   - balance_gate: add a stale-file check; quote the S0003 row in metrics.csv.

## Last session
- Did:
  - **VS-020 done.** It touched `scripts/sim/director.gd` (new `Director.raid_go_chance(target)`), `scripts/sim/defs.gd` (`RAID_DETER_FROM` 1200 s, `RAID_DETER_PER_PLATFORM` 0.25), `scripts/selftest.gd` (asserts for an undefended HQ, the t=1199/1200 boundary, 2 platforms giving 0.0625, and Union targets never deterred) and the DESIGN.md Ramp bullet.
  - **Mechanic:** a deterred raid is cancelled outright. The raid timer resets, no ships spawn, and the HUD says "Hive raid on X turned back by your Defense Platforms".
  - **RNG:** `randf()` is drawn only when the go-chance is below 1, so the passive game and the first 20 minutes keep the same RNG stream.
  - **Dev iterations:** 0.6 with no time gate pushed nw20 past the 130k cap. 0.6 from minute 20 and 0.4 both failed. 0.25 passed.
  - **QA** reproduced the developer's numbers exactly with fresh GATE_OUT directories. QA's regression checks were check.sh, a 90 s combat_long run, and map/dock/combat shots (file-level only).
- Check: PASS · Git: 15b724b (VS-020) + wrap-up commit (HANDOVER/LOG/state) · Roles collapsed: none

## In-flight / uncommitted work
None from this session. Scratch is in gitignored `.tools/`:
- `.tools/s0011_dev/`: dev gate A/B outputs econ_a..d, econ_d_p1, pass_d
- `.tools/s0011_qa/`: QA gates, check.txt, combat_long.txt
- older `.tools/s0010*` directories

## Build health
- check.sh: PASS (~25 s). The selftest now also covers the raid deterrent.
- Known noise, not bugs: "ObjectDB instances leaked" / "resources still in use at exit", and ALSA errors under xvfb.
- Latest metrics (S0011 row): econ30, 9 seeds:
  - nw10 93.2k, nw20 107.7k [103.5–127.0k], nw30 122.3k [117.3–146.6k]
  - HQ 9/9; Union does not collapse by minute 30
  - Hive ships at minute 20: 58
  - passive40: HQ lost 33.7 [32.1–35.8], 2/9 survive

## Backlog snapshot
todo 4 · in-progress 0 · done 14 · blocked 1 · split 2 · ready 3 · Top ready: VS-005 surface marker declutter (P2 S), VS-010 traders stuck at player station (P2 S), VS-007 wing commands (P2 S)

## Watch out for
- **Raid deterrent (VS-020):** the go-chance is 0.25^n, so 2 platforms give 6.25% and 3 give 1.6%.
  - Cancelled raids are not redirected, so they take total Hive pressure off the board.
  - A platform counts toward its own deterrence when it is the target.
  - Any softening must keep econ nw30 ≥ nw20 on the 9-seed gate. Plain margin is ~15k; under perturbation nw20 is 126k, close to the 130k cap.
- **Sim chaos:** the global `randf()` is seeded at universe.gd:30. Judge balance only on 9-seed medians and IQR, and use the `--perturb` / `--nowave` controls.
- **Gate timing:** the device has 2 cores, and the econ 30-min gate takes 154–165 s of the 180 s cap. Passive 40 min needs two calls (`GATE_OFFSETS="0 3"`, then `"6"`). Always use a fresh `GATE_OUT`: the tags don't include the game version.
- **Passive gate is near its ceiling** (33.7 vs 35). Any new defence must stay player-only.
- **PauseGate must stay main's first child**, because of the `_input` order.
- **Code size:** main.gd is ~306 lines; split it before adding more. universe.gd is ~454 lines.
- **Conventions:** every sound goes through `Sfx.play()`. The default font has no arrow glyphs.

## Open questions for Daniel
- Is it acceptable that, after minute 20, a player who fortifies the HQ sector with 2+ Defense Platforms almost never gets raided there? If not, the planning round will propose a floor or a ramp.
- Still open: should the save file remember tutorial tips? What is the target session length (the design assumes 30–40 min)?
- The S0010 fallback question (accept a mild decline for VS-020) is moot now: strict growth was achieved.

## Answers to Daniel
- None new (INBOX was empty). Earlier rulings still apply: a slower early game after VS-016 is fine; VS-007/VS-009 were restored to todo; the studio never pushes unless asked; 9-seed gates are the standard.

## Session history (newest first, keep 10)
- S0011 2026-10-26 BUILD — VS-020 late-game decline fixed with a player-only raid deterrent (econ nw30 55.9k→122.3k, HQ 9/9, passive unchanged; QA PASS first round)
- S0010 2026-10-26 BUILD — VS-021 9-seed balance gates + A/B switches done; VS-014 pause-screen touch/mouse done (both QA PASS first round)
- S0009 2026-10-26 BUILD — VS-018 First Sortie done (QA FAIL → fix round → PASS); VS-021 added (sim chaos makes 3-seed gates unreliable)
- S0008 2026-10-26 BUILD — VS-011 split → VS-019 harness done (HQ 6/6, nw30 74k) + VS-020 open; VS-017 tutorial tips follow the world done (QA PASS after 1 fix round)
- S0007 2026-10-26 PLANNING+BUILD — first review round (critic 5.1/10) → VS-015..018; VS-015 title freeze/overlay fix + VS-016 trade arbitrage fix done (both QA PASS)
- S0006 2026-10-26 BUILD — VS-004 tutorial tips + VS-012 touch row/pause-mute/sfx assert done (both QA PASS); VS-013, VS-014 added
- S0005 2026-10-26 BUILD — took over stale S0004 lock; VS-003 procedural SFX done (QA PASS); VS-012 added
- S0004 2026-10-26 SUPERSEDED — took lock 03:32Z, device calls stalled ~8 h; resumed later as S0006
- S0003 2026-10-26 BUILD — cleaned up hung S0002; VS-001 mid-game rebalance done (nw20 8k→139k, HQ 5/6); VS-011 added
- S0002 2026-10-26 ABORTED — hung during VS-001, cancelled by Daniel; diff salvaged, no handover
