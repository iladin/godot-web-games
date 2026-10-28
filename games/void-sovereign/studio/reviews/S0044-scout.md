# S0044 Scout proposals (void-sovereign)

Inputs: S0044 critic (6.7/10, no mover), QA sweep, balance report; DESIGN Out of scope respected (no flag changes). VS-042 (real-browser smoke) and VS-044 already exist in BACKLOG and are not re-proposed. S0037 "Clean prompts" and "Second beat" remain in the Ideas parking lot; not repeated here. Suggested order: 4, 1, 3, 2, 5.

### Low hull bites: a wounded HQ earns and defends less
- Answers: Critic problem 2 (damage has no consequence), critic bold idea, HANDOVER/BACKLOG follow-up "reduced intake below 50% hull"
- Pillar: Economy legibility (deepens VS-048 and the economy)
- Pitch: When the HQ drops below 50% hull its station income and shield recharge scale down with hull %, and the dock and map say so ("Station hull 40%: income -20%, Repair 4800 cr recovers it"). Ignoring a wound now costs more every minute, so paying the repair bill becomes a real decision against buying a Corvette.
- Reference: Starsector (damaged colony/fleet upkeep pressure), X4 (damaged stations lose output).
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] Hull % below 50 applies a linear penalty (cap at -30%) to HQ station income and HQ shield regen, via one Defs constant pair
  - [ ] Dock and map text quote the penalty and the repair cost next to the DAMAGED label
  - [ ] Repair removes the penalty immediately; save/load round-trip selftest covers a wounded HQ
  - [ ] 9-seed gate after the change: economic HQ survives >= 7/9, passive HQ loss median still 20-35 min
  - [ ] check.sh PASS, 0 SCRIPT ERROR
- Risks: Death spiral for early-hit players (critic warns); keep the cap low and never touch the 12k price. Passive loss median 28.9 sits near the edge.
- Why now: Critic named this the highest-leverage fix and the repair sink is already shipped.

### Raids leave marks: chip damage when not intercepted
- Answers: Critic problem 1 (damage never triggers in normal play); balance metric economic HQ survives 9/9
- Pillar: Pacing & difficulty
- Pitch: A raid that reaches the HQ sector without being intercepted chips the HQ hull in proportion to survivors and says so in the raid report ("Raid reached HQ: -1,800 hull"). A competent defender still takes none, but a sloppy one sees a scar and a bill.
- Reference: Battlezone '98 (base attrition when you ignore a front), Starsector (raids with lasting consequence).
- Size: M   Type: balance
- Acceptance criteria:
  - [ ] Un-intercepted raid survivors deal hull damage to the HQ once per raid, tuned so a typical Breach costs 10-25% hull
  - [ ] Raid outcome text includes the hull lost; a new `hq_wounded` shot shows the result on map and dock
  - [ ] 9-seed economic: HQ survives >= 7/9; passive loss median 20-35 min; perturb=1 run not worse on survival
  - [ ] Selftest asserts damage applies once and is zero when the raid is intercepted
- Risks: Balance edge on passive loss; do after proposal 1 is measured or tune together. Touch: no UI beyond existing raid text.
- Why now: Without an organic trigger the new wound system is invisible (3 reviews running).

### Bots repair: close the sink in the balance harness
- Answers: Critic problem 3 (bots never repair); balance report recommends the gate cover VS-048
- Pillar: Pacing & difficulty
- Pitch: The economic bot repairs the HQ whenever hull is below 80% and credits exceed a reserve, so the gate measures net worth with the sink included. Players get tuned numbers instead of guesses.
- Reference: Starsector-style economy tuning against upkeep sinks.
- Size: S   Type: balance
- Acceptance criteria:
  - [ ] Harness economic policy calls `repair_station` when hull < 80% and credits > configurable reserve (default 25,000)
  - [ ] 9-seed gate rerun with the policy: economic nw20 >= 90,000, HQ survives >= 7/9, passive loss 20-35 min; metrics.csv row appended with the session id
  - [ ] Passive policy stays no-repair (control)
  - [ ] check.sh PASS
- Risks: Without proposal 2 no wounds occur, so the policy is unexercised; run it with 1 and 2 in the same round or add a forced-wound control seed.
- Why now: VS-048 balance sign-off is incomplete per the critic.

### Surface freeze at 900-940 px wide
- Answers: QA P2 (surface scenario hangs at 900x720, 900x721, 920x720; touch_surface at 900x720)
- Pillar: Web/touch fitness
- Pitch: Landing on a planet in a browser window around 900-940 px wide runs normally instead of freezing. A shot-driver time guard makes any future hang fail fast.
- Reference: Everspace/Elite planetary approach rely on stable frame pacing; no borrowed mechanic, a stability fix.
- Size: S   Type: tech
- Acceptance criteria:
  - [ ] `RES=900x720`, `920x720`, `900x721` surface and touch_surface shots finish within 20 s with a PNG
  - [ ] Root cause identified and recorded in HANDOVER (viewport-dependent loop in surface/terrain/HUD, or llvmpipe-only with evidence)
  - [ ] shots.sh and the headless selftest runner enforce a wall-clock timeout that fails the run
  - [ ] check.sh PASS; surface_long unchanged (core dead ~67 s)
- Risks: May be llvmpipe-only; if so confirm in the VS-042 real-browser pass and note it. Touch layout is the affected path.
- Why now: A P2 freeze on a plausible real window size outranks polish.

### Say what money did: signed deltas with a source
- Answers: Critic problem 4 (unlabelled delta; repair will show as one); QA P3 (Hull 100% / Station hull 100% buttons read as unavailable actions); balance-neutral
- Pillar: Economy legibility
- Pitch: When a sale, bounty or repair lands, a short fading line next to the net rate shows "-4800 repair" or "+150 sale" for about 2 s. At full hull the dock repair rows read as plain status text, not greyed buttons.
- Reference: X4 and Starsector transaction logs (rate separate from one-offs); Homeworld minimal HUD deltas.
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] Every `CreditLedger` entry above 100 cr triggers a signed delta with its category word, fading in ~2 s, never replacing the net rate
  - [ ] Repair purchase shows a negative delta in a neutral colour
  - [ ] Dock rows for ship and station hull at 100% render as status labels (no button styling)
  - [ ] 1280, 900 and touch layouts pass the text-fit guard; selftest asserts delta text
  - [ ] check.sh PASS
- Risks: Top bar width on touch; stacking when sales are rapid (cap at 2 lines).
- Why now: VS-047 made the rate honest; one-off deltas are the missing half and repair spending makes it matter.
