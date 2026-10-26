# S0007 Critic review: Void Sovereign

_First critic review (no earlier `*-critic.md` in `studio/reviews/`), so every trend is "new" (baseline). Build: HEAD after S0006 (VS-004 tips, VS-012 touch row). Evidence was rendered 2026-10-26 12:37-12:39 UTC._

| # | Pillar | Score | Trend | Justification |
|---|---|---|---|---|
| 1 | Fantasy | 6 | new | Three layers in one sim really work (the map shows Hive threat per sector, Ember sits in your home sector). But the first minutes feel like "admin of a quiet sector", not "rising sovereign under siege". |
| 2 | Flight feel | 5 | new | Readable reticle and target brackets. In `combat_long` the ship's hull stays 600/600 for 95 s in the "contested" Cinder Belt, so there is no threat and no reason to use boost/roll. |
| 3 | Command depth | 6 | new | The order set (patrol/escort/auto-trade/auto-mine) plus buy/build is a good X4-lite. Orders only exist on the map (VS-007 still todo). |
| 4 | On-foot FPS | 4 | new | The objective line is clear, but pylon labels overlap (VS-005 still open, see `surface.png`). The terrain is a flat pink-brown with few landmarks, and the bot evacuated at Core 53% (t≈58 s) in `surface_long`. |
| 5 | Economy legibility | 3 | new | There is no income rate, ledger or breakdown anywhere (`scripts/ui/` has no income readout). Credits jump +1,553 with no visible cause (`combat_long` t=65). The HQ dock says "This station does not trade wares." |
| 6 | First 10 minutes | 5 | new | The tips are well styled and worded, and the touch wording is right. But tip 3 can't be completed at home, the tip order contradicts the OBJECTIVE, and nothing hostile shows up at home for 10+ minutes (see problems 1 to 3). |
| 7 | Readability & UX | 6 | new | Clean HUD panels, and the map panel is legible at 1280x720. At t=3 s, though, five instructions compete for attention (problem 3). The tip box sits over the ship model (parking lot). |
| 8 | Visual identity | 6 | new | The amber/cyan/magenta faction palette is consistent and intentional, and the Hive planet glow is striking. Ships are box-kit silhouettes and the surface is flat. |
| 9 | Pacing & difficulty | 4 | new | Raids are announced at HQ but never reach it in the first 10 minutes. The late game slides (VS-011: nw falls from minute 20 to 30 in 4/6 seeds). |
| 10 | Web/touch fitness | 6 | new | After VS-012 the touch layout is clean (`touch.png`, `touch_surface.png`) and there is no load-time asset fetch. Still open: the tip box steals steer drags (VS-013), pause-screen taps (VS-014), and late-game ship counts (VS-006). |

**Average: 5.1 / 10** (baseline).

## First 10 minutes: tutorial tips (VS-004) verdict
Shots: `.tools/shots/void-sovereign/hints.png` (desktop, TIP 1/6), `hints_touch.png` (TIP 4/6 touch), `touch.png` (TIP 1/6 touch), `combat.png`.
- **Good:** the box is legible, amber-framed and fades in, with a "TIP n/6" counter. Touch wording matches the buttons (THR+/-, TGT, ACT, MAP), and the skip affordance is shown on every tip. This is the right format.
- **Broken flow:** tips are a fixed linear queue (steer → throttle → target → dock → map → land). `current()` shows the *first unfinished* step, so whatever is stuck blocks every later tip, even ones the player has already done.
- **Tip 3 is a dead end at home** (problem 1). Tip 4 sends you to the HQ dock, which has nothing to trade (problem 4). The OBJECTIVE bar meanwhile says "Fly to planet Ember" the whole time (problem 3).
- Known and not re-reported: VS-013 (box overlaps the touch steer zone, H undocumented), plus the parking-lot items about the box over the ship model, the duplicate "Click to capture mouse" line, MOVE vs "steer" wording and touch "press F to land".

## Top 5 problems (by player impact)

### 1. Tip 3 ("lock onto a Hive ship") can't be completed in the home sector, so the tutorial stalls
- **Symptom:** after steer and throttle, the player sees "Press R / tap TGT to lock onto a Hive ship" in Haven's Reach. There are no Hive ships there, R silently does nothing, and tips 4 to 6 (dock, map, land) never show.
- **Evidence:** a headless probe (`Universe.setup(seed)` + `step(0.1)` for 600 s, counting alive Hive entities in `u.hq.sector`) found **no Hive ship in Haven's Reach during the first 10 minutes in 3/3 seeds (7, 101, 118)**. `space_view.gd` `_cycle_target()` only considers `Faction.HIVE` in the current sector and returns with no feedback when none exist. `tutorial_hints.gd` `current()` returns the first unfinished step, and the `target` condition is `sp.target_id != 0`.
- **Why it matters:** the tutorial asks for something impossible right after the player has learned to fly. Most players will skip tips or conclude R is broken. The guided start (VS-004's whole purpose) only works for players who wander into Cinder Belt.
- **Direction:** make the tip order follow what the world actually offers. Either teach targeting only when a hostile is in-sector (show other tips meanwhile, so the queue is not blocking), or put a killable Hive presence near Ember. Give R/TGT visible feedback ("No Hive contacts in sector") when nothing is targetable.

### 2. The opening has no threat: raids are announced but never arrive, and combat never hurts
- **Symptom:** "HIVE RAID: 5 ships moving on Sovereign HQ in Haven's Reach" fires, the "Next raid" counter ticks, and nothing ever shows up at home.
- **Evidence:** probe for seed 7 tracking raiders with `order_target == hq.id`: by t=300 s all 5 raiders of raid 1 are dead in sector 3 (Cinder Belt). The 7-ship raid 2 also dies in sectors 3 and 1, and by t=600 s none has entered Haven's Reach. HQ hull stays 30,000/30,000. In `--shot=combat_long` (95 s in Cinder Belt) the player hull reads `hull=600` on every line, so it is never scratched.
- **Why it matters:** false alarms teach the player to ignore the raid warning, which is the game's main tension device. With no danger in the first 10 minutes there is nothing to defend and no reason to build a fleet or care about the HQ bar. This is the "early hook" pillar.
- **Direction:** make the first raid a deliberate, beatable set piece that *reaches* the player around minute 3 to 4 (e.g. a small first wave that spawns or enters at the home gate). Make "moving on X" messages honest (track and report when a raid is intercepted). Give Cinder Belt drones some real bite. Coordinate with VS-011 so the early wave doesn't skew the balance gates.

### 3. Instruction pile-up: five competing directives on screen at t=3 s, and the tip order contradicts the objective
- **Symptom:** in `hints.png` the player sees all of these at once:
  - top-right: "Kill the Hive Cores, then the Nests. M = command map"
  - centre: TIP 1/6 "Click the view to capture the mouse…"
  - below it: "F: Dock at Sovereign HQ"
  - below that: "Click to capture mouse for steering" (duplicate)
  - bottom: OBJECTIVE "Fly to planet Ember, press F to land…"
  
  The tip queue then says target, then dock, then map, while the objective says go to Ember.
- **Evidence:** `hints.png`, `touch.png` and `hints_touch.png` (the TIP 4/6 dock tip sits directly above "ACT: Dock at Sovereign HQ", saying the same thing twice).
- **Why it matters:** too many voices with conflicting goals is the classic X4 onboarding failure this game should avoid. A new player can't tell which instruction is "the one".
- **Direction:** one voice in the centre. While a tip is shown, suppress or merge the contextual prompt and the capture hint, and order the tips so they lead *toward* the current OBJECTIVE (fly to Ember → land → after the Core, map and fleet). Duplicate-line cleanup is already in the parking lot; the bigger change is aligning the tips with the objective.

### 4. Economy is invisible: no income readout, and docking at HQ is a dead end
- **Symptom:** credits change with no explanation. Tip 4 sends the new player to dock at the HQ, which "does not trade wares" and only sells ships for 4,500 to 16,000 cr. Nothing says where money comes from or what to do next.
- **Evidence:** `dock.png`. `combat_long`: credits jump 30,300 → 31,853 at t=65 with no player action. `grep -i income scripts/ui/*.gd scripts/main.gd` finds nothing, and the HUD (`hud.gd`) shows only a "+150 cr" bounty popup.
- **Why it matters:** "Earn credits (trade, mining fleets, stations…)" is half the core loop (DESIGN.md), and the player can't see it working. You can't make economic decisions you can't read. It also hides whether the VS-011 balance work is felt in play.
- **Direction:** add a compact ledger: a cr/min rate next to credits plus a last-minute breakdown (trade, mining, stations, bounties, repairs) in the map panel. Point the dock tip at a station where a first trade is possible, or have the HQ dock panel say in one line how to earn.

### 5. Late-game slide and the on-foot layer pull the session down (known: VS-011, VS-005)
- **Symptom:** an economic player peaks at minute 20 and then loses ships and net worth. On foot, the objective markers overlap and the surface has little to read.
- **Evidence:** VS-011 (S0003: nw falls from minute 20 to 30 in 4/6 seeds, e.g. 106k → 6k). `surface.png` / `touch_surface.png` show "PYLON 366m" and "PYLON 413m" drawn on top of each other (VS-005). In `surface_long` the bot evacuates at Core 53% (t≈58 s).
- **Why it matters:** the win condition needs both the late-game fleet and the surface Cores, which are the two weakest stretches.
- **Direction:** keep VS-011 as the top build task; VS-005 is a cheap readability win. No new task needed beyond these.

## Protect this
- **One simulation, three views.** The map's galaxy inset (Hive counts per sector, Ember threat level in the panel) makes the strategic picture readable at a glance. Don't fork the sim per view.
- **The tip box style and touch layout** after VS-004/VS-012: clean, consistent, and the touch wording matches the button labels. Fix the *flow* (problems 1 and 3), not the presentation.

## One bold idea
**"First Sortie" opening set piece.** At minute 1, a small Hive wave drops out of the Ember orbit toward the player. The two starting escort fighters engage, and the tips teach R target and G fleet attack in that live fight. When the wave is beaten, a beacon on Ember's surface opens and the tip says "Land (F/ACT) and kill the Core". In about three minutes this teaches flight, targeting, fleet command and landing in the order the objective asks, and it fixes problems 1 to 3 at once. The tips become a scenario, not a checklist.

## Evidence index
- Screenshots: `.tools/shots/void-sovereign/{hints,hints_touch,touch,title,map,dock,surface,touch_surface,combat,over,win}.png` (rendered S0007, 1280x720)
- `--shot=combat_long`: hull=600 throughout; credits 30,150 → 30,300 → 31,853 (t=65)
- `--shot=surface_long`: pylons down by t=50, Core 85% → 53%, back in flight at t=60 with ship hull 360
- Hive-in-home-sector probe (seeds 7/101/118, 600 s): none. Raid-tracking probe (seed 7): raids "on Sovereign HQ" die in sectors 3 and 1. Probe scripts were kept outside the repo in `$HOME/critic/`.
