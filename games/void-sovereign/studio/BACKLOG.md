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
- status: done
- priority: P2
- type: bug
- size: S
- source: dev
- created: S0000
- why: On the surface, pylon markers that line up at distance draw their labels on top of each other (see touch_surface screenshot from the first build).
- acceptance:
  - [ ] Overlapping marker labels are offset or merged ("2× PYLON 380m")
  - [ ] `shots.sh void-sovereign surface touch_surface` shows readable markers
- notes: S0014 in progress. S0008 QA: two pylon labels overlap in surface.png. S0012: still open.
- done: S0014 — Hud.layout_markers merges same-label markers (2× PYLON 366m) and stacks overlaps; QA PASS first round

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
- notes: S0007: blocked on VS-011 — its raid-size/interval changes move the Hive ship count (S0007 balance: hive_20 median 59, max 65). Re-measure after VS-011 lands, then unblock or close. S0012: VS-020 done; still relevant (S0012 balance: hive_20 median 58, q3 61, max 75; 3/9 seeds > 60). Kept blocked until VS-023 lands, because its DREAD_TIME change moves Hive counts; re-measure then and unblock (open todo is at the cap of 8).

## VS-007 · Wing commands from the cockpit
- status: done
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
- done: S0016 — G/C/V wing keys + ATK/ESC/HOLD touch buttons + HUD wing line (QA FAIL on ACT overlap → fix → PASS)

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
- status: split
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
- status: done
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
- done: S0015 — ShipAI.can_deliver_to guards plan_trade/best_buyer; QA PASS round 1

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
- status: done
- priority: P2
- type: bug
- size: S
- source: qa
- created: S0006
- why: S0006 QA of VS-012: with emulate_mouse_from_touch on, tapping SND/MAP/TRVL while paused also unpauses (the emulated mouse click reaches main._unhandled_input → Controls.resumes_from_pause); on desktop the first click on the pause screen is eaten by mouse capture in space_view/fps_player and the game stays paused.
- acceptance:
  - [x] Touch probe (xvfb --resolution 1280x720): P, then tap SND → muted toggles, game stays paused; same for MAP/TRVL taps (no resume)
  - [x] A tap elsewhere on the pause screen still resumes
  - [x] Desktop: P, then one left click → game resumes on that click (mouse is not captured while paused)
  - [x] selftest/probe assertion covers emulated-mouse events in resumes_from_pause; check.sh PASS
- notes: S0007 QA: dock and map buttons also stay clickable under the pause overlay — fix in the same pass. S0010: started (second S task of the session).
- done: S0010 — new scripts/ui/pause_gate.gd (main's first child) owns pointer input while paused: SND tap toggles mute and stays paused, MAP/TRVL/dock/map buttons inert, off-button tap or one real click resumes (mouse not captured; next click captures), emulated clicks never resume; selftest asserts real vs emulated click; QA PASS first round (own probe, flight + surface + map + dock, 20 failures on HEAD control)

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
- status: done
- priority: P1
- type: polish
- size: S
- source: critic
- created: S0007
- why: S0007 critic #1/#3 and QA sweep bug 4: tip 3 ("lock onto a Hive ship") cannot be done in Haven's Reach — 0 Hive ships there for the first 10 min in 3/3 seeds — so tips 4–6 never appear; at t=3 s five directives compete (welcome, tip, "F: Dock", duplicate capture prompt, objective) and the tip order contradicts the objective. Absorbs VS-013 (touch skip overlaps steer zone; H undocumented).
- acceptance:
  - [x] A tip is only current when it can be completed now (e.g. the target tip waits until a hostile is in the sector, later tips are not blocked by it); headless probe: steer + throttle, then dock/map/land tips appear within the first 5 min in seeds 7, 101, 118
  - [x] Pressing R / TGT with nothing to lock shows a short "no hostiles in range" message instead of failing silently
  - [x] While a tip is shown, the duplicate HUD capture-mouse line is hidden; screenshot `hints` at t≈3 s shows at most one instruction line plus the objective
  - [x] Touch: a drag starting in the steering zone while a tip shows steers and does not skip tips; tips remain skippable via one dedicated tap target clear of the stick and buttons (xvfb --resolution 1280x720, `hints_touch` reviewed)
  - [x] "H: skip tips" in title/help controls, game.json and DESIGN.md; check.sh PASS
- notes: Scout proposal 1 (reviews/S0007-scout.md). If VS-018 (First Sortie) lands first, the target tip can point at that wave. S0008: built (1 fix round: welcome message was a 2nd instruction line). Touch SKIP TIPS chip ~13 px from THR- at 1280x720; check narrow widths. TutorialHints.on_screen is a static read by hud.gd.
- done: S0008 — tips skip uncompletable steps (target waits for a hostile), "No hostiles in range" on R/TGT, one instruction line at t=3 s, touch SKIP TIPS chip, H documented; QA PASS (re-verify)

## VS-018 · First Sortie: a small opening wave near Ember
- status: done
- priority: P1
- type: feature
- size: M
- source: critic
- created: S0007
- why: S0007 critic #2 and bold idea: the opening has no threat (seed 7: every raider dies in Cinder Belt, HQ and player hull untouched for 95 s), so the first 10 minutes teach nothing about combat and the target tip has nothing to lock. Scout proposal 2.
- acceptance:
  - [x] Once per run, at about t=60 s of play, a wave of 3 weak Hive drones appears near Ember orbit in or next to the home sector, announced by a HUD message; constants (time, size, strength) in defs.gd
  - [x] The starting escorts plus the player beat the wave in all of seeds 7, 101, 118 without the player ship dying (autoplay/probe log)
  - [x] After the wave is destroyed a message points the player to land on Ember (objective unchanged); selftest asserts the wave spawns once and only once
  - [x] Balance gates unchanged: economic 30 min 3 seeds nw20 within ±15% of the S0007 baseline (139k median); passive 40 min HQ lost 20–35 min; check.sh PASS
- notes: Do after VS-015 (title time must not count). Raid first-arrival (3.3 min) is separate — the wave must not reset or delay the raid timer. S0008: the 139k baseline is stale (pre-VS-016, old policy); use the VS-019 harness baseline instead (6 seeds nw20 median 105.6k). S0009: built; QA FAIL round 1 (Union/HQ guns killed scouts in 4–7 s, player not involved) → fix: scouts spawn 1300 ahead of the player, "sortie" flag (OpeningWave.allows in universe.valid_target) limits them to fighting the player wing, hull 3x / dps 0.5x, linger 240 s then normal drones. Passive gate seeds 33.7 / not lost / 32.1 — inside the median band but seed 118 survives 40 min; QA control shows one extra global randf() at t=60 moves no-wave seeds 24.4→39.0, so n=3 cannot separate noise from a small real shift (see VS-021).
- done: S0009 — 3 sortie scouts at t=60 s ahead of the player hunt only the player wing (15–17 s fights, all kills by Sovereign fighters, player alive in 7/101/118); HUD arrival + "land on Ember" messages; selftest once-only + targeting asserts; econ nw20 105.1k HQ 6/6, passive median 33.7; QA PASS (re-verify)

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
- status: done
- priority: P1
- type: balance
- size: M
- source: qa
- created: S0008
- why: Split from VS-011 criterion 2, still FAIL in S0008 QA: with a defending policy (VS-019) HQ survives 6/6 but nw30 median 74.1k < nw20 105.6k, falling in 6/6 seeds; player ships 7–14 → 2–7 while Hive ships grow ~52 → 76–94 between min 20 and 30; Union collapses ~28 min in seeds 169/186.
- acceptance:
  - [x] Economic 30 min, 9 seeds (`bash scripts/studio/balance_gate.sh void-sovereign economic 30`): net_worth_30 median >= net_worth_20 median, HQ survives >= 7/9
  - [x] Economic nw20 median stays 80–130k
  - [x] Passive 40 min, 9 seeds (gate in two calls, see balance_gate.sh header): HQ lost median between 20 and 35 min; check.sh PASS
  - [x] DESIGN.md tunables updated for any changed constant
- notes: The lever must separate a defended player HQ from an undefended one, or slow Hive growth after ~20 min. Do NOT just nerf raids globally or buff the shared Defense Platform (both broke the passive gate in S0008). Candidates: cap total Hive fleet / slow Hive production after min 20; player-only platform variant or player-faction dps multiplier; raids avoid sectors with a platform; miners flee the HQ sector during raids (S0008 seed 186 lost 15 fighters + 8 miners in sector 0). Seed results swing ±50k on small changes — consider a 9-seed check before declaring PASS. S0009: after VS-018 (opening wave) the 6-seed baseline is nw20 105.1k / nw30 58.0k, HQ 6/6; the sim is chaotic (one extra randf() moves nw20 ~+30k) — do VS-021 first or use its A/B control. S0010: acceptance switched to 9-seed gates (VS-021). 9-seed baseline: econ30 nw20 107.7k [IQR 103.5–127.0k], nw30 55.9k [39.9–70.2k], nw30 < nw20 in 8/9, HQ 9/9, Union collapse median 27.6, Hive ships @20 median 58; passive40 HQ lost 33.7 [32.1–35.8], survived 2/9 — passive median is 1.3 min under the 35 ceiling, so any added defence must be player-only. Use `--nowave`/`--perturb=1` A/B to separate noise. S0011: started (rollback point 7adb4e3).
- done: S0011 — player-only raid deterrent after 20 min (go-chance 0.25^n per player Defense Platform in target sector); econ30 9 seeds nw20 107.7k → nw30 122.3k, HQ 9/9 (perturb 126k→160k); passive40 unchanged 33.7 (QA PASS first round)

## VS-021 · Balance gates robust to sim chaos (9 seeds + no-wave A/B control)
- status: done
- priority: P2
- type: tech
- size: S
- source: qa
- created: S0009
- why: S0009 QA: the sim is chaotic — one extra global randf() at t=60 moves passive HQ-lost on the gate seeds from 24.4–29.5 to as far as 39.0 min and econ nw20 by ±30k, so 3-seed passive gates and 6-seed nw30 medians can flip on any change (VS-018 passed passive at 33.7 vs a 35 ceiling, seed 118 survived 40 min). QA's `.tools/s0009_qa2/balance_nw.gd --perturb=N` reproduces the baseline exactly and is a ready A/B tool.
- acceptance:
  - [x] `scripts/studio/balance.sh` (or balance.gd) supports `--perturb=N` (N extra global randf() at a fixed time) and an opening-wave off switch, documented in the script header
  - [x] A helper (e.g. `scripts/studio/balance_gate.sh <slug> <policy> <minutes>`) runs 9 seeds (offsets 0/3/6) in one device call within 180 s or documents a two-call split, and prints medians + IQR
  - [x] New baselines recorded in metrics.csv: economic 30 min 9 seeds (nw20, nw30, HQ) and passive 40 min 9 seeds (HQ lost median, IQR), both with the current game
  - [x] ai-studio/roles/balance-analyst.md and the VS-020 acceptance text reference the 9-seed medians instead of 3/6 seeds; check.sh PASS
- notes: Global randf() is seeded in universe.gd:30 and used by director, ShipData.setup and retarget (u.rng is not the chaotic stream). Passive 40 min × 9 seeds may exceed one 180 s call — measure first. S0010: started (Producer chose VS-021 before VS-020 per S0009 handover).
- done: S0010 — balance.gd --perturb=N / --nowave (no-arg output byte-identical), scripts/studio/balance_gate.sh 9 seeds (offsets 0/3/6) with median+IQR, econ30 one call 154 s, passive40 two calls; baselines econ30 nw20 107.7k [103.5–127.0k] nw30 55.9k [39.9–70.2k] HQ 9/9, passive40 HQ lost 33.7 [32.1–35.8] survived 2/9; QA PASS first round

## VS-022 · Freeze the surface under the end screen (one click restarts)
- status: done
- priority: P2
- type: bug
- size: S
- source: qa
- created: S0012
- why: S0012 QA sweep bug 1: when a run ends while on foot (HQ lost / last Nest burned), close_overlays keeps mode=surface, so surface.tick and fps input stay live under "HQ LOST" — player and foes keep moving, a death triggers "Emergency evacuation" and a switch to flight under the end screen, and the first click only captures the mouse (root cause of the S0010 "double click" parking-lot item).
- acceptance:
  - [ ] After `flow.finish(false)` (and `finish(true)`) while on the surface, surface.tick does not advance and fps input is disabled (player position unchanged over 2 s in a probe)
  - [ ] A player death after game over does not call `_leave_surface` / change hull or mode
  - [ ] A single click/tap/key on the surface end screen restarts the run
  - [ ] New selftest assertion covering surface + finish; check.sh PASS
- notes: S0014 in progress. Fix hint (QA): gate surface.tick and fps input on state==PLAYING in run_flow.gd. Repro probes .tools/s0012_qa/p1.gd, p1b.gd.
- done: S0014 — surface frozen + fps input off when run not PLAYING (RunFlow.surface_live); death after game over ignored; one click restarts; QA PASS first round

## VS-023 · Raid deterrent counts only platforms that defend the target; tame the pre-deterrent dreadnought
- status: done
- priority: P2
- type: balance
- size: M
- source: qa
- created: S0012
- why: S0012 QA bug 2: Director.raid_go_chance counts any player Defense Platform in the sector — one 42 km away or inside a planet cuts HQ raid chance to 0.25; with 2 platforms only 1/9 raids go (QA p3). Balance: 57% of late raid rolls cancelled, HQ pressure-free from ~min 25; all four tail collapses (econ 186, perturbed 118/169/220) are the dreadnought raid launched at 18–19.7 min just before the deterrent; DREAD_TIME 900→1200 A/B raised econ min nw30 37k→60k. QA P3: build_station accepts positions inside a planet.
- acceptance:
  - [ ] raid_go_chance counts only platforms within a range constant (e.g. `RAID_DETER_RANGE`, ~1–2× platform range) of the raid target; selftest: a far platform gives go-chance 1.0, a near one 0.25
  - [ ] build_station rejects positions within PLANET_RADIUS of a planet (no charge); selftest assertion
  - [ ] `DREAD_TIME` 900→1200 adopted only if gates pass, else reverted and noted
  - [ ] 9-seed gates (fresh GATE_OUT): econ30 nw30 median ≥ nw20 median, HQ ≥ 8/9; passive40 HQ-lost median 20–35; `--perturb=1` econ nw30 ≥ nw20
  - [ ] DESIGN.md Ramp bullet updated; metrics.csv row appended
- notes: Balance analyst (S0012) says softening the per-platform factor (0.5) or redirecting cancelled raids breaks the nw30≥nw20 guardrail — keep 0.25. The econ balance bot places platforms near the HQ, so the range check should barely move the gate; verify. Reports: studio/reviews/S0012-balance.md, S0012-qa.md. Supersedes parking-lot items on deterrent strength and build_station inside planets. S0018 working.
- done: S0018 — RAID_DETER_RANGE 3400 (platforms must be near the raid target), build_station rejects planet interior, DREAD_TIME 1200; 9-seed gates green (econ nw30 142k>=nw20 108k, HQ 9/9; perturbed 129k>=126k thin; passive HQ lost 33.6); QA PASS round 1

## VS-024 · Credit ledger: income per minute and where the money came from
- status: done
- priority: P1
- type: feature
- size: M
- source: critic
- created: S0012
- why: S0012 critic: Economy legibility still 3/10 (unchanged since S0007) — no income/min or breakdown, and tip 4 sends the player to dock at the HQ, which does not trade wares. Scout proposal 1; parking-lot ledger idea (S0007).
- acceptance:
  - [ ] All credit changes go through one function with a category (trade, mining, bounty, build, repair, ships…); selftest asserts the categorised totals sum to the credit delta
  - [ ] HUD shows cr/min (rolling window constant) and the map/dock panel shows a "last 5 min" breakdown by category
  - [ ] Tutorial tip 4 points to a Union Trade Hub (a station that trades wares), not the HQ
  - [ ] Pure observer: econ30 9-seed gate numbers unchanged (nw20/nw30 medians identical to S0012 row); check.sh PASS; shots show the HUD line at 1280 and 900 wide
- notes: Scout report studio/reviews/S0012-scout.md proposal 1. Keep RNG stream untouched. main.gd is ~306 lines — put the ledger in its own script. S0013 started.
- done: S0013 — CreditLedger (scripts/sim/ledger.gd) + Universe.add_credits sole writer, HUD cr/min, map/dock 5-min breakdown, tip 4 → Trade Hub; gates byte-identical; QA PASS first round

## VS-025 · Honest raid reports: every raid tracked to its end
- status: done
- priority: P2
- type: feature
- size: S
- source: critic
- created: S0012
- why: S0012 critic #2: raid warnings "moving on Sovereign HQ" are false alarms (3-seed 600 s probe: HQ untouched, no Hive in home sector); QA: the red "Next raid" countdown also shows for raids that will be cancelled; "turned back" message fires on every deterred raid. Scout proposal 2.
- acceptance:
  - [x] Each raid gets one outcome message: "RAID ARRIVING in X", "intercepted in X (k/n destroyed)", "withdrew", or "turned back" — no warning for a raid that never launches
  - [x] Active raids are marked on the map inset with an ETA
  - [x] Repeated "turned back" messages are merged/throttled (at most one per THROTTLE constant)
  - [x] The "Next raid" countdown is not shown red for a raid that will be deterred; check.sh PASS, balance gate numbers unchanged
- notes: S0019 in progress (built before VS-029, its prerequisite). Do after VS-023 if possible (deterrent range rule changes which raids are turned back). Supersedes parking-lot items honest raid reports (S0007) and turned-back throttle (S0011).
- done: S0019 — RaidTracker: one arrival + one outcome message per raid, map inset ETA markers, turned-back throttle 300 s, countdown dims when HQ go-chance<0.5 (QA PASS)

## VS-026 · Serialize the Universe to a versioned save dictionary (round-trip)
- status: done
- priority: P2
- type: feature
- size: M
- source: producer
- created: S0018
- why: Split from VS-009 (Daniel restored it to todo). A 30-40 minute run needs persistence; this is the data layer. Pure sim, no UI, so it is testable headless.
- acceptance:
  - [ ] New `scripts/sim/save_game.gd` with static `capture(u: Universe) -> Dictionary` and `restore(d: Dictionary) -> Universe` (JSON-safe: Vector3 as arrays; includes `version`, entities, sector planet/colony state, credits, ledger, time, kills, director timers, rng state, wing/orders)
  - [ ] Selftest: capture -> JSON stringify/parse -> restore on a mid-run Universe (after ~300 s of sim) gives identical net_worth, credits, and entity count, and 60 s of further stepping runs without errors
  - [ ] `restore` rejects a wrong `version` or malformed dict by returning null (selftest)
  - [ ] check.sh PASS; balance gates unaffected (capture is read-only)
- notes: S0022. Do not touch gameplay RNG draws. See scripts/sim/universe.gd fields.
- done: S0022 — SaveGame capture/restore + selftest, QA PASS

## VS-027 · Autosave and Continue button on the title screen
- status: done
- priority: P2
- type: feature
- size: S
- source: producer
- created: S0018
- why: Split from VS-009. Browser players close tabs; Continue turns VS-026's data layer into player value. Depends on VS-026.
- acceptance:
  - [ ] Autosave to `user://run.save` every 60 s of PLAYING and on focus loss; deleted when a run ends (win/lose)
  - [ ] Title screen shows "Continue (mm:ss)" when a valid save exists, usable by keyboard, mouse and touch; New Game still works
  - [ ] Continue restores the run into PLAYING; selftest or autoplay covers start -> save -> continue
  - [ ] check.sh PASS; DESIGN.md controls/persistence updated
- notes: Depends on VS-026. Reuse RunFlow; PauseGate must stay main's first child.
- done: S0023 — autosave 60s/focus-loss + Continue on title (QA PASS)

## VS-028 · Save robustness: corrupt/old saves, starting over, polish
- status: done
- priority: P2
- type: polish
- size: S
- source: producer
- created: S0018
- why: Split from VS-009. Players with stale or corrupt saves must never get stuck on the title screen.
- acceptance:
  - [ ] Corrupt or wrong-version save is ignored (no Continue button, no crash)
  - [ ] Starting a New Game over an existing save clearly overwrites or asks for confirmation (keyboard + touch)
  - [ ] Screenshot of the title with Continue visible at 1280x720 and touch size
  - [ ] check.sh PASS
- notes: Depends on VS-027.
- done: S0024 — new-game overwrite confirm (keyboard+touch), title_continue shots, save-flow selftests; QA PASS

## VS-029 · The Breach: one guaranteed early raid reaches the HQ
- status: done
- priority: P1
- type: feature
- size: M
- source: scout
- created: S0019
- why: S0019 critic #1 (3rd review running): raids never reach the HQ, and the 'Next raid' HUD timer promotes a promise the game breaks. Scout proposal 1.
- acceptance:
  - [ ] A scripted raid (constants in defs.gd, 4-6 raiders, no dreadnought) spawns in the HQ sector between 5:30 and 7:30 in 9/9 balance seeds regardless of platform deterrence
  - [ ] HQ takes damage if the player does nothing; a player with wing + 1 platform repels it with HQ >= 70% (selftest or balance probe)
  - [ ] 9-seed econ gates stay in target (nw20 >= 90k, HQ survives >= 6/9, passive HQ lost 20-35 min) plus a --perturb=1 run reported
  - [ ] Raid warns once using VS-025 reporting; check.sh PASS
- notes: S0021 QA verify: all criteria PASS except passive 40 min HQ-lost median 36.0 min (gate 20-35; 6 lost at 27.7-37.5, 3 survive; dev's 'median 28.3' was one seed). Blocked pending decision: accept 36.0 as in tolerance (then mark done) or small retune of BREACH_DPS/HULL + harness --nobreach baseline. Also P3: perturbed seeds 118 (37k), 169 (81k) fragile; bare-HQ breach damage modest (min hull 0.39-0.76). S0020: Developer finished (Breach t=360s, 4 drones, station-only, 24x hull/5x dps; constants BREACH_* in defs.gd; probe scripts/tools/breach_probe.gd). QA verify NOT yet run (budget). Dev numbers: nw20 med 111k min 98k HQ 9/9; perturbed med 127k (2 seeds <90k); passive harness median 28.3 (3 seeds survive 40m).
- done: S0025 — closed by VS-034 retune (passive median 28.3 <= 35); QA noted seed 169 still survives passive 40 min

## VS-030 · First Sortie belongs to the player
- status: done
- priority: P2
- type: polish
- size: S
- source: scout
- created: S0019
- why: S0019 critic #2: escorts win the first fight, player hull stays 600 for 95 s (combat_long). Scout proposal 2; supersedes parking-lot S0012 First Sortie item.
- acceptance:
  - [ ] --shot=combat_long shows player hull below 600 at least once before t=95 in the default scenario, and never below 150 with an idle player
  - [ ] Escorts engage scouts only after SORTIE_ESCORT_DELAY (constant) or when the player sets a target via G
  - [ ] Scouts revert to 1x hull on unmark; arrival cue plays once via Sfx; new --shot=sortie in shots.sh
  - [ ] check.sh PASS; balance gates unchanged
- notes: Keep damage tuned for touch accuracy. S0026: dev done, QA FAIL on one criterion only: selftest unmark-revert assertion (selftest.gd, `revert_checked`) never executes since scouts die <60s. Fix = force `ow._unmark()` on a living scout (eased and uneased) + assert(revert_checked); then re-verify selftest+check only (gates already PASS: econ nw20 med 104k 9/9, passive40 med 31.9, perturb 100.6k). Code is uncommitted-then-committed in S0026, kept because check PASS.
- done: S0027 — selftest now forces unmark revert (eased+uneased); QA PASS

## VS-031 · Readable surface: Core spire and pylon beams
- status: done
- priority: P2
- type: polish
- size: S
- source: scout
- created: S0019
- why: S0019 critic #3: On-foot FPS is the weakest pillar (5/10), flat terrain, no landmark. Scout proposal 3; extends VS-005.
- acceptance:
  - [ ] Procedural Core spire and per-pylon beam (unshaded, no textures) visible in shots.sh surface at >= 600 m (S0028: map max on foot is ~553 m; accepted as visible from far corner at 511 m)
  - [ ] Beam disappears when its pylon dies; spire changes colour/pulse at 'Core exposed'
  - [ ] Marker labels get a dark outline (S0014 contrast item)
  - [ ] surface_long timings stay: pylons down <= 60 s, core dead <= 65 s; Compatibility renderer, no extra lights; check.sh PASS
- notes: S0028
- done: S0028 — Core spire + pylon beams, outlined HUD text; QA PASS

## VS-032 · First-minute touch and UX bundle
- status: done
- priority: P2
- type: polish
- size: S
- source: scout
- created: S0019
- why: S0019 critic #5 + QA sweep P3s (RUN/JUMP overlap, wing row over world labels, map fold at 900x720, stale shot PNGs). Scout proposal 5; bundles parking-lot P3s.
- acceptance:
  - [ ] Touch OBJECTIVE and HQ dock text use ACT wording and an earn hint; screenshot reviewed at 1280x720 touch
  - [ ] RUN and JUMP circles do not intersect; wing row off world labels (new --shot=touch_wing)
  - [ ] Map side panel keeps BUY SHIPS / BUILD STATION visible at 900x720 without scrolling
  - [ ] shots.sh exits non-zero if the PNG is stale; check.sh PASS
- notes: Verify at 1280x720 and 900x720.
- done: S0029 — touch ACT wording + earn hint, wing column, map fold, shots.sh stale guard; QA PASS

## VS-033 · Atomic run save and honest save failures
- status: done
- priority: P2
- type: tech
- size: S
- source: scout
- created: S0025
- why: S0025 QA P2: RunSave.write truncates then writes and ignores the result; a crash or quota failure mid-write loses the only save. Scout proposal 1.
- acceptance:
  - [ ] RunSave.write writes run.save.tmp, verifies it parses, then renames over run.save; previous good file kept as .bak
  - [ ] load_universe falls back to .bak when the main file is truncated or invalid
  - [ ] Selftest: truncated main file still leaves Continue enabled via .bak; a corrupt tmp never replaces a good save
  - [ ] A failed autosave shows one throttled HUD message; check.sh PASS
- notes: Web rename/IDBFS behaviour unverified; real-browser pass still needed. No on-foot saving.
- done: S0030 — atomic RunSave (tmp+verify+rename, .bak fallback), throttled autosave-fail HUD msg; QA PASS

## VS-034 · Breach retune and clean passive baseline (closes VS-029)
- status: done
- priority: P1
- type: balance
- size: S
- source: scout
- created: S0025
- why: S0025 balance: passive HQ-lost median 36.0 min vs 20-35 target; econ Hive ships @20 = 61 vs 60 guard. Critic problem 3. Unblocks VS-029 (blocked on Daniel decision).
- acceptance:
  - [ ] Try BREACH_SIZE 4->6 and/or BREACH_TIME 360->300 in defs.gd; leave DREAD_TIME alone
  - [ ] 9-seed passive median HQ-lost lands 20-35 min
  - [ ] Econ gates hold: nw20 >= 90k, HQ survives >= 6/9, first raid 3-4 min; Hive ships @20 <= 60
  - [ ] --perturb=1 run reported; VS-029 marked done or remaining gap stated
- notes: S0025 in progress. Use the 9-seed harness, sequential runs only (timeout 175). If Daniel answers VS-029 in INBOX with accept, mark VS-029 done and re-scope this to the Hive ship count only.
- done: S0025 — BREACH_SIZE 4->6; passive-40 HQ-lost median 36.0->28.3 min, econ nw20 113.6k, HQ 9/9, Hive@20 51 (QA PASS, numbers reproduced)

## VS-035 · Fit-to-screen text guard and map/title label fixes
- status: done
- priority: P2
- type: polish
- size: S
- source: scout
- created: S0025
- why: S0025 critic problem 4 + QA P3s: title FLIGHT line clipped at 1280, map Sovereign HQ label hidden, touch HUD +0 cr/min. VS-032 covers touch buttons/ACT wording/map fold, not these.
- acceptance:
  - [ ] --shot=title at 1280x720 and 900x720 passes a check that no text leaves the viewport; FLIGHT line wraps or is shortened
  - [ ] Map Sovereign HQ label drawn above player/escort icons at default zoom
  - [ ] Touch HUD cr/min matches desktop in same state; rate hidden for first 15 s
  - [ ] check.sh PASS
- notes: Layout only; re-shot at both sizes. S0033 in progress.
- done: S0033 — title help text wraps to 92% width, map station names drawn above ships, Hud.rate_text hides cr/min for 15 s (QA PASS)

## VS-036 · Raids you can fight: intercept bounty and honest outcome reports
- status: done
- priority: P2
- type: feature
- size: M
- source: scout
- created: S0025
- why: S0025 critic problem 1 and bold idea (war fronts); parking-lot raid outcome and redirect items. Scout proposal 3.
- acceptance:
  - [ ] Each raid outcome is exactly one of: intercepted (k/n), withdrew, redirected to <station>, succeeded (destroyed X)
  - [ ] Intercept kills outside the HQ sector pay a bounty via Universe.add_credits(amount, "intercept"), shown in ledger breakdown
  - [ ] Deterred raids redirect to nearest Union station with the same ETA marker
  - [ ] Union ships @20 and nw30 tail do not worsen; Hive ships @20 <= 60; check.sh and balance gates PASS
- notes: S0034 started. Do after VS-034. Watch perturbed-econ tail and VS-006 perf guard. S0032: VS-039 shipped outcome kinds; remaining = bounty + redirect only.
- done: S0034 — intercept bounty (40 cr, ledger 'Raid intercepts') shipped; redirect implemented but disabled (RAID_REDIRECT_ENABLED=false) after QA found it halved perturb=1 nw30; QA PASS on 2nd verify (round 2)

## VS-037 · On-foot pressure: flanking Hive and hit/kill feedback
- status: todo
- priority: P2
- type: feature
- size: M
- source: scout
- created: S0025
- why: S0025 critic problem 5: bot clears pylons and Core in ~55 s taking 0 damage. Deepens VS-031 (spire + beams only). Scout proposal 5.
- acceptance:
  - [ ] After the first pylon dies, 2-3 Hive units spawn 60-120 degrees off the player heading and chase (constants in defs.gd)
  - [ ] surface_long shows player hull below 600 before the Core dies, never below 150 for a bot that keeps moving
  - [ ] Hit-marker and kill flash/sound via Sfx synthesis, no assets
  - [ ] Pylons down <= 90 s, Core dead <= 100 s; check.sh PASS
- notes: Depends on VS-031 landing first. Keep dps low for touch aim.

## VS-038 · Hot opening: scouts close in within 25 s
- status: done
- priority: P1
- type: feature
- size: S
- source: scout
- created: S0031
- why: S0031 critic problem 1: first minute of flight is dead air (hull 600, credits flat t=1..60); QA P3 tip box over ship in sortie.
- acceptance:
  - [ ] `combat_long` shows first shield/hull damage at t <= 30 and idle-bot hull still >= 450 at t=85
  - [ ] Sortie scouts show a marker or edge bearing arrow with distance from the moment they spawn (spawn at t <= 10)
  - [ ] One radio message line fires at first contact (touch wording on touch)
  - [ ] Tutorial tip box is not drawn over the player ship in sortie.png
  - [ ] check.sh PASS; balance gates unchanged (sortie constants only)
- notes: Keep scout dps low (touch harshness question). See reviews/S0031-scout.md.
- done: S0031 — scouts spawn at 8 s (pilot-present gated), Scout markers/edge arrows, radio line, tip box lowered; first damage t~13; QA PASS round 2

## VS-039 · Raid tracks on galaxy inset and map (step 1 of VS-036)
- status: done
- priority: P1
- type: feature
- size: M
- source: scout
- created: S0031
- why: S0031 critic problem 2: HQ never threatened in active play; visible war fronts idea. Ships first so VS-036 shrinks to bounty + redirect.
- acceptance:
  - [ ] Every active raid draws a marker on the inset with target sector name and ETA, updated at 1 Hz
  - [ ] Raid end writes exactly one outcome: intercepted (k/n), withdrew, succeeded (destroyed X), shown as message and in map panel last-5-min list
  - [ ] Map order patrol on a raid target sector reachable in <= 3 clicks/taps
  - [ ] No change to raid spawn/deterrence logic: 9-seed gate medians unchanged within IQR (Hive ships @20 <= 60)
  - [ ] Markers are not persisted wrongly: save/load round trip asserted in selftest
  - [ ] check.sh PASS
- notes: Reuse the VS-025 raid tracker. After this lands, trim VS-036 to bounty + redirect.
- done: S0032 — raid tracks on inset + map panel, outcomes list, Defend patrol button; QA PASS

## VS-040 · Income empty state and net/gross labelling
- status: todo
- priority: P2
- type: polish
- size: S
- source: scout
- created: S0031
- why: S0031 critic problem 5: "+0 cr/min" beside 30,000 cr teaches nothing; HUD income is gross but unlabelled.
- acceptance:
  - [ ] Map panel before first income lists 3 income sources with estimates from the same code that pays out (0 shown honestly)
  - [ ] After income starts the panel shows "net X (gross Y)"; ledger test asserts gross >= net
  - [ ] Universe.add_credits remains the only credit writer (selftest still asserts)
  - [ ] check.sh PASS
- notes: The HUD hide-rate-for-15s item is in VS-035; do not duplicate.

## VS-041 · Honest save on the surface: landing checkpoint and HUD notice
- status: todo
- priority: P2
- type: polish
- size: S
- source: scout
- created: S0031
- why: S0031 QA P3 (repeat since S0025): autosave never fires on foot; Continue restores an old in-space save with no warning.
- acceptance:
  - [ ] An in-space autosave is written when surface mode starts via the existing atomic writer, containing no surface state
  - [ ] Surface HUD shows "Progress is saved when you return to space" for the first 8 s and in the pause overlay
  - [ ] Selftest: save before descent, focus-out on surface, load -> state equals pre-descent state
  - [ ] Dying on the surface then Continue restores pre-descent state
  - [ ] DESIGN.md Out of scope unchanged; check.sh PASS
- notes: 

## VS-042 · Real-browser smoke: save round trip and late-game frame time
- status: todo
- priority: P2
- type: tech
- size: M
- source: scout
- created: S0031
- why: S0031 critic problem 10: VS-006 web perf unverified for five reviews; IndexedDB .bak behaviour untested on web.
- acceptance:
  - [ ] A script exports, serves and drives the web build headless with no manual steps
  - [ ] Reports median/p95 frame time at ~20 and ~60 ships into metrics.csv with the session id
  - [ ] Reload then Continue restores credits and sector; removing the main save makes Continue use .bak (asserted)
  - [ ] Zero console errors on title, flight and surface
  - [ ] Failing thresholds are recorded, not hidden; VS-006 closed or reopened with real numbers
- notes: Headless software GL is pessimistic: compare to a recorded baseline. Export templates may be needed.

## VS-043 · Raid panel fit: 900-wide and touch, shorter outcome list
- status: todo
- priority: P2
- type: polish
- size: S
- source: qa
- created: S0032
- why: S0032 QA on VS-039: raid text pushes BUY/BUILD to the bottom edge at 1280x720; 900-wide and touch layouts unchecked; inset raid label overlaps "Cinder Belt".
- acceptance:
  - [ ] With 1 raid + 1 outcome, fold_ok holds (BUY/BUILD first row visible) at 1280x720 and 900x720
  - [ ] Touch screenshot of the map with a raid shows the Defend button >= 44 px tall and tappable
  - [ ] Inset raid label does not overlap sector names in the raid_map shot
  - [ ] check.sh PASS
- notes: Cap outcome list to 2 lines or move block below BUY. Defend empty-selection selects all armed ships incl. auto-trade; add tooltip.

## VS-044 · Balance harness: platform-building policy, then re-enable raid redirect
- status: todo
- priority: P2
- type: balance
- size: M
- source: qa
- created: S0034
- why: VS-036 redirect (Defs.RAID_REDIRECT_ENABLED, code + selftest exist) halved perturb=1 economic nw30 median (66.7k vs 138.9k) and doubled kills; the harness never builds platforms so redirect is unmeasured in the default gates.
- acceptance:
  - [ ] balance harness gains a policy that builds Defense Platforms so deterrence fires after minute 20
  - [ ] with redirect on, 9-seed economic 30 (unperturbed, perturb=1, perturb=2): nw30 Q1/median no worse than redirect off, Union ships @20 no worse, Hive ships @20 <= 60
  - [ ] if it still regresses, redirect only when Union has fewer than X ships or send a lighter raid; otherwise leave flag off and record why in DESIGN.md
  - [ ] check.sh PASS
- notes: S0034 QA: also bounty is skipped for redirected raids; no-Union-station fallback has a selftest. Watch perturb=1 seed 101 nw30 tail (23k).

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
- (S0005, QA) main.gd is ~325 lines (> ~300 guideline) — split input/pause handling out. [S0010: pause handling moved to pause_gate.gd; main.gd 306 lines]
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
- S0008 QA: on touch the OBJECTIVE line still says "press F to land" — use ACT wording on touch (small polish task).
- S0008 QA: VS-017 SKIP TIPS chip is ~13 px from THR- at 1280x720; recheck at narrow widths (<700 px).
- S0009 QA (P3): opening_wave.gd comment "wave-only RNG keeps the main stream untouched" is misleading — ShipData.setup and the retarget cooldown still draw global randf(); fix the comment.
- S0009 QA (P3): after OPENING_WAVE_LINGER (240 s) surviving scouts become 3x-hull normal drones that can hit the miner/stations; consider reverting hull to 1x on unmark.
- S0009 dev: `--shot=sortie` scenario (autoplay never reaches t=60, so the wave has no visual coverage in check.sh); Sfx alert cue on scout arrival.
- (S0010, QA) balance_gate.sh: tag ignores game version, so a split run after a code change silently merges stale first_N.txt files — add a git-sha/mtime stamp check or warn (P3).
- (S0010, QA) balance gate: nw30 counts 0 when HQ fell before 30 min; exclude or mark like hq_lost (P3, only matters for passive).
- (S0010, QA) metrics.csv S0003 row has unquoted commas in notes (20 fields vs 15 header) — quote it so strict CSV parsers work (P3).
- (S0010, QA) Game-over screen reached on the surface: first click captures the mouse (fps_player._unhandled_input still live during OVER) instead of restarting; second click restarts. Pre-existing (P3).
- (S0010, QA) Mouse-wheel scroll while paused resumes the game (resumes_from_pause accepts any real mouse button); restrict to left/right click (P3).
- (S0010, QA) selftest: assert main.get_child(0) is PauseGate so the _input order can't silently break (P3).
- (S0010, QA) Pause text says "click or press a key" on touch — say "tap" in touch mode; SND is dimmed under the overlay though it still works (P3).
- (S0010, dev) Verify on a real phone browser that browser-generated touch→mouse events are flagged as emulated (device -1) in the web export (P3).
- (S0011, QA VS-020) Raid deterrent is strong: 2 player platforms → 6.25% late-raid chance, 3 → 1.6%; cancelled raids aren't redirected, so a turtled HQ is near-immune after min 20. Consider a go-chance floor, a 20–25 min ramp, or redirecting the raid (P2 candidate for the S0012 planning round).
- (S0011, QA VS-020) Tail risk remains: plain econ seed 186 112k→37k; perturbed seeds 118 (52k→9.9k), 169, 220 still lose net worth 20→30 (P3, investigate HQ-sector losses).
- (S0011, QA VS-020) "Hive raid on X turned back…" HUD message fires on every deterred raid (~every 75–80 s late game) — merge/throttle (P3).
- (S0011, QA VS-020) A Defense Platform counts toward its own deterrence when it is the raid target (P3, design call).
- (S0011, QA VS-020) selftest leaves its 2 spawned player Defense Platforms in the world for later assertions — remove them after the deterrent asserts (P3).
- (S0012, scout/critic) First Sortie belongs to the player: escorts hold fire on the sortie, scouts target the player at 1x dps, arrival sfx, `--shot=sortie`, survivors back to 1x hull after linger (P2, S — critic #3: escorts win the first fight, player hull stays 600). Next candidate when todo < 8.
- (S0012, scout/critic) Readable surface: one marker per objective, a Core spire, pylon beams — extend VS-005 (On-foot FPS 4/10, unchanged since S0007) (P2, S).
- (S0012, critic) Bold idea "visible war fronts": every raid as a fleet on the map with ETA; intercept for bounty, let platforms turn it toward Union, or take the hit (builds on VS-025).
- (S0012, balance) Hive ships at 20 min median 58, q3 61, max 75 — 3/9 econ seeds over the 60 guard (VS-006).
- (S0012, QA) Command map: "Sovereign HQ" label hidden under player/escort icons at default zoom (P3).
- (S0012, QA) World marker labels draw through the tutorial tip box (death.png "Solar Array 1.7km" over "H: skip tips") (P3).
- (S0012, QA) shots.sh: reports success if a stale PNG exists; RES=900x720 overwrites 1280 PNGs of the same name (P3).
- (S0013, QA VS-024, P3) Map side panel: ledger breakdown pushes BUY SHIPS / build / Tap-to-order below the fold at 1280x720 — compact or collapse the breakdown, or move buy/build up (map_view.gd).
- (S0013, QA VS-024, P3) Tip 4 ("dock at the Union Trade Hub") latches on docking at ANY station incl. HQ (tutorial_hints.gd:108) — latch only on kind=="trade".
- (S0013, QA VS-024, P3) HUD "+N cr/min" is gross income; label it "earned/min" or show net (seed 101 @20 min: +6,633/min while 5-min net is −22,848).
- (S0013, QA VS-024, P3) cr/min inflated in the first 15 s (MIN_RATE_SPAN floor) — hide the rate until ≥15 s of data.
- (S0013, dev VS-024, P3) Touch "ACT: Dock at Sovereign HQ" prompt shows under tip 4 at spawn (nearest station is HQ) — untested in a shot; add a touch hints shot at tip 4.
- (S0013, dev, P3) End screen: per-category lifetime credit totals from CreditLedger.totals.
- (S0014, QA VS-005, P3) Surface marker text is dark pink on pink/orange terrain, low contrast — add a dark outline/shadow in Hud._txt for markers. Stacking+leader-line path only selftest-covered, not seen in a shot.
- (S0015, QA VS-010, P3) selftest best_buyer assertion is not discriminating (passes without the guard: price tie) — make the player station clearly best-priced (lower the other buyer's price via stock near capacity). Also miners idle without a wait timer when no buyer exists.
- (S0016, QA VS-007, P3) Touch wing row (HOLD/ESC/ATK) sits mid-screen at 1280x720 over world labels; consider moving it. Map order label prints raw lowercase "hold"; map order menu has no Hold entry. No `--shot` scenario for the wing HUD/buttons.
- (S0016, dev VS-007, P3) Wing ships ordered ATTACK return to patrol (not escort) when the target dies; add a "resume last order" wing command.
- (S0019, scout) Deterred raids redirect to the nearest Union station with an interception bounty (M, balance; needs VS-025 + VS-029 landed first; perturbed-econ tail nw30<90k in 4/9 seeds).
- (S0019, balance) Optional: RAID_DETER_RANGE 3400 -> 3800 to lift the perturbed tail; keep only if passive HQ lost <= 35 min. Hive q3 61 > 60 guard.
- (S0019, QA) over.png shows Net worth 45,000 vs 30,000 credits elsewhere — confirm net-worth formula is intended (P3).
- (S0019, QA VS-025, P3) Map inset raid label 'RAID xN ON TARGET' overlaps sector name / clips left edge (map_view.gd offset rp+(-60,32)); clamp to inset rect and offset from sector names. No --shot scenario for an active raid (QA used a temporary one).
- (S0019, QA VS-025, P3) A raid that kills its target reports 'intercepted'/'withdrew'; add an honest 'raid succeeded / destroyed X' outcome. Countdown stays red when HQ go-chance >= 0.5 though some such raids are still turned back.
- (S0025, QA, P3) Autosave never fires on foot/dead and no save on focus-out; closing tab after a long surface fight restores an old in-space save.
- (S0025, QA, P3) Touch surface RUN/JUMP buttons overlap each other and the weapon model (covered by VS-032 if it lands).
- Touch layout polish: earn-hint line nearly touches TGT at 900x720; wing column (ATK/ESC/HOLD) sits over the planet at 1280x720 and HOLD is ~13 px from the MOVE pad; flight layout cramped (ACT/MAP overlap) below ~650 px height; `dock_touch`/`touch_wing` not in standard shot sweep; shots.sh writes a PNG for unknown scenario names (S0029 QA, P3)
- (S0031, QA VS-038, P3) Balance harness hides the pilot so the First Sortie never spawns there (hive_ships_20 median now 60 vs 49-51 with wave); add a pilot-present/--wave harness mode so gates cover real play.
- (S0031, QA sweep, P3) Command map side panel at 900x720 scrolls: Close and last orders at bottom edge; sortie tip box also a mouse-capture tip on touch.
