# Void Sovereign — design

- **Pitch:** A pocket X4: fly, trade and fight across a living 7-sector cluster, command your growing fleet from a tactical map, and land on Hive-infested worlds to fight on foot — because the Hive Nests in space can only be killed once their planetside Cores fall.

## Three layers, one simulation
Everything (every ship, station, ware and credit in all 7 sectors) lives in one data simulation (`scripts/sim/universe.gd`). The 3D views only *render* the sector the player is in — the rest keeps running out of sight, X4-style.

| Layer | What you do | Where |
|---|---|---|
| **Flight** (space sim) | Fly your interceptor, shoot, dock to trade and repair, jump gates, land on planets | `scripts/space/` |
| **Command** (RTS) | Tactical map: select owned ships, order move/attack/patrol/escort/auto-trade/auto-mine, buy ships, build stations | `scripts/ui/map_view.gd` |
| **Surface** (FPS) | On foot on a procedural planet: destroy shield pylons, then the Hive Core, survive waves | `scripts/surface/` |

## Core loop
Earn credits (trade, mining fleets, stations, bounties, colonies) → buy fighters/corvettes → land on Hive worlds and kill their Cores → send the fleet to kill the now-unshielded Nests → before Hive raids grind down your HQ.

## Economy
4 wares: Ore (mined from asteroid fields) → Refinery (Ore+Energy → Alloy) → Factory (Alloy+Energy → Munitions); Solar makes Energy. Shipyards consume Alloy + Munitions. Prices float with stock (`price = base × lerp(1.4, 0.6, fill)`). A batch is priced unit by unit along that curve, each unit at the stock level after it moves (`StationData.batch_total`, VS-016): buying pays the rising side and selling gets the falling side, so buying and immediately selling back at one station always loses a little — no same-station arbitrage, profit comes only from carrying wares between stations. The dock panel shows the spot (next-unit) price. Every trade between owners moves player credits; Union money is infinite. Trade Hubs buy every ware and export surplus off-map each cycle, so they stay a reliable buyer. NPC Union traders and miners keep the market moving; player stations sell to them.

## Factions
Sovereign (you, amber) · Union (neutral-friendly, cyan) · Hive (hostile, magenta).

## Controls
| | Keyboard / mouse | Touch |
|---|---|---|
| Flight | Mouse (click to capture) or arrows steer · W/S throttle · Q/E roll · Shift boost · T travel drive · LMB/Space fire · R target · G fleet attacks target · F dock/land · M map · X stop · P pause · N mute · H skip tips | Left stick steer · FIRE, BOOST, THR±, TGT, ACT, MAP, SND buttons · SKIP TIPS chip under the tip box |
| Map | LMB select (drag = box) · RMB order · wheel zoom · click galaxy to switch sector | Tap select · toggle ORDER, then tap to order |
| Surface | WASD · mouse look · LMB fire · R reload · Space jump · Shift sprint · F board ship · N mute | Left stick move · drag right half to look · FIRE / JUMP / RELOAD / ACT / SND |

First-run tips (`tutorial_hints.gd`) show one at a time; a tip waits until it can be done now (the target tip waits for a Hive ship in your sector, later tips are not blocked). While a tip shows, the HUD capture-mouse line is hidden. R / TGT with nothing to lock says "No hostiles in range". H (touch: SKIP TIPS chip) hides tips for the run.

## Win / lose / score
- **Win:** both Hive Nests destroyed.
- **Lose:** your HQ station is destroyed. (Dying in your ship respawns you at HQ for 25% of your credits; dying on foot evacuates you to orbit.)
- **Score:** net worth + 5,000 per colony + (on win) 50,000 + time bonus. Best saved to `user://save.cfg`.

## Ramp
- Hive raid every `max(75, 180 − t/12)` s; size `RAID_SIZE_START + t/RAID_SIZE_GROWTH` = `3 + t/90` (cap 16). Ravagers from 5 min, Dreadnoughts from 15 min. A raid whose target is gone withdraws to the nearest Nest instead of camping the sector.
- What lets an economic player outgrow the ramp (VS-001, all tunables in `defs.gd`): Trade Hubs export surplus (`TRADE_HUB_EXPORT` 80/cycle above `TRADE_HUB_TARGET_FILL` 10%) so ore and trade income doesn't stall; miners and freighters plan around sectors with ≥ `CIVILIAN_AVOID_HIVE` (2) Hive warships and need `CROSS_SECTOR_SELL_PENALTY` (6 cr/unit) more to sell outside their sector; your warships patrolling the HQ sector fight within HQ gun range + `GUARD_LEASH` (400) and regain hull near the HQ (`REPAIR_RATE` 2%/s within `REPAIR_RANGE` 2000 when not under fire). Fighter 320 hull / 180 shield / 36 dps; HQ 30,000 hull / 6,000 shield.
- Measured (S0003, `balance.sh`): economic 30 min × 6 seeds → net worth at 20 min median ≈ 139k, HQ survives 5/6; passive 40 min × 3 seeds → HQ lost at ≈ 25 min (median). A player who builds nothing still loses.
- Nest drone spawn interval `max(12, 30 − t/40)` s, cap `6 + t/120`.
- Surface level 1–3: pylons = level + 1, more enemies per wave, faster waves.

## Juice
Screen shake on hits, explosion flashes + debris, hit markers, damage vignette, shield shimmer, floating bounty text, travel-drive streaks.

## Run flow
`scripts/run_flow.gd` (RunFlow, owned by main.gd) handles title → play → end → restart. The universe only simulates while a run is in progress. It is frozen behind the title screen (no raid countdown, no time charged against the win bonus) and behind the end screen. When a run ends, the command map and dock close and the HUD and touch buttons hide, so any click, tap or Space restarts. If a run ends during the landing fade, no surface is built.

## Audio
`scripts/audio/sfx.gd` (owned by main.gd, no autoload) synthesises six effects at startup into `AudioStreamWAV` (22050 Hz mono 16-bit, ~2 s total, a few ms): laser, rifle, hit, explosion, gate jump, UI click. No files, no `AudioStreamGenerator`. Nothing plays before the first key/click/tap (browser autoplay rule). N or the SND touch button toggles mute. Volumes and pitch jitter (±8 %) are constants at the top of the script; explosions are audible within 2.5 km in flight.

## Testing hooks
`scripts/check.sh void-sovereign` runs import, title smoke, a 15 s `--autoplay` that first idles 10 frames on the title (asserting the world is frozen) and then walks flight → map orders/buy/build → dock → landing + FPS → evacuation, and `scripts/selftest.gd` (routing, pricing, transactions, production, 8 simulated minutes, Core→Nest unlock).
`scripts/test_driver.gd` also supports `-- --shot=<title|map|dock|surface|touch|over|over_map|win|death|combat> --shotfile=out.png` for rendered screenshots (run without `--headless`).

## Out of scope
Ship interiors, boarding, research tree, diplomacy, save-anywhere (only best score persists), multiplayer, audio assets.
