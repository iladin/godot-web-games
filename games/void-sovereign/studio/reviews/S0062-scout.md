# S0062 Feature Scout: Void Sovereign

Inputs: S0062 critic (6.8), QA sweep (no P0-P2, three carried 900x720 P3s), balance (9/9 medians, econ HQ 8/9, nw30 168k -> 106k). Already queued, so not re-proposed: VS-068 tabs, VS-065 900x720 polish (answers the QA P3s). Real-browser pass VS-042 stays blocked on Daniel's egress allowlist; do it before shipping more features.
Out of scope respected (no interiors, boarding, research, diplomacy, manual saves, multiplayer, audio assets).

### Nest cap 135 trial and nw30 gate
- Answers: Balance rec 1 and 3 (economic nw30 168k -> 106k, seed 186 lost at 23.7 min, HQ 8/9); Critic #3
- Pillar: Pacing & difficulty
- Pitch: A weaker player should still reach minute 30 with a fleet and a sense of recovery. Retune the Hive cap growth between 126 and 145 so economic runs keep a margin without letting passive HQ loss drop below 22 min. Fallback if 135 fails the passive gate: Sovereign warship cost -10%.
- Reference: Starsector (difficulty curve keeps a recoverable floor).
- Size: S   Type: balance
- Acceptance criteria:
  - [ ] NEST_CAP_GROWTH 135 tested on 9 seeds passive (no --reserve) and economic: passive earliest HQ loss >= 22 min, median 25-30
  - [ ] Economic HQ survives >= 8/9 (target 9/9) and nw30 median >= 120,000, Q1 >= 90,000
  - [ ] nw30 median and Q1 row added to the balance role target table and metrics.csv
  - [ ] If 135 fails, the warship cost -10% variant is run and the result is recorded; keep whichever passes all gates
- Risks: earliest HQ loss is very seed-sensitive; device runs ~100 s per 3 economic seeds (3-4 seeds per call).
- Why now: the largest measured regression this round, and the gate cannot see it yet.

### Shakedown probe: the first raid arrives early
- Answers: Critic #2 (scripted/active player never meets a raid in the first 99 s; first raid at 196 s), Critic pillars 1 and 6
- Pillar: First 10 minutes
- Pitch: Around 90-100 s a small, telegraphed Hive probe (2-3 ships, one sector from HQ) appears with the existing forecast line, so a new player sees forecast, impact, intercept bounty and Repair HQ inside the opening session. The real first raid stays at 3.3 min.
- Reference: Battlezone '98 (early skirmish teaches the loop); Deep Rock Galactic (first wave is small and scripted).
- Size: S   Type: feature
- Acceptance criteria:
  - [ ] Probe spawns at a fixed time (tunable, ~90 s), reuses raid forecast/track code; HUD shows "Next raid" for it with the existing 60 s forecast
  - [ ] combat_long log shows the probe forecast, a hit or interception, and an honest outcome line before t=99
  - [ ] Balance gate unchanged: first Hive raid still 3-4 min, passive median HQ loss within 25-30, economic HQ >= 8/9
  - [ ] raid_hit shot still passes within its timeout; selftest asserts probe size is capped and saved/loaded state is consistent
- Risks: could shift the passive baseline (re-run both gates); keep tiny so the opening stays calm for touch players.
- Why now: raised in four consecutive reviews; the best systems are invisible in a short session.

### Core collapse and extract beat (surface)
- Answers: Critic #5 (Core dead t=67, then 30 s of nothing, ship 223 m away; min_hp 84), Critic pillar 4
- Pillar: On-foot FPS
- Pitch: When the Core dies the spire collapses with a screen shake and a short countdown; a last Hive wave pours from the breach while a ship-direction marker and distance counter guide you to the extraction. Getting out in time pays a bonus; failing costs hull, not the run.
- Reference: Deep Rock Galactic (objective, then a tense extraction run); Planetside (clear waypoint).
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] Core kill triggers collapse effect, 30-45 s countdown, and a waypoint to the ship that updates distance on keyboard and touch
  - [ ] Counter-attack wave spawns at the breach (capped count, reuses flank spawner); surface_long min_hp drops below 70 on the scripted bot
  - [ ] Reaching the ship in time pays a bonus; missing it applies a defined penalty and never softlocks (QA run: 0 script errors, mission always ends)
  - [ ] Touch layout at 900x720 and 1280x720 keeps the waypoint readable and does not overlap ACT/FIRE buttons
- Risks: touch overlap (VS-065 pending), frame time with extra enemies; keep wave cap at the flank cap.
- Why now: the on-foot payoff is the flattest moment in the game, flagged repeatedly.

### Sovereign's Decree: fortify a sector for 2 minutes
- Answers: Critic "One bold idea" and #3 (surplus credits have no sink; players coast on nw30 106-257k); Backlog parking lot (S0056)
- Pillar: Command depth
- Pitch: Once per run, spend about 25k credits on the command map to declare a sector Fortified for 2 minutes: platforms spawn, Union ships rally and raids turn back, with a proclamation on screen. It is the sovereign fantasy made visible and the first spectacle credit sink. This is the single brand-new system this round.
- Reference: Homeworld (readable fleet surge), X4 (map-order spectacle).
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] Map Orders tab (after VS-068) shows Decree with cost and cooldown; disabled states shown with reason
  - [ ] Cost charged once; platforms/ships spawn using Reserve caps; expiry cleans all entities; mid-decree save/load round trip works
  - [ ] Selftest covers charge, expiry and save/load; harness flag `--decree` for A/B (default bot never uses it)
  - [ ] Economic 9-seed gate with `--decree`: HQ >= 8/9 and nw30 not reduced by more than 10%
  - [ ] Proclamation banner readable at 900x720 and on touch; no new fold-assert failures
- Risks: balance (keep it pricey); depends on VS-068 tabs and VS-061 Reserve spawn/expiry; entity count on web.
- Why now: lands after tabs; gives the economy an end-game sink.

### Map stakes: raid banner and fleet route lines
- Answers: Critic #4 (map ~70% empty, raid line is an 11 px pink line), Critic pillars 7 and 8; QA P3 truncated raid line at 900x720
- Pillar: Command depth
- Pitch: Raids get a large colour-coded banner (inbound / hit / intercepted) at the top of the panel, and the map draws route lines for your fleets and arrows for inbound raids with sector stakes (what each sector holds). The command map finally looks like a place where decisions matter.
- Reference: Homeworld (fleet readability); X4 (route lines on the map); Starsector (sector stakes at a glance).
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] Raid banner uses 14 px or larger text, colour-coded by state, never truncated at 900x720 (shorten text, not font)
  - [ ] Map draws a route line per ordered fleet and an arrow per inbound raid; screenshots raid_map, raid_map_damaged and raid_map_touch reviewed at 1280x720 and 900x720
  - [ ] Pinned strip stays above the fold; fold assert passes; check.sh PASS
- Risks: draw cost on the Compatibility renderer (cap lines, reuse the existing raid track drawing); depends on VS-068.
- Why now: tabs free the space this needs.
