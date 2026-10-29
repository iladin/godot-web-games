# S0056 Scout proposals: Void Sovereign
Deduped against VS-001..VS-062 and the parking lot. VS-061 (Reserve A/B) and VS-062 (button placement) already exist and are not re-proposed. Out of scope respected. Real-browser pass (VS-042) stays a Daniel item (allowlist), not a proposal.

### Command strip: raid actions pinned, buy/build in tabs
- Answers: Critic #3 (and #1, #7); QA P3 map panel clipped at 900x720; parking lot S0050/S0013/S0031 map-panel fold items
- Pillar: Command depth (and Readability & UX)
- Pitch: When a raid is inbound, the player sees one fixed strip on the command map with forecast, ETA, Call Reserve (with ship count, linger time, cost) and Repair HQ. Buy ships, Build and Orders become three tabs, so nothing important scrolls off the bottom and the map reads as a command screen.
- Reference: Homeworld/X4 map side menus (tabbed, context actions always visible); Starsector fleet screen.
- Size: M   Type: polish
- Acceptance criteria:
  - [ ] map_view side panel has a fixed top strip (forecast, Call Reserve, Repair) that never scrolls; Buy/Build/Orders are tabs, keyboard + touch selectable
  - [ ] Call Reserve button >= 44 px high and fully on-screen at 1280x720 and 900x720 in map, raid_map, raid_map_touch shots (extends VS-043 fold assert to cover this ordering)
  - [ ] Reserve button text states ship count and linger time; disabled state shows the refusal reason (cooldown/credits)
  - [ ] check.sh PASS; no sim change (balance gates byte-identical)
- Risks: map_view.gd size (split into a tab helper); touch hit targets; keep VS-062 scope merged in, not duplicated.
- Why now: Reserve is built but buried; this makes it findable exactly when raids matter.

### Raid-hit proof run: scripted "first raid lands" scenario
- Answers: Critic #2 (hull 600 / HQ 100% in every scripted run, 3rd review in a row)
- Pillar: Fantasy (and Pacing & difficulty)
- Pitch: A `raid_hit` shot/long-run scenario fast-forwards to the first Breach, lets it land on an unattended HQ, then shows forecast, HQ hull readout, chip damage and a Call Reserve response in sequence. The team (and Critic) finally see the headline systems from S0043-S0055 working, instead of inferring them from code.
- Reference: Homeworld/Everspace automated demo flights; Battlezone '98 scripted set-piece testing.
- Size: S   Type: tech
- Acceptance criteria:
  - [ ] `shots.sh void-sovereign raid_hit` renders at least 3 frames (forecast, impact with HQ <100%, Reserve arrived) at 1280x720 with no script errors
  - [ ] A headless `raid_hit_long` log prints HQ hull %, reserve ships alive and credits at 30 s steps; HQ hull < 100% at some step; no softlock
  - [ ] Added to the shot list in HANDOVER; check.sh unaffected (not part of it) and PASS
- Risks: scenario must not touch gameplay RNG or balance harness; runtime under device limit (single call < 175 s).
- Why now: three reviews running have scored Fantasy/Pacing without ever seeing a raid land.

### Sovereign's Decree: fortify a sector for 2 minutes
- Answers: Critic bold idea and #4 (economy too generous at the top: nw30 median 168k, start 30,000 cr); Balance extra row (nw30 168k)
- Pillar: Fantasy (and Economy legibility)
- Pitch: Once per run (cooldown-gated later), the player pays a large sum on the command map to Fortify one owned sector: a proclamation banner shows, a ring of temporary defense platforms and Union ships appear, and raids aimed there turn back for 2 minutes. It gives rich players a visible, dramatic credit sink and makes the rising-sovereign fantasy readable.
- Reference: Starsector fleet-command big-ticket orders; Battlezone '98 commander calls; reuses the Fleet Reserve spawn/expiry code (VS-059) rather than new simulation.
- Size: M   Type: feature   (the one brand-new system this round)
- Acceptance criteria:
  - [ ] Map action "Decree: Fortify <sector>" with cost in defs.gd (tunable, start ~25,000 cr), refusal reasons like reserve_refusal, once-per-run flag saved/loaded
  - [ ] While active, Director raid_go_chance for that sector is 0 and N temporary platforms exist; all expire at 120 s with a "Decree ends" message; no kills credited on expiry
  - [ ] On-screen proclamation banner (single message lane, touch-safe) at activation; dock/map show remaining time
  - [ ] Selftest: cost charged once, save/load round trip mid-decree, expiry cleans entities; economic 9-seed gate: HQ >= 8/9 and nw30 not reduced > 10% (bot never uses it by default; harness flag `--decree` for A/B)
- Risks: perf (platform count capped, reuse reserve caps); depends on VS-061 and command strip for UI placement; balance (keep sink pricey, evaluate with --decree A/B).
- Why now: economy is easy for competent players; this is the first credit sink with spectacle.

### Passive Hive cap trim (guard the earliest HQ loss)
- Answers: Balance metric "Hive ships @20 passive 60 (q3 65) WARN" and recommendations 1-2 (earliest passive HQ loss 21.1 min vs floor 20)
- Pillar: Pacing & difficulty
- Pitch: The Hive grows a touch slower when the player has almost no fleet, so a passive player is not erased close to the 20-minute floor while an active player's pressure stays unchanged.
- Reference: Starsector/Homeworld rubber-banded enemy escalation (slow growth against a collapsed player rather than harder raids).
- Size: S   Type: balance
- Acceptance criteria:
  - [ ] defs.gd Hive t/126 cap lowered ~5-8% (or spawn slowed while player fleet < 3 ships); constants commented with the S0056 balance reference
  - [ ] 9-seed passive: hive_ships_20 median <= 58 and q3 <= 62; HQ lost median stays 20-35 min, earliest >= 22 min
  - [ ] 9-seed economic: HQ >= 8/9, nw20 median >= 90,000, hive_ships_20 median <= 60; metrics.csv row appended, DESIGN Ramp bullet updated
- Risks: easing the cap may push passive HQ loss past 35 min; run seeds single-call under timeout 175; do not strengthen raid damage.
- Why now: cheap, and the only open balance WARN in S0056.

### 900x720 touch and panel polish bundle
- Answers: QA S0056 sweep bugs P3 x3 (touch surface button cluster, map panel clip, over.png "Best" collision); Critic #7/#10 (THR+ over station, wing buttons on planet limb)
- Pillar: Web/touch fitness
- Pitch: On a small touch window the on-foot ACT/JUMP/RUN/FIRE buttons sit apart with distinct hit targets, the gun model no longer hides under them, and the game-over "Best" line is readable. Fewer mis-taps on the first-impression platforms (phone/tablet browsers).
- Reference: Deep Rock Galactic / Call of Duty Mobile thumb-zone layouts; Freelancer's uncluttered HUD.
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] touch_surface at 900x720: ACT/JUMP/RUN/FIRE rects do not overlap (assert min gap >= 12 px in selftest) and the gun model is offset clear of the cluster
  - [ ] over.png "Best" line does not overlap the ship model at 1280x720 and 900x720
  - [ ] Map side panel at 900x720 shows a visible scroll cue (fade or "more" chevron) when content is clipped
  - [ ] Shots re-rendered at 1280x720 and 900x720 with no regressions; check.sh PASS
- Risks: touch layout in hud code is cramped; run VS-043 fold assert after any map UI change. Overlaps with the command strip task on the map panel: do polish items there after it lands.
- Why now: three QA P3s with a common fix, and touch fitness has the lowest verification coverage.
