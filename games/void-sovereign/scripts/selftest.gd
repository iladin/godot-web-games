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
	# VS-010: NPC sellers skip player stations that cannot pay (credits <= TRADER_RESERVE).
	var other := u.spawn_station("solar", Defs.Faction.UNION, 0, Vector3(900, 0, 0))
	pst.stock["energy"] = 0
	other.stock["energy"] = 0
	npc.cargo = {"energy": 10}
	u.credits = Defs.TRADER_RESERVE
	assert(not ShipAI.can_deliver_to(u, npc, pst, "energy"), "broke player station cannot take NPC delivery")
	var nb := ShipAI.best_buyer(u, npc, "energy")
	assert(nb != null and nb.id != pst.id, "NPC seller picks a different buyer when player cannot pay")
	u.credits = Defs.START_CREDITS
	assert(ShipAI.can_deliver_to(u, npc, pst, "energy"))
	npc.cargo.clear()
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
	var min_hull := 1e9   # VS-030: idle player's lowest hull while the wave is alive
	var hold_checked := false
	var revert_checked := false
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
		if ow.state == OpeningWave.State.ACTIVE:
			min_hull = minf(min_hull, u.player_ship.hull)
			var sc: ShipData = u.get_ent(ow.ids[0]) as ShipData
			if sc != null and sc.sortie and not ow.engaged and ow.active_t < Defs.SORTIE_ESCORT_DELAY - 0.2:
				hold_checked = true
				assert(not ow.escorts_ok(), "escorts hold fire during SORTIE_ESCORT_DELAY")
				var esc := ShipData.new()
				esc.setup("fighter", Defs.Faction.PLAYER)
				esc.sector = sc.sector
				assert(not u.valid_target(esc, sc) and not u.valid_target(sc, esc), "escorts and scouts ignore each other during the delay")
			if ow.active_t >= Defs.OPENING_WAVE_LINGER + 0.1 and not revert_checked:  # opportunistic; forced test below is authoritative
				for id: int in ow.ids:
					var s2 := u.get_ent(id) as ShipData
					if s2 != null and s2.alive:
						revert_checked = true
						assert(not s2.sortie and s2.hull_max <= float(Defs.SHIP["drone"]["hull"]) + 0.01, "scouts revert to 1x hull on unmark")
		# VS-029 The Breach: nothing before BREACH_TIME, then exactly one scripted raid in the HQ sector.
		if u.time < Defs.BREACH_TIME - 0.5:
			assert(u.director.breach_count == 0, "the breach waits for BREACH_TIME")
		assert(u.director.breach_count <= 1, "the breach spawns only once")
	assert(u.director.breach_count == 1 and Defs.BREACH_TIME >= 330.0 and Defs.BREACH_TIME <= 450.0, "the breach raid spawned once in 5:30-7:30")
	assert(Defs.BREACH_SIZE >= 4 and Defs.BREACH_SIZE <= 6, "breach has 4-6 raiders")
	assert(ow.spawn_count == 1 and wave_hostile_seen, "the opening wave spawned once")
	assert(hold_checked, "escort hold window observed")
	assert(min_hull < 600.0 and min_hull >= 150.0, "idle player is hurt but survives the sortie (min hull %.0f)" % min_hull)
	print("sortie idle min hull: %.0f" % min_hull)
	# G on a scout releases the escorts early; the unmark math reverts hull proportionally.
	var ow2 := OpeningWave.new(u)
	ow2.state = OpeningWave.State.ACTIVE
	assert(not ow2.escorts_ok(), "fresh wave holds escorts")
	ow2.engaged = true
	assert(ow2.escorts_ok(), "engaged wave frees escorts")
	# VS-030: force the unmark on living scouts, uneased and eased, and verify the 1x revert.
	for use_ease in [false, true]:
		var ow3 := OpeningWave.new(u)
		ow3._spawn()
		var live: Array[ShipData] = []
		for id3: int in ow3.ids:
			var sc3 := u.get_ent(id3) as ShipData
			if sc3 != null and sc3.alive:
				live.append(sc3)
		assert(live.size() > 0, "forced wave has living scouts")
		var base_hull := float(Defs.SHIP["drone"]["hull"])
		assert(live[0].sortie and live[0].hull_max > base_hull + 0.01, "scouts are scaled while marked")
		var dps_base: float = live[0].dps / Defs.OPENING_WAVE_DPS
		if use_ease:
			ow3.eased = true
			for s3: ShipData in live:
				s3.dps *= Defs.SORTIE_EASE
		ow3._unmark()
		for s3: ShipData in live:
			assert(not s3.sortie and absf(s3.hull_max - base_hull) < 0.01, "unmark reverts scouts to 1x hull (eased=%s)" % str(use_ease))
			assert(absf(s3.dps - dps_base) < 0.01, "unmark reverts scout dps to 1x (eased=%s)" % str(use_ease))
		print("sortie revert checked (eased=%s)" % str(use_ease))
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
	# VS-038: hot opening: scouts arrive early, radio line has a bearing and per-input wording.
	assert(Defs.OPENING_WAVE_TIME <= 10.0, "opening wave arrives within 10 s")
	ow.touch = false
	var rl := ow.radio_line(Vector3(0, 0, -1000.0) + u.hq.pos)
	assert(rl.contains("press R") and rl.contains("bearing"), "radio line (keyboard)")
	ow.touch = true
	assert(ow.radio_line(u.hq.pos + Vector3(0, 0, -1000.0)).contains("tap TGT"), "radio line (touch)")
	print("opening wave: spawned once, cleared")
	assert(raids_seen, "Hive raids should start within 8 minutes")
	assert(u.time > 479.0)
	var union_ships := 0
	for e: SimEntity in u.entities.values():
		if e is ShipData and e.faction == Defs.Faction.UNION:
			union_ships += 1
	assert(union_ships > 5, "Union fleet should survive and be replenished")
	print("credits after 8 min: %d, net worth %d, union ships %d, raids %d" % [u.credits, u.net_worth(), union_ships, u.director.raid_count])

	# VS-020: player Defense Platforms deter raids on their sector; undefended / Union targets don't.
	var dir := u.director
	var t_save := u.time
	assert(dir.raid_go_chance(u.hq) == 1.0, "an undefended HQ is always raided")
	u.spawn_station("defense", Defs.Faction.PLAYER, u.hq.sector, u.hq.pos + Vector3(-900, 0, 700))
	u.spawn_station("defense", Defs.Faction.PLAYER, u.hq.sector, u.hq.pos + Vector3(900, 0, 900))
	u.time = Defs.RAID_DETER_FROM - 1.0
	assert(dir.raid_go_chance(u.hq) == 1.0, "no deterrence before RAID_DETER_FROM")
	u.time = Defs.RAID_DETER_FROM
	assert(absf(dir.raid_go_chance(u.hq) - pow(Defs.RAID_DETER_PER_PLATFORM, 2)) < 0.001, "two platforms deter raids on the HQ")
	for e: SimEntity in u.entities.values():
		if e.alive and e is StationData and e.faction == Defs.Faction.UNION:
			assert(dir.raid_go_chance(e as StationData) == 1.0, "Union targets are never deterred")
			break
	# VS-023: a platform far from the target does not deter; one nearby does.
	for e: SimEntity in u.ents_in(u.hq.sector):
		if e.alive and e is StationData and (e as StationData).kind == "defense" and e.faction == Defs.Faction.PLAYER:
			e.alive = false
	u.time = Defs.RAID_DETER_FROM
	var far_pl := u.spawn_station("defense", Defs.Faction.PLAYER, u.hq.sector, u.hq.pos + Vector3(Defs.RAID_DETER_RANGE + 500.0, 0, 0))
	assert(dir.raid_go_chance(u.hq) == 1.0, "a far platform does not deter raids on the HQ")
	var near_pl := u.spawn_station("defense", Defs.Faction.PLAYER, u.hq.sector, u.hq.pos + Vector3(900, 0, 900))
	assert(absf(dir.raid_go_chance(u.hq) - Defs.RAID_DETER_PER_PLATFORM) < 0.001, "a near platform deters raids at 0.25")
	far_pl.alive = false
	near_pl.alive = false
	# VS-023: building inside a planet is rejected without charging.
	var cr0 := u.credits
	u.credits = 1.0e6
	var inside := u.build_station("solar", u.hq.sector, u.sectors[u.hq.sector].planet_pos + Vector3(100, 0, 0))
	assert(inside == null and u.credits == 1.0e6, "build_station rejects positions inside a planet without charging")
	u.credits = cr0
	u.time = t_save

	# VS-025: raids are tracked to their end; one outcome message each, throttled "turned back".
	var msgs: Array[String] = []
	var on_msg := func(t: String, _c: Color) -> void: msgs.append(t)
	u.message.connect(on_msg)
	var nest0: StationData = u.alive_nests()[0]
	var raiders: Array[ShipData] = []
	for i in 3:
		var rs := u.spawn_ship("drone", Defs.Faction.HIVE, nest0.sector, nest0.pos + Vector3(300, 0, 0))
		rs.order = "raid"
		rs.order_target = u.hq.id
		rs.order_sector = u.hq.sector
		raiders.append(rs)
	dir.tracker.raids.clear()   # the scripted Breach / earlier raids may still be in flight
	var intercept0 := float(u.ledger.totals.get("intercept", 0.0))   # earlier simulated raids may already have paid
	dir.tracker.history.clear()
	dir.tracker.add(raiders, u.hq)
	dir.tracker.step(Defs.RAID_TRACK_INTERVAL)
	assert(msgs.is_empty(), "no raid warning while the raid is still far from its target")
	var act := dir.tracker.active()
	assert(act.size() == 1 and int(act[0]["ships"]) == 3 and float(act[0]["eta"]) > 0.0, "active raid exposes ships and an ETA")
	for rs: ShipData in raiders:
		rs.sector = u.hq.sector
	dir.tracker.step(Defs.RAID_TRACK_INTERVAL)
	dir.tracker.step(Defs.RAID_TRACK_INTERVAL)
	assert(msgs.size() == 1 and msgs[0].begins_with("RAID ARRIVING"), "one arrival warning, once: %s" % [msgs])
	raiders[0].alive = false
	raiders[1].alive = false
	raiders[2].order = "patrol"
	dir.tracker.step(Defs.RAID_TRACK_INTERVAL)
	assert(msgs.size() == 2 and "2/3 destroyed" in msgs[1], "interception reports kills: %s" % [msgs])
	assert(dir.tracker.active().is_empty(), "finished raid leaves the tracker")
	# VS-039: exactly one outcome per raid, in the message log and in the last-5-min history.
	assert(dir.tracker.history.size() == 1 and dir.tracker.history[0]["kind"] == "intercepted", "interception written to history once")
	assert(dir.tracker.recent().size() == 1 and "2/3 destroyed" in String(dir.tracker.recent()[0]["text"]), "recent() lists the outcome")
	# A raid that is called off with no losses reports "withdrew"; a raid wiped out en route never warns.
	var w := u.spawn_ship("drone", Defs.Faction.HIVE, nest0.sector, nest0.pos + Vector3(300, 0, 0))
	w.order = "raid"
	var wl: Array[ShipData] = [w]
	dir.tracker.add(wl, u.hq)
	w.order = "patrol"
	dir.tracker.step(Defs.RAID_TRACK_INTERVAL)
	assert(msgs.size() == 3 and "withdrew" in msgs[2], "withdrawn raid reported: %s" % [msgs])
	assert(dir.tracker.history.size() == 2 and dir.tracker.history[1]["kind"] == "withdrew", "withdrawal written to history once")
	# A raid whose target station is destroyed reports "succeeded (destroyed X)", once.
	var victim := u.spawn_station("solar", Defs.Faction.PLAYER, u.hq.sector, u.hq.pos + Vector3(900, 0, 0))
	var sv := u.spawn_ship("drone", Defs.Faction.HIVE, nest0.sector, nest0.pos + Vector3(300, 0, 0))
	sv.order = "raid"
	var svl: Array[ShipData] = [sv]
	dir.tracker.add(svl, victim)
	var lab := dir.tracker.label_for(dir.tracker.active()[0])
	assert(victim.sector == u.hq.sector and "RAID x1" in lab and u.sectors[victim.sector].name in lab, "inset label names the target sector: %s" % lab)
	victim.alive = false
	sv.order = "patrol"
	dir.tracker.step(Defs.RAID_TRACK_INTERVAL)
	dir.tracker.step(Defs.RAID_TRACK_INTERVAL)
	assert(msgs.size() == 4 and "SUCCEEDED" in msgs[3] and victim.display_name in msgs[3], "successful raid reported: %s" % [msgs])
	assert(dir.tracker.history.size() == 3 and dir.tracker.history[2]["kind"] == "succeeded", "success written to history once")
	# VS-036: the HQ-sector interception above paid no bounty; one outside the HQ sector pays per kill via add_credits("intercept").
	assert(float(u.ledger.totals.get("intercept", 0.0)) == intercept0, "intercept in the HQ sector pays no bounty")
	var far_sector := nest0.sector
	assert(far_sector != u.hq.sector)
	var bs: Array[ShipData] = []
	for i in 3:
		var b := u.spawn_ship("drone", Defs.Faction.HIVE, far_sector, nest0.pos + Vector3(300, 0, 0))
		b.order = "raid"
		bs.append(b)
	dir.tracker.add(bs, u.hq)
	bs[0].alive = false
	bs[1].alive = false
	bs[2].order = "patrol"
	var cr_b := u.credits
	dir.tracker.step(Defs.RAID_TRACK_INTERVAL)
	assert(absf(u.credits - cr_b - 2.0 * Defs.RAID_INTERCEPT_BOUNTY) < 0.001 and absf(float(u.ledger.totals.get("intercept", 0.0)) - intercept0 - 2.0 * Defs.RAID_INTERCEPT_BOUNTY) < 0.001, "intercept outside the HQ sector pays the bounty into the ledger")
	assert(dir.tracker.history[-1]["kind"] == "intercepted" and Defs.RAID_INTERCEPT_BOUNTY < float(Defs.BOUNTY["drone"]), "bounty is modest and the outcome is still intercepted")
	assert(u.ledger.breakdown(u.time).any(func(row: Array) -> bool: return row[0] == "intercept"), "intercept shows in the ledger breakdown")
	# VS-036: a deterred raid is sent at the nearest Union station (same tracker marker) and reports "redirected to <station>" once.
	var near_union := dir.nearest_union_station(u.hq.sector)
	assert(near_union != null and near_union.faction == Defs.Faction.UNION, "a Union station exists to redirect to")
	var hops_best := 0 if near_union.sector == u.hq.sector else u.route(u.hq.sector, near_union.sector, false).size()
	for e: SimEntity in u.entities.values():
		if e.alive and e is StationData and e.faction == Defs.Faction.UNION:
			var h := 0 if e.sector == u.hq.sector else u.route(u.hq.sector, e.sector, false).size()
			assert(h >= hops_best, "redirect picks the nearest Union station")
	u.time = Defs.RAID_DETER_FROM
	var pl1 := u.spawn_station("defense", Defs.Faction.PLAYER, u.hq.sector, u.hq.pos + Vector3(900, 0, 900))
	var pl2 := u.spawn_station("defense", Defs.Faction.PLAYER, u.hq.sector, u.hq.pos + Vector3(-900, 0, 700))
	for e: SimEntity in u.entities.values():
		if e.alive and e is StationData and e.faction == Defs.Faction.PLAYER and e != u.hq and (e as StationData).kind != "defense":
			e.alive = false   # only the HQ is a player target, so _pick_raid_target is the HQ 65% of the time
	dir.tracker.raids.clear()
	dir.tracker.history.clear()
	# Flag off (shipped default): a deterred raid just turns back, nothing is launched.
	assert(not dir.redirect_enabled, "redirect ships disabled")
	for i in 60:
		dir.raid_t = 0.0
		dir._raids(0.01)
	assert(dir.tracker.raids.all(func(x: Dictionary) -> bool: return String(x["redirected_from"]) == ""), "with the flag off no raid is redirected")
	dir.tracker.raids.clear()
	dir.redirect_enabled = true
	var redirected := false
	for i in 400:
		dir.raid_t = 0.0
		dir._raids(0.01)
		if not dir.tracker.raids.is_empty() and String(dir.tracker.raids[-1]["redirected_from"]) != "":
			redirected = true
			break
		dir.tracker.raids.clear()
	assert(redirected, "a deterred raid is redirected instead of vanishing")
	var rr: Dictionary = dir.tracker.raids[-1]
	var rt := u.get_ent(int(rr["target_id"]))
	assert(rt.faction == Defs.Faction.UNION, "the redirected raid targets a Union station")
	var rlive := dir.tracker.active()
	assert(rlive.size() == 1 and float(rlive[0]["eta"]) >= 0.0 and "RAID x" in dir.tracker.label_for(rlive[0]), "redirected raid keeps the normal marker and ETA")
	for id: int in rr["ids"]:
		(u.get_ent(id) as ShipData).order = "patrol"   # called off with no losses
	var icp := float(u.ledger.totals.get("intercept", 0.0))
	dir.tracker.step(Defs.RAID_TRACK_INTERVAL)
	assert(float(u.ledger.totals.get("intercept", 0.0)) == icp, "redirected raids pay no intercept bounty")
	assert(dir.tracker.history.size() == 1 and dir.tracker.history[0]["kind"] == "redirected" and ("redirected to " + str(rr["target_name"])) in String(dir.tracker.history[0]["text"]), "exactly one 'redirected to <station>' outcome: %s" % [dir.tracker.history])
	# No Union station left: falls back to turning back, nothing launched.
	var saved_union: Array[StationData] = []
	for e: SimEntity in u.entities.values():
		if e.alive and e is StationData and e.faction == Defs.Faction.UNION:
			e.alive = false
			saved_union.append(e as StationData)
	assert(dir.nearest_union_station(u.hq.sector) == null, "no Union station, no redirect target")
	dir.tracker.raids.clear()
	var rc1 := dir.raid_count
	var seen_redirect := false
	for i in 60:
		dir.raid_t = 0.0
		dir._raids(0.01)
		for x: Dictionary in dir.tracker.raids:
			if String(x["redirected_from"]) != "":
				seen_redirect = true
	assert(not seen_redirect, "no Union station: deterred raids turn back instead of redirecting")
	for e: StationData in saved_union:
		e.alive = true
	dir.redirect_enabled = Defs.RAID_REDIRECT_ENABLED
	pl1.alive = false
	pl2.alive = false
	dir.tracker.history.clear()   # these entries were stamped at RAID_DETER_FROM, ahead of the restored clock
	u.time = t_save
	var tt := u.time
	u.time += Defs.RAID_HISTORY_WINDOW + 1.0
	assert(dir.tracker.recent().is_empty(), "outcomes older than 5 min leave the list")
	u.time = tt
	msgs.clear()
	var dtarget := u.hq
	dir.turned_back_at = -1.0e9
	dir.turned_back_pending = 0
	t_save = u.time
	u.time = 5000.0
	dir._report_turned_back(dtarget)
	u.time = 5000.0 + Defs.RAID_TURNED_BACK_THROTTLE * 0.5
	dir._report_turned_back(dtarget)
	dir._report_turned_back(dtarget)
	assert(msgs.size() == 1, "turned-back messages are throttled")
	u.time = 5000.0 + Defs.RAID_TURNED_BACK_THROTTLE + 1.0
	dir._report_turned_back(dtarget)
	assert(msgs.size() == 2 and "+2 earlier" in msgs[1], "throttled turn-backs are merged into the next message: %s" % [msgs])
	u.message.disconnect(on_msg)
	u.time = t_save

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
	_test_touch_ux()
	_test_ledger()
	_test_text_fit()
	_test_save_game()
	_test_run_save_file()
	_test_marker_layout()
	_test_run_flow()
	await _test_surface_over()
	await _test_surface_landmarks()
	await _test_surface_flank()
	await _test_save_flow()
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

	# VS-007: wing commands reach only armed player ships in the sector; status line reflects them.
	var wsec := u.player_ship.sector
	var w1 := u.spawn_ship("fighter", Defs.Faction.PLAYER, wsec, Vector3(300, 0, 0))
	var wn := Wing.members(u, wsec).size()
	assert(wn >= 1 and Wing.members(u, wsec).has(w1), "wing members include armed player ships")
	assert(not Wing.members(u, wsec).has(u.player_ship), "the player is not in the wing")
	assert(Wing.command(u, wsec, Wing.ATTACK, 0) == 0, "attack without a target orders nobody")
	assert(Wing.command(u, wsec, Wing.HOLD) == wn and w1.order == "hold", "hold reaches the whole wing")
	assert(Wing.status(u, wsec) == "WING %d · HOLD" % wn, "status shows count and order")
	var hpos := w1.pos
	for i in 60:
		ShipAI.update(u, w1, 0.1)
	assert(w1.pos.distance_to(hpos) < 400.0, "a holding ship does not wander off")
	assert(Wing.command(u, wsec, Wing.ESCORT) == wn and w1.order == "escort", "escort recalls the wing")
	w1.order = "patrol"
	assert(Wing.status(u, wsec) == "WING %d · MIXED" % wn or wn == 1, "mixed orders read MIXED")
	print("wing commands OK")

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
	assert(TutorialHints.hint_text("dock", false, "X").contains("Trade Hub") and TutorialHints.hint_text("dock", true, "X").contains("Trade Hub"), "VS-024: tip 4 sends the player to a station that trades wares, not the HQ")
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


## VS-024: every change to the player's credits goes through Universe.add_credits() with a
## category; the categorised totals must add up to the credit delta.
## VS-026: capture -> JSON -> restore on a mid-run Universe matches, keeps running, and bad saves return null.
func _test_save_game() -> void:
	var u := Universe.new()
	u.setup(JOURNEY_SEED)
	for i in 3000:
		u.step(JOURNEY_DT)
	assert(u.time > 299.0)
	var nw := u.net_worth()
	# VS-039: an in-flight raid marker and the outcome history survive the round trip.
	var rn: ShipData
	for e: SimEntity in u.entities.values():
		if e is ShipData and e.faction == Defs.Faction.HIVE and e.alive:
			rn = e as ShipData
			break
	assert(rn != null)
	var rl: Array[ShipData] = [rn]
	rn.order = "raid"
	u.director.tracker.raids.clear()
	u.director.tracker.add(rl, u.hq)
	u.director.tracker.history.append({"t": u.time - 10.0, "kind": "withdrew", "text": "Raid withdrew from X"})
	var rng_state := u.rng.state
	var ids_before := u.entities.keys().size()
	var d := SaveGame.capture(u)
	assert(u.rng.state == rng_state and u.net_worth() == nw and u.entities.size() == ids_before, "capture is read-only")
	var text := JSON.stringify(d)
	var parsed: Variant = JSON.parse_string(text)
	assert(parsed is Dictionary, "save is JSON-safe")
	var r := SaveGame.restore(parsed as Dictionary)
	assert(r != null, "restore of a fresh save succeeds")
	assert(absf(r.net_worth() - nw) < 0.001, "net worth (JSON keeps ~15 digits) round-trips: %f vs %f" % [r.net_worth(), nw])
	assert(absf(r.credits - u.credits) < 0.001 and absf(r.time - u.time) < 0.001 and r.kills == u.kills)
	assert(r.entities.size() == u.entities.size() and r.next_id == u.next_id)
	assert(r.player_ship != null and r.player_ship.id == u.player_ship.id and r.hq.id == u.hq.id)
	assert(r.rng.state == u.rng.state and absf(r.ledger.total() - u.ledger.total()) < 0.001)
	assert(r.ledger.breakdown(r.time).size() == u.ledger.breakdown(u.time).size())
	assert(absf(r.director.raid_t - u.director.raid_t) < 0.001 and r.director.raid_count == u.director.raid_count)
	assert(r.director.tracker.raids.size() == u.director.tracker.raids.size())
	assert(r.director.tracker.raids.size() == 1 and int(r.director.tracker.raids[0]["target_id"]) == u.hq.id and int(r.director.tracker.raids[0]["ids"][0]) == rn.id, "raid marker round-trips")
	assert(r.director.tracker.history.size() == u.director.tracker.history.size() and r.director.tracker.recent().size() == u.director.tracker.recent().size() and r.director.tracker.recent().size() >= 1, "raid history round-trips")
	assert(r.director.tracker.label_for(r.director.tracker.active()[0]) == u.director.tracker.label_for(u.director.tracker.active()[0]), "restored raid shows the same inset label")
	assert(r.colonies() == u.colonies() and r.alive_nests().size() == u.alive_nests().size())
	for e: SimEntity in u.entities.values():
		var o := r.get_ent(e.id)
		assert(o != null and o.pos.is_equal_approx(e.pos) and is_equal_approx(o.hull, e.hull) and o.faction == e.faction and o.sector == e.sector)
		if e is ShipData:
			assert((o as ShipData).order == (e as ShipData).order and (o as ShipData).cargo == (e as ShipData).cargo)
			assert((o as ShipData).plan.size() == (e as ShipData).plan.size())
		else:
			assert((o as StationData).stock == (e as StationData).stock)
	# Capturing again from the restored run keeps every section.
	var d2 := SaveGame.capture(r)
	assert(d2.keys() == d.keys() and (d2["entities"] as Array).size() == (d["entities"] as Array).size(), "re-capture of a restored run has the same shape")
	for i in 600:
		r.step(JOURNEY_DT)
	assert(r.time > u.time + 59.0 and r.entities.size() > 0 and not is_nan(r.net_worth()))
	# Bad saves
	var bad := d.duplicate(true)
	bad["version"] = SaveGame.VERSION + 1
	assert(SaveGame.restore(bad) == null, "wrong version rejected")
	bad = d.duplicate(true)
	bad.erase("version")
	assert(SaveGame.restore(bad) == null, "missing version rejected")
	bad = d.duplicate(true)
	bad.erase("entities")
	assert(SaveGame.restore(bad) == null, "missing entities rejected")
	bad = d.duplicate(true)
	bad["sectors"] = []
	assert(SaveGame.restore(bad) == null, "wrong sector count rejected")
	bad = d.duplicate(true)
	(bad["entities"] as Array)[0].erase("pos")
	assert(SaveGame.restore(bad) == null, "entity without pos rejected")
	bad = d.duplicate(true)
	(bad["entities"] as Array)[0]["type"] = "no_such_class"
	assert(SaveGame.restore(bad) == null, "unknown entity type rejected")
	bad = d.duplicate(true)
	bad["hq_id"] = 999999
	assert(SaveGame.restore(bad) == null, "dangling hq id rejected")
	assert(SaveGame.restore({}) == null, "empty dict rejected")
	assert(SaveGame.restore({"version": SaveGame.VERSION}) == null, "version-only dict rejected")
	for x: Universe in [u, r]:
		x.director = null


## VS-027: RunSave file I/O round trip; missing, garbage and wrong-version files give no save.
func _test_run_save_file() -> void:
	var path := "user://selftest_run.save"
	RunSave.delete(path)
	assert(RunSave.peek_time(path) < 0.0 and RunSave.load_universe(path) == null, "no file -> no save")
	var u := Universe.new()
	u.setup(JOURNEY_SEED)
	for i in 600:
		u.step(JOURNEY_DT)
	assert(RunSave.write(u, path), "write succeeds")
	assert(absf(RunSave.peek_time(path) - u.time) < 0.001, "peek_time = saved run time")
	var r := RunSave.load_universe(path)
	assert(r != null and r.entities.size() == u.entities.size() and r.player_ship != null, "load_universe round trip")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	assert(RunSave.peek_time(path) < 0.0, "garbage file ignored")
	var d := SaveGame.capture(u)
	d["version"] = SaveGame.VERSION + 1
	f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	assert(RunSave.peek_time(path) < 0.0, "wrong-version file ignored")
	# VS-033: atomic write keeps .bak; truncated main falls back to .bak; a corrupt tmp never replaces a good save.
	RunSave.delete(path)
	assert(RunSave.write(u, path) and RunSave.write(u, path), "two writes succeed")
	assert(FileAccess.file_exists(path + RunSave.BAK_EXT) and not FileAccess.file_exists(path + RunSave.TMP_EXT), "second write keeps .bak, no tmp left")
	var good := FileAccess.get_file_as_string(path)
	f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(good.substr(0, good.length() / 2))   # truncated main
	f.close()
	assert(absf(RunSave.peek_time(path) - u.time) < 0.001, "truncated main -> .bak still gives Continue")
	assert(RunSave.write(u, path), "write after truncation succeeds")
	assert(FileAccess.get_file_as_string(path) == good, "main replaced by a fresh good file")
	f = FileAccess.open(path + RunSave.TMP_EXT, FileAccess.WRITE)
	f.store_string("{corrupt")
	f.close()
	assert(RunSave.peek_time(path) >= 0.0 and FileAccess.get_file_as_string(path) == good, "stale corrupt tmp ignored, good save intact")
	assert(RunSave.write(u, path) and RunSave.peek_time(path) >= 0.0, "write over stale tmp works")
	assert(not RunSave.write(u, "user://no_such_dir/x.save"), "unwritable path reports failure")
	RunSave.delete(path)
	assert(not FileAccess.file_exists(path), "delete removes the file")
	for x: Universe in [u, r]:
		x.director = null


## VS-035: title help text never leaves the viewport; HUD cr/min hidden for the first 15 s.
func _test_text_fit() -> void:
	for w: float in [1280.0, 900.0, 640.0, 480.0]:
		for touch: bool in [false, true]:
			var worst := 0.0
			for l: String in Overlay.title_body(w, touch):
				worst = maxf(worst, ThemeDB.fallback_font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, Overlay.TITLE_BODY_FS).x)
			assert(worst <= w * Overlay.TITLE_MARGIN + 0.5, "title help text fits %d px wide (widest %.0f)" % [int(w), worst])
	assert(Overlay.title_body(1280.0).size() >= 8 and Overlay.title_body(900.0).size() > Overlay.title_body(1280.0).size() - 1, "title keeps all help lines")
	var u := Universe.new()
	u.setup(JOURNEY_SEED)
	u.time = 5.0
	assert(Hud.rate_text(u) == "", "cr/min hidden before %d s" % int(CreditLedger.MIN_RATE_SPAN))
	u.time = CreditLedger.MIN_RATE_SPAN + 1.0
	assert(Hud.rate_text(u).ends_with("cr/min"), "cr/min shown after the first window")
	print("text fit: title wraps at 1280/900/640/480, cr/min gated OK")


func _test_ledger() -> void:
	var u := Universe.new()
	u.setup(JOURNEY_SEED)
	var c0 := u.credits
	var ps := u.player_ship
	var hub: StationData = null
	for e: SimEntity in u.ents_in(u.hq.sector):
		if e is StationData and (e as StationData).kind == "trade":
			hub = e
	assert(hub != null, "the HQ sector has a Union Trade Hub (tip 4 sends the player there)")
	assert(u.transact(ps, hub, "ore", 10, true) == 10)
	assert(u.transact(ps, hub, "ore", 10, false) == 10)
	var miner := u.buy_ship("miner", u.hq)
	miner.cargo["ore"] = 20
	assert(u.transact(miner, hub, "ore", 20, false) > 0)
	var hauler := u.buy_ship("trader", u.hq)
	assert(u.transact(hauler, hub, "energy", 5, true) == 5)
	u.add_credits(200000.0, "trade")   # fund the build below (stands in for a run of profitable trades)
	var pst := u.build_station("solar", u.hq.sector, u.hq.pos + Vector3(1500, 0, 0))
	pst.stock["energy"] = 40
	var npc := u.spawn_ship("trader", Defs.Faction.UNION, u.hq.sector, Vector3.ZERO)
	assert(u.transact(npc, pst, "energy", 10, true) > 0)
	var drone := u.spawn_ship("drone", Defs.Faction.HIVE, u.hq.sector, Vector3(0, 0, 3000))
	u._on_killed(drone, ps.id)
	u.add_credits(-42.0, "repair")
	u.respawn_player()
	u.core_destroyed(4)
	for i in 50:
		u.time += 0.5
		u.add_credits(float(u.colonies()) * Defs.COLONY_INCOME / 60.0 * 0.5, "colonies")
	for c: String in ["trade", "mining", "freight", "stations", "ships", "build", "bounty", "repair", "losses", "colonies"]:
		assert(u.ledger.totals.has(c), "ledger category '%s' recorded" % c)
	assert(absf(u.ledger.total() - (u.credits - c0)) < 0.01, "ledger categories sum to the credit delta (%.3f vs %.3f)" % [u.ledger.total(), u.credits - c0])
	assert(float(u.ledger.totals["ships"]) < 0.0 and float(u.ledger.totals["bounty"]) == Defs.BOUNTY["drone"])
	var rate := u.ledger.income_per_min(u.time)
	assert(rate > 0.0, "cr/min counts recent income")
	# VS-040: gross >= net; panel shows net (gross) once income starts and sources before.
	assert(u.ledger.income_per_min(u.time) >= u.ledger.net_per_min(u.time) - 0.001, "gross >= net")
	assert(Hud.ledger_text(u).contains("net ") and Hud.ledger_text(u).contains("gross "), "panel labels net and gross")
	var fresh := Universe.new()
	fresh.setup(JOURNEY_SEED)
	assert(fresh.income_sources().size() == 3 and Hud.ledger_text(fresh).contains("No income yet") and Hud.ledger_text(fresh).contains("0 owned"), "empty state lists 3 sources")
	assert(not u.ledger.breakdown(u.time).is_empty())
	# Rolling windows: after 6 quiet minutes the breakdown is empty and only new income counts.
	u.time += 360.0
	u.add_credits(600.0, "bounty")
	var bd := u.ledger.breakdown(u.time)
	assert(bd.size() == 1 and String(bd[0][0]) == "bounty", "breakdown forgets entries older than 5 min")
	var r2 := u.ledger.income_per_min(u.time)
	assert(r2 >= 600.0 - 0.01 and r2 <= 600.0 * 60.0 / (CreditLedger.RATE_WINDOW - CreditLedger.BUCKET) + 0.01, "cr/min = income over the last RATE_WINDOW (%.1f)" % r2)
	assert(absf(u.ledger.total() - (u.credits - c0)) < 0.01)
	u.director = null
	print("ledger: %d categories sum to credit delta %+.0f OK" % [u.ledger.totals.size(), u.credits - c0])


func _test_run_flow() -> void:
	# The Universe only simulates during a run: never behind the title or the end screen.
	assert(not RunFlow.sim_runs(VoidMain.State.TITLE), "world frozen on the title screen")
	assert(RunFlow.sim_runs(VoidMain.State.PLAYING), "world runs while playing")
	assert(not RunFlow.sim_runs(VoidMain.State.OVER), "world frozen on the end screen")
	assert(RunFlow.surface_live(VoidMain.State.PLAYING) and not RunFlow.surface_live(VoidMain.State.OVER), "surface only live mid-run")
	print("run flow: sim gating OK")


## VS-028: finish() clears the save; New Game over a save asks first; Continue from a non-home sector restores it.
func _test_save_flow() -> void:
	var path := "user://selftest_flow.save"
	var g: VoidMain = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	await process_frame
	g.flow.save_path = path   # never touch a real save
	RunSave.delete(path)
	# finish() deletes the save.
	g._start_game()
	await process_frame
	assert(g.flow.autosave() and FileAccess.file_exists(path), "autosave wrote the file")
	g.flow.finish(false)
	assert(not FileAccess.file_exists(path) and RunSave.peek_time(path) < 0.0, "finish() clears the save")
	# Save a run that is away from the home sector, then return to the title.
	g._new_world()
	g._start_game()
	await process_frame
	var away := 0
	for i in g.u.sectors.size():
		if i != g.u.hq.sector:
			away = i
			break
	g.u.player_ship.sector = away
	g.space.enter_sector(away)
	g.u.add_credits(1234.0, "trade")
	var credits := g.u.credits
	for i in 30:
		await process_frame
	assert(g.flow.autosave(), "autosave away from home")
	g._new_world()
	g.state = VoidMain.State.TITLE
	assert(g.overlay.continue_time >= 0.0, "title offers Continue for a valid save")
	# New Game over a save: first press asks, a double-tap is ignored, the confirming press deletes the save.
	assert(not g.flow.request_new_game(true, 10.0) and g.flow.confirming(), "first New Game press only asks")
	assert(not g.flow.request_new_game(true, 10.1), "double-tap cannot confirm")
	assert(FileAccess.file_exists(path), "save kept while asking")
	g.flow.cancel_new_game()
	assert(not g.flow.confirming() and FileAccess.file_exists(path), "cancel keeps the save")
	assert(g.flow.request_new_game(false, 11.0), "no save -> New Game starts at once")
	# Continue restores the non-home sector.
	assert(g.flow.continue_run(), "continue works from the title")
	assert(g.state == VoidMain.State.PLAYING and g.u.player_ship.sector == away, "continue restores the player's sector")
	assert(g.space.sector_idx == away and absf(g.u.credits - credits) < 1.0, "flight view + credits restored")
	# Confirming path: ask, wait, confirm -> save deleted.
	g.state = VoidMain.State.TITLE
	assert(not g.flow.request_new_game(true, 20.0) and g.flow.request_new_game(true, 20.5), "second press confirms")
	assert(not FileAccess.file_exists(path), "confirmed New Game deletes the old save")
	# VS-033: failed autosave shows one throttled HUD message.
	var fails: Array = [0]
	g.u.message.connect(func(_t: String, _c: Color) -> void: fails[0] += 1)
	g.flow.save_path = "user://no_such_dir/x.save"
	g.state = VoidMain.State.PLAYING
	assert(not g.flow.autosave() and fails[0] == 1, "failed autosave shows a HUD message")
	assert(not g.flow.autosave() and fails[0] == 1, "second failure is throttled")
	assert(g.flow.report_save_failure(Time.get_ticks_msec() / 1000.0 + RunFlow.SAVE_FAIL_MSG_GAP + 1.0) and fails[0] == 2, "message returns after the gap")
	g.flow.save_path = path
	g.state = VoidMain.State.TITLE
	# A corrupt file leaves no Continue and continue_run fails cleanly.
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("garbage")
	f.close()
	g._new_world()
	assert(g.overlay.continue_time < 0.0 and not g.flow.continue_run(), "corrupt save: no Continue, no crash")
	RunSave.delete(path)
	g.queue_free()
	await process_frame
	print("save flow: finish clears, confirm gate, continue from sector %d OK" % away)


## VS-031: spire + per-pylon beams; beam goes with its pylon; spire changes colour when the Core is exposed.
func _test_surface_landmarks() -> void:
	var g: VoidMain = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	await process_frame
	g._start_game()
	await process_frame
	g._on_land(0)
	for i in 300:
		await process_frame
		if g.surface != null:
			break
	for i in 3:
		await process_frame
	var sv: SurfaceView = g.surface
	assert(sv != null and sv.get_node_or_null("Spire") != null, "Core spire exists")
	var shielded: Color = sv.spire_mat.albedo_color
	var beams := 0
	var pylons: Array = []
	for f in sv.foes:
		if f.kind == "pylon":
			pylons.append(f)
			if f.node.get_node_or_null("Beam") != null:
				beams += 1
	assert(pylons.size() > 0 and beams == pylons.size(), "one beam per pylon")
	var first = pylons[0]
	sv._kill(first)
	await process_frame
	assert(not is_instance_valid(first.node) or first.node.is_queued_for_deletion(), "dead pylon (and its beam) freed")
	for f in pylons.slice(1):
		sv._kill(f)
	for i in 5:
		await process_frame
	assert(sv.pylons_left() == 0 and sv.spire_mat.albedo_color.to_html(false) == SurfaceView.SPIRE_EXPOSED.to_html(false), "spire colour switches at Core exposed")
	assert(shielded.to_html(false) != sv.spire_mat.albedo_color.to_html(false), "spire colour differs from shielded")
	g.queue_free()
	await process_frame
	print("surface landmarks OK")


## VS-037: the first pylon kill spawns FLANK_MIN..MAX Hive units 60-120 degrees off the player's heading, once.
func _test_surface_flank() -> void:
	var g: VoidMain = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	await process_frame
	g._start_game()
	await process_frame
	g._on_land(0)
	for i in 300:
		await process_frame
		if g.surface != null:
			break
	for i in 3:
		await process_frame
	var sv: SurfaceView = g.surface
	assert(sv != null and not sv.flanked, "no flank before a pylon dies")
	sv.fps.global_position = Vector3(0, sv.height(0, 0) + 2.0, 0)
	sv.fps.rotation = Vector3(0, deg_to_rad(40.0), 0)
	var heading := -sv.fps.global_transform.basis.z
	heading.y = 0.0
	heading = heading.normalized()
	var kills: Array[bool] = []
	sv.kill_confirmed.connect(func(big: bool) -> void: kills.append(big))
	var pylons: Array = sv.foes.filter(func(f: SurfaceView.Foe) -> bool: return f.kind == "pylon")
	sv._kill(pylons[0])
	assert(sv.flanked and sv.flank_spawned >= Defs.FLANK_MIN and sv.flank_spawned <= Defs.FLANK_MAX, "flank squad size %d" % sv.flank_spawned)
	assert(kills.size() == 1 and kills[0], "pylon kill emits kill_confirmed(big)")
	var seen := 0
	for f: SurfaceView.Foe in sv.foes:
		if f.alive and (f.kind == "crawler" or f.kind == "drone") and f.node.position.distance_to(sv.fps.global_position) < Defs.FLANK_DIST + 5.0 and f.node.position.distance_to(sv.fps.global_position) > Defs.FLANK_DIST - 5.0:
			var off := f.node.position - sv.fps.global_position
			off.y = 0.0
			var ang := rad_to_deg(absf(heading.angle_to(off.normalized())))
			assert(ang >= Defs.FLANK_ANGLE_MIN - 1.0 and ang <= Defs.FLANK_ANGLE_MAX + 1.0, "flanker %.0f deg off heading" % ang)
			seen += 1
	assert(seen == sv.flank_spawned, "all flankers spawned at FLANK_DIST (%d of %d)" % [seen, sv.flank_spawned])
	var n1 := sv.flank_spawned
	sv._kill(pylons[1])
	assert(sv.flank_spawned == n1, "flank squad spawns once")
	var mob: SurfaceView.Foe = sv.foes.filter(func(f: SurfaceView.Foe) -> bool: return f.alive and f.kind == "crawler")[0]
	sv._kill(mob)
	assert(kills.size() == 3 and not kills[2], "mob kill emits kill_confirmed(small)")
	g.queue_free()
	await process_frame
	print("surface flank OK")


## VS-022: ending a run while on foot freezes the surface, and a later death does not evacuate.
func _test_surface_over() -> void:
	for won in [false, true]:
		var g: VoidMain = load("res://scenes/main.tscn").instantiate()
		root.add_child(g)
		await process_frame
		await process_frame
		g._start_game()
		await process_frame
		g._on_land(0)
		for i in 60:
			await process_frame
		assert(g.mode == "surface" and g.surface != null, "landed for the surface/finish test")
		var fps = g.surface.fps
		g.flow.finish(won)
		assert(g.state == VoidMain.State.OVER and not fps.input_enabled, "fps input off once the run is over")
		var p0: Vector3 = fps.global_position
		var hull0: float = g.u.player_ship.hull
		Input.action_press("move_f")
		for i in 90:
			await process_frame
		Input.action_release("move_f")
		assert(fps.global_position.distance_to(p0) < 0.01, "player frozen under the end screen")
		fps.take_damage(5000.0)
		for i in 60:
			await process_frame
		assert(g.mode == "surface" and g.surface != null and is_equal_approx(g.u.player_ship.hull, hull0), "death after game over does not evacuate")
		g.queue_free()
		await process_frame
	print("surface + finish: frozen, no evacuation OK")


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


## VS-032: touch layouts never overlap hit zones (RUN/JUMP, wing row), and touch wording says ACT/MAP.
func _test_touch_ux() -> void:
	for sz: Vector2 in [Vector2(1280, 720), Vector2(900, 720), Vector2(1280, 800)]:
		for l: String in TouchControls.LAYOUTS:
			var cs := TouchControls.layout_circles(l, sz)
			for i in cs.size():
				var ci: Dictionary = cs[i]
				var p: Vector2 = ci["c"]
				var r: float = ci["r"] * 1.15
				assert(p.x - r >= 0.0 and p.x + r <= sz.x and p.y - r >= 0.0 and p.y + r <= sz.y, "%s button %s on screen at %s" % [l, ci["name"], str(sz)])
				for j in range(i + 1, cs.size()):
					var cj: Dictionary = cs[j]
					var gap := p.distance_to(cj["c"]) - r - float(cj["r"]) * 1.15
					assert(gap >= TouchControls.BTN_GAP, "%s: %s and %s hit zones overlap at %s (gap %.1f)" % [l, ci["name"], cj["name"], str(sz), gap])
	var wing_x: float = -1.0
	for c: Dictionary in TouchControls.layout_circles("flight", Vector2(1280, 720)):
		if str(c["name"]).begins_with("wing_"):
			assert((c["c"] as Vector2).x < 128.0, "wing row sits in the left column, off the world labels")
			wing_x = (c["c"] as Vector2).x
	assert(wing_x > 0.0, "flight layout has the wing buttons")
	var u2 := Universe.new()
	u2.setup(7)
	var tch := Hud.objective_for(u2, true)
	var kb := Hud.objective_for(u2, false)
	assert(tch.contains("ACT") and not tch.contains("press F") and not tch.contains("M:"), "touch objective uses ACT wording: " + tch)
	assert(kb.contains("press F"), "keyboard objective keeps F")
	assert(Hud.earn_hint(true).contains("tap ACT") and Hud.earn_hint(false).contains("(F)"), "earn hint wording")
	var dh := DockPanel.hq_hint(true)
	assert(dh.contains("MAP") and dh.contains("ACT") and dh.contains("Earn") and not dh.contains("(M)"), "touch HQ dock text")
	assert(DockPanel.hq_hint(false).contains("(M)") and DockPanel.hq_hint(false).contains("press F"), "keyboard HQ dock text")
	print("touch ux: no overlapping buttons, ACT wording OK")


func _test_marker_layout() -> void:
	var col := Color.WHITE
	var a: Array[Dictionary] = [
		{"sp": Vector2(400, 300), "col": col, "label": "PYLON", "dist": 413.0},
		{"sp": Vector2(430, 304), "col": col, "label": "PYLON", "dist": 366.0},
	]
	var r := Hud.layout_markers(a)
	assert(r.size() == 1 and r[0]["text"] == "2\u00d7 PYLON 366m", "close same-label markers merge")
	assert((r[0]["pts"] as Array).size() == 2)
	var b: Array[Dictionary] = [
		{"sp": Vector2(400, 300), "col": col, "label": "PYLON", "dist": 100.0},
		{"sp": Vector2(900, 300), "col": col, "label": "PYLON", "dist": 200.0},
		{"sp": Vector2(410, 306), "col": col, "label": "CORE", "dist": 150.0},
	]
	r = Hud.layout_markers(b)
	assert(r.size() == 3, "far-apart or different labels stay separate")
	var ys: Array[float] = []
	for m: Dictionary in r:
		if (m["text_pos"] as Vector2).x < 600.0:
			ys.append((m["text_pos"] as Vector2).y)
	assert(ys.size() == 2 and absf(ys[0] - ys[1]) >= Hud.MARKER_LINE_H, "overlapping labels are offset")
