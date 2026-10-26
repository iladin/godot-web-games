# S0007 Feature Scout: Void Sovereign

Inputs: `S0007-critic.md` (avg 5.1, baseline), `S0007-qa.md` (sweep), `S0007-balance.md`, DESIGN.md (Out of scope respected), HANDOVER.md, BACKLOG.md incl. parking lot. INBOX is empty.

Not re-proposed because they already exist or belong to QA/Producer: VS-011 tuning (the balance recommendations stand as-is), VS-005 pylon labels, VS-013 tip box vs steer zone, VS-014 pause input, QA bugs (title-screen sim, Trade Hub arbitrage, map softlock on end screen, station inside planet). Where a proposal depends on one of these, it says so.

Mix: 4 deepen existing systems (tips, raids/director, credits, fleet orders), 1 new scripted event (First Sortie). Nothing touches Out of scope.

### 1. Tips follow the world, one voice on screen
- Answers: Critic problem #1 (tip 3 is impossible at home, so tips 4–6 never show) and #3 (five directives at t=3 s, tip order contradicts the OBJECTIVE); QA P2 "tip 3 blocks tips 4–6"; parking lot "tip 1 duplicates the capture HUD line" (folded in here).
- Pillar: First 10 minutes
- Pitch: The tip I see is always something I can do right now, and it leads me toward the objective bar instead of fighting it. If I press R with nothing to lock, the game tells me why instead of doing nothing. While a tip is up, it is the only instruction in the centre of the screen.
- Reference: Freelancer's opening, where each prompt is triggered by the situation (an enemy appears, then "target it") and never asks for something the world can't provide; Homeworld's single centred mission prompt.
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] `TutorialHints.current()` returns the first unfinished step whose precondition holds; "target" is eligible only when a Hive ship is in the player's sector, so a missing precondition no longer blocks later tips (selftest: with 0 Hive in sector, after steer+throttle the current tip is not "target")
  - [ ] Step order leads toward the OBJECTIVE: steer → throttle → land on Ember → map → dock, with "target" inserted whenever a Hive contact is in-sector
  - [ ] Pressing R / TGT with no Hive contact in the sector shows "No Hive contacts in sector" (HUD message), in flight only
  - [ ] While a tip is shown, the HUD's contextual prompt ("F: Dock at…") and "Click to capture mouse" line are hidden; `shots.sh void-sovereign hints hints_touch` show one instruction in the centre
  - [ ] check.sh PASS (existing `_test_hints` / `_exercise_hints` updated, not deleted)
- Risks: Scope creep into VS-013 (touch overlap): keep that task separate. If First Sortie (#2) lands, "target" will become eligible at about minute 1, so build #1 first; it must work with or without #2.
- Why now: the tutorial built in S0006 currently stalls for most players on tip 3, so the guided start isn't doing its job.

### 2. First Sortie: a small opening wave from Ember orbit
- Answers: Critic bold idea; critic problem #2 (no threat in the first 10 minutes, hull 600/600 for 95 s) and #1; Pacing & difficulty 4/10.
- Pillar: First 10 minutes (also Fantasy, Pacing & difficulty)
- Pitch: About a minute after I launch, three Hive drones rise out of Ember's orbit and come for me. My two escort fighters engage, I learn to lock on (R/TGT) and send my wing in (G), and once the wave is down the game says "Ember's Core is exposed: land (F/ACT)". It's a three-minute fight that teaches flying, targeting, fleet command and landing in the order the objective asks.
- Reference: Battlezone '98 mission openers, which put a small scripted skirmish in your face right away before the RTS layer opens up; Homeworld's first mission, which teaches by example with a beatable attack.
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] `director.gd` spawns a one-time "first sortie" (constants in `defs.gd`, e.g. `FIRST_SORTIE_T` 60 s, `FIRST_SORTIE_SIZE` 3, drone class) near Ember in the HQ sector, ordered to attack the player ship, with a HUD message "Hive drones launching from Ember orbit"
  - [ ] Headless probe or selftest: from launch, ≥ 1 Hive ship is in the HQ sector between t=60 s and t=120 s, and with no player input the starting escorts destroy the wave by t ≤ 240 s (seeds 7/101/118)
  - [ ] In a `--shot=combat`-style run the player hull drops below max at least once but the player doesn't die with no input (the wave is beatable, not lethal)
  - [ ] When the wave is destroyed, the message "Wave cleared. Ember's Core is exposed: land (F/ACT)" appears (ACT wording on touch)
  - [ ] Balance gates still hold: `balance.sh` passive 40 min × 3 → HQ lost 20–35 min; economic 30 min × 6 (with the seed offset) → nw20 and HQ survival within the VS-011 bands. Record before/after in the task notes
  - [ ] check.sh PASS; `--autoplay` passes through or past the wave without errors
- Risks: Depends on QA bug "sim runs behind the title" being fixed first, or the wave fires while the player reads the controls. It shifts the early economy slightly (bounties of about 150 cr each), so coordinate with VS-011 and change one variable at a time. Touch players need to be able to beat it with the escorts alone.
- Why now: the opening is the weakest stretch (5/10) and this one event fixes the critic's problems 1–3 together.

### 3. Credit ledger: cr/min and where it came from
- Answers: Critic problem #4 (no income readout, +1,553 cr jump with no visible cause), Economy legibility 3/10 (the lowest pillar).
- Pillar: Economy legibility
- Pitch: Next to my credits I see "+1,240 cr/min", green or red. On the map panel a small breakdown for the last minute shows Trade +900, Mining +410, Bounties +150, Ships −4,500, so when credits jump I know why. Docked at HQ, one line tells me how to start earning.
- Reference: X4's Player Information → Financial report (income by source), shrunk to a Starsector-style one-line rate in the HUD.
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] Every change to `Universe.credits` goes through one function such as `earn(category, amount)`, with categories trade, mining, stations, bounty, nest, colony, purchase, build, repair and respawn. Selftest: after an 8-minute sim the sum of the ledger equals the credits delta (±1 cr)
  - [ ] The ledger keeps a rolling 60 s window; the HUD shows a signed cr/min next to credits (green ≥ 0, red < 0), readable at 1280x720 and in the touch layout
  - [ ] The map side panel shows the last-60 s breakdown, with non-zero categories only, sorted by size
  - [ ] HQ dock panel adds one line: "Earn credits: trade at a Trade Hub, send miners to auto-mine, or build stations (map)"
  - [ ] `shots.sh void-sovereign map dock touch` reviewed; check.sh PASS
- Risks: Small per-frame cost (keep fixed buckets, e.g. 12 × 5 s, with no allocation per tick); HUD space on touch. Fix the QA Trade Hub arbitrage bug first or alongside, so the ledger doesn't advertise the exploit. universe.gd is 451 lines: put the ledger in its own small script (`scripts/sim/ledger.gd`).
- Why now: it's the lowest-scoring pillar, and it also lets players (and the critic) feel whether the VS-011 balance changes worked.

### 4. Honest raid reports: track a raid until it ends
- Answers: Critic problem #2 ("moving on Sovereign HQ" warnings for raids that die in Cinder Belt teach the player to ignore the main tension device); critic Pacing & difficulty 4/10.
- Pillar: Pacing & difficulty (also Readability & UX)
- Pitch: When a raid is announced, the map shows it as a magenta group arrow with its target and position. When it's stopped somewhere else I get "Raid on Sovereign HQ intercepted in Cinder Belt (5/5 destroyed)". When it actually enters my home sector I get a red "RAID ARRIVING: Haven's Reach". Warnings mean something again.
- Reference: Homeworld/Starsector fleet readability, where an incoming enemy fleet is a tracked map object with intent; X4's "station under attack" vs "enemy sighted" distinction.
- Size: S   Type: feature
- Acceptance criteria:
  - [ ] Each raid gets an id stored on its ships; the director tracks remaining members per raid
  - [ ] When all members of a raid are dead or withdrawn, the message "Raid on <target> intercepted in <sector> (k/n destroyed)" or "Raid on <target> withdrew" is emitted exactly once (selftest with seed 7: raid 1 produces one intercept message by t=300 s)
  - [ ] When the first raid member enters the target's sector, "RAID ARRIVING: <sector>" is emitted once, in red
  - [ ] The map galaxy inset marks sectors containing an active raid with its target name; `shots.sh void-sovereign map` reviewed
  - [ ] check.sh PASS
- Risks: Message spam in the late game (raids every 75 s): merge messages for multiple raids, and cap at one intercept message per 10 s. A tiny amount of extra state per ship.
- Why now: once First Sortie (#2) makes the early game dangerous, raid warnings need to be trustworthy too; it's cheap and builds on director code that already exists.

### 5. Standing reinforcement order at HQ (keep N fighters)
- Answers: Balance §3 diagnosis for VS-011 (an economic player hits 14 ships before minute 10, then never replaces losses: ships go 14 → 0–6 and nw falls in 5/6 seeds); balance recommendation 3 ("give the policy a late-game sink: replace lost fighters"); Command depth 6/10.
- Pillar: Command depth (also Pacing & difficulty)
- Pitch: On the map I set "HQ guard: keep 6 fighters". When raids kill one, HQ's shipyard queues a replacement as soon as I can afford it above my reserve, so my late-game credits turn into a defence that holds instead of piling up while the fleet melts.
- Reference: Starsector's fleet replacement and X4's "restock subordinates" order on a commander, a standing order the player sets once and the economy then feeds.
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] Map panel control (keyboard and touch tappable) sets an HQ guard target of 0–12 fighters (default 0 = off, so nothing changes for players who ignore it)
  - [ ] While the count of player fighters on HQ patrol is below the target and credits − `TRADER_RESERVE` ≥ fighter cost, HQ buys one fighter at most every `REINFORCE_COOLDOWN` s (defs constant) and assigns it to HQ patrol; the purchase shows a HUD message (and a ledger "purchase" line if #3 exists)
  - [ ] Selftest: with target 4, after the sim kills 2 guard fighters and credits are sufficient, the count returns to 4 within the cooldown bound; with credits below reserve, no purchase happens
  - [ ] The economic balance policy uses the order (target 8). Record the nw30/nw20 medians before and after in VS-011's notes; the passive policy is unchanged
  - [ ] DESIGN.md Command layer row updated; check.sh PASS
- Risks: Overlaps VS-011's harness work. Ideally done as part of VS-011, or right after its seed-offset item, so the measurement is clean. Map panel space on touch. If combined with smoothing the Hive ramp, change one lever per balance run.
- Why now: the late-game slide is the top P1, and balance found that half of it is "the player has no way to turn money into lasting defence".
