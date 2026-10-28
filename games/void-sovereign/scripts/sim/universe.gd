class_name Universe
extends RefCounted
## The whole cluster as data. Every sector is simulated every frame; views only render one.

signal message(text: String, color: Color)
signal shot(src_id: int, dst_id: int)
signal destroyed(ent: SimEntity, killer_id: int)
signal player_died()
signal planet_changed(sector_idx: int)
signal finished(won: bool)
signal credits_changed(amount: float, cat: String)   ## VS-053: every add_credits(), for the HUD's signed delta

var sectors: Array[SectorData] = []
var entities: Dictionary = {}          # id -> SimEntity
var sector_ents: Array = []            # per sector: Array[SimEntity], rebuilt each step
var hive_presence: Array[int] = []     # per sector: live Hive warships, rebuilt each step
var next_id: int = 1
var credits: float = Defs.START_CREDITS  # write only through add_credits() (VS-024)
var ledger := CreditLedger.new()
var time: float = 0.0
var player_ship: ShipData
var hq: StationData
var player_evasion: float = 0.0        # set by the flight view from player speed
var kills: int = 0
var over: bool = false
var director: Director
var rng := RandomNumberGenerator.new()


func setup(p_seed: int = 7) -> void:
	rng.seed = p_seed
	seed(p_seed)
	_build_sectors()
	for s: SectorData in sectors:
		var def: Dictionary = Defs.SECTORS[s.idx]
		var ring := 0
		for st: Array in def["stations"]:
			var kind: String = st[0]
			var fac: int = st[1]
			var ang := TAU * float(ring) / float(def["stations"].size()) + rng.randf_range(-0.3, 0.3)
			var dist := 900.0 + rng.randf_range(0.0, 1300.0) if kind != "hq" else 600.0
			var p := Vector3(cos(ang) * dist, rng.randf_range(-150.0, 150.0), sin(ang) * dist)
			var station := spawn_station(kind, fac, s.idx, p)
			if kind == "hq":
				hq = station
			if kind == "nest":
				station.shield_locked = true
			ring += 1
	director = Director.new(self)
	director.seed_fleets()
	_rebuild_cache()


func _build_sectors() -> void:
	for i in Defs.SECTORS.size():
		var def: Dictionary = Defs.SECTORS[i]
		var s := SectorData.new()
		s.idx = i
		s.name = def["name"]
		s.map_pos = def["map"]
		s.planet_state = def["planet"]
		s.level = def["level"]
		s.planet_name = def["planet_name"]
		s.rng_seed = 1000 + i * 77
		sectors.append(s)
	for link: Vector2i in Defs.LINKS:
		_add_gate(link.x, link.y)
		_add_gate(link.y, link.x)
	for s: SectorData in sectors:
		# Planet sits away from the gates: opposite of the average gate direction.
		var avg := Vector3.ZERO
		for g: Dictionary in s.gates:
			avg += (g["pos"] as Vector3).normalized()
		var pdir := -avg.normalized() if avg.length() > 0.1 else Vector3(0, 0, 1)
		pdir = (pdir + Vector3(0, -0.25, 0)).normalized()
		s.planet_pos = pdir * Defs.PLANET_DIST
		var nfields: int = Defs.SECTORS[s.idx]["fields"]
		for f in nfields:
			var ang := rng.randf() * TAU
			var d := rng.randf_range(1400.0, 2800.0)
			s.fields.append({"pos": Vector3(cos(ang) * d, rng.randf_range(-300.0, 300.0), sin(ang) * d), "radius": rng.randf_range(350.0, 600.0)})
		sector_ents.append([])
		hive_presence.append(0)


func _add_gate(a: int, b: int) -> void:
	var sa := sectors[a]
	var dir2 := (sectors[b].map_pos - sa.map_pos).normalized()
	var p := Vector3(dir2.x, 0.0, dir2.y) * Defs.SECTOR_RADIUS
	sa.gates.append({"pos": p, "to": b})


# --- Spawning ---------------------------------------------------------------------
func spawn_ship(cls: String, faction: int, sector_idx: int, p: Vector3) -> ShipData:
	var s := ShipData.new()
	s.setup(cls, faction)
	s.id = next_id
	next_id += 1
	s.sector = sector_idx
	s.pos = p
	entities[s.id] = s
	sector_ents[sector_idx].append(s)
	return s


func spawn_station(kind: String, faction: int, sector_idx: int, p: Vector3) -> StationData:
	var st := StationData.new()
	st.setup(kind, faction)
	st.id = next_id
	next_id += 1
	st.sector = sector_idx
	st.pos = p
	entities[st.id] = st
	if sector_ents.size() > sector_idx:
		sector_ents[sector_idx].append(st)
	return st


func spawn_player(sector_idx: int, p: Vector3) -> ShipData:
	player_ship = spawn_ship("interceptor", Defs.Faction.PLAYER, sector_idx, p)
	player_ship.is_player = true
	player_ship.display_name = "You"
	return player_ship


func respawn_player() -> void:
	add_credits(-credits * Defs.RESPAWN_PENALTY, "losses")
	var p := hq.pos + Vector3(0, 60, hq.radius + 120.0)
	spawn_player(hq.sector, p)
	message.emit("Ship lost. New interceptor issued at HQ (-%d%% credits)" % int(Defs.RESPAWN_PENALTY * 100.0), Color.ORANGE)


# --- Queries ------------------------------------------------------------------------
func get_ent(id: int) -> SimEntity:
	return entities.get(id) as SimEntity


func ents_in(sector_idx: int) -> Array:
	return sector_ents[sector_idx]


func valid_target(e: SimEntity, t: SimEntity) -> bool:
	if t == null or not t.alive or t.sector != e.sector:
		return false
	if t is ShipData and (t as ShipData).hidden:
		return false
	if e is ShipData and (e as ShipData).breach and not (t is StationData):
		return false
	return Defs.hostile(e.faction, t.faction) and OpeningWave.allows(self, e, t)


func nearest_hostile(e: SimEntity, max_dist: float) -> SimEntity:
	var best: SimEntity = null
	var best_d := max_dist * max_dist
	for o: SimEntity in sector_ents[e.sector]:
		if not valid_target(e, o):
			continue
		var d := e.pos.distance_squared_to(o.pos)
		if d < best_d:
			best_d = d
			best = o
	return best


func alive_nests() -> Array[StationData]:
	var out: Array[StationData] = []
	for e: SimEntity in entities.values():
		if e.alive and e is StationData and (e as StationData).kind == "nest":
			out.append(e as StationData)
	return out


func sector_has_nest(idx: int) -> bool:
	for e: SimEntity in sector_ents[idx]:
		if e is StationData and (e as StationData).kind == "nest" and e.alive:
			return true
	return false


## Civilian planners (trade, mining) skip sectors with a Nest or a Hive pack (Defs.CIVILIAN_AVOID_HIVE).
func sector_unsafe(idx: int) -> bool:
	return sector_has_nest(idx) or hive_presence[idx] >= Defs.CIVILIAN_AVOID_HIVE


## BFS over gates. Returns the hops after `from` (empty if same sector or unreachable).
func route(from: int, to: int, avoid_hive: bool = false) -> Array[int]:
	var out: Array[int] = []
	if from == to:
		return out
	var prev: Dictionary = {from: -1}
	var queue: Array[int] = [from]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		if cur == to:
			break
		for g: Dictionary in sectors[cur].gates:
			var nxt: int = g["to"]
			if prev.has(nxt):
				continue
			if avoid_hive and nxt != to and sector_has_nest(nxt):
				continue
			prev[nxt] = cur
			queue.append(nxt)
	if not prev.has(to):
		return out
	var c := to
	while c != from:
		out.push_front(c)
		c = prev[c]
	return out


func sectors_within(from: int, hops: int, avoid_hive: bool) -> Array[int]:
	var out: Array[int] = [from]
	var frontier: Array[int] = [from]
	for h in hops:
		var nf: Array[int] = []
		for c: int in frontier:
			for g: Dictionary in sectors[c].gates:
				var n: int = g["to"]
				if n in out or (avoid_hive and sector_unsafe(n)):
					continue
				out.append(n)
				nf.append(n)
		frontier = nf
	return out


## VS-040: the three income sources shown before the first income, with estimates computed from the
## same Defs numbers that pay out (full-hold sale at base price, per-minute colony income).
func income_sources() -> Array[String]:
	var hold: int = int(Defs.SHIP["interceptor"]["cargo"])
	var haul: int = int(Defs.SHIP["miner"]["cargo"])
	var miners := 0
	for e: Variant in entities.values():
		if e is ShipData and (e as ShipData).faction == Defs.Faction.PLAYER and (e as ShipData).cls == "miner":
			miners += 1
	return [
		"Trading: sell a full hold of munitions ~%s cr" % Hud._fmt(float(hold) * float(Defs.BASE_PRICE["munitions"])),
		"Miners (%s owned): ~%s cr per ore haul each" % [miners, Hud._fmt(float(haul) * float(Defs.BASE_PRICE["ore"]))],
		"Colonies (%d owned): +%d cr/min each" % [colonies(), int(Defs.COLONY_INCOME)],
	]


func colonies() -> int:
	var n := 0
	for s: SectorData in sectors:
		if s.planet_state == "colony":
			n += 1
	return n


func net_worth() -> float:
	var w := credits
	for e: SimEntity in entities.values():
		if not e.alive or e.faction != Defs.Faction.PLAYER:
			continue
		if e is ShipData:
			w += (e as ShipData).value()
		elif e is StationData:
			w += (e as StationData).value()
	return w


func score(won: bool) -> int:
	var s := net_worth() + colonies() * 5000.0
	if won:
		s += 50000.0 + maxf(0.0, 3600.0 - time) * 10.0
	return int(s)


# --- Economy ----------------------------------------------------------------------------
## Moves `qty` of `ware` between a ship and a station. buy=true: ship buys from station.
## Credits only move when exactly one side belongs to the player. Returns qty moved.
func transact(ship: ShipData, st: StationData, ware: String, qty: int, buy: bool) -> int:
	if qty <= 0 or not st.alive:
		return 0
	var p := st.price(ware)
	if buy:
		qty = mini(qty, int(st.stock.get(ware, 0)))
		qty = mini(qty, ship.cargo_free())
	else:
		qty = mini(qty, int(ship.cargo.get(ware, 0)))
		qty = mini(qty, st.room(ware))
	var ship_player := ship.faction == Defs.Faction.PLAYER
	var st_player := st.faction == Defs.Faction.PLAYER
	if ship_player != st_player:
		# The player is the payer when buying as a ship, or when their station receives goods.
		var player_pays := (buy and ship_player) or (not buy and st_player)
		if player_pays:
			# Automated player assets (traders, stations) keep a reserve for repairs and purchases;
			# only the pilot's own ship may spend down to zero.
			var budget := credits if ship.is_player else credits - Defs.TRADER_RESERVE
			qty = mini(qty, int(floor(maxf(budget, 0.0) / maxf(p, 0.01))))
			# Batches walk the price curve (StationData.batch_total), so trim to what the budget covers.
			while qty > 0 and st.batch_total(ware, qty, buy) > budget:
				qty -= 1
	if qty <= 0:
		return 0
	var total := st.batch_total(ware, qty, buy)
	if ship_player != st_player:
		var player_pays2 := (buy and ship_player) or (not buy and st_player)
		add_credits(-total if player_pays2 else total, _trade_category(ship, st_player))
	if buy:
		st.stock[ware] = int(st.stock[ware]) - qty
		ship.cargo[ware] = int(ship.cargo.get(ware, 0)) + qty
	else:
		st.stock[ware] = int(st.stock[ware]) + qty
		ship.cargo[ware] = int(ship.cargo[ware]) - qty
		if int(ship.cargo[ware]) <= 0:
			ship.cargo.erase(ware)
	return qty


## VS-024: the single writer of the player's credits. Every change carries a CreditLedger category.
## VS-048: cost to restore a station to full hull.
func station_repair_cost(st: StationData) -> float:
	return maxf(0.0, st.hull_max - st.hull) * Defs.STATION_REPAIR_COST if st.alive else 0.0


## VS-048: pay (up to available credits) to restore station hull; returns hull points restored.
func repair_station(st: StationData) -> float:
	if not st.alive or st.faction != Defs.Faction.PLAYER or credits <= 0.0:
		return 0.0
	var pts := minf(st.hull_max - st.hull, credits / Defs.STATION_REPAIR_COST)
	if pts <= 0.5:
		return 0.0
	add_credits(-pts * Defs.STATION_REPAIR_COST, "repair")
	st.hull += pts
	return pts


func add_credits(amount: float, cat: String) -> void:
	credits += amount
	ledger.record(time, amount, cat)
	credits_changed.emit(amount, cat)


func _trade_category(ship: ShipData, st_player: bool) -> String:
	if st_player:
		return "stations"
	if ship.is_player:
		return "trade"
	return "mining" if ship.role == "miner" else "freight"


func buy_ship(cls: String, at: StationData) -> ShipData:
	var cost := float(Defs.SHIP[cls]["cost"])
	if credits < cost or at == null or not at.alive:
		return null
	add_credits(-cost, "ships")
	var off := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 0.3), rng.randf_range(-1, 1)).normalized()
	var s := spawn_ship(cls, Defs.Faction.PLAYER, at.sector, at.pos + off * (at.radius + 150.0))
	match s.role:
		"miner":
			s.order = "mine"
		"trader":
			s.order = "trade"
		_:
			s.order = "escort"
	message.emit("%s purchased" % s.display_name, Defs.faction_color(Defs.Faction.PLAYER))
	return s


func build_station(kind: String, sector_idx: int, p: Vector3) -> StationData:
	var cost := float(Defs.STATION[kind]["cost"])
	if credits < cost:
		message.emit("Not enough credits", Color.ORANGE_RED)
		return null
	if sector_has_nest(sector_idx):
		message.emit("Cannot build in a Hive sector", Color.ORANGE_RED)
		return null
	if p.distance_to(sectors[sector_idx].planet_pos) < Defs.PLANET_RADIUS:
		message.emit("Cannot build inside a planet", Color.ORANGE_RED)
		return null
	add_credits(-cost, "build")
	var st := spawn_station(kind, Defs.Faction.PLAYER, sector_idx, p)
	for w: String in Defs.WARES:
		st.stock[w] = 0
	message.emit("%s built in %s" % [st.display_name, sectors[sector_idx].name], Defs.faction_color(Defs.Faction.PLAYER))
	return st


func core_destroyed(sector_idx: int) -> void:
	var s := sectors[sector_idx]
	s.planet_state = "colony"
	for e: SimEntity in sector_ents[sector_idx]:
		if e is StationData and (e as StationData).kind == "nest":
			(e as StationData).shield_locked = false
			message.emit("Hive Nest in %s is EXPOSED — send the fleet!" % s.name, Defs.faction_color(Defs.Faction.HIVE))
	message.emit("%s claimed: colony established (+%d cr/min)" % [s.planet_name, int(Defs.COLONY_INCOME)], Defs.faction_color(Defs.Faction.PLAYER))
	planet_changed.emit(sector_idx)


# --- Simulation step ----------------------------------------------------------------------
func step(delta: float) -> void:
	if over:
		return
	time += delta
	_rebuild_cache()
	var hq_mult := 1.0 - (hq.wound_penalty() if hq != null and hq.alive else 0.0)
	add_credits(float(colonies()) * Defs.COLONY_INCOME / 60.0 * hq_mult * delta, "colonies")
	for e: SimEntity in entities.values():
		if not e.alive:
			continue
		e.regen(delta)
		if e.faction == Defs.Faction.PLAYER and e is ShipData:
			_dock_repair(e as ShipData, delta)
		if e is StationData:
			(e as StationData).produce(delta)
		elif not (e as ShipData).is_player:
			ShipAI.update(self, e as ShipData, delta)
		if e.armed():
			_combat(e, delta)
	director.step(delta)
	_reap()


## HQ dock crews (Defs.REPAIR_*): idle automated ships near the HQ slowly regain hull.
func _dock_repair(s: ShipData, delta: float) -> void:
	if s.is_player or hq == null or not hq.alive or s.sector != hq.sector or s.hull >= s.hull_max:
		return
	if s.since_hit > Defs.SHIELD_DELAY and s.pos.distance_to(hq.pos) < Defs.REPAIR_RANGE:
		s.hull = minf(s.hull_max, s.hull + s.hull_max * Defs.REPAIR_RATE * delta)


func _rebuild_cache() -> void:
	for arr: Array in sector_ents:
		arr.clear()
	hive_presence.fill(0)
	for e: SimEntity in entities.values():
		if e.alive:
			sector_ents[e.sector].append(e)
			if e.faction == Defs.Faction.HIVE and e is ShipData:
				hive_presence[e.sector] += 1


func _combat(e: SimEntity, delta: float) -> void:
	if e is ShipData and (e as ShipData).hidden:
		return
	e.fire_cd -= delta
	e.retarget_cd -= delta
	var t := get_ent(e.target_id)
	if e.retarget_cd <= 0.0 or not valid_target(e, t):
		e.retarget_cd = Defs.RETARGET_TIME + randf() * 0.2
		t = null
		if e is ShipData:
			var forced := get_ent((e as ShipData).order_target)
			if (e as ShipData).order == "attack" and valid_target(e, forced) and e.pos.distance_to(forced.pos) < Defs.SENSOR_RANGE:
				t = forced
		if t == null:
			t = nearest_hostile(e, Defs.SENSOR_RANGE if not e.is_station else e.weapon_range)
		e.target_id = t.id if t else 0
	if t == null or e.fire_cd > 0.0:
		return
	if e.pos.distance_to(t.pos) > e.weapon_range + t.radius:
		return
	e.fire_cd = Defs.SHOT_INTERVAL * randf_range(0.85, 1.15)
	var dmg := e.dps * Defs.SHOT_INTERVAL
	if t == player_ship:
		dmg *= 1.0 - player_evasion
	shot.emit(e.id, t.id)
	if t.take_damage(dmg, e.id):
		_on_killed(t, e.id)


## Called by the flight view when the player's own guns hit something.
func player_hit(t: SimEntity, dmg: float) -> void:
	# Friendly fire is off: only Hive targets take damage from the player's guns.
	if t == null or not t.alive or t.faction != Defs.Faction.HIVE:
		return
	if t.take_damage(dmg, player_ship.id if player_ship else 0):
		_on_killed(t, player_ship.id if player_ship else 0)


func _on_killed(t: SimEntity, killer_id: int) -> void:
	destroyed.emit(t, killer_id)
	var killer := get_ent(killer_id)
	if t.faction == Defs.Faction.HIVE and killer != null and killer.faction == Defs.Faction.PLAYER and t is ShipData:
		var b: float = Defs.BOUNTY.get((t as ShipData).cls, 0.0)
		add_credits(b, "bounty")
		kills += 1
	if t is StationData:
		var st := t as StationData
		match st.kind:
			"hq":
				message.emit("HQ DESTROYED", Color.RED)
				over = true
				finished.emit(false)
			"nest":
				add_credits(20000.0, "bounty")
				message.emit("Hive Nest in %s destroyed! +20000 cr" % sectors[st.sector].name, Defs.faction_color(Defs.Faction.PLAYER))
				if alive_nests().filter(func(n: StationData) -> bool: return n != st).is_empty():
					over = true
					finished.emit(true)
			_:
				message.emit("%s %s lost in %s" % [Defs.FACTION_NAMES[st.faction], st.display_name, sectors[st.sector].name], Color.ORANGE)
				if st.faction == Defs.Faction.UNION:
					director.queue_rebuild(st)
	elif t == player_ship:
		player_died.emit()


func _reap() -> void:
	var dead: Array[int] = []
	for id: int in entities:
		if not (entities[id] as SimEntity).alive:
			dead.append(id)
	for id: int in dead:
		entities.erase(id)
