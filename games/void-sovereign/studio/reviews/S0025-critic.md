# S0025 Critic review: Void Sovereign

_Fourth critic review; compared with `S0019-critic.md` (6.1/10). Build: HEAD after S0024 (VS-029 The Breach, VS-026/027/028 save/continue/new-game confirm). Evidence rendered 2026-10-27 into `.tools/shots/void-sovereign/` (title, map, dock, surface, touch, touch_surface, combat, over, win); viewed: title, combat, touch, surface. Not individually inspected: map, dock, touch_surface, over, win. `combat_long` and `surface_long` re-run. Balance numbers quoted from `S0025-balance.md` / metrics.csv, not re-run._

| # | Pillar | Score | Trend | Justification |
|---|---|---|---|---|
| 1 | Fantasy | 6 | → | Continue-from-save and wing orders support the commander role, but the HQ still goes untouched in a normal game. |
| 2 | Flight feel | 5 | → | `combat_long` still reads hull=600 on all 19 lines; nothing in the opening fight touches the player. |
| 3 | Command depth | 7 | → | Map and wing orders and the ledger are unchanged. The deterrent is still the best spend, and the Breach is a one-off. |
| 4 | On-foot FPS | 6 | ↑ | `surface.png` now has rolling hills, magenta vein cracks and boulders instead of a flat plain. Bot still finishes in ~55 s with no hull loss until the Core falls. |
| 5 | Economy legibility | 6 | → | HUD "+600 cr/min" now shows at t=3 in `combat.png`, though touch `touch.png` shows "+0 cr/min" in the same state (inconsistent). Gross vs net is still an open question. |
| 6 | First 10 minutes | 7 | → | Single tip, objective, raid timer. Touch objective still says "press F to land"; "Continue (1:00)" on the title is a good return-player hook. |
| 7 | Readability & UX | 6 | ↓ | Title FLIGHT controls line runs off both edges at 1280 (`title.png`). On touch, HOLD still overprints "Trade Hub 2.0km" and THR+ sits over the station (`touch.png`). Nothing fixed since S0019. |
| 8 | Visual identity | 6 | → | Amber/cyan/magenta still carry it. The surface now has more character, but it is still one salmon palette. Ships are still box-kit. |
| 9 | Pacing & difficulty | 5 | → | Econ nw30 median rose to 167k and HQ is 9/9, so an active player is more comfortable. The Breach nudged passive HQ-lost to 36.0 min (target <=35) and Hive ships @20 to 61 (guard 60). |
| 10 | Web/touch fitness | 7 | → | Layout is functional. VS-006 (web perf guard) is still unverified three reviews running, and Hive ships @20 is now over its own guard. |

**Average: 6.1 / 10** (S0019: 6.1). Biggest mover: On-foot FPS +1 (5 -> 6); Readability & UX -1 (7 -> 6, more a stricter read of the title and touch overlaps that were never fixed than a regression). Everything else flat.

## What changed since S0019
- Surface terrain readability improved visibly (`surface.png`). `surface_long`: pylons down by t=45, "Core exposed (84%)" at t=50, 46% at t=55, then back in flight with hull 360.
- VS-026/027/028 give a Continue path and a New Game confirm: good friction removal, but invisible to the core loop.
- VS-029 The Breach is the first non-raid pressure on the HQ, but it is a one-off at 6:00 and balance shows it did not tighten the mid-game (passive HQ-lost 33.6 -> 36.0).
- Not addressed: S0019 problems 1 (raids that never arrive), 2 (first fight by escorts), 4 (turtle) and 5 (small first-minute friction) are all still present.

## Top 5 problems (by player impact)

### 1. The HQ is still never meaningfully threatened (VS-025 and war fronts still open)
- **Symptom:** "Next raid 196s" is on the HUD from t=3 (`combat.png`), but an active player finishes 30 minutes with HQ 9/9 and nw30 167k.
- **Evidence:** S0025 balance: econ HQ survives 9/9, nw30 median 167,205 (up from 142k); the Breach is a single event.
- **Why it matters:** the main tension device is a countdown with no consequence; session length is whatever the player wants.
- **Direction:** make at least one early raid reach the home sector as a beatable fight, report raid outcomes honestly (VS-025), and show raid groups with ETA on the galaxy inset.

### 2. The first fight is still won by the escorts
- **Symptom:** `combat_long` hull=600 for 95 s; credits only move at t=5 (+150) and t=65 (+1,483 sortie bounty). In `combat.png` the first Hive Drone is 1.7 km away with nothing forcing contact.
- **Why it matters:** boost, roll, evasion and the wing commands have no early test; flight feel can't be felt, so it scores 5 for the third time.
- **Direction:** VS-030 First Sortie is the right vehicle. Make the scouts target the player and delay the escorts so the player takes some damage and the first kill.

### 3. Passive and late-game balance drifted the wrong way
- **Symptom:** passive HQ-lost median 36.0 (target 20-35, survives 3/9); Hive ships @20 econ 61 (>60); nw30 floor 36,756 (seed 101).
- **Evidence:** `S0025-balance.md`, metrics.csv S0025 rows.
- **Why it matters:** the HQ falls later while Hive counts creep toward the web guard, which is the wrong direction on both.
- **Direction:** the balance report's BREACH_SIZE/BREACH_TIME retune, or an explicit accept from Daniel (VS-029 open question). Re-verify with `--perturb=1`, which has not been run since S0019.

### 4. UX overlaps that have now survived two reviews
- **Symptom:**
  - Title FLIGHT line is clipped at both edges at 1280 (`title.png`).
  - Touch HOLD overprints "Trade Hub 2.0km"; THR+ sits on a station silhouette (`touch.png`).
  - Touch objective says "press F to land"; touch HUD shows "+0 cr/min" where desktop shows "+600".
  - Surface prompt "Click to capture mouse" floats mid-screen over the terrain (`surface.png`).
- **Why it matters:** these are the first 60 seconds on the platform this game targets (phone web).
- **Direction:** one polish task: wrap or shorten the title controls, input-aware objective text, backing fill and spacing for touch buttons, and check why the touch income figure is zero.

### 5. On-foot combat is still shooting at markers
- **Symptom:** terrain is better, but the objective reads as pink rings and "PYLON 366m" text, with no beam or spire as a landmark. The bot clears pylons and Core in ~55 s with 0 damage (`surface_long`: hull=600 through t=55).
- **Why it matters:** the climax is a short, risk-free walk-and-shoot.
- **Direction:** skyward pylon beams or a visible Core spire, and enemies that flank or pressure so the bot (and a human) takes damage; add hit-marker and kill feedback.

## Protect this
- **The ledger as pure observer** (`Universe.add_credits(amount, cat)` sole writer; deterministic balance).
- **One-voice onboarding plus Continue/New Game confirm flow**: clean HUD, one tip, one objective, and a title that returns you to your run in one press.

## One bold idea
**Visible war fronts** (carried over): every Hive raid is a tracked fleet on the galaxy inset with target and ETA, and the player can intercept with the wing (bounty in the ledger), let platforms deter it so it redirects onto Union stations, or take the hit at the HQ. It fixes problems 1 and 3 together and gives the wing commands a purpose.

## Evidence index
- **Screenshots:** `.tools/shots/void-sovereign/*.png` (1280x720).
- **`combat_long`:** sector 3, hull=600 on all lines; credits 30,150 (t=5), 30,300 (t=10..60), 31,783 (t=65..95).
- **`surface_long`:** credits 30,000 -> 30,780 by t=55; "Core exposed" 84% at t=50, 46% at t=55; hull 360, sector 0 flight from t=60; 32,263 -> 32,713 sortie bounties.
- **Balance:** `S0025-balance.md` (9 seeds; perturb not run).
