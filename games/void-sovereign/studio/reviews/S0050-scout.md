# S0050 Feature Scout: Void Sovereign

Inputs: S0050 critic (6.8/10), QA sweep (P3 only), balance (all OK, two WARN), DESIGN.md (Out of scope untouched), HANDOVER, BACKLOG VS-001..053 + Ideas. INBOX has no open items. Not re-proposed: raid redirect (VS-044, off), repair reserve tuning (critic says no), chip damage retune.

### Raid forecast: see the hit before it lands
- Answers: Critic problem #3 (no pre-raid info) and #2 (new systems never felt); builds on VS-025/VS-039 raid tracks
- Pillar: Command depth
- Pitch: At T-60 s the top bar and the map inset show the incoming raid: ship count, target sector and "~9% hull if unintercepted". The player can choose to fly out, buy fighters, or repair first, instead of reading the damage afterwards in the dock.
- Reference: X4 and Homeworld threat read-outs; Starsector pre-battle strength comparison.
- Size: S   Type: feature
- Acceptance criteria:
  - [ ] At T-60 s before a raid arrives, the HUD shows "RAID: N ships -> <sector>, ~X% hull" with X computed from `RAID_CHIP_PER_SHIP` x N capped at `RAID_CHIP_MAX`.
  - [ ] The same line appears on the map inset marker and in the raid panel; it updates if the raid is thinned in transit.
  - [ ] Forecast is silent for Union targets and for raids the Director has called off.
  - [ ] Selftest asserts forecast percent equals the hull actually lost on an uncontested arrival.
  - [ ] `--shot=combat` (or a new `raid_warn` shot) shows the line at 1280x720 and 900x720 without overlap.
- Risks: HUD crowding on touch (pair with the message-lane proposal); no sim change, so balance is unaffected.
- Why now: Critic ranks this problem #3 and it is the cheapest way to make chip damage legible.

### HQ hull readout and damaged-HQ shot scenarios
- Answers: Critic problem #2 (HQ bar full in `combat.png`, systems unseen); BACKLOG VS-048 follow-up (hq_wounded / dock_wounded shots)
- Pillar: Fantasy
- Pitch: The HQ bar on the HUD shows hull as a number and turns amber below 80% and red below 50%, with a "WOUNDED -x% income" tag once the penalty bites. A scripted `hq_wounded` scenario makes chip, wound and repair visible in screenshots and in the Critic's evidence.
- Reference: Everspace and Elite hull/shield read-outs; Battlezone '98 base-health bar.
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] HUD HQ bar shows "HQ 12,300 / 30,000" (or compact "41%") at all widths down to 900x720.
  - [ ] Colour steps at 80% and 50% match `REPAIR_BELOW` and `WOUND_PENALTY_START`.
  - [ ] `shots.sh void-sovereign hq_wounded` and `dock_wounded` exist, write PNGs, and show the DAMAGED label with a non-clipped "%".
  - [ ] No new script errors in `check.sh`.
- Risks: touch HUD space; the clipped "DAMAGED 88%" label is a known P3 and is fixed here.
- Why now: Eight-plus sessions of wound/chip work still score 6 on Fantasy because the player cannot see it.

### Fleet Reserve call-in (comeback button)
- Answers: Critic problem #1 and "One bold idea" (late collapse is a cliff); balance extra (nw30 Q1 48k, seed 135 HQ loss at 29.7 min)
- Pillar: Pacing & difficulty
- Pitch: Once per 10 minutes, from the map or dock, pay a large lump of credits to call a Union relief squadron to the HQ sector. After losing the fleet at minute 20, the player has a decision to make instead of a slow loss. Needs a new bot policy so the balance gate can prove the path is recoverable.
- Reference: Starsector reinforcement calls; Battlezone '98 emergency drop-ins; Homeworld fleet-in-reserve.
- Size: M   Type: feature (the one new system this round)
- Acceptance criteria:
  - [ ] Button on map and dock: "Call Reserve (N cr)", disabled with a stated reason when on cooldown (10 min) or credits are short.
  - [ ] Spawns a fixed Union squadron (tunables in `defs.gd`: cost, ship count, linger time) at the HQ sector gate; it defends the HQ and despawns or joins Union after the linger.
  - [ ] Ledger shows "Reserve call -X cr" with a source label; selftest covers cost, cooldown, spawn, save/load round trip.
  - [ ] Harness: bot calls the reserve when player+Union warships fall under a threshold after min 18 (`--reserve` flag, default off for A/B).
  - [ ] 9-seed A/B (economic 30): HQ survives >= 8/9 and nw30 Q1 improves over 48,075 with median not below 115k; passive 0/9 unchanged and first 20 min unchanged.
- Risks: could trivialise late raids; keep cost near 15-20% of typical nw20 and tune with the A/B. Web cost is a handful of ships; stay under the Hive-cap web guard.
- Why now: This is the lever the Critic says the repair reserve is not; today's data answers "can I come back?" with no.

### One message lane for touch HUD
- Answers: Critic problem #4; QA P3 (touch surface 900x720 pylon labels overprint, ACT/JUMP/FIRE/RUN crowd); BACKLOG touch layout polish items
- Pillar: Web/touch fitness
- Pitch: Phone players get a single bottom-centre lane where tips, the trade hint, objective and raid forecast queue by priority, and the tip box stays clear of THR-/TGT and the lower-right action cluster. Tips are ordered by what is happening, so "Drag to steer" does not compete with the First Sortie.
- Reference: Everspace and mobile shooters' single-toast lane; Freelancer's one-line context prompts.
- Size: M   Type: polish
- Acceptance criteria:
  - [ ] In `touch.png` at 1280x720 and 900x720, tip box, trade hint and OBJECTIVE never overlap each other or any touch button (checked by the existing fit-to-screen guard plus a rect-overlap assertion in selftest).
  - [ ] Only one of tip / trade hint / objective / raid forecast is shown at a time, with a documented priority (raid forecast > sortie > objective > trade hint > tips).
  - [ ] Surface touch: duplicate pylon waypoint labels are deduped or staggered and do not overlap the crosshair; ACT/JUMP/FIRE/RUN have at least 12 px spacing at 900x720.
  - [ ] Desktop HUD is unchanged.
- Risks: touches `tutorial_hints.gd` and HUD layout; guard with shot diffs. Pairs with the raid forecast, so schedule after it.
- Why now: Phone is the web target and this is the first screen a mobile player sees; two reviews running have flagged it.

### Hive ship guard and harness fleet floor
- Answers: Balance recommendation 1 (Hive ships @20 = 61 economic, q3 61 passive vs guard 60); Critic extra ask (late-game fleet-floor policy)
- Pillar: Pacing & difficulty
- Pitch: Trim the Hive cap or spawn rate in `defs.gd` by about 5% so late fleets stay inside the web performance guard, and add a `--fleet-floor=N` harness policy (keep at least N warships before buying anything else after min 18). Together they show whether seeds 101/135 are recoverable by spending alone, and give the reserve proposal a baseline.
- Reference: Starsector fleet-upkeep tuning; Deep Rock Galactic swarm caps for web-safe counts.
- Size: S   Type: balance
- Acceptance criteria:
  - [ ] Hive ships @20 median <= 60 for economic and passive on 9 seeds; passive HQ-lost earliest seed stays >= 20 min and the median stays within 20-35.
  - [ ] `--perturb=1` still passes; economic HQ survives >= 8/9.
  - [ ] `--fleet-floor` flag documented in DESIGN.md; a 9-seed run with floor N=10 is recorded in metrics.csv and a review file.
  - [ ] One lever changed in `defs.gd`, noted in DESIGN.md.
- Risks: dispersion may move the other way (Q1 48k); run the full gate before committing.
- Why now: Hive count has crept 52 -> 60 -> 61 across three gates and the fleet-floor data is a prerequisite for judging the call-in.

## Suggested order
1. Raid forecast (S), 2. HQ hull readout (S), 3. Hive guard + fleet floor (S), 4. Fleet Reserve call-in (M, needs 3), 5. Touch message lane (M, needs 1).
Unchanged: VS-042 real-browser pass stays blocked on the network allowlist (needs Daniel); not a proposal.
QA P3s not covered above (Score/Best thousands separators in overlay.gd:124; map side panel clip at 900x720) can bundle into any polish session.
