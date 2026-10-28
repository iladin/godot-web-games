# S0037 Feature Scout: Void Sovereign

Not re-proposed (already in BACKLOG): VS-041 surface checkpoint, VS-042 real-browser smoke, VS-043 raid panel fit, VS-044 redirect harness, VS-045 flank costs on-foot hp. Critic problem 1 is answered here for the space/station side; VS-045 covers the on-foot side. Critic problem 5 = VS-042 (do it before more tuning). No Out of scope changes needed.

### Station wounds that stay wounded
- Answers: Critic problem 1 + "One bold idea" (persistent war damage); parking lot S0003 QA (dock repair is free/uncapped); balance: econ HQ survives 9/9, nw30 < nw20 in 3/9 (late-game attrition already a lever)
- Pillar: Pacing & difficulty (secondary: Command depth)
- Pitch: When a Hive raid reaches one of my stations and I did not intercept it, the station keeps its lost hull instead of regenerating, and its output (trade/ore intake) drops until I pay repair credits or park the wing there. A raid I ignore now costs me something I can read on the map, so Defend/Intercept becomes a real decision rather than a countdown that rarely bites.
- Reference: X4 (station damage and repair as an economic cost), Starsector (persistent fleet damage and repair cost).
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] Station hull damage from a raid persists (no free regen above a floor) until repaired; map and dock show "Hull NN%" and a Repair button with a credit cost from Defs
  - [ ] A station below 50% hull has reduced intake (value in Defs) and shows a damaged marker on the map
  - [ ] Repair costs credits (uses REPAIR_COST path; dock repair for ships no longer free/uncapped for ships on manual orders)
  - [ ] Save/Continue round-trips station hull (selftest asserts)
  - [ ] Balance gate: HQ survives 30 min >= 6/9, passive HQ lost 20-35 min, nw20 >= 90,000; ships@20 <= 60 in economic
  - [ ] A scripted ignored raid in a headless run drops a station hull and the ledger/map reflects it; 0 SCRIPT ERROR; check.sh PASS
- Risks: Balance spiral (damage plus lower income); keep floor at 25% hull and repair cost small. Save format bump. No perf impact.
- Why now: every tension device resets, and a repair cost gives the raid tracks (VS-039) and bounty (VS-036) an economic reason to matter.

### Tips follow the threat
- Answers: Critic problem 2 (tip 1/6 "capture the mouse" over the first fight); HANDOVER open question on scout fight 8 s after takeoff
- Pillar: First 10 minutes
- Pitch: When a hostile is inbound within a few seconds of takeoff, I see "lock target / fire" first, with the capture-mouse line merged into it, instead of reading about steering while a drone shoots me. On touch the same order applies using the touch wording.
- Reference: Everspace and Freelancer tutorials (teach the verb the screen demands right now); Battlezone '98 contextual hints.
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] If a hostile is within TIP_THREAT_RANGE when tip 1 would show, the tip shown is lock/fire; steering tip follows after the first kill or 20 s
  - [ ] Tip never sits over the pressured shield bar; one voice on screen preserved (VS-017)
  - [ ] Selftest covers the ordering; `combat` shot at T+00:03 shows the new tip text
  - [ ] First contact timing (t~11) unchanged; check.sh PASS
- Risks: Touch layout overlap with the tip box; tutorial state machine edge cases when tips are skipped.
- Why now: the hot opening shipped in VS-038 and the tip order was never revisited.

### Honest top-bar income
- Answers: Critic problem 3 (unlabelled "+150 cr" is a one-off sale); HANDOVER carry-over (top-bar HUD rate gross); Critic recommendation "net, labelled"
- Pillar: Economy legibility
- Pitch: The number I stare at all game says "NET +NNN cr/min" once there is enough data, and shows a short fading "+150" delta when a sale lands, so I can tell a rate from a one-off. It matches the wording of the map ledger.
- Reference: X4 and Starsector money readouts (rate separated from transactions); Homeworld-style minimal HUD deltas.
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] Top bar shows "net N cr/min" using `CreditLedger.net_per_min`, hidden for the first 15 s (VS-035 item not duplicated)
  - [ ] One-off earnings show as a transient delta (about 2 s) and never as the rate
  - [ ] 1280, 900 and touch layouts: no clipping or overlap (text-fit guard passes)
  - [ ] Selftest asserts label wording matches ledger; check.sh PASS
- Risks: Top-bar width on touch; a negative net may alarm early players (use neutral colour).
- Why now: ledger net/gross shipped in VS-040, and the HUD is now the one dishonest readout.

### Clean prompts: capture bar, wing column, title controls
- Answers: Critic problem 4; QA P3 (title FLIGHT line orphan "travel · M", map HQ square hidden by player/escort icons); parking lot touch layout polish
- Pillar: Readability & UX
- Pitch: "Click to capture mouse" lives in one fixed bottom bar instead of floating mid-screen, the touch wing column has an opaque backing and no longer sits on the planet limb or station silhouette, the title controls paragraph wraps without a widow, and the HQ marker stays visible under the player icons.
- Reference: Deep Rock Galactic and Elite Dangerous (fixed, quiet prompt rails); Homeworld (clean fleet-command readability).
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] Capture prompt anchored to a bottom bar on surface and flight at 1280x720 and 900x720
  - [ ] Touch wing column has a backing panel, no overlap with THR+ or the MOVE pad (shots touch, touch_surface)
  - [ ] Title FLIGHT line has no single-word last line at 1280 and 900
  - [ ] Map HQ marker remains visible when player/escort icons are over it (offset or draw order)
  - [ ] Text-fit guard passes; check.sh PASS
- Risks: Touch layout regressions; keep to existing layout helpers. Overlaps VS-043 only in the touch panel, so do after it if both are in flight.
- Why now: capture prompt has been flagged five reviews running and is the first thing a new player sees.

### Second beat: the Union convoy under fire
- Answers: Critic "Open" (nothing happens t=45..75, credits flat at 30,450) and Critic problem 1 (every tension device resets); Pillar: Fantasy gap (HQ not threatened by an active player)
- Pillar: First 10 minutes
- Pitch: Around 40 s after the first sortie dies, a small Hive group hits a Union freighter near Ember and a "Convoy under attack" call appears with a marker; if I reach it and kill them I earn a bounty and reputation credit, and if I ignore it the freighter dies and my trade income dips briefly. The opening becomes two fights with a choice instead of one fight and a lull.
- Reference: Freelancer (distress calls on the flight path), Everspace (scripted early escalation with a reward).
- Size: S   Type: feature
- Acceptance criteria:
  - [ ] Once per run, `OPENING_BEAT2_DELAY` (Defs) after the First Sortie ends, a freighter and `BEAT2_SIZE` Hive units spawn in the home sector with a HUD message and map/world marker
  - [ ] Killing all attackers pays a bounty through the ledger category used by VS-036; ignoring them costs the freighter only (no HQ damage), no raid timer or `raid_count` change (first raid stays 3.3 min)
  - [ ] Unit counts stay inside VS-006 guard (ships@20 <= 60) in the balance gate; passive HQ lost still 20-35 min
  - [ ] `combat_long` shows a second shield dip between t=45 and t=90 with hull untouched or a clear reason; 0 SCRIPT ERROR; check.sh PASS
  - [ ] Touch: marker readable, no new buttons
- Risks: Harness hides the pilot so the beat never spawns there (parking lot S0031); keep it pilot-gated and out of the gate numbers. Scope creep into a mission system, so one scripted instance only.
- Why now: the hot opening ends at t=45 and the critic found 30 s of nothing after it.
