# S0069 Critic review: Void Sovereign

_Eleventh critic review; compared with S0062 (6.8/10). Build: HEAD after S0068 (VS-065 touch polish, VS-068 map tabs, VS-073 collapse-and-extract beat, VS-074 raid banner and route lines, VS-075 Defense Platform 24k). Rendered via shots.sh (1280x720): title map dock surface touch combat; viewed map, touch, surface. Others carried. combat_long and surface_long re-run headless, no script errors. No real-browser pass (VS-042 still blocked), so pillar 10 is screenshot/code only._

| # | Pillar | Score | Trend | Justification |
|---|---|---|---|---|
| 1 | Fantasy | 6 | → | Scripted runs still never meet a raid; the galaxy minimap shows Hive triangles with counts (6, 6, 2) but nothing in the first minutes makes me a threatened sovereign. |
| 2 | Flight feel | 7 | → | combat_long: shield dips 400->108 by t=31, regenerates to 400 by t=43, hull never moves from 600 over 99 s; the fight reads fine, stakes do not exist. |
| 3 | Command depth | 7 | → | Buy/Build/Orders tabs and Call Reserve (6 ships, 4,000 cr) are real decisions; still no evidence a human-like run uses them under pressure. |
| 4 | On-foot FPS | 7 | ↑? | surface_long now ends with "BASE COLLAPSING 21 s - RUN TO THE EXTRACTION ZONE" and a counted-down sprint, a genuine climax. min_hp 84 and mobs=0 from t=57 mean the Core fight itself is still toothless. |
| 5 | Economy legibility | 7 | → | Costs on every button, a "No raid inbound" line; nothing says what Reserve, a colony or a platform returns. |
| 6 | First 10 minutes | 7 | → | touch.png objective bar ("Fly to planet Ember, tap ACT to land") and "Next raid 196s" are clear; 30,000 cr up front is still a wall of choices with no guidance on what to spend it on. |
| 7 | Readability & UX | 7 | → | map.png: tab strip fits, no more clipped fleet line. Mouse-hint footer and raid line are small grey text; surface.png HUD text on a pink sky is low contrast. |
| 8 | Visual identity | 7 | → | Nebula/Hive pink consistent; surface is a flat low-poly haze with a huge dark weapon blob covering the lower centre; map is ~70% empty ring field. |
| 9 | Pacing & difficulty | 6 | → | metrics S0068 economic 9/9 nw30 median 132k (q1 116k); passive gate ambiguity (VS-077) unresolved; seeds 101/135 weak (nw30 89k/71k). Surplus has no sink. |
| 10 | Web/touch fitness | 7 | → | touch.png: THR+ still sits on the solar-panel streak, ATK/ESC/HOLD still overlap the planet limb. Eleventh review with zero browser verification. |

**Average: 6.7 / 10** (S0062: 6.8). Biggest mover: On-foot FPS (the collapse beat is a real improvement, but pressure is still absent); no pillar moved a full point.

## Top 5 problems (by player impact)

### 1. Real-browser behaviour is still unverified (eleventh review)
- Symptom: VS-042 blocked on egress allowlist.
- Evidence: HANDOVER open questions.
- Why: IndexedDB autosave, audio gating, touch in an iframe are first-impression killers; the save now carries wound/reserve/raid state.
- Direction: ask Daniel for one manual load-and-play of the exported build or unblock a chromium. Stop adding features before this.

### 2. The first sit-down never experiences a raid
- Symptom: combat_long hull 600 flat for 99 s; first raid 196 s out; surface_long t=85-97 shows only a shield drain.
- Evidence: combat_long and surface_long logs; same finding S0044 through S0062.
- Why: forecast, HQ wound, repair, Reserve, route lines and the raid banner are the game's best work and a casual session never sees them.
- Direction: a guaranteed small early probe raid or shorter first timer, so forecast -> impact -> repair is the first 5 minutes.

### 3. Surface Core fight has no teeth
- Symptom: mobs=0 from t=57 to the Core dying at t=67; min_hp 84; flank=6 earlier then nothing.
- Evidence: surface_long log (foot=84/60 steady).
- Why: the collapse timer now rewards the kill but nothing makes the kill hard; the best FPS beat is a countdown with no opposition.
- Direction: let the Core spawn defenders as it drops (health-gated waves) so the sprint is a retreat under fire.

### 4. Economy: brittle at the floor, generous at the top, surplus unspent
- Symptom: economic nw30 median 132k yet seeds 101/135 sit at 89k/71k; passive-gate baseline loses seed 169 at 19.2 min (VS-077).
- Evidence: metrics.csv S0062/S0068 rows, HANDOVER.
- Why: strong players coast, weak seeds spiral, and credits past ~100k have nowhere to go.
- Direction: resolve the gate definition, then add a late-game sink and a floor-support for weak seeds together.

### 5. Touch HUD collisions and thin map content
- Symptom: touch.png THR+ over the station streak, wing buttons over the planet limb; map.png shows ~70% empty rings with no routes visible in a calm sector.
- Evidence: touch.png, map.png (1280x720).
- Why: touch is a primary web target and the map is the game's USP.
- Direction: reposition the throttle/wing clusters off the planet limb; show standing orders, trade routes and sector stakes on the main sector view.

## Protect this
- Hot opening: objective bar, "Next raid" timer and bounty popups; touch.png reads instantly.
- The pinned command strip (raid status, Call Reserve, tabs) at the top of the map panel and the base-collapse countdown line; do not bury either.

## One bold idea
"Sovereign's Decree": a once-per-run, cooldown-gated map ability that spends a large credit pile to declare a sector Fortified for 2 minutes (platforms spawn, Union ships rally, raids turn back) with an on-screen proclamation. It gives surplus a sink and makes the rising-sovereign fantasy visible.
