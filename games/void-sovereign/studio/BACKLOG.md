# Void Sovereign — Backlog

Format and rules: `scripts/studio/backlog.py` (header docstring) and `ai-studio/studio-cycle.md`.
One task per `##` heading. The Producer owns this file; `python3 scripts/studio/backlog.py validate` must pass.

## VS-001 · Rebalance so an economic player survives and grows past minute 20
- status: done
- priority: P1
- type: balance
- size: M
- source: balance
- created: S0000
- why: Baseline (S0000, 3 seeds): economic policy net worth 41k at 10 min collapses to 8k at 20 min (fleet wiped by raids), HQ survives only 1/3 seeds (median loss 26.7 min), Union collapses ~24 min. A passive player ends minute 20 richer (38k) than one who invests — the mid-game punishes building an economy.
- acceptance:
  - [x] `bash scripts/studio/balance.sh void-sovereign 30 3 economic` → net_worth_20 median ≥ 90,000 and HQ survives in ≥ 2/3 seeds
  - [x] `bash scripts/studio/balance.sh void-sovereign 40 3 passive` → HQ lost between 20 and 35 min (median)
  - [x] Changes are constants in `scripts/sim/defs.gd` (or a clearly named new mechanic) and DESIGN.md "Ramp" is updated
  - [x] selftest still passes (raids still start within 8 minutes)
- notes: S0001 new baseline (after VS-002 reserve + VS-008 start stock), economic 30 min: 3 seeds credits_10 3716/4364/7692, nw10 med 46364, nw20 med 8022, HQ 0/3 (6 seeds 101-186: 3/6), Union collapse med 21.5. Use 6 seeds for survival metrics — 3 is noisy. Likely levers: raid targeting (non-combat ships are free kills), RAID_INTERVAL ramp, raid size cap, defence platform cost, union quota. Measure before/after. S0002 hung mid-task (cancelled); its unverified diff is in studio/salvage/S0002-VS-001-abandoned.patch. S0003 restarted it.
- done: S0003 — hub export sink, civilian raid avoidance, home guard, free HQ dock repair, raid withdrawal, fighter/HQ buffs; econ 6 seeds nw20 139k HQ 5/6, passive HQ lost 25.4 min (QA PASS)

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
- status: done
- priority: P1
- type: feature
- size: M
- source: dev
- created: S0000
- why: The game is silent; combat feedback relies on visuals alone. Flagged as the top next step after the first build.
- acceptance:
  - [x] Laser, rifle, hit, explosion, gate jump and UI click sounds generated in code into `AudioStreamWAV` at startup (no `AudioStreamGenerator`, no downloaded assets)
  - [x] No sound plays before the first click/key/tap (browser autoplay rule); a mute toggle exists (key + touch)
  - [x] Volume constants at the top of the audio script; pitch varies slightly per shot
  - [x] check.sh PASS; `--autoplay` exercises sound playback without errors
- notes: S0005 started (rollback HEAD 935f699). S0004 took the lock at 03:32Z and left no other trace.
- done: S0005 — scripts/audio/sfx.gd synthesises 6 AudioStreamWAVs at startup, gated on first input, N/SND mute, ±8% pitch; autoplay plays 15 / blocks 63 pre-input (QA PASS)

## VS-004 · Guided first 10 minutes
- status: done
- priority: P1
- type: polish
- size: S
- source: dev
- created: S0000
- why: A new player gets a wall of controls on the title screen and one objective line. Nothing teaches throttle, targeting, docking, the map or landing in context.
- notes: S0006 started (rollback HEAD 48b0706).
- acceptance:
  - [x] Contextual hints appear in sequence based on state (capture mouse → throttle → target an enemy → dock → open map → land on Ember), each disappears once done
  - [x] Hints show touch wording when touch is active
  - [x] Hints can be skipped (one key/button) and never reappear in that run
  - [x] Screenshot of at least two hint states reviewed
- done: S0006 — scripts/ui/tutorial_hints.gd: 6 state-latched tips (steer→throttle→target→dock→map→land Ember), touch wording, skip via H or tap; selftest + autoplay asserts (QA PASS, assert mutation-tested)

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
- status: done
- priority: P1
- type: tech
- size: S
- source: dev
- created: S0000
- why: selftest covers pricing, transactions and production, but not the multi-step AI loops most likely to regress (gate travel, mining, trading).
- acceptance:
  - [x] Assertion: a ship ordered to another sector arrives there via gates within a time bound
  - [x] Assertion: a miner completes at least one ore sale within a time bound
  - [x] Assertion: `ShipAI.plan_trade` returns a plan with positive expected profit on the starting universe
  - [x] check.sh PASS
- done: S0001 — selftest covers gate travel, miner ore sale and plan_trade profit; start stock fills swapped so trade is profitable at start
- notes: S0001: _test_ai_journeys() (seed 7; goto 0->3 in 82/288 s, miner sale 64/289 s, plan_trade munitions x80 profit 1787); QA mutation-tested all 3. Bundled balance change: start stock inputs 1/3, outputs 1/2 (Defs.START_FILL_INPUT/OUTPUT) — plan_trade was empty on the starting universe.

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

## VS-011 · Economic player keeps growing from minute 20 to 30
- status: todo
- priority: P1
- type: balance
- size: M
- source: qa
- created: S0003
- why: S0003 QA verify of VS-001: nw20 median 139k but net worth falls sharply by min 30 in 4/6 seeds (e.g. 106k -> 6k, player ships 14 -> 0-6), HQ lost at 27.4 in seed 118, Union collapses ~24 min in 3/6 seeds. Early economy also overshoots (credits_10 10-27k).
- acceptance:
  - [ ] `balance.sh` gains a seed-offset option so a 6-seed 30-min run can be split into two calls under the 180 s device cap (current 6-seed run takes ~174 s)
  - [ ] Economic 30 min, 6 seeds: net_worth_30 median >= net_worth_20 median, and HQ survives >= 5/6
  - [ ] Economic 30 min, 6 seeds: net_worth_20 median between 80k and 130k (trim the overshoot, e.g. TRADE_HUB_EXPORT 50-60 or TARGET_FILL 0.15)
  - [ ] Passive 40 min, 3 seeds: HQ still lost between 20 and 35 min (median); check.sh PASS
- notes: Balance harness prints net worth/ships at 30 min in the per-seed BALANCE_ lines. Levers: RAID_SIZE_GROWTH/MAX, Union quota/strength, defense platform cost. Consider removing raid withdrawal / dock repair if not needed (fewer mechanics).

## VS-012 · Audio/touch follow-ups from VS-003 QA
- status: todo
- priority: P2
- type: polish
- size: S
- source: qa
- created: S0005
- why: S0005 QA of VS-003: the SND touch button overlaps the second message line in surface mode (touch_surface.png), N while paused both unpauses and toggles mute, and the autoplay guard `push_error("sfx played before first input")` in test_driver.gd would not fail check.sh.
- acceptance:
  - [ ] `shots.sh void-sovereign touch_surface` and `touch` show SND/TRVL/MAP clear of the message log, even with two stacked messages
  - [ ] Pressing N while paused toggles mute only (game stays paused), or unpauses only — not both
  - [ ] Playing a sound before first input makes check.sh FAIL (assert or a pattern check.sh matches); verified by a temporary mutation, then reverted
  - [ ] check.sh PASS

## VS-013 · Tutorial tip follow-ups (touch skip overlap, docs)
- status: todo
- priority: P2
- type: polish
- size: S
- source: qa
- created: S0006
- why: S0006 QA of VS-004: in touch mode the tap-to-skip tip box (x 260–1020, y 418–484 at 1280x720) overlaps the left-side steering zone, so a player starting a steer drag on it skips all tips instead of steering; the H key isn't documented anywhere but the tip itself.
- acceptance:
  - [ ] A touch drag starting in the steering zone while a tip shows steers the ship and does not skip tips (xvfb probe at --resolution 1280x720)
  - [ ] Tips are still skippable on touch with one dedicated tap target that does not overlap the stick zone or the touch buttons (screenshot hints_touch reviewed)
  - [ ] "H: skip tips" appears in the title/help controls, game.json controls and DESIGN.md controls
  - [ ] check.sh PASS

# Ideas parking lot
- selftest.gd: track a failure flag so "SELFTEST OK" never prints after a failed assert (today only check.sh's SCRIPT ERROR grep catches failures) (S0001 QA)
- selftest: full trader buy -> sell -> idle state-machine cycle (S0001 dev)
- Show TRADER_RESERVE in the dock panel / make it player-adjustable (S0001 dev)
- Engine trails and a proper travel-drive streak effect
- Station construction takes time (construction ship + progress bar) instead of instant placement
- Per-planet surface biomes (palette, props, Hive structure layouts) for levels 2–3
- Dreadnought "boss" encounter with weak points the player can target
- Escort/convoy missions from Union stations for credits and reputation
- Home guard (VS-001) silently overrides manual Patrol in the HQ sector; explain in UI or apply only to auto patrols (S0003 QA, P3)
- Dock repair heals ships on manual orders too and is free/uncapped; limit to automated ships or charge REPAIR_COST (S0003 QA, P3)
- `route(..., avoid_hive)` still avoids only Nest sectors; use `sector_unsafe` so civilians don't path through raids (S0003 QA, P3)
- `_home_nest_sector`: empty route counted as 0 hops would pick an unreachable nest (S0003 QA, P3, no effect on current map)
- (S0005, QA) Explosion SFX peaks at full scale and is hard-clipped by clampf — lower its gain or soft-clip.
- (S0005, QA) main.gd is ~325 lines (> ~300 guideline) — split input/pause handling out.
- (S0005, dev) Click sounds on map/dock buttons; HUD mute indicator; persist mute in user://save.cfg; distance-scaled explosion volume; NPC weapon sounds.
- (S0006, QA) Tutorial tip box sits at 58% height over the player ship model; move higher/side (BOX_Y_FRAC in tutorial_hints.gd).
- (S0006, QA) Desktop tip 1 duplicates the HUD line "Click to capture mouse for steering"; hide the HUD line while tip 1 shows.
- (S0006, QA) Touch steer tip says "drag on the left side" / "steer" but the stick is labelled MOVE — align wording.
- (S0006, QA) The "land" tip completes on any planet, not Ember specifically (harmless on the current map).
- (S0006, dev/QA) Touch OBJECTIVE line says "press F to land"; use ACT wording in touch mode.
- (S0006, dev) Persist "tips completed/skipped" in user://save.cfg so returning players don't see them.
