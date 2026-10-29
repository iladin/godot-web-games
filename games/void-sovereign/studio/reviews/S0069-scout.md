# S0069 Feature Scout: Void Sovereign

Inputs: S0069 critic (6.7/10), QA sweep (no P0-P2), balance (9 of 9 medians met), BACKLOG (VS-001..077; todo: VS-076, VS-077; Ideas parking lot checked). Out of scope respected. VS-042 (real browser) remains blocked on egress allowlist; critic #1 is a Daniel ask (manual load-and-play of exported build), not a feature. VS-077 and VS-076 already cover the balance-gate and map-tab follow-ups, so they are not re-proposed.

### Core Defenders: the collapse is a retreat under fire
- Answers: Critic #3 (Core fight toothless, mobs=0 from t=57, min_hp 84); Pillar 4 On-foot FPS; builds on VS-073.
- Pillar: On-foot FPS
- Pitch: As the Core's health drops through thresholds (75/50/25%) it releases a short wave of Hive defenders, and when it dies the collapse sprint to the extraction zone has chasers on your heels. The player wins the Core fight by moving and shooting, then must survive to extract.
- Reference: Deep Rock Galactic (extraction under pursuit); Planetside objective pressure.
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] Core spawns a wave at each of 3 health thresholds (3-5 mobs, existing mob types, capped alive count); no new assets
  - [ ] During the collapse timer 2-4 chasers spawn near the Core and path toward the player
  - [ ] surface_long: min_hp drops below 60 on at least one seed yet the bot still extracts; no softlock; mission still ends within about 25 s of collapse start
  - [ ] Surface L1 bot pylons-down time stays <= 60 s (balance gate); check.sh PASS
- Risks: Compatibility-renderer frame cost on surface (cap mob count); touch players need forgiving aggro; bot may fail extraction, tune one lever only.
- Why now: The collapse beat exists but nothing opposes it; cheapest way to move On-foot FPS past 7.

### Touch Cluster Rehome
- Answers: Critic #5 / Pillar 10 (THR+ on station streak, ATK/ESC/HOLD over planet limb); QA P3 (ACT/JUMP/RUN/FIRE clustered on touch surface); QA P3 900x720 unverified.
- Pillar: Web/touch fitness
- Pitch: On touch, move the throttle and wing clusters off the planet limb and spread ACT/JUMP/RUN away from FIRE with 12+ px gaps and 44 px minimum targets. Re-shoot at 1280x720 and 900x720 so the S0056 findings are confirmed fixed.
- Reference: Freelancer-style thumb-zone layouts; Everspace console-port HUD spacing.
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] touch and touch_surface shots at 1280x720 and 900x720: no touch control overlaps another; gaps >= 12 px; targets >= 44 px
  - [ ] Selftest rect-overlap assert for flight and surface touch layouts
  - [ ] Map side panel at 900x720 shows a scroll cue or fits; check.sh PASS
- Risks: Very short screens (< 650 px height) already cramped; may need per-aspect offsets.
- Why now: Touch is the primary web target and three consecutive reports flag the same overlaps.

### Payback Labels: what does this return?
- Answers: Critic #4 / Pillar 5 (nothing says what Reserve, colony or platform returns); Pillar 6 (30,000 cr wall of choices).
- Pillar: Economy legibility
- Pitch: Every Buy/Build/Reserve button gets a one-line effect: colony "+X cr/min, pays back in ~N min", platform "defends this sector, raids -Y%", Reserve "6 fighters for 180 s". At game start the dock highlights one suggested first spend as a hint, not a lock.
- Reference: Starsector and X4 station-module tooltips with yield and upkeep.
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] Effect line on each Buy, Build and Call Reserve entry, computed from Defs (no hard-coded text that can drift)
  - [ ] Selftest asserts the colony payback figure equals cost / defined cr/min
  - [ ] Lines fit at 1280x720 and 900x720 (fold asserts from VS-043/076 pass); check.sh PASS
- Risks: Map panel already tight (coordinate with VS-076); small text on touch.
- Why now: Economy is balanced but opaque; cheapest pillar to lift.

### Standing Orders on the Sector View
- Answers: Critic #5 (map ~70% empty, no routes or stakes in a calm sector); Pillars 3 and 8.
- Pillar: Command depth
- Pitch: In calm sectors the main map draws standing orders, trader routes and per-sector stake chips (own stations, platform cover, wounded HQ hull) so the map always reads as a living empire. Extends VS-074 route lines from raids to everyday traffic.
- Reference: X4 sector map with trade lanes; Homeworld fleet readability.
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] Player ship orders (patrol/escort/attack) and trader legs draw as thin route lines using the VS-074 renderer, redraw throttled to <= 1 per 0.25 s
  - [ ] Each owned sector shows a stake chip; chips do not overlap sector names at 1280x720 and 900x720
  - [ ] map shot with 20+ ships stays within the VS-006 frame-time guard in a headless run; check.sh PASS
- Risks: Draw cost at late-game ship counts; clutter; touch tap targets.
- Why now: VS-074 provided the renderer; the map is the USP and shows empty rings in calm play.

### Sovereign's Decree (the one new system; previously parked)
- Answers: Critic bold idea and Problem #4 (surplus past ~100k has no sink; economic nw30 median 132k); Pillar 1 Fantasy.
- Pillar: Fantasy
- Pitch: Once per run, spend about 25,000 cr to declare a sector Fortified for 2 minutes: platforms and Union ships rally and raids on it turn back, with an on-screen proclamation. Gives rich players a sink and the moment of feeling like a sovereign.
- Reference: Starsector fleet-wide abilities; Battlezone '98 commander call-ins.
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] Decree button in the pinned map command strip (VS-067), 44 px, disabled with reason when credits < cost or already used
  - [ ] Reuses Fleet Reserve spawn/expiry; raids targeting the sector are cancelled for 120 s; state saved and restored in the autosave dictionary
  - [ ] `--decree` harness flag (off by default); 9-seed economic A/B keeps nw30 median >= 120k and Q1 >= 90k
  - [ ] check.sh PASS with selftest asserts for cost, expiry and save round-trip
- Risks: Strip space; could trivialise late raids if cost too low; must not shift the passive gate.
- Why now: VS-066/068 UI landed and VS-061 Reserve results exist, removing the parking-lot blockers.

## Notes
- Needs Daniel (not a proposal): critic #1, one manual load-and-play of the exported web build until VS-042 is unblocked.
- Suggested priority: Core Defenders, Touch Cluster Rehome, Payback Labels, Standing Orders, Decree.
