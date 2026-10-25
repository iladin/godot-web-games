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
4 wares: Ore (mined from asteroid fields) → Refinery (Ore+Energy → Alloy) → Factory (Alloy+Energy → Munitions); Solar makes Energy. Shipyards consume Alloy + Munitions. Prices float with stock (`price = base × lerp(1.4, 0.6, fill)`). Every trade between owners moves player credits; Union money is infinite. NPC Union traders and miners keep the market moving; player stations sell to them.

## Factions
Sovereign (you, amber) · Union (neutral-friendly, cyan) · Hive (hostile, magenta).

## Controls
| | Keyboard / mouse | Touch |
|---|---|---|
| Flight | Mouse (click to capture) or arrows steer · W/S throttle · Q/E roll · Shift boost · T travel drive · LMB/Space fire · R target · G fleet attacks target · F dock/land · M map · X stop · P pause | Left stick steer · FIRE, BOOST, THR±, TGT, ACT, MAP buttons |
| Map | LMB select (drag = box) · RMB order · wheel zoom · click galaxy to switch sector | Tap select · toggle ORDER, then tap to order |
| Surface | WASD · mouse look · LMB fire · R reload · Space jump · Shift sprint · F board ship | Left stick move · drag right half to look · FIRE / JUMP / RELOAD / ACT |

## Win / lose / score
- **Win:** both Hive Nests destroyed.
- **Lose:** your HQ station is destroyed. (Dying in your ship respawns you at HQ for 25% of your credits; dying on foot evacuates you to orbit.)
- **Score:** net worth + 5,000 per colony + (on win) 50,000 + time bonus. Best saved to `user://save.cfg`.

## Ramp
- Hive raid every `max(70, 180 − t/12)` s; size `3 + t/90`. Ravagers from 5 min, Dreadnoughts from 15 min.
- Nest drone spawn interval `max(12, 30 − t/40)` s, cap `6 + t/120`.
- Surface level 1–3: pylons = level + 1, more enemies per wave, faster waves.

## Juice
Screen shake on hits, explosion flashes + debris, hit markers, damage vignette, shield shimmer, floating bounty text, travel-drive streaks.

## Testing hooks
`scripts/check.sh void-sovereign` runs import, title smoke, a 15 s `--autoplay` that walks flight → map orders/buy/build → dock → landing + FPS → evacuation, and `scripts/selftest.gd` (routing, pricing, transactions, production, 8 simulated minutes, Core→Nest unlock).
`scripts/test_driver.gd` also supports `-- --shot=<map|dock|surface|touch|over|win|death|combat> --shotfile=out.png` for rendered screenshots (run without `--headless`).

## Out of scope
Ship interiors, boarding, research tree, diplomacy, save-anywhere (only best score persists), multiplayer, audio assets.
