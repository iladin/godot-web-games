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
| Flight | Mouse (click to capture) or arrows steer · W/S throttle · Q/E roll · Shift boost · T travel drive · LMB/Space fire · R target · G wing attacks target · C wing returns/escorts · V wing holds position · F dock/land · M map · X stop · P pause · N mute · H skip tips | Left stick steer · FIRE, BOOST, THR±, TGT, ACT, MAP, SND buttons · ATK / ESC / HOLD wing buttons · SKIP TIPS chip under the tip box |
| Map | LMB select (drag = box) · RMB order · wheel zoom · click galaxy to switch sector | Tap select · toggle ORDER, then tap to order |
| Surface | WASD · mouse look · LMB fire · R reload · Space jump · Shift sprint · F board ship · N mute | Left stick move · drag right half to look · FIRE / JUMP / RELOAD / ACT / SND |

First-run tips (`tutorial_hints.gd`) show one at a time; a tip waits until it can be done now (the target tip waits for a Hive ship in your sector, later tips are not blocked). While a tip shows, the HUD capture-mouse line is hidden. R / TGT with nothing to lock says "No hostiles in range". H (touch: SKIP TIPS chip) hides tips for the run.

Pause (P, or focus loss; `ui/pause_gate.gd`): the world freezes and the mouse is released. Any key, one click, or a tap away from the touch buttons resumes (the resume click never fires or captures; the next click does). While paused only N / SND work (mute without resuming); MAP, TRVL, dock and map buttons are inert.

Title: Space, Enter, click or tap starts a New Game. When a valid autosave exists a "Continue (mm:ss)" button appears above the prompt: press C, click it or tap it to resume.

## Persistence: autosave and Continue (VS-027)
`SaveGame` (VS-026) is the data layer; `RunSave` (`scripts/run_save.gd`) does the file I/O at `user://run.save` (JSON). `RunFlow` autosaves every `AUTOSAVE_INTERVAL` (60 s) of PLAYING and on focus loss (before pausing), and deletes the file when the run ends (win or lose). A save is skipped while on foot (surface) or dead awaiting respawn; the previous save stays. Continue calls `VoidMain._new_world(restored)`, the same path New Game uses, so every signal/message hook, the HUD, map and space view bind to the restored Universe; the player returns in flight (undocked, in their sector), PauseGate stays main's first child. A missing/corrupt/wrong-version file just hides Continue. Restored runs are valid continuations, not bit-identical (global RNG reseeded). Autoplay/`--shot` runs use `user://run_autoplay.save` and never touch a real save. With a valid save, New Game (Space/click/tap) first shows "Replace your saved run?" (RunFlow.request_new_game; Esc or Continue cancels); a second press after 0.35 s deletes the save and starts over. With no save it starts at once. Corrupt/wrong-version files are ignored (no Continue). `--shot=title_continue|title_continue_touch|title_confirm` seed `user://run_autoplay.save`.

## Win / lose / score
- **Win:** both Hive Nests destroyed.
- **Lose:** your HQ station is destroyed. (Dying in your ship respawns you at HQ for 25% of your credits; dying on foot evacuates you to orbit.)
- **Score:** net worth + 5,000 per colony + (on win) 50,000 + time bonus. Best saved to `user://save.cfg`.

## Ramp
- **First Sortie** (VS-018, `scripts/sim/opening_wave.gd`, stepped by the Director): once per run, at `OPENING_WAVE_TIME` (60 s) of play time, `OPENING_WAVE_SIZE` (3) Hive Scouts (drones at `OPENING_WAVE_HULL` 3.0x hull, `OPENING_WAVE_DPS` 0.5x dps) appear `OPENING_WAVE_RANGE` (1300) ahead of the player in the home sector (along its heading, leaning toward Ember's orbit) and hunt the player. Scouts are the player's fight: they only trade fire with the player and Sovereign warships; stations, Union ships and the miner are ignored and ignore them (`OpeningWave.allows`, used by `Universe.valid_target`) until `OPENING_WAVE_LINGER` (240 s), after which they become normal drones. HUD message on arrival ("HIVE SCOUTS inbound from Ember ..."); when all are dead a message points to landing on Ember. Not a raid: the raid timer and `raid_count` are untouched (first raid still 3.3 min). Makes the "lock a Hive ship" tip reachable at minute one. Probe (seeds 7/101/118, pilot parked at HQ or near the Argent gate, pilot not firing): the two escorts alone win in 15–18 s, all kills by Sovereign fighters, player loses at most ~260 shield, hull untouched.
- Hive raid every `max(75, 180 − t/12)` s; size `RAID_SIZE_START + t/RAID_SIZE_GROWTH` = `3 + t/90` (cap 16). Ravagers from 5 min, Dreadnoughts from 20 min (`DREAD_TIME` 1200, VS-023; at 900 the pre-deterrent dreadnought raid caused every late collapse). A raid whose target is gone withdraws to the nearest Nest instead of camping the sector.
- Fortified sectors deter raids (VS-020, `Director.raid_go_chance`): from `RAID_DETER_FROM` (1200 s = 20 min) on, a raid aimed at a Sovereign station is called off ("Hive raid on X turned back by your Defense Platforms"; timer still resets, no ships spawn) unless a roll beats `RAID_DETER_PER_PLATFORM`^n (0.25^n), n = your Defense Platforms within `RAID_DETER_RANGE` (3400 = 2x platform gun range) of the target station (VS-023: a platform in another corner of the sector or inside a planet no longer counts; `build_station` also rejects positions inside a planet). Union targets and an undefended player are unaffected, and no extra random draw happens when n = 0, so the passive run and the first 20 minutes are unchanged. Gives late-game platform investment a payoff without buffing the shared platform.
- Raid bounty and redirect (VS-036): when a raid is intercepted (`RaidTracker`, outcome "intercepted") outside the HQ sector, every raider killed pays `RAID_INTERCEPT_BOUNTY` (40 cr, vs 150 for a drone kill) through `Universe.add_credits(..., "intercept")`, listed as "Raid intercepts" in the ledger breakdown; HQ-sector fights pay nothing extra. Redirect ships DISABLED (`Defs.RAID_REDIRECT_ENABLED := false`; it made perturbed economic runs much worse, so it needs a platform-building balance policy before re-enabling). When enabled, a deterred raid (VS-020) is no longer cancelled when a Union station exists: it launches at the nearest Union station by gate hops (`Director.nearest_union_station`, ties lowest id) with the normal inset marker and ETA, and its single outcome reads "Raid redirected to <station>: intercepted (k/n) / SUCCEEDED / withdrew" (kind `redirected`). With no Union station left (or redirect disabled) it just turns back as before; redirected raids pay no bounty. Deterrence only starts at 20 min, so the first 20 minutes are unchanged.
- What lets an economic player outgrow the ramp (VS-001, all tunables in `defs.gd`): Trade Hubs export surplus (`TRADE_HUB_EXPORT` 80/cycle above `TRADE_HUB_TARGET_FILL` 10%) so ore and trade income doesn't stall; miners and freighters plan around sectors with ≥ `CIVILIAN_AVOID_HIVE` (2) Hive warships and need `CROSS_SECTOR_SELL_PENALTY` (6 cr/unit) more to sell outside their sector; your warships patrolling the HQ sector fight within HQ gun range + `GUARD_LEASH` (400) and regain hull near the HQ (`REPAIR_RATE` 2%/s within `REPAIR_RANGE` 2000 when not under fire). Fighter 320 hull / 180 shield / 36 dps; HQ 30,000 hull / 6,000 shield.
- Wounded HQ (VS-050, `Defs.WOUND_PENALTY_START` 0.5, `Defs.WOUND_PENALTY_MAX` 0.3): below 50% hull the HQ applies a linear penalty (0 at 50% -> 30% at 0%) to colony income (the HQ trades no goods, so colonies are its income) and to its own shield regen (`StationData.wound_penalty/regen_mult`, `Universe.step`). The dock repair button and the map DAMAGED label quote the penalty and repair cost; repair (0.4 cr/pt, `STATION_REPAIR_COST`) clears it at once. Gate S0045: economic 30 min 9 seeds HQ survives 9/9; passive 40 min HQ lost median 28.9 min (unchanged, q1 28.6 q3 35.8). Harness (VS-052): the economic bot repairs the HQ below `REPAIR_BELOW` 80% hull when credits exceed `REPAIR_RESERVE` 25000 (`--repair-reserve=N`), spending only the excess; passive never repairs; `--wound=F` forces the HQ to F of max hull at 300 s to exercise the path. Gate S0046: economic nw20 median 120726, HQ 9/9; passive loss median 28.9.
- Raid chip damage (VS-051, `Defs.RAID_CHIP_PER_SHIP` 0.02, `RAID_CHIP_MAX` 0.25): when a raid reaches a Sovereign station (RaidTracker arrival), each surviving raider removes 2% of that station's max hull, once per raid, capped at 25%, never lethal (leaves >=1 hull). The Breach (6 ships) costs about 12%. Raids killed before arriving cost nothing. Arrival and outcome text quote it ("hull -12%"). Gate S0048 (0.02): economic 30 min HQ 8/9 (seed 135 collapses at 23.7 min; it was already the weak seed, nw30 20847), nw20 median 103637 (was 120726), nw30 median 121347 (was 157636); perturb=1 9/9 (chip 0: 8/9); passive 40 min HQ lost median 27.3 min (was 28.9). 0.025 gave the same 8/9 with nw30 146654.
- Measured (S0003, `balance.sh`): economic 30 min × 6 seeds → net worth at 20 min median ≈ 139k, HQ survives 5/6; passive 40 min × 3 seeds → HQ lost at ≈ 25 min (median). A player who builds nothing still loses.
- Nest drone spawn interval `max(12, 30 − t/40)` s, cap `6 + t/120`.
- Surface level 1–3: pylons = level + 1, more enemies per wave, faster waves.
- VS-037 flank: when the first pylon dies, `Defs.FLANK_MIN..FLANK_MAX` (2-3) Hive units (crawlers, every 3rd a drone) spawn `FLANK_DIST` (55 m) from the player, `FLANK_ANGLE_MIN..MAX` (60-120 deg) off the player's heading on a random side, and chase. Once per landing. Kill feedback: red X + faint screen flash on the crosshair (`HUD.kill`, longer for pylon/Core) and the synthesised `kill` blip (two rising tones) on top of the existing hit tick. The autoplay bot strafes around the Core (`BOT_STRAFE_TIME`) and answers flankers first; `surface_long` prints `foot=hp/shield`, `min_foot` (hp+shield scaled to ship-hull units, x600/160), `flank=`, `mobs=`.

## Juice
Screen shake on hits, explosion flashes + debris, hit markers, damage vignette, shield shimmer, floating bounty text, travel-drive streaks.

## Run flow
`scripts/run_flow.gd` (RunFlow, owned by main.gd) handles title → play → end → restart. The universe only simulates while a run is in progress. It is frozen behind the title screen (no raid countdown, no time charged against the win bonus) and behind the end screen. When a run ends, the command map and dock close and the HUD and touch buttons hide, so any click, tap or Space restarts. If a run ends during the landing fade, no surface is built.

## Audio
`scripts/audio/sfx.gd` (owned by main.gd, no autoload) synthesises six effects at startup into `AudioStreamWAV` (22050 Hz mono 16-bit, ~2 s total, a few ms): laser, rifle, hit, explosion, gate jump, UI click. No files, no `AudioStreamGenerator`. Nothing plays before the first key/click/tap (browser autoplay rule). N or the SND touch button toggles mute. Volumes and pitch jitter (±8 %) are constants at the top of the script; explosions are audible within 2.5 km in flight.

## Testing hooks
`scripts/check.sh void-sovereign` runs import, title smoke, a 15 s `--autoplay` that first idles 10 frames on the title (asserting the world is frozen) and then walks flight → map orders/buy/build → dock → landing + FPS → evacuation, and `scripts/selftest.gd` (routing, pricing, transactions, production, 8 simulated minutes incl. the First Sortie spawning exactly once without moving the raid timer, Core→Nest unlock).
`scripts/test_driver.gd` also supports `-- --shot=<title|map|dock|surface|touch|over|over_map|win|death|combat> --shotfile=out.png` for rendered screenshots (run without `--headless`).

## Out of scope
Ship interiors, boarding, research tree, diplomacy, save-anywhere (only the best score and a single autosave persist; no manual slots, no on-foot saves), multiplayer, audio assets.

- VS-040 income panel (map/dock `Hud.ledger_text`): before any income it lists 3 sources (`Universe.income_sources()`: full-hold munitions sale, miner ore haul, colony cr/min, computed from Defs); afterwards `Income: net X (gross Y) cr/min` via `CreditLedger.net_per_min` / `income_per_min`. The top-bar HUD rate stays gross.
