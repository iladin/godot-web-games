# S0056 Critic review: Void Sovereign

_Ninth critic review; compared with S0050 (6.8/10). Build: HEAD after S0055 (Fleet Reserve sim + Call Reserve button). Rendered 2026-10-29 via shots.sh; viewed combat, map, touch, dock, surface (1280x720). title/over/win/touch_surface re-rendered, not viewed (scores carry). `combat_long` (min_hull 600, sh 400 flat through t=99, 31,933 cr banked, mode flight, no script errors) and `surface_long` (pylon1 45 s, pylons 55 s, core 67 s, flank=6, min_foot 315, then 30 s idle) re-run. No balance run this session (metrics.csv last row S0052). No real-browser pass (VS-042 blocked), so pillar 10 is code-reading only._

| # | Pillar | Score | Trend | Justification |
|---|---|---|---|---|
| 1 | Fantasy | 6 | → | Fleet Reserve is a sovereign-flavoured lever, but the scripted player still never sees HQ damage (HQ 100%, hull 600 flat). |
| 2 | Flight feel | 7 | → | Unchanged; combat_long hull/shield never move after the opening. |
| 3 | Command depth | 7 | ↑? | Call Reserve (4,000 cr) is the first raid-response lever (answers S0050 #1/#3) but is untuned (VS-061) and invisible in the first minutes. Held at 7 until A/B. |
| 4 | On-foot FPS | 7 | → | surface_long: Core dead t=67, 30 s of nothing after; objective text clear in surface.png. |
| 5 | Economy legibility | 7 | → | dock.png "No income yet. Ways to earn" is good; map still shows 30,000 cr with no hint what Reserve earns back. |
| 6 | First 10 minutes | 7 | → | Hot opening intact (Sortie at 60 s). Touch objective bar now a clean single lane (touch.png). Start-of-game 30,000 cr with a 4,500 cr fighter is generous. |
| 7 | Readability & UX | 6 | ↓ | map.png: Call Reserve sits at the very bottom edge of the side panel, below the fold with a scrollbar, and is a short thin button (VS-062 already open). Surface "Click to capture mouse" overlaps the middle of the view. |
| 8 | Visual identity | 7 | → | Surface pink sky + beams intentional; ships still box-kit; map is sparse (huge empty ring field). |
| 9 | Pacing & difficulty | 6 | → | Late cliff unchanged until Reserve is measured; economic nw30 168k (S0052) suggests the economy is now easy for a competent player. |
| 10 | Web/touch fitness | 7 | → | Still no browser pass (ninth review). touch.png HUD is cleaner than S0050 but THR+ overlaps a passing station silhouette and ATK/ESC/HOLD collide with the planet limb. |

**Average: 6.7 / 10** (S0050: 6.8). Biggest mover: Readability & UX (-1, Reserve button placement); Command depth only conditionally up.

## Top 5 problems (by player impact)

### 1. Reserve is built but unmeasured and undiscoverable
- Symptom: Call Reserve shows only as a bottom-edge grey button (map.png, dock.png); no tip, no raid-time prompt, no statement of what 4,000 cr buys.
- Evidence: map.png (button at y~682 of 720, panel scrollbar), HANDOVER VS-061/062 todo; defs.gd tunables "untuned".
- Why: a rescue lever nobody finds or trusts does not fix the late cliff (S0050 #1).
- Direction: finish the A/B, then surface it exactly when it matters (raid forecast panel: "Call Reserve" with ship count and linger time) and label what it delivers.

### 2. The active player still never feels raids, chip or wound
- Symptom: combat_long hull 600 / HQ 100% for the whole run; surface min_hp 84.
- Evidence: combat_long and surface_long logs above; same finding in S0044 and S0050.
- Why: headline systems from S0043-S0055 are invisible in any short human session; first raid is 3.3 min away and the scripted run ends before it matters.
- Direction: a scripted "first raid lands" shot/run so the team actually sees damage, forecast and Reserve interplay; consider a visible HQ hull number (VS-055 exists, check it shows on this HUD at all times).

### 3. Command map is empty and has an off-screen action column
- Symptom: map.png: ~70% empty ring field, orders in a clipped side panel with a scrollbar; key rescue button is last.
- Evidence: map.png; VS-043 fold assert exists but does not cover this ordering.
- Why: command depth is the pillar that differentiates this game from a shooter; the panel buries it.
- Direction: put raid-response actions in a persistent strip separate from the buy lists; collapse buy/build into tabs.

### 4. Economy is too generous at the top, brutal in the tail
- Symptom: nw30 median 168k (S0052) while weak seeds collapse (8/9 perturb); player starts with 30,000 cr.
- Evidence: metrics.csv S0052 rows.
- Why: competent players coast, weak ones spiral; neither is tension.
- Direction: after VS-061, retune start credits vs raid ramp together; test that a wrecked fleet at minute 20 can recover with Reserve.

### 5. Real-browser behaviour unverified (ninth review)
- Symptom: VS-042 blocked on allowlist.
- Evidence: HANDOVER open questions.
- Why: autosave/IndexedDB/audio/touch-in-iframe failures are first-impression killers; save now carries wound and reserve state.
- Direction: unblock a headless browser or ask Daniel to do one manual load-and-play pass of the exported build.

## Protect this
- Hot opening: Sortie at 60 s with escorts winning in ~15 s and a clear OBJECTIVE bar (combat.png, touch.png).
- Dock "No income yet. Ways to earn" panel and signed bounty text: they explain money better than most games in the genre.

## One bold idea
"Sovereign's Decree": a once-per-run, cooldown-gated command-map ability that lets the player spend a big pile of credits to declare a sector Fortified for 2 minutes (platforms spawn, Union ships rally, raids turn back) with a dramatic on-screen proclamation. It converts surplus late credits into a visible, spectacular power move, gives the economic player a sink, and makes the "rising sovereign" fantasy readable.
