# S0044 Critic review: Void Sovereign

_Seventh critic review; compared with `S0037-critic.md` (6.7/10). Build: HEAD after S0043 (VS-048 paid station repair, DAMAGED labels, dock Repair button, HUD hull %). Evidence rendered 2026-10-28 into `.tools/shots/void-sovereign/` (title, map, dock, surface, combat re-rendered; viewed: combat, wound_dock; wound_map/wound_hud are QA shots from S0043, not re-viewed; touch, touch_surface, over, win not re-rendered this run, so touch/over/win scores carry over). `combat_long` and `surface_long` re-run headless. Balance from metrics.csv (S0037 9-seed gate; S0043 6-seed econ / 3-seed passive rerun, unchanged sim)._

| # | Pillar | Score | Trend | Justification |
|---|---|---|---|---|
| 1 | Fantasy | 6 | → | Repair bill makes the HQ a thing you own, but the active player still never sees it hurt (no wound in any scripted run). |
| 2 | Flight feel | 7 | → | `combat_long`: sh 400 -> 108 by t=33, back to 400 by t=49, hull 600 throughout. Unchanged. |
| 3 | Command depth | 7 | → | Repair is a new credit sink, but bots never repair and nothing forces the choice (repair vs Corvette 16,000). |
| 4 | On-foot FPS | 7 | → | `surface_long`: flank=6 now; hp dips to 84 (min_foot 315) at t=57 then stays 84 and ends untouched. First visible cost, still trivial. |
| 5 | Economy legibility | 6 | → | Ledger has a "repair" category and the dock quotes the price ("Station hull 60% — Repair (4800 cr)", `wound_dock.png`). But `combat.png` top bar still shows bare "+150 cr", despite VS-040 net label. |
| 6 | First 10 minutes | 7 | → | Hot opening intact; tip 1 vs first fight collision not touched. |
| 7 | Readability & UX | 7 | → | Dock repair line reads clearly. Open P3s: Defend button ~30 px at 900x720, map DAMAGED label clip, HUD % past backing. |
| 8 | Visual identity | 7 | → | No change; ships and stations still box-kit. |
| 9 | Pacing & difficulty | 6 | → | Persistence exists in the code but cannot bite: econ HQ survives 9/9, nothing in a normal run chips the HQ. Passive 0/9 survive, median 28.9 min. |
| 10 | Web/touch fitness | 7 | → | Still no real-browser pass (VS-042/VS-006, now seven reviews). |

**Average: 6.7 / 10** (S0037: 6.7). Biggest mover: none; no pillar changed. Nothing regressed.

## Extra ask: is 12k HQ repair plus permanent damage too punishing or too soft?

**Verdict: too soft in practice, slightly mis-shaped in principle. Do not lower the price.**

- **The numbers.** `STATION_REPAIR_COST` 0.4 cr per hull point; HQ hull 30,000 so full rebuild is 12,000 cr (`defs.gd:47`, `defs.gd:85`). Dock quote at 60% hull is 4,800 cr (`wound_dock.png`). Start credits are 30,000; nw10 median is ~94k, nw20 ~121k (S0037/S0043). So 12k is 40% of the starting purse but about 13% of a 10-minute net worth and ~10% at 20 min. Late it is a rounding error; at 5 to 8 minutes it is a real choice (about 2.7 fighters).
- **Why too soft.** The wound is rarely taken. In every scripted run the HQ is never damaged (no wound visible in `combat_long`; economic gate is 9/9 HQ survived). The design only matters if raids actually reach the HQ, and the Breach (one scripted raid) is the only guaranteed contact. A cost that never appears is not a cost. There is also no urgency: station hull never regenerates but nothing degrades with low hull (no reduced intake, shield, or gun output; the "reduced intake below 50% hull" idea is only in the parking lot). You can leave the HQ at 40% forever and lose nothing but the number, then pay once when rich. Permanent damage with no consequence is a to-do item, not a pressure.
- **Why not too punishing.** The cost is linear and partial repair is allowed (`repair_station` pays up to available credits), so a broke player can patch incrementally; the HQ is never bricked. A player at 100% hull to 0% loses the run anyway (HQ lost), so the repair price only matters on the survivable middle. That middle is where it should hurt more, not less.
- **Where it could turn punishing.** If the follow-up makes wounds bite (reduced income, shield cut) AND raids are tuned to land more, a player who is hit before ~minute 8 (cash ~50-60k, nothing banked) would face a 12k bill plus a weaker HQ with no regen: a death spiral. Passive HQ loss median 28.9 min already sits near the 35 ceiling; do not tune raids harder without a second look.
- **Recommended direction (not implementation).** Keep 0.4 cr/pt. Make damage matter before it makes the HQ die: scale something the player feels (shield, turret DPS, or income) with hull %, so ignoring a wound costs more than paying. Make the repair price progressive or show "repair now saves X" so the decision is legible. Let raids that reach the HQ do real chip damage (verify with a damaged-HQ shot scenario `hq_wounded`). Give the wing/drydock a sink so repair competes with ship purchase early rather than only at the end. Re-run the 9-seed gate after any of that because passive loss time is at the edge.

## Top 5 problems (by player impact)

### 1. Persistent damage exists but never triggers in normal play
- **Symptom:** hull 600 for the whole `combat_long` run; `surface_long` min_hp 84; economic runs 9/9 HQ survived; no wounded-HQ state occurs organically.
- **Evidence:** `combat_long` t=1..97; `surface_long` t=57..97; metrics S0037/S0043 economic rows; `wound_dock.png` is a hand-built scenario.
- **Why it matters:** S0037 problem 1 is the same problem, now with a bill attached. The new cost and the DAMAGED label are invisible to a player who defends competently.
- **Direction:** raids and the Breach must leave marks (shield-pierce chip damage when not intercepted in-sector); add a consequence for low hull.

### 2. Damage has no consequence below zero
- **Symptom:** a 40% HQ works exactly like a 100% HQ (income, shield, guns unchanged); repair is purely optional.
- **Evidence:** `universe.gd:316-328` (cost only); no hull-% scaling anywhere in sim; BACKLOG VS-048 follow-up lists intake reduction as a parking-lot item.
- **Why it matters:** rational players will skip repair until they have spare cash, so the 12k price is not a decision.
- **Direction:** scale one visible stat with hull %; promote "reduced intake below 50% hull" from the parking lot.

### 3. Bots never repair, so balance ignores the sink
- **Symptom:** HANDOVER: "Bots never repair, so late-game balance ignores repair spending."
- **Evidence:** HANDOVER line 29; metrics S0043 row (sim unchanged).
- **Why it matters:** the new sink could shift nw30 and passive HQ-loss time in ways the gates cannot see; balance sign-off for VS-048 is incomplete (full 9-seed gate not run).
- **Direction:** give the econ bot a repair-when-above-N-credits policy and rerun the gate (target: econ HQ survive >= 7/9, passive loss 20-35 min).

### 4. Economy HUD still shows an unlabelled "+150 cr"
- **Symptom:** `combat.png` top-left: "30,150 cr  +150 cr"; VS-040 claimed a labelled net cr/min.
- **Evidence:** `combat.png` at T+00:03.
- **Why it matters:** a repair purchase will also show as an unlabelled delta; the HUD is the thing watched most. Either the label only appears after a window of income or the fix did not take; verify.
- **Direction:** label as cr/min net, and show a one-off delta transiently with a sign and source ("-4800 repair").

### 5. Real-browser behaviour still unverified, and the opening tip collides with the first fight
- **Symptom:** VS-042/VS-006 slipped a seventh review; tip 1 "Click to capture the mouse" still sits over the first fight (`combat.png`: Hive Drone 1.7 km out at T+00:03 while the objective line is the only guidance).
- **Evidence:** HANDOVER open question; `combat.png`.
- **Why it matters:** save/IndexedDB/audio failures kill the first impression and repair state now rides on saves (new save field).
- **Direction:** one real-browser pass including a save round-trip of a damaged HQ; reorder tips by what is happening.

## Protect this
- **Dock quote that names the price in the button** ("Station hull 60% — Repair (4800 cr)"): honest, legible, and the right place for the decision.
- **The hot opening and pure-observer ledger with atomic Continue/New Game** (carried over), plus the pylon beams and Core spire on the surface.

## One bold idea
**Wounds with a clock:** a damaged HQ below 50% hull begins to leak (income and shield scale down) and a "Dockyard Crew" building or hired repair ship slowly mends it for less than the 12k cash price, so the player chooses between buying time with a station and paying cash now. It turns the new repair sink into a real macro decision (cash vs infrastructure vs fleet) and gives raids a purpose beyond a countdown.

## Notes for open questions (HANDOVER)
- 12k price: keep. Fix consequences, not the number (see Extra ask).
- Permanent damage: keep, but it needs a felt consequence and an organic trigger.
- Reduced intake below 50% hull: yes, do it (problem 2).
- Repair from map without docking: yes, but add a small premium so docking stays cheaper; otherwise the dock trip is meaningless.

## Evidence index
- **Screenshots:** `.tools/shots/void-sovereign/{title,map,dock,surface,combat}.png` (fresh); `wound_dock.png`, `wound_map.png`, `wound_hud.png` (S0043 QA).
- **`combat_long`:** credits 30,000 -> 30,150 at t~11 -> 31,933 at t=65; shield 400 -> 108 by t=33, 400 by t=49; hull 600 throughout.
- **`surface_long`:** pylon1 45 s, pylons 55 s, Core dead 67 s, flank=6 at t=49, min_foot 315, min_hp 84; no SCRIPT ERROR.
- **Code:** `defs.gd:47,85`, `universe.gd:316-328`, `selftest.gd:1219`.
