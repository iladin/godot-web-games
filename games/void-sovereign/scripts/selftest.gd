extends SceneTree
## Logic checks for the simulation layer. Run by scripts/check.sh.

# AI journey tests (fixed seed). Time bounds = worst-case straight-line path / ship speed x slack.
const JOURNEY_SEED := 7
const JOURNEY_DT := 1.0 / 10.0     # coarser than the game tick: keeps the selftest fast
const PATH_SLACK := 2.0            # accel/brake ramps, arrival slow-down, gate approach offsets
const TRAVEL_FROM := 0             # Haven's Reach
const TRAVEL_TO := 3               # Cinder Belt: 2 jumps via Argent Fields
const MINE_SELL_MARGIN := 60.0     # extra seconds for docking approach at the buyer


func _init() -> void:
	var u := Universe.new()
	u.setup(7)

	# Galaxy wiring
	assert(u.sectors.size() == Defs.SECTORS.size())
	assert(u.route(0, 5).size() == 3, "Haven -> Black Choir is 3 jumps")
	assert(u.route(2, 2).is_empty())
	assert(u.hq != null and u.hq.sector == 0)
	assert(u.player_ship != null and u.player_ship.is_player)
	assert(u.alive_nests().size() == 2)
	for n: StationData in u.alive_nests():
		assert(not n.can_be_damaged(), "nests start shielded by their planet Core")

	# Pricing: empty stock is expensive, full stock is cheap.
	var st := StationData.new()
	st.setup("refinery", Defs.Faction.UNION)
	st.stock["ore"] = 0
	var hi := st.price("ore")
	st.stock["ore"] = st.capacity
	var lo := st.price("ore")
	assert(hi > lo)
	assert(is_equal_approx(hi, 16.0 * Defs.PRICE_HIGH))

	# Transactions: player buys from Union -> pays; Union buys from player station -> player earns.
	var ship := u.spawn_ship("trader", Defs.Faction.PLAYER, 0, Vector3.ZERO)
	var seller := u.spawn_station("solar", Defs.Faction.UNION, 0, Vector3(500, 0, 0))
	var before := u.credits
	var price := seller.price("energy")
	var cost10 := seller.batch_total("energy", 10, true)
	assert(cost10 > price * 10.0, "VS-016: a bought batch walks up the price curve")
	var got := u.transact(ship, seller, "energy", 10, true)
	assert(got == 10)
	assert(is_equal_approx(u.credits, before - cost10))
	# Player auto-traders never spend below TRADER_RESERVE.
	seller.stock["energy"] = 200
	var price_r := seller.price("energy")
	u.credits = Defs.TRADER_RESERVE + price_r * 3.5
	ship.cargo.clear()
	var got_r := u.transact(ship, seller, "energy", 50, true)
	assert(got_r == 3, "trader buys only what the reserve allows")
	assert(u.credits >= Defs.TRADER_RESERVE)
	u.credits = Defs.TRADER_RESERVE - 1.0
	assert(u.transact(ship, seller, "energy", 10, true) == 0, "trader below reserve buys nothing")
	assert(is_equal_approx(u.credits, Defs.TRADER_RESERVE - 1.0))
	u.credits = Defs.START_CREDITS
	var pst := u.spawn_station("solar", Defs.Faction.PLAYER, 0, Vector3(-500, 0, 0))
	pst.stock["energy"] = 50
	var npc := u.spawn_ship("trader", Defs.Faction.UNION, 0, Vector3.ZERO)
	before = u.credits
	var p2 := pst.batch_total("energy", 20, true)
	u.transact(npc, pst, "energy", 20, true)
	assert(is_equal_approx(u.credits, before + p2))
	_check_no_round_trip_profit(u)

	# Production cycle consumes inputs, makes outputs.
	var ref := u.spawn_station("refinery", Defs.Faction.UNION, 1, Vector3.ZERO)
	ref.stock["ore"] = 100
	ref.stock["energy"] = 100
	ref.stock["alloy"] = 0
	ref.cycle_t = 0.0
	ref.produce(Defs.CYCLE_TIME + 0.01)
	assert(int(ref.stock["alloy"]) == 3 and int(ref.stock["ore"]) == 92)

	# VS-001: Trade Hubs export surplus above TRADE_HUB_TARGET_FILL each cycle (never below it).
	var hub := StationData.new()
	hub.setup("trade", Defs.Faction.UNION)
	var hub_target := int(float(hub.capacity) * Defs.TRADE_HUB_TARGET_FILL)
	hub.stock["ore"] = hub.capacity
	hub.stock["energy"] = hub_target + 5
	hub.cycle_t = 0.0
	hub.produce(Defs.CYCLE_TIME + 0.01)
	assert(int(hub.stock["ore"]) == hub.capacity - Defs.TRADE_HUB_EXPORT, "hub exports surplus ore")
	assert(int(hub.stock["energy"]) == hub_target, "hub never exports below its target fill")
	# VS-001: civilians plan around sectors holding a Hive pack.
	u._rebuild_cache()
	assert(not u.sector_unsafe(0), "Haven's Reach starts safe")
	assert(u.sector_unsafe(3), "Cinder Belt starts infested")

	# Run 8 minutes of simulated time and make sure the world keeps working.
	var trades_before := 0
	for e: SimEntity in u.entities.values():
		if e is StationData:
			trades_before += int((e as StationData).stock["energy"])
	var raids_seen := false
	var dt := 1.0 / 20.0
	var ow := u.director.opening
	var wave_hostile_seen := false
	for i in int(480.0 / dt):
		u.step(dt)
		if u.director.raid_count > 0:
			raids_seen = true
		# VS-018 First Sortie: nothing before OPENING_WAVE_TIME, then exactly one wave in the
		# home sector, and the raid countdown runs on untouched.
		if u.time < Defs.OPENING_WAVE_TIME - 0.5:
			assert(ow.spawn_count == 0, "opening wave waits for OPENING_WAVE_TIME")
		elif ow.spawn_count == 1 and ow.state == OpeningWave.State.ACTIVE and not wave_hostile_seen:
			wave_hostile_seen = true
			assert(ow.ids.size() == Defs.OPENING_WAVE_SIZE, "wave has OPENING_WAVE_SIZE ships")
			assert(TutorialHints.hostile_in(u, u.hq.sector), "the wave makes the target tip reachable at home")
			assert(absf(u.director.raid_t - (Defs.FIRST_RAID - u.time)) < 0.2, "the wave does not reset or delay the raid timer")
		assert(ow.spawn_count <= 1, "the opening wave spawns only once")
	assert(ow.spawn_count == 1 and wave_hostile_seen, "the opening wave spawned once")
	# Sortie scouts are the player's fight: only the player and Sovereign warships trade fire with them.
	var scout := ShipData.new()
	scout.setup("drone", Defs.Faction.HIVE)
	scout.sortie = true
	var mk := func(cls: String, fac: int) -> ShipData:
		var x := ShipData.new()
		x.setup(cls, fac)
		return x
	assert(u.valid_target(mk.call("fighter", Defs.Faction.PLAYER), scout), "escorts engage scouts")
	assert(u.valid_target(scout, u.player_ship) and u.valid_target(scout, mk.call("fighter", Defs.Faction.PLAYER)), "scouts hunt the player's wing")
	assert(not u.valid_target(mk.call("fighter", Defs.Faction.UNION), scout), "Union patrols leave scouts alone")
	assert(not u.valid_target(u.hq, scout) and not u.valid_target(scout, u.hq), "stations and scouts ignore each other")
	assert(not u.valid_target(scout, mk.call("miner", Defs.Faction.PLAYER)), "scouts leave the miner alone")
	assert(ow.state == OpeningWave.State.CLEARED, "HQ + escorts beat the opening wave within 8 min")
	print("opening wave: spawned once, cleared")
	assert(raids_seen, "Hive raids should start within 8 minutes")
	assert(u.time > 479.0)
	var union_ships := 0
	for e: SimEntity in u.entities.values():
		if e is ShipData and e.faction == Defs.Faction.UNION:
			union_ships += 1
	assert(union_ships > 5, "Union fleet should survive and be replenished")
	print("credits after 8 min: %d, net worth %d, union ships %d, raids %d" % [u.credits, u.net_worth(), union_ships, u.director.raid_count])

	# Core destruction exposes the nest.
	u.core_destroyed(4)
	assert(u.sectors[4].planet_state == "colony")
	for n: StationData in u.alive_nests():
		if n.sector == 4:
			assert(n.can_be_damaged())
	u.director = null  # break the ref cycle so nothing leaks at exit

	_test_ai_journeys()
	_test_sfx()
	_test_hints()
	_test_run_flow()
	print("SELFTEST OK")
	quit()


## Multi-step ship AI loops on a fresh universe. Only the ship under test is stepped
## (ShipAI.update), so combat and the director can't make the result flaky.
func _test_ai_journeys() -> void:
	var u := Universe.new()
	u.setup(JOURNEY_SEED)

	# Trade planning on the starting universe must find a profitable run.
	var tr := u.spawn_ship("trader", Defs.Faction.PLAYER, u.hq.sector, u.hq.pos + Vector3(0, 0, 400))
	var plan := ShipAI.plan_trade(u, tr)
	assert(not plan.is_empty(), "plan_trade finds a run on the starting universe")
	assert(float(plan["profit"]) > 0.0, "planned trade has positive expected profit")
	var pfrom := u.get_ent(int(plan["from"])) as StationData
	var pto := u.get_ent(int(plan["to"])) as StationData
	var pware: String = plan["ware"]
	assert(pfrom != null and pfrom.sells(pware) and pto != null and pto.buys(pware))
	assert(int(plan["qty"]) > 0 and int(plan["qty"]) <= tr.cargo_cap)

	# Gate travel: a ship ordered to another sector arrives within the bound.
	var hops := u.route(TRAVEL_FROM, TRAVEL_TO).size()
	assert(hops == 2)
	var mover := u.spawn_ship("trader", Defs.Faction.PLAYER, TRAVEL_FROM, Vector3.ZERO)
	mover.order = "goto"
	mover.order_sector = TRAVEL_TO
	# Each leg is at most a sector diameter (gate to gate across the sector).
	var travel_bound := float(hops + 1) * 2.0 * Defs.SECTOR_RADIUS / mover.speed * PATH_SLACK
	var t := 0.0
	var jumps := 0
	var last_sector := mover.sector
	while mover.order == "goto" and t < travel_bound:
		ShipAI.update(u, mover, JOURNEY_DT)
		if mover.sector != last_sector:
			jumps += 1
			last_sector = mover.sector
		t += JOURNEY_DT
	assert(mover.sector == TRAVEL_TO, "ship reaches its destination sector via gates")
	assert(mover.order != "goto", "ship finishes its goto order within %.0f s" % travel_bound)
	assert(jumps == hops, "ship took the shortest gate route")
	var travel_t := t

	# Mining loop: fly to a field, fill the hold, sell ore to a refinery (none in Haven -> gate hop).
	var miner := u.spawn_ship("miner", Defs.Faction.PLAYER, u.hq.sector, u.hq.pos + Vector3(0, 0, 300))
	miner.order = "mine"
	var fill_time := float(miner.cargo_cap) / ShipAI.MINE_RATE
	var mine_bound := fill_time + 2.0 * (2.0 * Defs.SECTOR_RADIUS / miner.speed) * PATH_SLACK + MINE_SELL_MARGIN
	var credits0 := u.credits
	var was_full := false
	var sold := false
	t = 0.0
	while not sold and t < mine_bound:
		ShipAI.update(u, miner, JOURNEY_DT)
		if miner.cargo_free() <= 0:
			was_full = true
		if was_full and miner.cargo_used() == 0:
			sold = true
		t += JOURNEY_DT
	assert(was_full, "miner fills its hold")
	assert(sold, "miner sells its ore within %.0f s" % mine_bound)
	assert(u.credits > credits0, "player miner's ore sale earns credits")
	print("journeys: trade plan %s x%d profit %.0f, travel %d jumps in %.0f/%.0f s, miner sold ore in %.0f/%.0f s" % [pware, int(plan["qty"]), float(plan["profit"]), jumps, travel_t, travel_bound, t, mine_bound])
	u.director = null


## Procedural audio: every stream is generated and non-empty; nothing plays before input; mute works.
func _test_sfx() -> void:
	var t0 := Time.get_ticks_msec()
	var streams := Sfx.generate_all()
	var gen_ms := Time.get_ticks_msec() - t0
	for n: String in Sfx.NAMES:
		assert(streams.has(n), "sfx stream generated: %s" % n)
		var w := streams[n] as AudioStreamWAV
		assert(w != null and w.data.size() > 400, "sfx stream non-empty: %s" % n)
		assert(w.format == AudioStreamWAV.FORMAT_16_BITS and w.mix_rate == Sfx.MIX_RATE and not w.stereo)
		assert(Sfx.VOLUME_DB.has(n), "volume constant for %s" % n)
	var s := Sfx.new()
	s.streams = streams
	assert(not s.play("laser"), "audio is gated until the first input")
	assert(s.blocked == 1 and s.played == 0)
	s.unlock()
	assert(s.play("laser"), "audio plays after the first input")
	s.toggle_mute()
	assert(not s.play("explosion"), "muted audio does not play")
	s.toggle_mute()
	assert(s.play("hit"))
	# VS-012: N on the pause screen toggles mute only; P's own release doesn't end the pause.
	s._ready()   # registers the "mute" action
	Controls.register()
	var n := InputEventKey.new()
	n.physical_keycode = Sfx.MUTE_KEY
	n.pressed = true
	assert(n.is_action_pressed("mute") and not Controls.resumes_from_pause(n), "N while paused only mutes")
	var k := InputEventKey.new()
	k.physical_keycode = KEY_P
	k.pressed = true
	assert(Controls.resumes_from_pause(k), "a fresh key press resumes")
	k.pressed = false
	assert(not Controls.resumes_from_pause(k), "a key release does not resume")
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	assert(Controls.resumes_from_pause(tap), "a tap resumes")
	# VS-014: the mouse click Godot emulates from a touch never resumes (the touch itself decides);
	# a real desktop click still does.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	assert(Controls.resumes_from_pause(click), "a real click resumes")
	click.device = InputEvent.DEVICE_ID_EMULATION
	assert(not Controls.resumes_from_pause(click), "an emulated (touch) click does not resume")
	print("sfx: %d streams generated in %d ms" % [streams.size(), gen_ms])
	s.free()


func _test_hints() -> void:
	var h := TutorialHints.new()
	assert(h.current() == "steer", "first tip is steering")
	h.update({"throttle": true})
	assert(h.current() == "steer", "tips show in order even if a later step is done early")
	h.update({"steer": true})
	assert(h.current() == "target", "steps done out of order stay done")
	h.update({"steer": false, "target": true, "dock": true})
	assert(h.current() == "map" and h.done.has("steer"), "done steps are latched")
	var h3 := TutorialHints.new()
	h3.update({"steer": true, "throttle": true, "ready": {"target": false}})
	assert(h3.current() == "dock", "an uncompletable tip (no hostile to lock) does not block later tips")
	h3.update({"ready": {"target": true}})
	assert(h3.current() == "target", "the target tip returns once a hostile is in the sector")
	h3.update({"dock": true, "map": true, "land": true, "ready": {"target": false}})
	assert(h3.current() == "" and not h3.done.has("target"), "a waiting tip is hidden, not completed")
	h3.free()
	assert(TutorialHints.hint_text("throttle", true, "Ember").contains("THR+"), "touch wording")
	assert(TutorialHints.hint_text("throttle", false, "Ember").contains("W / S"), "keyboard wording")
	assert(TutorialHints.hint_text("land", false, "Ember").contains("Ember"))
	for st: String in TutorialHints.STEPS:
		assert(TutorialHints.hint_text(st, false, "X") != "" and TutorialHints.hint_text(st, true, "X") != "")
	h.skip()
	assert(h.skipped and h.current() == "", "skip hides tips")
	h.update({"map": true, "land": false})
	assert(h.current() == "", "skipped tips never reappear")
	var h2 := TutorialHints.new()
	h2.update({"steer": true, "throttle": true, "target": true, "dock": true, "map": true, "land": true})
	assert(h2.current() == "", "all steps done hides tips")
	print("hints: step order, latch and skip OK")
	h.free()
	h2.free()


func _test_run_flow() -> void:
	# The Universe only simulates during a run: never behind the title or the end screen.
	assert(not RunFlow.sim_runs(VoidMain.State.TITLE), "world frozen on the title screen")
	assert(RunFlow.sim_runs(VoidMain.State.PLAYING), "world runs while playing")
	assert(not RunFlow.sim_runs(VoidMain.State.OVER), "world frozen on the end screen")
	print("run flow: sim gating OK")


## VS-016: buying N then selling N of a ware at the same station never increases the player's
## credits — for every station kind and ware it both buys and sells, N in {1, 10, 40}, at a spread
## of stock levels (start, near-empty, half, near-full).
func _check_no_round_trip_profit(u: Universe) -> void:
	var ps := u.player_ship
	var saved_cargo := ps.cargo.duplicate()
	var saved_credits := u.credits
	var pairs := 0
	for kind: String in Defs.STATION:
		var st := StationData.new()
		st.setup(kind, Defs.Faction.UNION)
		for w: String in Defs.WARES:
			if not (st.buys(w) and st.sells(w)):
				continue
			for n: int in [1, 10, 40]:
				for level: int in [int(st.stock[w]), n, st.capacity / 2, st.capacity - 1]:
					st.stock[w] = level
					ps.cargo.clear()
					u.credits = 1.0e6
					var c0 := u.credits
					var got := u.transact(ps, st, w, n, true)
					assert(got == n, "round trip buys %d %s at %s" % [n, w, kind])
					u.transact(ps, st, w, got, false)
					assert(u.credits < c0, "VS-016: buy %d / sell %d %s at %s (stock %d) must not profit (%+.2f)" % [n, n, w, kind, level, u.credits - c0])
					assert(int(st.stock[w]) == level)
					pairs += 1
	assert(pairs >= 4 * 3 * 4, "Trade Hub covers every ware")
	ps.cargo = saved_cargo
	u.credits = saved_credits
