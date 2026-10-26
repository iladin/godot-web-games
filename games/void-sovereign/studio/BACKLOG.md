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
- notes: S0008 QA: two pylon labels ("PYLON 366m"/"PYLON 413m") overlap in surface.png.

## VS-006 · Web performance guard for late-game ship counts
- status: blocked
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
- notes: S0007: blocked on VS-011 — its raid-size/interval changes move the Hive ship count (S0007 balance: hive_20 median 59, max 65). Re-measure after VS-011 lands, then unblock or close.

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
- notes: S0007: parked by Producer to keep open todo ≤ 8 (no review finding asks for it this round). Daniel can reprioritise via INBOX. Daniel (2026-10-26, after S0007): restore to todo.

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
- notes: Size L on purpose — exercises the split rule. S0007: parked by Producer to keep open todo ≤ 8; needs Daniel to confirm save/continue is wanted (see HANDOVER open questions) before it is split. Daniel (2026-10-26, after S0007): restore to todo.

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
- status: split
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
- notes: Balance harness prints net worth/ships at 30 min in the per-seed BALANCE_ lines. Levers: RAID_SIZE_GROWTH/MAX, Union quota/strength, defense platform cost. Consider removing raid withdrawal / dock repair if not needed (fewer mechanics). S0007 balance (reviews/S0007-balance.md): unchanged since S0003, nw30 falls in 5/6 seeds (median 42.9k vs nw20 139k). Raids hit RAID_SIZE_MAX 16 at ~19.5 min and RAID_INTERVAL_MIN 75 s at ~21 min while the econ policy stops buying after ~10 min. Suggested: RAID_INTERVAL_MIN 75→100, RAID_SIZE_MAX 16→13, TRADE_HUB_EXPORT 80→60; harness: policy replaces lost fighters + builds a Defense Platform after 10 min. Seed-offset prototype: .tools/s0007/balance_offset.gd (adds --first=). S0007 VS-016 (curve batch pricing) lowered income: econ 3 seeds (101/118/135) credits_10 17.4k/21.2k/10.3k (was 23.9k/27.2k/20.7k), nw20 median 129k (was 139k), HQ 2/3 (135 lost 27.6 min; 118 now survives); seed 101 nw30 7.8k with 1 ship. Re-baseline 6 seeds before tuning. S0008: split → VS-019 (harness: criteria 1/3/4, done, QA PASS) + VS-020 (criterion 2: nw30 >= nw20, still FAIL — needs a game lever).

## VS-012 · Audio/touch follow-ups from VS-003 QA
- status: done
- priority: P2
- type: polish
- size: S
- source: qa
- created: S0005
- why: S0005 QA of VS-003: the SND touch button overlaps the second message line in surface mode (touch_surface.png), N while paused both unpauses and toggles mute, and the autoplay guard `push_error("sfx played before first input")` in test_driver.gd would not fail check.sh.
- notes: S0006 started (rollback HEAD 77a703a).
- acceptance:
  - [x] `shots.sh void-sovereign touch_surface` and `touch` show SND/TRVL/MAP clear of the message log, even with two stacked messages
  - [x] Pressing N while paused toggles mute only (game stays paused), or unpauses only — not both
  - [x] Playing a sound before first input makes check.sh FAIL (assert or a pattern check.sh matches); verified by a temporary mutation, then reverted
  - [x] check.sh PASS
- done: S0006 — touch utility row at TOP_ROW_Y 190 (clear of 2+ messages); Controls.resumes_from_pause ignores mute/key-up; autoplay sfx guard is an assert (mutation → check FAIL) (QA PASS)

## VS-013 · Tutorial tip follow-ups (touch skip overlap, docs)
- status: split
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
- notes: S0007: superseded by VS-017 (tips follow the world), which carries all four acceptance items.

## VS-014 · Touch/mouse input on the pause screen
- status: todo
- priority: P2
- type: bug
- size: S
- source: qa
- created: S0006
- why: S0006 QA of VS-012: with emulate_mouse_from_touch on, tapping SND/MAP/TRVL while paused also unpauses (the emulated mouse click reaches main._unhandled_input → Controls.resumes_from_pause); on desktop the first click on the pause screen is eaten by mouse capture in space_view/fps_player and the game stays paused.
- acceptance:
  - [ ] Touch probe (xvfb --resolution 1280x720): P, then tap SND → muted toggles, game stays paused; same for MAP/TRVL taps (no resume)
  - [ ] A tap elsewhere on the pause screen still resumes
  - [ ] Desktop: P, then one left click → game resumes on that click (mouse is not captured while paused)
  - [ ] selftest/probe assertion covers emulated-mouse events in resumes_from_pause; check.sh PASS
- notes: S0007 QA: dock and map buttons also stay clickable under the pause overlay — fix in the same pass.

## VS-015 · Freeze the world on the title screen and close overlays when a run ends
- status: done
- priority: P1
- type: bug
- size: S
- source: qa
- created: S0007
- why: S0007 QA sweep (reviews/S0007-qa.md bugs 1 and 3): main._process steps the Universe whenever state != OVER, so the sim runs behind the title (idle 1653 s → "HQ LOST" without starting; first-raid countdown and win time bonus eaten by title time; flight HUD and "F: Dock"/capture prompts render on the title). If a run ends while the command map is open, the full-screen MapView (mouse_filter STOP) eats clicks/taps, so only Space restarts — a touch softlock on the most likely win path.
- acceptance:
  - [x] Universe time does not advance while on the title screen; new selftest/autoplay assertion (e.g. u.time == 0 after N title frames) — mutation-checked
  - [x] Title screen shows no flight HUD lines, dock prompt or capture-mouse prompt (`shots.sh void-sovereign title` reviewed)
  - [x] Ending a run (win or loss) while the map or dock is open returns to the end overlay, and a click or tap at (400,400) restarts (probe, xvfb --resolution 1280x720)
  - [x] Map/dock buttons are not usable on the end screen; if the run ends during the landing fade, no surface is built afterwards (state guard after the await)
  - [x] check.sh PASS
- notes: QA suggested _set_mode("flight") in _on_finished. main.gd is ~329 lines — move the touched state/overlay handling into a helper script rather than growing it. S0007 started (rollback HEAD b8744ab).
- done: S0007 — sim steps only while PLAYING (RunFlow.sim_runs), title shows no HUD/prompts, finish() closes map/dock and frees mouse, land/dock guards; autoplay title assert + over_map shot (QA PASS, 2 mutations)

## VS-016 · Stop buy/sell arbitrage at the same station
- status: done
- priority: P1
- type: bug
- size: S
- source: qa
- created: S0007
- why: S0007 QA sweep (reviews/S0007-qa.md bug 2): Universe.transact() prices a whole batch at the pre-trade price and Trade Hubs buy and sell at the same price, so Buy 10 ×4 → Sell all at one hub nets credits forever (50 cycles: munitions +11,333 cr, alloy +5,333 cr, no game time). Breaks the economy pillar for the player.
- acceptance:
  - [x] Buying N units then selling N units of the same ware at the same station never increases player credits, for every ware a station both buys and sells and for N in {1, 10, 40} (new selftest assertion, mutation-checked)
  - [x] Batches are priced per unit along the price curve, or stations apply a buy/sell spread constant in defs.gd (documented in DESIGN.md)
  - [x] ShipAI.plan_trade still returns a profitable plan on the starting universe (existing selftest) and NPC/automated traders still trade (autoplay)
  - [x] Economic balance run (3 seeds, 30 min) recorded in notes: credits_10 > TRADER_RESERVE in all seeds; check.sh PASS
- notes: S0007 started (rollback HEAD d16b60d).
- done: S0007 — StationData.batch_total prices each unit along the stock curve (buy rising, sell falling), transact charges it; selftest round-trip check over every station×ware×N (QA PASS, 2 mutations); econ 3 seeds credits_10 17k/21k/10k, nw20 129k

## VS-017 · Tutorial tips follow the world (one voice on screen)
- status: todo
- priority: P1
- type: polish
- size: S
- source: critic
- created: S0007
- why: S0007 critic #1/#3 and QA sweep bug 4: tip 3 ("lock onto a Hive ship") cannot be done in Haven's Reach — 0 Hive ships there for the first 10 min in 3/3 seeds — so tips 4–6 never appear; at t=3 s five directives compete (welcome, tip, "F: Dock", duplicate capture prompt, objective) and the tip order contradicts the objective. Absorbs VS-013 (touch skip overlaps steer zone; H undocumented).
- acceptance:
  - [ ] A tip is only current when it can be completed now (e.g. the target tip waits until a hostile is in the sector, later tips are not blocked by it); headless probe: steer + throttle, then dock/map/land tips appear within the first 5 min in seeds 7, 101, 118
  - [ ] Pressing R / TGT with nothing to lock shows a short "no hostiles in range" message instead of failing silently
  - [ ] While a tip is shown, the duplicate HUD capture-mouse line is hidden; screenshot `hints` at t≈3 s shows at most one instruction line plus the objective
  - [ ] Touch: a drag starting in the steering zone while a tip shows steers and does not skip tips; tips remain skippable via one dedicated tap target clear of the stick and buttons (xvfb --resolution 1280x720, `hints_touch` reviewed)
  - [ ] "H: skip tips" in title/help controls, game.json and DESIGN.md; check.sh PASS
- notes: Scout proposal 1 (reviews/S0007-scout.md). If VS-018 (First Sortie) lands first, the target tip can point at that wave.

## VS-018 · First Sortie: a small opening wave near Ember
- status: todo
- priority: P1
- type: feature
- size: M
- source: critic
- created: S0007
- why: S0007 critic #2 and bold idea: the opening has no threat (seed 7: every raider dies in Cinder Belt, HQ and player hull untouched for 95 s), so the first 10 minutes teach nothing about combat and the target tip has nothing to lock. Scout proposal 2.
- acceptance:
  - [ ] Once per run, at about t=60 s of play, a wave of 3 weak Hive drones appears near Ember orbit in or next to the home sector, announced by a HUD message; constants (time, size, strength) in defs.gd
  - [ ] The starting escorts plus the player beat the wave in all of seeds 7, 101, 118 without the player ship dying (autoplay/probe log)
  - [ ] After the wave is destroyed a message points the player to land on Ember (objective unchanged); selftest asserts the wave spawns once and only once
  - [ ] Balance gates unchanged: economic 30 min 3 seeds nw20 within ±15% of the S0007 baseline (139k median); passive 40 min HQ lost 20–35 min; check.sh PASS
- notes: Do after VS-015 (title time must not count). Raid first-arrival (3.3 min) is separate — the wave must not reset or delay the raid timer. S0008: the 139k baseline is stale (pre-VS-016, old policy); use the VS-019 harness baseline instead (6 seeds nw20 median 105.6k).

## VS-019 · Balance harness: seed offset, honest medians, defending economic policy
- status: done
- priority: P1
- type: tech
- size: S
- source: producer
- created: S0008
- why: Split from VS-011 (S0008) — the harness half of VS-011 that QA verified. A 6-seed 30-min run could not fit the 180 s device cap, lost-HQ seeds were silently dropped from medians, and the economic policy stopped defending after minute 10 (S0007 balance).
- acceptance:
  - [x] `balance.sh` 5th arg `first` / balance.gd `--first=N` seed offset; no 5th arg behaves as before
  - [x] Summary includes net_worth_30_median; a lost HQ records remaining checkpoints as net worth 0
  - [x] Economic policy builds a Defense Platform at HQ from 10 min and a second from 18 min, using only player-available actions
  - [x] Economic 30 min 6 seeds: nw20 median 80–130k, HQ >= 5/6; passive 40 min 3 seeds HQ lost 20–35 min (median); check.sh PASS
- done: S0008 — seed offset + defending econ policy; 6 seeds (101..186) nw20 105.6k, nw30 74.1k (was 33.6k), HQ 6/6; passive median 25.4; QA PASS on these criteria
- notes: S0008: no game code changed (scripts/sim untouched). Fixed seed list 101,118,135 (first=0) + 152,169,186 (first=3); run both halves in parallel in one device call (~101 s). Numbers are not comparable with S0003/S0007 (new policy, lost HQ = 0). Tried and reverted: raid nerf 75→100/16→13 (passive HQ survives 3/3 — breaks the passive gate); Defense Platform buff 24k/dps140 (econ nw30 100k but passive median 37.6 — Union stations use the same platform).

## VS-020 · Late-game Hive pressure: economic net worth grows from minute 20 to 30
- status: todo
- priority: P1
- type: balance
- size: M
- source: qa
- created: S0008
- why: Split from VS-011 criterion 2, still FAIL in S0008 QA: with a defending policy (VS-019) HQ survives 6/6 but nw30 median 74.1k < nw20 105.6k, falling in 6/6 seeds; player ships 7–14 → 2–7 while Hive ships grow ~52 → 76–94 between min 20 and 30; Union collapses ~28 min in seeds 169/186.
- acceptance:
  - [ ] Economic 30 min, 6 seeds (101..186 via two offset calls): net_worth_30 median >= net_worth_20 median, HQ survives >= 5/6
  - [ ] Economic nw20 median stays 80–130k
  - [ ] Passive 40 min, 3 seeds: HQ still lost between 20 and 35 min (median); check.sh PASS
  - [ ] DESIGN.md tunables updated for any changed constant
- notes: The lever must separate a defended player HQ from an undefended one, or slow Hive growth after ~20 min. Do NOT just nerf raids globally or buff the shared Defense Platform (both broke the passive gate in S0008). Candidates: cap total Hive fleet / slow Hive production after min 20; player-only platform variant or player-faction dps multiplier; raids avoid sectors with a platform; miners flee the HQ sector during raids (S0008 seed 186 lost 15 fighters + 8 miners in sector 0). Seed results swing ±50k on small changes — consider a 9-seed check before declaring PASS.

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
- (S0006, QA) With 6 stacked HUD messages the last line grazes the touch MAP/TRVL outlines; TOP_ROW_Y≈200 or MAX_MSGS=5 on touch.
- (S0006, dev) Scale touch layout offsets with viewport height for unusual aspect ratios.
- (S0007, scout/critic) Credit ledger: route all credit changes through earn(category, amount); HUD cr/min, map panel last-60 s breakdown, HQ dock "how to earn" line. Critic: Economy legibility 3/10 — top candidate for the next planning round (P2, M).
- (S0007, scout/critic) Honest raid reports: track each raid to its end, "intercepted in X (k/n destroyed)" or "RAID ARRIVING", mark active raids on the map inset (P2, S).
- (S0007, scout/balance) Standing HQ reinforcement order "keep N fighters" — a late-game credit sink and defence; revisit with VS-011 (P2, M).
- (S0007, QA) build_station() accepts positions inside a planet (0 m from centre, PLANET_RADIUS 1500); reject placements within the planet radius (P3).
- (S0007, QA) Title backdrop: player-ship model sits behind the controls text (y≈400–450); shot runs share user://save.cfg best score with real play (win shot sets best 170997) — use a separate save path in shot/autoplay modes (P3).
- (S0007, dev) Autoplay step that ends a run from the map and restarts (15 s autoplay window nearly full) (P3).
- (S0007, QA/dev VS-016) Dock panel shows the next-unit price; show the batch cost ("Buy 10 ≈ X cr"); ShipAI.plan_trade could estimate with batch_total (P3).
- (S0007, QA) `shots.sh dock` only shows the HQ (no trade grid) — add a trade-hub dock scenario for visual coverage of Buy/Sell (P3).
