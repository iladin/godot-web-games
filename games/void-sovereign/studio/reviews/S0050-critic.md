# S0050 Critic review: Void Sovereign

_Eighth critic review; compared with `S0044-critic.md` (6.7/10). Build: HEAD after S0049 (raid chip 0.015, wounded HQ penalty, bot HQ repair, signed credit deltas, redirect A/B, redirect stays off). Evidence rendered 2026-10-28 into `.tools/shots/void-sovereign/`: combat, map, touch, surface viewed; dock, over, win, touch_surface re-rendered but not viewed (title.png is stale, 13:12; title score carries over). `combat_long` and `surface_long` re-run headless, no script errors. Balance from `.tools/balance_gate/{qa49_default,chip2}`, metrics.csv, `reviews/S0049-redirect-ab.txt`. No real-browser pass exists (VS-042 blocked), so pillar 10 is code-reading only._

| # | Pillar | Score | Trend | Justification |
|---|---|---|---|---|
| 1 | Fantasy | 6 | → | Chip + wound now exist in the sim, but the scripted player still never sees the HQ hurt (`combat_long` hull 600 flat, HQ bar full in `combat.png`). |
| 2 | Flight feel | 7 | → | `combat_long`: sh 400 -> 108 by t=31, back to 400 by t=43; hull 600 throughout. Identical to S0044. |
| 3 | Command depth | 7 | → | Repair (0.4 cr/pt) vs ships is now a real trade in the bot data, but redirect was a dead end and the map offers no raid-response lever beyond "build Defense". |
| 4 | On-foot FPS | 7 | → | `surface_long`: flank=6 at t=49, foot hp 84 then untouched; Core dead t=67, then 30 s of nothing. Objective text in `surface.png` is clear. |
| 5 | Economy legibility | 7 | ↑ | Signed deltas and net label shipped (VS-053/VS-047); `combat.png` now reads "+150 cr bounty" with a source. Map panel lists the three ways to earn before first income. |
| 6 | First 10 minutes | 7 | → | Hot opening intact. `touch.png`: tip box, "Need credits? Dock at Trade Hub" hint and OBJECTIVE all stack at the bottom, tip 1 is "Drag to steer" while the first Sortie is minute one. |
| 7 | Readability & UX | 7 | → | Map panel clean at 900x720; touch layout cramped (tip box over THR-/TGT cluster, `touch.png`). Open P3s unchanged. |
| 8 | Visual identity | 7 | → | Surface pylon beams + Ember pink sky read as intentional; ships and stations still box-kit. |
| 9 | Pacing & difficulty | 6 | → | Chip makes raids matter, but the cost is a cliff, not a ramp: 8/9 HQ survives, and two of nine seeds are wrecks (101 nw30 40.9k with 5 ships; 135 lost at 29.7 min). Median nw30 fell 157.6k -> 123k. Passive 0/9. |
| 10 | Web/touch fitness | 7 | → | No real-browser pass, now eight reviews running. Touch HUD works but is crowded. |

**Average: 6.8 / 10** (S0044: 6.7). Biggest mover: Economy legibility (+1). Nothing regressed.

## Extra ask: do late economy / seed 135 need a bigger bot repair reserve?

**Verdict: no. The repair reserve is not the lever; do not spend a session tuning it.** (If "bigger reserve" means a bigger repair *allowance*, i.e. a lower `REPAIR_RESERVE` than 25,000, the answer is still no for the same reasons.)

- **Reserve never binds in the failing seeds.** `repair_spent` for seed 135 at chip 0.02 was 4,370-4,398 before it died at 23.7 min; in the 0.015 run that survived (`.tools/balance_gate/*`, nw30 20,847) it spent only 293 with HQ hull ending 0.67. credits_20 was 6,967-9,443, credits_30 4,375. The bot is below the 25k reserve almost the whole game, so repair rarely fires at all; it spends everything on ships first.
- **The seed-135 failure is a collapse of the Union and fleet, not an unpaid hull bill.** player_ships 10 -> 3, union_ships 21 -> 9 -> 3, hive_ships 63 -> 95, raids 17 in 30 min. HQ hull 0.67 at end is not the killer; there is simply nothing left to kill raiders. Seed 101 shows the same shape in the passing 0.015 run: nw20 115.7k -> nw30 40.9k, 14 -> 5 ships, repair_spent 3,945.
- **Raising repair priority would make it worse.** Credits spent on hull are not spent on fighters, and the data says fleet count is what holds. Wound penalty is capped at 30% of colony income and shield regen, small next to losing the escort.
- **0.015 verdict.** It moved seed 135 from 23.7 to 29.7 min (still lost), left 101 intact on HQ but gutted its net worth, and kept nw30 median ~123k. This is a fine knob; it bought time, not stability. The weak tail is the real issue: Q1 nw30 48k (S0049b) vs 105k at 0.02 median-seeds, i.e. variance went up, not down.
- **What would actually help a bot (direction, not implementation):** a late-game "fleet floor" policy in the harness (keep >= N warships before buying anything else after min 18), and platforms earlier on seeds whose Union drops below ~10 ships. That tests whether the economy has a recoverable path, which is the player-facing question: "can I come back from losing my fleet at minute 20?" Today the answer in the data is no.
- **Human-facing implication:** a human who gets chipped repeatedly (3-4 raids x ~9%) faces a 12k repair bill at the exact time the bot shows cash is lowest. Nothing in the UI warns "next raid will cost ~X% hull"; the dock only quotes after the fact.

## Top 5 problems (by player impact)

### 1. Late-game collapse is a cliff with no comeback path
- **Symptom:** two of nine economic seeds end wrecked (101: 14 -> 5 ships, nw 115k -> 41k in 10 min; 135: HQ lost 29.7 min).
- **Evidence:** `.tools/balance_gate/qa49_default`; S0049b row: HQ 8/9, nw30 Q1 48,075; passive median 27.3 min, 0/9.
- **Why it matters:** once the fleet is under ~10 ships against 60-95 Hive ships there is nothing a player can buy that stabilises. It reads as arbitrary loss, not a mounting-pressure story.
- **Direction:** give the late game an explicit recovery tool (cheap defensive purchase, drydock rebuild, or Union reinforcement call-in) and test with the bot, rather than tuning chip damage.

### 2. The active player still never feels the new systems
- **Symptom:** `combat_long` hull 600 for 97 s; HQ bar full in `combat.png`; surface min_hp 84; wound/chip exist only in the long-sim.
- **Evidence:** `combat_long` and `surface_long` logs above; S0044 problem 1 unchanged.
- **Why it matters:** chip, wound, repair are the headline S0043-S0049 work and none appear in a short human session (first raid 3.3 min).
- **Direction:** make the Breach/first raid visibly land (arrival telegraph with predicted hull cost) and show the HQ hull as a number on the HUD bar.

### 3. No pre-raid information, so damage cannot be planned for
- **Symptom:** top bar shows "Next raid 196s" only; no raid size, no target, no expected hull cost. Dock only quotes cost after damage.
- **Evidence:** `combat.png`, `touch.png` (top-left HUD); chip formula in DESIGN.md.
- **Why it matters:** command depth requires foreseeable choices (defend, build platform, repair first).
- **Direction:** raid preview at T-60 s (ships, sector, "~9% hull if unintercepted") on HUD and map.

### 4. Touch first-run HUD is a pile-up
- **Symptom:** bottom of `touch.png`: tip box, trade hint and OBJECTIVE all stacked; tip box overlaps THR- and TGT circles; first tip is "Drag to steer" while a Sortie is about to arrive.
- **Evidence:** `.tools/shots/void-sovereign/touch.png`.
- **Why it matters:** the phone is the web target; this is the first screen a mobile player sees.
- **Direction:** one message lane at the bottom (priority queue), tip box away from thumb clusters, tips ordered by what is happening.

### 5. Real-browser behaviour still unverified (eighth review)
- **Symptom:** VS-042 blocked on the network allowlist (HANDOVER).
- **Evidence:** HANDOVER open questions; export templates installed S0049.
- **Why it matters:** autosave/IndexedDB/audio/touch-in-iframe failures are the first-impression killers, and save now carries wound state.
- **Direction:** Daniel to allow cdn.playwright.dev or point at an installed chromium; first test: damaged-HQ save round trip.

## Protect this
- **Pure-observer ledger with signed, source-labelled deltas** ("+150 cr bounty", net/gross wording): the best legibility work in the repo.
- **Paid repair quote in the dock button and the surface landing pylons/beam readout**: both tell the player what to do next at a glance.

## One bold idea
**Fleet Reserve call-in:** once per 10 minutes, spend a large lump of credits to summon a Union relief squadron to the HQ sector. It gives the late game a comeback button, turns "I just lost my fleet" into a decision rather than a loss, and gives the bot a measurable recovery policy to test against seeds 101/135.

## Evidence index
- **Screenshots:** `.tools/shots/void-sovereign/{combat,map,touch,surface}.png` viewed; `{dock,over,win,touch_surface}.png` rendered 19:04 but not viewed; `title.png` stale.
- **`combat_long`:** sh 400 -> 108 at t=31, 400 by t=43; credits 30,000 -> 31,933 at t=64; hull 600 throughout; no script errors.
- **`surface_long`:** pylon1 45.3 s, pylons 55.4 s, Core 67.1 s; flank=6 at t=49; min_foot 315, min_hp 84; no script errors.
- **Balance:** `.tools/balance_gate/qa49_default/first_{0,3,6}.txt`, `chip2`, metrics.csv S0048 rows, `reviews/S0049-redirect-ab.txt`. Seed 135 numbers cited from earlier `chip1`/`chip2` runs (0.02) plus the 0.015 run.
