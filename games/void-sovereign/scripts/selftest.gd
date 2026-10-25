extends SceneTree
## Logic checks for the simulation layer. Run by scripts/check.sh.


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
	var got := u.transact(ship, seller, "energy", 10, true)
	assert(got == 10)
	assert(is_equal_approx(u.credits, before - price * 10.0))
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
	var p2 := pst.price("energy")
	u.transact(npc, pst, "energy", 20, true)
	assert(is_equal_approx(u.credits, before + p2 * 20.0))

	# Production cycle consumes inputs, makes outputs.
	var ref := u.spawn_station("refinery", Defs.Faction.UNION, 1, Vector3.ZERO)
	ref.stock["ore"] = 100
	ref.stock["energy"] = 100
	ref.stock["alloy"] = 0
	ref.cycle_t = 0.0
	ref.produce(Defs.CYCLE_TIME + 0.01)
	assert(int(ref.stock["alloy"]) == 3 and int(ref.stock["ore"]) == 92)

	# Run 8 minutes of simulated time and make sure the world keeps working.
	var trades_before := 0
	for e: SimEntity in u.entities.values():
		if e is StationData:
			trades_before += int((e as StationData).stock["energy"])
	var raids_seen := false
	var dt := 1.0 / 20.0
	for i in int(480.0 / dt):
		u.step(dt)
		if u.director.raid_count > 0:
			raids_seen = true
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
	print("SELFTEST OK")
	quit()
