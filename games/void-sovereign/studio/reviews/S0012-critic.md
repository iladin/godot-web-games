# S0012 Critic review: Void Sovereign

_Second critic review. Compared with `S0007-critic.md` (5.1/10). Build: HEAD after S0011 (VS-015..VS-021 done since S0007). Evidence rendered 2026-10-27 ~02:30 UTC into `.tools/s0012_critic/` (kept separate from `.tools/shots/` because other review agents render concurrently). The 30-min balance gates were not re-run; balance numbers below are quoted from the S0011 metrics row._

| # | Pillar | Score | Trend | Justification |
|---|---|---|---|---|
| 1 | Fantasy | 6 | → | The First Sortie gives minute one a hostile with a story ("They came from Ember: fly there and land"). Economic play now grows to minute 30. But the HQ is never touched in a normal game, so you never *defend* a realm, you just administer one. |
| 2 | Flight feel | 5 | → | Reticle and brackets are still crisp. `combat_long` again shows `hull=600` on every line for 95 s. The sortie scouts have 0.5x dps and the two escorts kill them in 15–18 s, so the player's first fight can be over before they aim. |
| 3 | Command depth | 6 | → | Defense Platforms now have a real late-game payoff (VS-020). But 0.25^n is so steep that 2 platforms are a dominant answer, not a decision. Orders still exist only on the map (VS-007 todo). |
| 4 | On-foot FPS | 4 | → | No changes since S0007. The pylon labels still overprint each other (`surface.png`, `touch_surface.png`: "PYLON 366m"/"PYLON 413m"). `surface_long` is identical to S0007: Core 85% → 53%, evacuated at t≈58, ship hull 360. |
| 5 | Economy legibility | 3 | → | Nothing visible changed. There is no cr/min or ledger. Credits rise ~14k in 10 minutes with no shown source (probe), and `combat_long` jumps 30,300 → 31,783 at t=65. VS-016 fixed arbitrage, but the player can't see that it did. |
| 6 | First 10 minutes | 6 | ↑ | A real improvement. One tip at a time, the target tip waits for a hostile, and R gives "No hostiles in range". The sortie makes tip 3 reachable at t=60. Still open: tip 4 sends you to an HQ that "does not trade wares", and raids announced on the HQ never arrive. |
| 7 | Readability & UX | 7 | ↑ | `hints.png` at t=3 s shows one tip, one objective and one welcome line. The pile-up from S0007 is gone. Minor problems remain: the touch OBJECTIVE still says "press F to land", the title text is printed over the ship model, and the pylon labels collide. |
| 8 | Visual identity | 6 | → | The amber/cyan/magenta palette holds and the Ember planet glow is still the best image in the game. Ships are still box-kit, and the surface is still flat salmon with pink scars. |
| 9 | Pacing & difficulty | 5 | ↑ | The late-game slide is fixed (econ nw20 107.7k → nw30 122.3k, HQ 9/9). But it was fixed by *removing* pressure: deterred raids are cancelled, not redirected. The first 10 minutes still have no threat at home (problem 2). |
| 10 | Web/touch fitness | 7 | ↑ | VS-013 (tip box vs steer) and VS-014 (pause-screen taps) are done, and the touch layout is clean (`touch.png`, `hints_touch.png`) with the SKIP TIPS chip in the box. VS-006 (perf guard for late-game ship counts) is still unverified and unblocked. |

**Average: 5.5 / 10** (S0007: 5.1). Biggest movers: First 10 minutes, Readability, Pacing and Web/touch (+1 each). Economy legibility is still the floor at 3.

## What improved since S0007 (VS-015..VS-021)
- **S0007 problem 1 (tip 3 dead end): fixed.** The tips skip uncompletable steps, R/TGT gives feedback, and the sortie puts a hostile in the home sector at t=60 in 3/3 seeds (probe: `first_hive_home=60`).
- **S0007 problem 3 (instruction pile-up): fixed.** `hints.png` shows TIP 1/6 + OBJECTIVE + "Welcome, Sovereign." and no duplicate capture line.
- **S0007 problem 5 (late-game slide): fixed by VS-020**, with the side effect described in problem 5 below.
- **Title freeze / overlays (VS-015), arbitrage (VS-016) and 9-seed gates (VS-021)** are solid engineering, but invisible to a player.
- **Not addressed:** S0007 problems 2 (no threat; raids are false alarms) and 4 (economy invisible). They carry over as this review's problems 1 and 2.

## Top 5 problems (by player impact)

### 1. Economy is still invisible, and the tutorial still docks you at a station that can't trade
- **Symptom:** credits change with no stated cause. TIP 4/6 says "Fly close to your HQ station and tap ACT to dock" (`hints_touch.png`). The HQ dock panel answers "This station does not trade wares." (`dock.png`) and offers only ships costing 4,500–16,000 cr.
- **Evidence:**
  - Probe (seeds 7/101/118, 600 s, no player input): credits 30,000 → 45,289 / 44,013 / 43,604, and nothing on screen explains where the money came from.
  - `combat_long`: a +1,483 jump at t=65. `surface_long`: +1,483 at t=65 while the player is in orbit.
  - No income readout exists: there is no cr/min anywhere in `scripts/ui/`, and the HUD only shows "+150 cr" bounty popups.
- **Why it matters:** this is half of the core loop and the lowest score two reviews running. The player can't tell that their miner is earning, so they can't decide whether a second miner or a platform is worth it. The deterrent now makes "buy platforms" the best spend, and nothing communicates that either.
- **Direction:** add a cr/min figure next to credits, plus a "last 5 min" breakdown (mining, trade, stations, bounties, repairs/penalties) in the map panel. Retarget tip 4 to the Trade Hub 2 km away, where a first buy/sell is possible, or make the HQ dock state in one line how money is made.

### 2. The HQ is never threatened: raids "moving on Sovereign HQ" still never arrive
- **Symptom:** "HIVE RAID: 5 ships moving on Sovereign HQ in Haven's Reach" (t=200), then 7 ships (t=363), then 8 (t=513). The HQ bar never moves.
- **Evidence:** probe, 600 s, all three seeds:
  - HQ hull is 30,000/30,000 at t=600.
  - Hive count in Haven's Reach is 0 at t=150/300/450.
  - No message ever says a raid was intercepted or diverted.
  - Union stations die elsewhere ("Union Refinery lost in Argent Fields" at 533 s) while the player's own sector is untouched.
  - After minute 20, VS-020 cancels most raids on a fortified HQ outright.
- **Why it matters:** the raid warning is the main tension device, and it lies. In a normal session the HQ bar is decoration from minute 0 to 40. "Keep your HQ alive" (title screen) is a goal that never needs doing.
- **Direction:**
  - Make raid reports honest: track each raid group and report where it actually ended up ("raid on HQ broken up in Cinder Belt by Union patrols").
  - Make at least one early raid (around minute 5–7) actually reach the home sector as a beatable fight.
  - Show raid groups and their ETA on the galaxy inset.
  - Re-check passive40 with the 9-seed gate after any change.

### 3. The player's first fight is fought by someone else
- **Symptom:** the sortie arrives at t=60 and is dead by t=75–78 in every seed (the "Scouts destroyed!" message). The escorts get the kills, and a player still on TIP 1–2 may never fire.
- **Evidence:**
  - Probe: scouts are announced at 60 s and destroyed at 75/75/78 s, with the player hull at its 600 minimum throughout.
  - DESIGN.md itself states "the two escorts alone win in 15–18 s, all kills by Sovereign fighters, player loses at most ~260 shield".
  - `combat_long`: hull=600 for 95 s in contested Cinder Belt.
- **Why it matters:** flight feel needs stakes and a first kill that belongs to the player. Right now the opening teaches "your wingmen handle it". With 0.5x scout dps, boost, roll and evasion have no reason to exist in the first 10 minutes.
- **Direction:** give the player the first kill and some danger. For example, escorts engage only after the player fires or after a delay, scouts focus the player, and dps returns to 1x on the player only. Keep it inside the sortie flag so balance gates don't move (the sortie already uses its own targeting rule).

### 4. The on-foot layer hasn't moved since S0007 (VS-005 still open)
- **Symptom:** the two pylon markers print over each other at the crosshair ("PYLON 366m" over "PYLON 413m"). The terrain is a flat salmon plain with a few grey cubes. The bot run evacuates at Core 53%.
- **Evidence:** `.tools/s0012_critic/shots/surface.png` and `touch_surface.png`. `surface_long` matches S0007 line for line (pylons down by t≈50, Core 85% → 53%, back in flight at t=60 with hull 360).
- **Why it matters:** the win condition runs through two surface Cores. This is the layer with the lowest gameplay score (4), and it's the one the OBJECTIVE pushes the player toward from second 3.
- **Direction:** ship VS-005 (cheap). Then give the surface 2–3 readable landmarks (a Core spire visible from the landing site, pylon beams into the sky) so objective clarity doesn't depend on HUD text.

### 5. The late-game fix traded decline for a raid-immune turtle
- **Symptom:** after minute 20, two player Defense Platforms reduce a raid on the HQ to a 6.25% chance, and three reduce it to 1.6%. Cancelled raids are not redirected, and "Hive raid on X turned back…" repeats every 75–80 s.
- **Evidence:** `director.gd:94` (cancel plus message). HANDOVER "Watch out for" and the S0011 QA parking-lot notes. metrics S0011: nw30 122.3k, HQ 9/9.
- **Why it matters:** combined with problem 2, a competent player may *never* see the HQ under fire in a 40-minute run. The 20–40 minute stretch becomes economy idling against a scoreboard, which is the opposite of "before Hive raids grind down your HQ".
- **Direction:** keep the player-only principle, but turn deterred raids into *redirected* raids aimed at softer player assets or Union stations. Add a floor (e.g. ≥ 25% go-chance) or ramp it in over minutes 20–25. Merge the turned-back message into one counter. Re-run both 9-seed gates.

## Smaller notes (not new tasks unless cheap)
- On touch, the OBJECTIVE still says "press F to land" (`touch.png`, `hints_touch.png`). This is a known S0008 parking-lot item.
- The title screen's control text is printed over the ship model and over the HQ station on the right (`title.png`). A dim backing panel would fix it.
- The touch THR+ button is drawn over the HQ station silhouette (`touch.png`). It is still readable, but the button ring would benefit from a slight fill.

## Protect this
- **The one-voice tip system that follows the world (VS-017) plus the First Sortie hook (VS-018).** `hints.png` is now a clean, single-instruction opening, and the sortie's "they came from Ember" message chains straight into the objective. Change *who* wins the fight (problem 3), not the structure.
- **Player-only balance levers with 9-seed gates (VS-020/021).** Keeping passive40 unchanged while fixing economic play is the right discipline. Future tuning of the deterrent must stay player-only and gated.

## One bold idea
**Visible war fronts.** Make every Hive raid a tracked fleet on the galaxy inset, with a target and an ETA. When a raid is announced, the player gets a choice:
- intercept it en route with the fleet, for a visible bounty that feeds the ledger in problem 1;
- let platforms deter it, in which case it **redirects** to the nearest Union station and the player watches the Union buckle and loses that trade partner;
- let it hit the HQ.

This fixes problems 1, 2 and 5 in one system: raids become honest, deterrence has a cost, and income gets a visible "war" line. It also turns the X4-style "living sector" into decisions the player can read on the map.

## Evidence index
- **Screenshots** (1280x720, rendered S0012): `.tools/s0012_critic/shots/{title,hints,hints_touch,map,dock,surface,touch,touch_surface,combat,over,win}.png`
- **`--shot=combat_long`:** sector 3, hull=600 on every line; credits 30,150 → 30,300 (t=10) → 31,783 (t=65).
- **`--shot=surface_long`:**
  - pylons down by t≈50; Core 85% (t=50) → 53% (t=55)
  - back in flight at t=60 with hull 360
  - credits +150 every 5 s for t=65–80 in sector 0 (sortie bounties)
- **Probe `$HOME/critic/probe12.gd`** (outside the repo; seeds 7/101/118, 600 s, no player input):
  - first Hive in the home sector at 60 s (sortie); scouts dead at 75–78 s
  - raids announced on the HQ at 200/363/513 s; home-sector Hive count 0 at t=150/300/450
  - HQ 30,000 at t=600 in 3/3 seeds; credits ≈ 43.6–45.3k
- **Balance:** quoted from metrics.csv row S0011 (not re-run; device constraints).
