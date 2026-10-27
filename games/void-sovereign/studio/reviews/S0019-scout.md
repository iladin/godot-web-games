# S0019 Feature Scout: Void Sovereign

Inputs: S0019 critic (6.1/10), QA sweep (no P0-P2), balance (all targets OK, perturbed tail thin). BACKLOG checked: VS-025..028 exist and are NOT re-proposed (VS-025 raid reports, VS-026..028 save). Proposals 1 and 4 build on VS-025. Out of scope respected (save-anywhere is covered by Daniel-restored VS-009 split).

### The Breach: one early raid really reaches the HQ
- Answers: Critic #1 (HQ never threatened, raids are false alarms); Pillar 1 Fantasy 6, Pillar 9 Pacing 5
- Pillar: Fantasy / Pacing & difficulty
- Pitch: Around minute 6-7 a small, telegraphed Hive raid (4-6 raiders, no dreadnought) is guaranteed to jump into the home sector and strike the HQ. The player sees it coming on the map, scrambles the wing (ESC/ATK), and wins or loses a slice of HQ health. After that, raids resume their normal chance rules.
- Reference: Battlezone '98 (base under attack mid-mission), Starsector (first real fleet engagement as a lesson).
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] A scripted raid (constants in defs.gd) spawns in the HQ sector between 5:30 and 7:30 in 9/9 balance seeds, regardless of platform deterrence
  - [ ] HQ takes damage if the player does nothing, and a player with wing + 1 platform repels it with HQ >= 70% (selftest or balance probe)
  - [ ] 9-seed econ gates unchanged within target (nw20 >= 90k, HQ survives >= 6/9, passive HQ lost 20-35 min), plus --perturb=1 run reported
  - [ ] Raid warns once ("RAID ARRIVING in X") using VS-025's reporting if landed; check.sh PASS
- Risks: Moves chaos-sensitive balance numbers; touch not affected; perf low (small raid).
- Why now: Third review in a row that raids never arrive; the countdown HUD now promotes a promise the game breaks.

### First Sortie belongs to the player
- Answers: Critic #2 (escorts win the first fight, hull=600 for 95 s); parking-lot S0012 scout item
- Pillar: Flight feel / First 10 minutes
- Pitch: In the opening sortie the scouts focus the player at full damage and the escorts hold fire for the first few seconds. The player must boost, roll and use the new wing commands, and a hull dip is normal. Survivors revert to 1x hull after the linger.
- Reference: Freelancer's first dogfight, Everspace (early pressure that teaches evasion).
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] `--shot=combat_long` shows player hull below 600 at least once before t=95 in the default scenario, and never below 150 with an idle player
  - [ ] Escorts engage scouts only after SORTIE_ESCORT_DELAY (constant) or when the player's target is set via G
  - [ ] Scouts revert to 1x hull on unmark (fixes S0009 QA P3)
  - [ ] Arrival cue plays once (Sfx); new `--shot=sortie` added to shots.sh; check.sh PASS; balance gates unchanged
- Risks: Could frustrate touch players; keep damage tuned for touch accuracy.
- Why now: Flight feel has been stuck at 5 across two reviews with no change to this path.

### Readable surface: Core spire and pylon beams
- Answers: Critic #3 (On-foot FPS weakest, flat terrain, no landmark); QA surface_long
- Pillar: On-foot FPS / Visual identity
- Pitch: From the landing site the player sees a tall glowing Core spire on the horizon and a vertical beam over each shield pylon, so the objective is read by sight rather than by "PYLON 366m" text. Pylon death collapses its beam; the Core spire pulses when exposed.
- Reference: Planetside / Deep Rock Galactic objective beacons; Battlezone landmarks.
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] Core spire mesh and per-pylon beam (procedural, unshaded, no new textures) visible in `shots.sh void-sovereign surface` at >= 600 m
  - [ ] Beam disappears when its pylon dies; spire changes colour/pulse at "Core exposed"
  - [ ] Marker labels gain a dark outline (backlog S0014 contrast item)
  - [ ] surface_long timings stay: pylons down <= 60 s, core dead <= 65 s; Compatibility renderer, no extra lights, check.sh PASS
- Risks: Cheap additive meshes; keep transparency minimal on mobile.
- Why now: The win condition runs through surface Cores and that layer has not changed since S0007.

### Deterred raids redirect to the Union
- Answers: Critic #4 and bold idea; Balance perturb tail (nw30 < 90k in 4/9 perturbed seeds); backlog S0011 deterrent note
- Pillar: Command depth / Pacing & difficulty
- Pitch: When platforms deter a raid on the HQ, the raid redirects to the nearest Union station instead of vanishing. The player can send the wing to intercept for a bounty (ledger category), accept the Union's loss, or lose a trade partner. A turtled HQ is no longer pressure-free.
- Reference: X4 (fleets hit what is undefended), Homeworld/Starsector (threat shifts to weaker targets).
- Size: M   Type: balance
- Acceptance criteria:
  - [ ] A deterred raid retargets a Union station; the HUD/map message names it (reuses VS-025 wording)
  - [ ] Intercepting a redirected raid pays a bounty via `Universe.add_credits(amount, "bounty")` (ledger stays sole writer)
  - [ ] 9-seed econ and --perturb=1 gates: HQ survives >= 6/9, nw20 median >= 90k, perturbed nw30 < 90k seeds <= 3/9, passive HQ lost still 20-35 min, hive_20 q3 <= 61
  - [ ] Selftest asserts redirect target is a Union station and not a player asset in the deterring sector
- Risks: Balance chaos (re-run gates after each change); depends on VS-025 being merged first.
- Why now: Balance shows the thin tail and the critic scores Pacing 5.

### First-minute touch and UX bundle
- Answers: Critic #5; QA P3s (RUN/JUMP overlap, wing row over labels, map fold at 900x720, stale shot PNGs, HQ label)
- Pillar: Readability & UX / Web/touch fitness / First 10 minutes
- Pitch: Phone players get an input-aware OBJECTIVE ("tap ACT to land"), a one-line "how to earn" hint on the HQ dock, a wing row that no longer overprints world labels, separated RUN/JUMP hit areas, and the command map's BUY/BUILD controls above the fold.
- Reference: Freelancer's clean HUD; Homeworld fleet-panel readability.
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] Touch OBJECTIVE and HQ dock text use ACT wording and an earn hint; screenshot reviewed at 1280x720 touch
  - [ ] RUN and JUMP circles do not intersect; wing row moved off world labels (new `--shot=touch_wing`)
  - [ ] Map side panel keeps BUY SHIPS/BUILD STATION visible at 900x720 without scrolling
  - [ ] shots.sh fails (non-zero) if the PNG is stale; check.sh PASS
- Risks: Touch layout regressions; verify at 1280x720 and 900x720.
- Why now: Cheap fixes in the first 60 seconds on the platform where many web players land; bundles four P3s that keep recurring.
