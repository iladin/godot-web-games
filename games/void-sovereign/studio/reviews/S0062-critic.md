# S0062 Critic review: Void Sovereign

_Tenth critic review; compared with S0056 (6.7/10). Build: HEAD after S0061 (VS-064 nest cap 145; pinned command strip VS-067, damaged-HQ compaction VS-069, raid_hit shot). Rendered via shots.sh: title map dock surface touch touch_surface combat over win raid_map_damaged (1280x720); viewed map, raid_map_damaged, touch, combat. Others re-rendered, not viewed (scores carry). `combat_long` (hull 600 / sh 400 flat to t=99, 32,070 cr, mode flight, no script errors) and `surface_long` (pylon1 45.3 s, pylons 55.4 s, core 67.1 s, flank=6, min_foot 315, min_hp 84, then idle to t=99) re-run. No real-browser pass (VS-042 blocked) so pillar 10 is code/screenshot only._

| # | Pillar | Score | Trend | Justification |
|---|---|---|---|---|
| 1 | Fantasy | 6 | → | Scripted run still never shows HQ damage or a raid; the sovereign never gets to be threatened or to answer. |
| 2 | Flight feel | 7 | → | combat.png fine (bounty popup, target box); combat_long hull/shield never move. |
| 3 | Command depth | 7 | → | Call Reserve + Repair HQ + Defend order now appear when a raid is inbound (raid_map_damaged.png); still untested by a human-like run. |
| 4 | On-foot FPS | 7 | → | surface_long: Core dead t=67, 30 s of nothing after; min_hp 84 means no real pressure. |
| 5 | Economy legibility | 7 | → | Costs on every button; nothing says what Reserve or a colony earns back. |
| 6 | First 10 minutes | 7 | → | Objective bar clear; "Next raid 196s" in HUD is a good hook. Still 30,000 cr up front. |
| 7 | Readability & UX | 7 | ↑ | map.png: pinned strip puts raid status, Call Reserve and orders at the top of the panel, answering S0056 #3. Raid warning is a tiny pink 11 px line; panel still clips ("Fleet: Miners 1, Fighters 2" cut off). |
| 8 | Visual identity | 7 | → | Nebula backdrops and Hive pink read as intentional; the map is still ~70% empty ring field. |
| 9 | Pacing & difficulty | 6 | → | S0061 rows: passive HQ lost median 28.2, economic HQ 8/9 (seed 186 lost 23.7); economic is on the gate floor while nw30 was 168k in S0056. |
| 10 | Web/touch fitness | 7 | → | touch.png: THR+ still overlaps the station/solar-panel streak, ATK/ESC/HOLD sit on the planet limb, "WING 2 ESCORT" fine. Zero browser verification, tenth review running. |

**Average: 6.8 / 10** (S0056: 6.7). Biggest mover: Readability & UX (+1, pinned command strip).

## Top 5 problems (by player impact)

### 1. Real-browser behaviour is still unverified (tenth review)
- Symptom: VS-042 blocked on egress allowlist.
- Evidence: HANDOVER open questions.
- Why: autosave/IndexedDB, audio gating, touch in an iframe are first-impression killers; save now holds wound and reserve state.
- Direction: unblock a headless browser, or ask Daniel for one manual load-and-play pass of the exported build. Do this before more features.

### 2. The scripted/active player still never experiences a raid
- Symptom: combat_long hull 600, sh 400, no change for 99 s; the first raid is 196 s out.
- Evidence: combat_long log lines t=58..97; same finding S0044, S0050, S0056.
- Why: the best systems (forecast, HQ wound, repair, Reserve) are invisible in any short session, so the first-10-minutes hook relies on a raid the player has not met.
- Direction: a first-raid-early option (shorter first timer or a guaranteed small probe) so the first sit-down sees forecast to impact to repair; keep raid_hit as the proof shot.

### 3. Economy: generous at top, brittle at floor
- Symptom: economic HQ 8/9 with no margin; passive collapse ~28 min; nw30 168k (S0056).
- Evidence: metrics.csv S0056/S0061 rows.
- Why: competent players coast with a huge surplus, weak ones spiral; neither is tension, and surplus credits have no sink.
- Direction: add a late credit sink and retune start credits together with the ramp; check a wrecked-fleet recovery at minute 20.

### 4. Command map content is thin, and panel still clips
- Symptom: map.png has mostly empty ring field; the lower panel (sector info, fleet line) is cut by the viewport; raid line is 11 px pink.
- Evidence: map.png, raid_map_damaged.png; VS-068 tabs and VS-065 pending.
- Why: this is the pillar that separates the game from a shooter and the panel is still a scroll list.
- Direction: land the tabs; make the raid state a larger, colour-coded banner; give the map visible fleet/route lines and sector stakes.

### 5. Surface mission ends flat and has no pressure
- Symptom: Core dead t=67, then "return to your ship" with ship 223 m away and nothing happening for 30 s; min_hp 84.
- Evidence: surface_long log.
- Why: the on-foot payoff is a quiet walk; the climax is the Core kill, which is under-celebrated.
- Direction: a short collapse/extract beat with a counter-attack wave, and a clear waypoint to the ship.

## Protect this
- Hot opening: objective bar, bounty popups and "Next raid" HUD timer; combat.png and touch.png read instantly.
- The pinned command strip with raid status and Call Reserve at the top of the map panel; do not push it back below the fold.

## One bold idea
"Sovereign's Decree": a once-per-run, cooldown-gated command-map ability that spends a big credit pile to declare a sector Fortified for 2 minutes (platforms spawn, Union ships rally, raids turn back) with an on-screen proclamation. It gives surplus a sink and makes the rising-sovereign fantasy visible.
