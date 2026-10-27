# S0012 Feature Scout: void-sovereign

Inputs: `S0012-critic.md` (5.5/10), `S0012-qa.md` (sweep), `S0012-balance.md` (8/8 targets met), BACKLOG.md including the Ideas parking lot, DESIGN.md (Out of scope respected), HANDOVER.md, and the S0007 scout. No INBOX items are open.

How these were chosen: S0007 proposals 1 and 2 shipped (VS-017, VS-018). Proposals 3 (ledger) and 4 (honest raids) were parked and are now the critic's #1 and #2 problems for the second review running, so they come back here with tighter criteria instead of as duplicates. Every proposal deepens a system that already exists. None adds a new system, and none touches Out of scope. QA bug 1 (surface stays live under the end screen, P2) is a plain bug fix for the Producer to file directly, so it is not repeated here.

Shared constraint: the sim is chaotic (global `randf()`, universe.gd:30). Any proposal that touches the sim must add **no global `randf()` draws**. Observers and UI must be pure reads. Sim and balance changes are judged only on the 9-seed gates (`balance_gate.sh`).

---

### 1. Credit ledger: cr/min on the HUD, a "last 5 min" breakdown on the map, and tip 4 docks where trading works
- Answers: Critic #1 (Economy legibility 3/10, the floor two reviews running); critic first-10-min note (tip 4 docks at an HQ that "does not trade wares"); parking lot S0007 "Credit ledger" and S0001 "show TRADER_RESERVE".
- Pillar: Economy legibility
- Pitch: Next to my credits I see "+1,480 cr/min". On the map a small panel shows where the last 5 minutes of money came from: mining, trade, stations, bounties, colonies, and minus ships, builds, repairs and respawn. When I add a second miner I watch the mining line grow. The tutorial's dock tip sends me to the Trade Hub, where my first buy and sell actually happens.
- Reference: X4's Empire Overview transaction log (categorised income and expenses per entity); Starsector's monthly income/upkeep breakdown. Borrow the category list and a single rate number, not the full log.
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] Every change to `Universe.credits` goes through one `earn(category, amount)` / `spend(category, amount)` helper. The current direct writes in universe.gd (transact, ship buy, build, colony income, bounty, nest bonus), surface_view.gd:489 and dock_panel.gd:139 are all migrated. A selftest asserts that the sum of all ledger entries equals the credit delta over the 8 simulated minutes (mutation: skip one category → FAIL).
  - [ ] The HUD shows a rolling cr/min (60 s window) next to credits on desktop and touch (`shots.sh combat touch` reviewed).
  - [ ] The map panel shows the last-300 s totals per category, with signs. The +1,483 jump at t≈65 in `combat_long` is attributable to a named category.
  - [ ] The HQ dock panel says in one line how money is made (e.g. "Earn by mining, trading at Hubs, and your stations; HQ sells ships only"). TIP 4 points to the nearest Trade Hub, not the HQ. The headless tip probe (seeds 7/101/118) still reaches tips 5–6 within 5 min.
  - [ ] Balance gate output is byte-identical (ledger is a pure observer, no RNG); check.sh PASS.
- Risks: scope creep into a full log (keep it to ~8 categories in a ring buffer); touch HUD space near the credit line; missing a write site (the selftest sum check catches it).
- Why now: the lowest-scoring pillar for two reviews running, and the deterrent made "buy platforms" the best spend, which nothing on screen tells the player.

### 2. Honest raid reports: track each raid to its end, with ETA on the galaxy inset
- Answers: Critic #2 (raids "moving on Sovereign HQ" never arrive, and no message says why) and #5 (repeated "turned back" spam); QA note (the "Next raid Ns" countdown turns red for raids that will be cancelled); parking lot S0007 "Honest raid reports" and S0011 "merge/throttle turned back".
- Pillar: Pacing & difficulty
- Pitch: When a raid launches I see a magenta marker on the galaxy inset with "ETA 1:20 → Haven's Reach". If the Union breaks it up on the way, I'm told "Raid on HQ broken up in Cinder Belt (5/5 destroyed by Union patrols)". If it really arrives, I get "RAID ARRIVING" and a short alert. A deterred raid is reported once, as a running count: "Platforms have turned back 4 raids".
- Reference: Starsector intel reports (each raid tracked from launch to outcome); Homeworld's fleet-readable sensors view; X4 "under attack" notifications tied to a map marker.
- Size: S   Type: feature
- Acceptance criteria:
  - [ ] Director keeps a `RaidGroup` record per launched raid (ids, target, origin, launch time) and resolves it as exactly one of `arrived` / `intercepted (k/n, by faction)` / `withdrawn`. Selftest: within the 8 simulated minutes every launched raid ends in exactly one outcome message.
  - [ ] Launch messages are worded as intent ("heading for"), not fact. "RAID ARRIVING in <sector>" fires only when ≥1 raider enters the target sector.
  - [ ] The galaxy inset and command map draw each active raid group with its target and an ETA (`shots.sh map` reviewed).
  - [ ] The HUD "Next raid" countdown is hidden or neutral (not red) once the next raid's target is already known to be deterred. Turned-back raids collapse into one counter line, with at most one HUD message per 5 min.
  - [ ] No new global `randf()` draws: both 9-seed gates are unchanged (econ nw20/nw30, passive HQ-lost identical to S0011); check.sh PASS.
- Risks: deciding which faction got the kill (use the last-hit owner already used for bounties); inset clutter late game with 3+ raids (cap the drawn groups at 4).
- Why now: the raid warning is the game's main tension device and it currently lies. Telling the truth costs no balance budget and sets up a later raid redesign (the critic's "visible war fronts").

### 3. Deterrent that defends: range-gated platforms, valid placement, and a deterrable first dreadnought
- Answers: QA P2 bug 2 (a platform 42 km away, or buried inside Ember, still deters raids), QA P3 bug 3 (`build_station` accepts positions inside a planet); Critic #5 (raid-immune turtle); Balance rec 1 (`DREAD_TIME` 900→1200: econ min 37.4k→60.3k, passive unchanged at 33.6) and rec 2 (go-chance floor at 0.25 as the next lever); parking lot S0011 tail-seed collapses.
- Pillar: Command depth
- Pitch: Where I put my Defense Platforms matters. Only platforms that actually cover the target scare a raid off, and I can't hide one inside a planet. Two platforms are still a strong answer, but no longer a guarantee.
- Reference: Starsector's station defences (deterrence comes from fleets in reach, not from presence in the system); X4 station-defence placement, where range rings decide coverage.
- Size: M   Type: balance
- Acceptance criteria:
  - [ ] `Director.raid_go_chance` counts only player Defense Platforms within `RAID_DETER_RANGE` (defs.gd, ~2x platform range) of the target. Selftest: a far platform (30 km) gives go = 1.0; a platform at the HQ gives 0.25.
  - [ ] `build_station` rejects positions within `PLANET_RADIUS` (plus a margin) of `planet_pos` and inside existing station radii, with a HUD message. Selftest: building at `sectors[0].planet_pos` returns null and spends nothing.
  - [ ] `DREAD_TIME` 900 → 1200, adopted only after a 9-seed `--perturb=1` econ gate (balance rec 1).
  - [ ] The floor `maxf(go, RAID_DETER_FLOOR)` is A/B-tested at 0.25 and adopted only if it passes the gates below. Otherwise it is recorded as tried in notes.
  - [ ] Econ 30 min 9-seed gate: nw30 median ≥ nw20 median, nw20 in 80–130k, HQ ≥ 7/9. Passive 40 min 9-seed gate: HQ-lost median 20–35. DESIGN.md Ramp is updated; check.sh PASS.
- Risks: the range check weakens deterrence (balance showed softer variants broke nw30 ≥ nw20), so `DREAD_TIME` is the economy buffer that pays for it. The econ gate runs 154–165 s of the 180 s device cap. If the floor fails, ship range + placement + DREAD_TIME alone.
- Why now: two QA bugs make the VS-020 payoff exploitable today. Balance has a tested, passive-neutral lever ready to pair with the fix.

### 4. First Sortie belongs to the player: escorts hold, scouts come for you
- Answers: Critic #3 (escorts kill the scouts in 15–18 s, before the player aims; DESIGN.md records "all kills by Sovereign fighters"); Critic #2 Flight feel 5 (hull=600 for 95 s, so boost/roll/evasion have no reason to exist); parking lot S0009 (sortie Sfx alert cue; `--shot=sortie` coverage; revert linger hull to 1x).
- Pillar: Flight feel
- Pitch: At minute one three scouts dive at *me*. My wingmen call "Engaging on your mark". They hold for a few seconds or until I fire, so the first kill is mine. If I just sit there, the scouts chip my shields and hull and I learn to boost and roll. My escorts still save me if I'm in real trouble.
- Reference: Freelancer's opening missions (wingmen bracket the target but let the player land the kill); Everspace's early fights, which push you to use evasive movement.
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] All behaviour stays inside the sortie flag (`OpeningWave.allows` / sortie targeting). Escorts don't fire at scouts until the player has fired at a scout or `OPENING_WAVE_HOLD` (defs.gd, ~10 s) has passed since arrival, or the player's hull is below 50%.
  - [ ] Scouts target the player ship first, and their dps against the player is 1.0x (`OPENING_WAVE_DPS` applies to everyone else). Probe seeds 7/101/118 with the pilot firing at the locked target: the player scores ≥1 scout kill in 3/3 and survives in 3/3. With the pilot idle, the player takes hull damage but survives in 3/3.
  - [ ] An alert Sfx (through `Sfx.play()`) plays on scout arrival. A `--shot=sortie` scenario renders the fight, and `shots.sh sortie` is reviewed.
  - [ ] After `OPENING_WAVE_LINGER`, survivors revert to 1x hull (parking lot S0009).
  - [ ] No new global `randf()` draws (any jitter uses the wave rng). Both 9-seed gates stay inside their bands; selftest still asserts once-only spawn and an unchanged raid timer; check.sh PASS.
- Risks: deaths for new touch players (keep the low-hull escort override); balance chaos if the fight length changes kill timing (check against the gates, not 3 seeds).
- Why now: the structure is right (the critic says "protect this, change *who* wins"). This is a small constant-and-targeting change in one file.

### 5. Readable surface: one marker per objective, a Core spire and pylon beams
- Answers: Critic #4 (On-foot FPS 4/10, unchanged since S0007; pylon labels overprint; flat featureless terrain); VS-005 acceptance (folded in, not duplicated); QA re-observed VS-005.
- Pillar: On-foot FPS
- Pitch: When I land on Ember I see a tall magenta Core spire on the horizon and a beam rising from each shield pylon. I know where to go before reading any HUD text. Pylons that line up show as one tidy "2x PYLON 380m" marker, and each beam goes dark when its pylon falls.
- Reference: Deep Rock Galactic (objectives and drop pod readable as world-space light columns); Planetside 2 (objective beacons visible across the map); Battlezone '98 (structures as horizon landmarks).
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] VS-005 criteria: overlapping marker labels are merged or offset. `shots.sh surface touch_surface` shows readable markers.
  - [ ] Each live pylon has an unshaded, procedurally built vertical beam (a mesh, not particles). The Core has a spire mesh that is visible from the landing site. Beams turn off on pylon death and the spire changes colour when the Core is unshielded (`surface.png` reviewed at spawn and after pylons down).
  - [ ] Compatibility renderer only: no new lights or shaders beyond unshaded materials. Under 20 extra draw calls on the surface.
  - [ ] `surface_long` still matches S0007 behaviour (pylons down by about t=50, Core dies by t=60); check.sh PASS.
- Risks: beams through the touch HUD or tip box (draw them in the world, behind the UI); additive transparency cost on low-end phones (use a single opaque emissive quad if needed).
- Why now: this is the lowest-scoring gameplay layer, and the OBJECTIVE points the player at it from second 3. VS-005 alone is too small to change the score.

---

## Not proposed (and why)
- **Redirecting deterred raids** (critic #5 / bold idea): balance A/B broke nw30 ≥ nw20 in 6/9 seeds and Union collapse fell to 27.5. Revisit only after proposal 3 lands and proposal 2 makes raids visible.
- **Early raid that reaches the HQ sector** (critic #2): the passive gate is near its ceiling (33.7 vs 35), so any change to early raids risks it. Proposal 4 adds early danger player-only instead.
- **VS-006 perf guard**: it already exists and is now unblocked; the balance hive_ships_20 tail (61/75) supports doing it next. **VS-007 wing commands** are also already in the backlog.
