# S0019 Critic review: Void Sovereign

_Third critic review. Compared with `S0012-critic.md` (5.5/10). Build: HEAD after S0018 (VS-024 ledger, VS-005 marker declutter, VS-022, VS-010, VS-007 wing commands, VS-023 raid-deterrent range done since S0012). Evidence rendered 2026-10-27 into `.tools/s0019_critic/shots/` (title, map, dock, surface, touch, touch_surface, combat, over, win). Balance gates not re-run; numbers quoted from metrics.csv (S0018 rows). No probe re-run: raid/sortie findings from S0012 are carried over, unverified this round; VS-025 (honest raid reports) is still todo, so they should still hold._

| # | Pillar | Score | Trend | Justification |
|---|---|---|---|---|
| 1 | Fantasy | 6 | → | Wing orders (G/C/V) let you act like a commander. But the HQ is still never touched in a normal game, so you administer a realm and never defend it. |
| 2 | Flight feel | 5 | → | `combat_long` still reads hull=600 on all 7 lines (t=5..95). Nothing in the flight or opening-fight path changed. |
| 3 | Command depth | 7 | ↑ | Wing orders (HUD "WING 2 · ESCORT", ATK/ESC/HOLD touch buttons) plus map orders plus a visible "Last 5 min" ledger make spending choices readable. The deterrent still dominates as the best spend (0.25^n). |
| 4 | On-foot FPS | 5 | ↑ | VS-005 merged the overprinted pylon labels into one "2x PYLON 366m" (`surface.png`). The terrain is still flat salmon. `surface_long` is unchanged: pylons down ~t=50, Core 53% at t=55, hull 360 afterwards. |
| 5 | Economy legibility | 6 | ↑↑ | The biggest fix. HUD shows "+N cr/min" under credits, the map panel shows "Income +0 cr/min / Last 5 min: no credit changes yet", and the dock repeats it. It's still empty at t=0 and the breakdown wasn't visible in a mid-game shot (not rendered). |
| 6 | First 10 minutes | 7 | ↑ | One tip, one objective, tip 4 now points at the Union Trade Hub. Raid countdown "Next raid 196s" is visible from the start. Touch OBJECTIVE still says "press F to land" and the HQ dock still says "This station does not trade wares." |
| 7 | Readability & UX | 7 | → | The HUD is clean and the "Next raid" timer is a good addition. On touch, HOLD overprints the "Trade Hub 2.0km" label and THR+ sits on the station silhouette (`touch.png`); the wing row is mid-screen. |
| 8 | Visual identity | 6 | → | The amber/cyan/magenta palette and the glowing Ember planet still carry the look. The surface is untouched, and the ships are box-kit. |
| 9 | Pacing & difficulty | 5 | → | VS-023 (range-limited deterrent, DREAD_TIME 1200) lifts nw30 to 142k, i.e. it's even more comfortable. Passive HQ still falls at ~34 min, but an active player has no pressure. `--perturb=1` margin is thin (129k vs 126k). |
| 10 | Web/touch fitness | 7 | → | Touch layout is functional with the SKIP TIPS chip. Wing buttons added a crowded top row. VS-006 (web perf guard) is still unverified two reviews running. |

**Average: 6.1 / 10** (S0012: 5.5). Biggest mover: Economy legibility, +3 (3 → 6). Command depth, On-foot FPS and First 10 minutes +1 each. Nothing regressed.

## What improved since S0012
- **S0012 problem 1 (economy invisible): mostly fixed** by VS-024. The cr/min figure and "Last 5 min" panel exist in HUD, map and dock (`map.png`, `dock.png`), and tip 4 retargets the Trade Hub.
- **S0012 problem 4 (pylon overprint): fixed** by VS-005 (`surface.png`). The landmarks half of that problem (terrain readability) is not addressed.
- **Wing commands (VS-007)** give the escorts a job the player controls.
- **Not addressed:** S0012 problems 2 (raids never arrive), 3 (first fight belongs to the escorts) and 5 (raid-immune turtle; only partly eased by VS-023's range rule).

## Top 5 problems (by player impact)

### 1. The HQ is never threatened; raids remain a false alarm (VS-025 still todo)
- **Symptom:** "Next raid 196s" is now permanently on the HUD (`combat.png`), which promotes the promise, yet S0012's probe showed raids "moving on HQ" at 200/363/513 s with HQ 30,000/30,000 at t=600.
- **Evidence:** S0012 probe (carried over); metrics S0018 passive40 HQ lost ~33 min only when the player does *nothing*, and an active player gets nw30 142k with HQ 9/9. HANDOVER confirms VS-025 not started.
- **Why it matters:** the main tension device lies and now has a countdown that draws attention to it. A 40-minute run can pass without the HQ bar moving.
- **Direction:** ship VS-025 and report where each raid ends. Make one early raid (min 5-7) actually reach the home sector as a beatable fight. Show raid groups and ETA on the galaxy inset.

### 2. The player's first fight is still fought by the escorts
- **Symptom:** unchanged from S0012. The sortie scouts die at t=75-78 to the two escorts. `combat_long` shows hull=600 for 95 s.
- **Evidence:** `combat_long` (7 lines, all hull=600, credits 30,150 -> 30,300 -> 31,783 at t=65); DESIGN.md "escorts alone win in 15-18 s".
- **Why it matters:** boost, roll and evasion have no purpose in the first 10 minutes, and the new wing commands have no early test either.
- **Direction:** give the player the first kill and some danger inside the sortie flag: delay the escorts or have the scouts focus the player. Let the new HOLD/ESC/ATK commands matter here.

### 3. On-foot layer is still the weakest pillar: flat terrain, no landmark
- **Symptom:** the label fix helped, but `surface.png` is a salmon plain with no visible Core or pylon beam. Players depend on the "PYLON 366m" text to know where to go. `surface_long` is identical to S0012, with the bot done by t=55 and hull dropping to 360.
- **Evidence:** `.tools/s0019_critic/shots/surface.png`; `surface_long` t=5..55 all "Destroy the shield pylons (2 left)" until Core 53%.
- **Why it matters:** the win condition runs through two surface Cores, and this is where the player spends the climax.
- **Direction:** 2-3 readable landmarks (Core spire visible from the landing site, pylon beams to the sky) and some enemy behaviour that is more than "stand and be shot". Gunfeel pass: hit-marker, recoil, and kill feedback.

### 4. Late game is a raid-immune turtle with a thin perturbed margin
- **Symptom:** nw30 median 142k vs nw20 108k, HQ 9/9. The deterrent still scales 0.25^n, and VS-023 only restricts it by range. `--perturb=1` is 129k vs 126k with 4/9 seeds below.
- **Evidence:** metrics S0018 rows; HANDOVER "Watch out for".
- **Why it matters:** 20-40 minutes become economy idling. Combined with problem 1 there's no pressure to use the new command tools.
- **Direction:** redirect deterred raids to Union stations or soft player assets (see bold idea). Re-run both 9-seed gates, plus perturb, after each change.

### 5. Small friction that still sits in the first minute
- **Symptom:**
  - Touch OBJECTIVE says "press F to land" (`touch.png`).
  - The HQ dock says "This station does not trade wares." before it lists ships costing 4,500-16,000 cr, with no hint of how to earn (`dock.png`).
  - On touch, HOLD sits on top of the "Trade Hub 2.0km" label and THR+ on a station silhouette.
  - The title text still prints over the ship model (`title.png`, unchanged by inspection of the shot list; not re-inspected in detail).
- **Why it matters:** cheap fixes, but each one is a moment of confusion in the first 60 seconds on the platform (phone web) where many players will land.
- **Direction:** bundle into the planned P3 polish task: input-aware objective text, one-line earn hint in the HQ dock, a backing fill for touch buttons.

## Protect this
- **The ledger (VS-024) as a pure observer.** `Universe.add_credits(amount, cat)` as the sole writer, balance JSON byte-identical. Don't let new income sources bypass it.
- **One-voice tips plus the First Sortie hook (VS-017/018)** and the clean HUD (`combat.png`: one tip, one objective, one welcome line, raid timer).

## One bold idea
**Visible war fronts** (carried over, and now cheaper because the ledger exists). Every Hive raid is a tracked fleet on the galaxy inset with a target and ETA. The player can intercept it with the wing (a bounty line in the ledger), let platforms deter it (the raid *redirects* to the nearest Union station, and the Union buckles and the player loses a trade partner), or take the hit at the HQ. This fixes problems 1, 2 (via wing use) and 4 together, and turns the new wing and income tools into decisions the player can read.

## Evidence index
- **Screenshots** (1280x720): `.tools/s0019_critic/shots/{title,map,dock,surface,touch,touch_surface,combat,over,win}.png`; viewed: combat, map, surface, touch, dock. Not individually inspected: title, touch_surface, over, win.
- **`combat_long`:** sector 3, hull=600 on every line; credits 30,150 (t=5) -> 30,300 (t=20..50) -> 31,783 (t=65..95).
- **`surface_long`:** credits 30,000 -> 30,840 by t=55 (+180 per 10 s from t=25); "Core exposed (53%)" at t=55; hull 360 and sector 0 flight from t=65; credits 32,323 -> 32,773 (sortie bounties).
- **Balance:** quoted from metrics.csv rows S0018 (econ30 nw30 142,176; passive40 HQ lost 33.6) and HANDOVER (perturbed econ 129,014 vs 126,353). Not re-run.
