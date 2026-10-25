# Void Sovereign — Backlog

Format and rules: `scripts/studio/backlog.py` (header docstring) and `ai-studio/studio-cycle.md`.
One task per `##` heading. The Producer owns this file; `python3 scripts/studio/backlog.py validate` must pass.

## VS-001 · Rebalance so an economic player survives and grows past minute 20
- status: todo
- priority: P1
- type: balance
- size: M
- source: balance
- created: S0000
- why: Baseline (S0000, 3 seeds): economic policy net worth 41k at 10 min collapses to 8k at 20 min (fleet wiped by raids), HQ survives only 1/3 seeds (median loss 26.7 min), Union collapses ~24 min. A passive player ends minute 20 richer (38k) than one who invests — the mid-game punishes building an economy.
- acceptance:
  - [ ] `bash scripts/studio/balance.sh void-sovereign 30 3 economic` → net_worth_20 median ≥ 90,000 and HQ survives in ≥ 2/3 seeds
  - [ ] `bash scripts/studio/balance.sh void-sovereign 40 3 passive` → HQ lost between 20 and 35 min (median)
  - [ ] Changes are constants in `scripts/sim/defs.gd` (or a clearly named new mechanic) and DESIGN.md "Ramp" is updated
  - [ ] selftest still passes (raids still start within 8 minutes)
- notes: Likely levers: raid targeting (non-combat ships are free kills), RAID_INTERVAL ramp, raid size cap, defence platform cost, union quota. Measure before/after.

## VS-002 · Player auto-traders must not drain credits to zero
- status: done
- priority: P1
- type: bug
- size: S
- source: balance
- created: S0000
- why: Economic run seed 118 shows credits_10 = 1: player freighters on auto-trade spend every credit on cargo, which blocks repairs and purchases.
- acceptance:
  - [x] Player-owned traders never buy when it would leave credits below a reserve constant (e.g. `TRADER_RESERVE` in defs.gd)
  - [x] New selftest assertion: a player trader with low credits buys nothing / is clamped to the reserve
  - [x] Economic balance run shows credits_10 > reserve in all seeds
- done: S0001 — automated player assets keep a 2000 cr reserve (defs TRADER_RESERVE, Universe.transact clamp, selftest)
- notes: S0001: TRADER_RESERVE=2000 clamp in Universe.transact() for all automated player assets; QA verified (credits_10 4088/2104/3865, HQ 2/3). Seed 118 margin only ~104 cr.

## VS-003 · Procedural sound effects (web-safe)
- status: todo
- priority: P1
- type: feature
- size: M
- source: dev
- created: S0000
- why: The game is silent; combat feedback relies on visuals alone. Flagged as the top next step after the first build.
- acceptance:
  - [ ] Laser, rifle, hit, explosion, gate jump and UI click sounds generated in code into `AudioStreamWAV` at startup (no `AudioStreamGenerator`, no downloaded assets)
  - [ ] No sound plays before the first click/key/tap (browser autoplay rule); a mute toggle exists (key + touch)
  - [ ] Volume constants at the top of the audio script; pitch varies slightly per shot
  - [ ] check.sh PASS; `--autoplay` exercises sound playback without errors

## VS-004 · Guided first 10 minutes
- status: todo
- priority: P1
- type: polish
- size: S
- source: dev
- created: S0000
- why: A new player gets a wall of controls on the title screen and one objective line. Nothing teaches throttle, targeting, docking, the map or landing in context.
- acceptance:
  - [ ] Contextual hints appear in sequence based on state (capture mouse → throttle → target an enemy → dock → open map → land on Ember), each disappears once done
  - [ ] Hints show touch wording when touch is active
  - [ ] Hints can be skipped (one key/button) and never reappear in that run
  - [ ] Screenshot of at least two hint states reviewed

## VS-005 · Declutter surface objective markers
- status: todo
- priority: P2
- type: bug
- size: S
- source: dev
- created: S0000
- why: On the surface, pylon markers that line up at distance draw their labels on top of each other (see touch_surface screenshot from the first build).
- acceptance:
  - [ ] Overlapping marker labels are offset or merged ("2× PYLON 380m")
  - [ ] `shots.sh void-sovereign surface touch_surface` shows readable markers

## VS-006 · Web performance guard for late-game ship counts
- status: todo
- priority: P2
- type: perf
- size: M
- source: balance
- created: S0000
- why: Hive ship count reaches 56 at 20 min and 83 at 30 min (economic seed 101). Every ship is several draw calls in the flight view; mid-range phones will choke.
- acceptance:
  - [ ] Total Hive ships capped by a constant (raiders that finish a raid return to a nest or merge)
  - [ ] Flight view hides or simplifies ship proxies beyond a distance constant
  - [ ] Economic balance run: hive_ships_30 ≤ 60 in all seeds
  - [ ] No visible popping within 2 km in a combat screenshot

## VS-007 · Wing commands from the cockpit
- status: todo
- priority: P2
- type: feature
- size: S
- source: dev
- created: S0000
- why: Command depth lives only in the map; X4 and Freelancer let you command your wing while flying. `G` (attack my target) exists but nothing else.
- acceptance:
  - [ ] Keys + touch buttons for: wing attack my target (existing G), wing return/escort me, wing hold position
  - [ ] HUD shows a one-line wing status (count, current order)
  - [ ] DESIGN.md controls table and title screen updated

## VS-008 · Selftest coverage for ship AI journeys
- status: todo
- priority: P1
- type: tech
- size: S
- source: dev
- created: S0000
- why: selftest covers pricing, transactions and production, but not the multi-step AI loops most likely to regress (gate travel, mining, trading).
- acceptance:
  - [ ] Assertion: a ship ordered to another sector arrives there via gates within a time bound
  - [ ] Assertion: a miner completes at least one ore sale within a time bound
  - [ ] Assertion: `ShipAI.plan_trade` returns a plan with positive expected profit on the starting universe
  - [ ] check.sh PASS

## VS-009 · Save and continue a run
- status: todo
- priority: P2
- type: feature
- size: L
- source: dev
- created: S0000
- why: A full game takes 30–40 minutes; browser players close tabs. Only the best score persists today.
- acceptance:
  - [ ] The Producer splits this into S/M tasks before work (serialize Universe → user://, restore on title "Continue", autosave cadence, versioning)
- notes: Size L on purpose — exercises the split rule.

## VS-010 · NPC traders must not get stuck at a player station that can't pay
- status: todo
- priority: P2
- type: bug
- size: S
- source: qa
- created: S0001
- why: S0001 QA (VS-002 verify): below TRADER_RESERVE, Universe.transact() refuses NPC deliveries to player stations, but ship_ai.gd best_buyer()/plan_trade() keep picking the same station, so NPC traders/miners retry at the dock every tick. Balance runs sit at 2-4k credits, so this triggers often.
- acceptance:
  - [ ] best_buyer()/plan_trade() skip player stations when the player cannot afford a meaningful delivery (credits - TRADER_RESERVE below ~5 units' price)
  - [ ] New selftest assertion: with credits <= TRADER_RESERVE an NPC seller docked at a player station picks a different buyer instead of retrying
  - [ ] check.sh PASS; economic balance run credits_10 still > TRADER_RESERVE in all seeds

# Ideas parking lot
- Engine trails and a proper travel-drive streak effect
- Station construction takes time (construction ship + progress bar) instead of instant placement
- Per-planet surface biomes (palette, props, Hive structure layouts) for levels 2–3
- Dreadnought "boss" encounter with weak points the player can target
- Escort/convoy missions from Union stations for credits and reputation
