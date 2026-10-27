# S0031 Critic review: Void Sovereign

_Fifth critic review; compared with `S0025-critic.md` (6.1/10). Build: HEAD after S0030 (VS-030 First Sortie, VS-031 Core spire + pylon beams, VS-032 touch/UX bundle, VS-033 atomic save, VS-034 Breach retune). Evidence rendered 2026-10-27 into `.tools/shots/void-sovereign/` (title, map, dock, surface, touch, touch_surface, combat, over, win, sortie, surface_far); viewed: title, sortie, touch, surface_far, map. Not individually inspected: dock, touch_surface, combat, over, win. `combat_long` and `surface_long` re-run (headless, 85 s window each). Balance numbers quoted from metrics.csv, BACKLOG and LOG (no S0026-S0030 balance rows in metrics.csv; VS-034 numbers are from its backlog note), not re-run._

| # | Pillar | Score | Trend | Justification |
|---|---|---|---|---|
| 1 | Fantasy | 6 | → | Continue/New Game and wing orders carry it; the HQ is still never in real danger in a normal game. |
| 2 | Flight feel | 6 | ↑ | VS-030 works: `combat_long` hull 600 until t=60, then shield 299 -> 0 and hull 501 by t=85. But the first 60 s are still empty (credits 30000 flat, t=1..60). |
| 3 | Command depth | 7 | → | Map, wing orders, ledger unchanged. Map panel is better ordered (Income and Last 5 min now readable) but nothing new to decide. |
| 4 | On-foot FPS | 7 | ↑ | `surface_far.png`: magenta pylon beams read from 500 m; objective is now findable. Still no pressure (VS-037 todo). |
| 5 | Economy legibility | 6 | → | Touch and desktop both show "+0 cr/min" at t=3-9 (consistent now), but zero for a 30,000 cr start tells the player nothing. Gross vs net still unexplained. |
| 6 | First 10 minutes | 7 | → | One tip, one objective, touch wording fixed ("tap ACT to land"). Sortie arrives, but only after ~60 s of nothing. |
| 7 | Readability & UX | 6 | → | Title FLIGHT line still clipped (`title.png`), map "Sovereign HQ" label still sits under the ship icons (`map.png`), "Click to capture mouse" still floats over the surface. Touch is better. |
| 8 | Visual identity | 7 | ↑ | Beams plus pink sky and magenta veins in `surface_far.png` look intentional. Ships and stations are still box-kit. |
| 9 | Pacing & difficulty | 6 | ↑ | VS-034 brought passive HQ-lost to 28.3 min (in the 20-35 target); active play still ends at HQ 9/9 with no scheduled pressure. |
| 10 | Web/touch fitness | 7 | → | Touch layout is clean now, but VS-006 (web perf guard) has still never been verified, five reviews running. |

**Average: 6.5 / 10** (S0025: 6.1). Biggest movers: On-foot FPS +1 (6 -> 7), Visual identity +1 (6 -> 7), Flight feel +1 (5 -> 6), Pacing +1 (5 -> 6). Nothing regressed.

## What changed since S0025
- VS-030: the sortie now reaches the player. `combat_long`: shield 400 -> 0 and hull 501 by t=85, bounty +1,483 at t=65. Real, but it starts at ~t=60; `sortie.png` at t=9 shows the two scouts as tiny pink markers with a tip box over the ship.
- VS-031: pylon beams and Core spire are visible from afar (`surface_far.png`: three beams, "2x PYLON 511m"). Best single fix this cycle. `surface_long`: pylons gone by t=46, Core exposed t=48, 46% at t=55, flight at t=60 with hull 360 (the bot still takes no damage until the Core falls).
- VS-032: touch HOLD no longer overprints the hub label (`touch.png`); wing column moved left; ACT objective wording is correct. THR+ still overlaps a station silhouette on the right edge, and the wing column now sits on the planet limb.
- VS-033/034: atomic saves and the Breach retune (6 drones, passive HQ-lost 36.0 -> 28.3, econ Hive ships @20 51). Good, invisible, correct.
- Still open from S0025: problem 1 (HQ never threatened; VS-036 todo), problem 4 UX (VS-035 todo), problem 5 on-foot pressure (VS-037 todo).

## Top 5 problems (by player impact)

### 1. The first minute of flight is still dead air
- **Symptom:** `combat_long` shows credits 30000, hull 600, shield 400 for t=1..60 with no event; the sortie lands at ~t=60-65.
- **Evidence:** `combat_long` log; `sortie.png` at t=9 has only two distant markers behind a tip box.
- **Why it matters:** the sortie fix moved the fight, it did not make the opening a hook. A new player reads tips for a minute, then gets shot at while still orienting.
- **Direction:** make first contact visible and inevitable within ~20-30 s (scouts that visibly close in, a radio line, a bearing marker), and let the sortie shrink or grow with player action instead of a fixed clock.

### 2. The HQ is still never meaningfully threatened in active play
- **Symptom:** "Next raid 190s" on the HUD, but economic runs end 9/9 HQ survived, nw30 median 167k at S0025, with no newer econ gate rows since.
- **Evidence:** metrics.csv S0025 econ row; `sortie.png` HUD countdown.
- **Why it matters:** the main tension device is a countdown with no consequence for competent players; session length is up to the player.
- **Direction:** VS-036: raids as visible, interceptable fleets with honest outcome reports. Do it next, before any more polish.

### 3. On-foot combat is a walk to a beam
- **Symptom:** beams now tell you where to go, but the bot clears everything in ~48 s at hull 600 and only loses hull after taking off (hull 360 at t=60).
- **Evidence:** `surface_long` lines t=39..55, `surface_far.png`.
- **Why it matters:** the landmark fix exposed how empty the approach is: a clearly marked, undefended objective.
- **Direction:** VS-037, enemies that flank after the first pylon, plus hit and kill feedback.

### 4. Title and map text still break
- **Symptom:** title FLIGHT line is clipped at both edges at 1280 (leading "F" and trailing "M" cut, `title.png`); map "Sovereign HQ" label is overprinted by the player and escort icons (`map.png`); "Click to capture mouse" sits in mid-screen on the surface (`surface_far.png`).
- **Why it matters:** the title is the first thing every player sees; it has been clipped for three reviews.
- **Direction:** VS-035, with a fit-to-screen check so this cannot recur; move the capture prompt to a fixed bar.

### 5. Economy numbers do not teach anything at the start
- **Symptom:** "+0 cr/min" next to 30,000 cr on desktop and touch, "no credit changes yet" on the map; the first income appears only after a sale.
- **Evidence:** `sortie.png`, `touch.png`, `map.png` panel.
- **Why it matters:** the HUD shows a number that is correct but meaningless; the economy pillar stays at 6.
- **Direction:** hide the rate until there is something to rate (VS-035 already says 15 s) and show where income will come from (station income, trade) in the map panel's first state.

## Protect this
- **Pylon beams and Core spire as the surface landmark:** do not fog them, shrink them or make them optional.
- **The ledger as pure observer** (`Universe.add_credits(amount, cat)` sole writer; deterministic balance) and the atomic Continue/New Game flow.

## One bold idea
**Visible war fronts** (carried over, still the highest-leverage item): each Hive raid is a tracked fleet on the galaxy inset with target and ETA. The player can intercept with the wing (bounty), let platforms deter it so it redirects onto Union stations, or take the hit at the HQ. It addresses problems 1 and 2 together and gives the wing commands a purpose.

## Evidence index
- **Screenshots:** `.tools/shots/void-sovereign/*.png` (1280x720; map renders at 900x720).
- **`combat_long`:** hull 600 / shield 400 / credits 30,000 for t=1..60; credits 31,483 and shield 299 at t=65; shield 0 and hull 546 at t=80; hull 501 at t=85.
- **`surface_long`:** pylons (2 -> 1 -> 0) t=39..47, "Core exposed (96%)" t=48, 46% t=55, flight hull 360 t=60, credits 30,000 -> 32,713.
- **Script errors:** none in either run.
- **Balance:** metrics.csv last rows S0025; VS-034 note (passive-40 median 28.3, econ nw20 113.6k, HQ 9/9, Hive@20 51). Not re-run.
