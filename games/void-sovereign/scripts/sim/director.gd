class_name Director
extends RefCounted
## Faction-level brains: starting fleets, Hive nests + raids (the difficulty ramp),
## Union fleet upkeep and station rebuilding. The one-off opening wave lives in opening_wave.gd.

var u: Universe
var raid_t: float = Defs.FIRST_RAID
var redirect_enabled: bool = Defs.RAID_REDIRECT_ENABLED   # VS-036
var deterred_count: int = 0      # VS-044 telemetry: raids called off by Defense Platforms
var redirected_count: int = 0    # ...of which sent at a Union station
var union_t: float = Defs.UNION_SPAWN_TIME
var raid_count: int = 0
var rebuild_queue: Array[Dictionary] = []
var tracker: RaidTracker          # VS-025 follows every launched raid
var turned_back_at: float = -1.0e9
var turned_back_pending: int = 0
var breach_t: float = Defs.BREACH_TIME   # VS-029
var breach_count: int = 0
var opening: OpeningWave          # VS-018 one-off First Sortie wave


func _init(p_u: Universe) -> void:
	u = p_u
	opening = OpeningWave.new(p_u)
	tracker = RaidTracker.new(p_u)


func seed_fleets() -> void:
	var hq := u.hq
	u.spawn_player(hq.sector, hq.pos + Vector3(0, 40, hq.radius + 140.0))
	var m := u.spawn_ship("miner", Defs.Faction.PLAYER, hq.sector, hq.pos + Vector3(250, 0, 0))
	m.order = "mine"
	for i in 2:
		var f := u.spawn_ship("fighter", Defs.Faction.PLAYER, hq.sector, hq.pos + Vector3(-200, 20 * i, 200 + 60 * i))
		f.order = "escort"
	var union_sectors := _union_sectors()
	for cls: String in Defs.UNION_QUOTA:
		var n: int = Defs.UNION_QUOTA[cls]
		for i in n:
			var sidx: int = union_sectors[i % union_sectors.size()]
			var p := Vector3(randf_range(-2000, 2000), randf_range(-200, 200), randf_range(-2000, 2000))
			_assign(u.spawn_ship(cls, Defs.Faction.UNION, sidx, p), sidx)
	for nest: StationData in u.alive_nests():
		for i in 5:
			var d := u.spawn_ship("drone", Defs.Faction.HIVE, nest.sector, nest.pos + _rand_dir() * 500.0)
			d.order = "patrol"
			d.order_sector = nest.sector
	# Light infestation in Cinder Belt so the mid-game has a contested sector.
	for i in 3:
		var d2 := u.spawn_ship("drone", Defs.Faction.HIVE, 3, Vector3(randf_range(-1500, 1500), 0, randf_range(-1500, 1500)))
		d2.order = "patrol"
		d2.order_sector = 3


func step(delta: float) -> void:
	opening.step(delta)
	tracker.step(delta)
	_nests(delta)
	_breach(delta)
	_raids(delta)
	_union(delta)
	_rebuild(delta)


func _nests(delta: float) -> void:
	var cap := 6 + int(u.time / 120.0)
	for nest: StationData in u.alive_nests():
		nest.spawn_t -= delta
		if nest.spawn_t > 0.0:
			continue
		nest.spawn_t = maxf(Defs.NEST_SPAWN_MIN, Defs.NEST_SPAWN_START - u.time / 40.0)
		var count := 0
		for e: SimEntity in u.ents_in(nest.sector):
			if e is ShipData and e.faction == Defs.Faction.HIVE:
				count += 1
		if count < cap:
			var cls := "ravager" if u.time > Defs.RAVAGER_TIME and randf() < 0.25 else "drone"
			var d := u.spawn_ship(cls, Defs.Faction.HIVE, nest.sector, nest.pos + _rand_dir() * (nest.radius + 80.0))
			d.order = "patrol"
			d.order_sector = nest.sector


## VS-029: the scripted early raid. Fixed offsets (no extra RNG beyond spawn_ship's own); tracked like any raid.
func _breach(delta: float) -> void:
	if breach_t <= 0.0:
		return
	breach_t -= delta
	if breach_t > 0.0 or u.hq == null or not u.hq.alive:
		return
	breach_count += 1
	var hq := u.hq
	var base := Vector3(1, 0.05, 0.6).normalized() * Defs.BREACH_RANGE
	var side := base.cross(Vector3.UP).normalized()
	var launched: Array[ShipData] = []
	for i in Defs.BREACH_SIZE:
		var p := hq.pos + base + side * (float(i) - float(Defs.BREACH_SIZE - 1) * 0.5) * 120.0
		var s := u.spawn_ship("drone", Defs.Faction.HIVE, hq.sector, p)
		s.hull_max *= Defs.BREACH_HULL
		s.hull = s.hull_max
		s.dps *= Defs.BREACH_DPS
		s.breach = true
		s.order = "raid"
		s.order_target = hq.id
		s.order_sector = hq.sector
		launched.append(s)
	tracker.add(launched, hq)


func raid_interval() -> float:
	return maxf(Defs.RAID_INTERVAL_MIN, Defs.RAID_INTERVAL_START - u.time / 12.0)


func raid_size() -> int:
	return mini(Defs.RAID_SIZE_START + int(u.time / Defs.RAID_SIZE_GROWTH), Defs.RAID_SIZE_MAX)


func _raids(delta: float) -> void:
	raid_t -= delta
	if raid_t > 0.0:
		return
	raid_t = raid_interval()
	var nests := u.alive_nests()
	if nests.is_empty():
		return
	var redirected_from := ""
	var target := _pick_raid_target()
	if target == null:
		return
	var go := raid_go_chance(target)
	if go < 1.0 and randf() >= go:   # no extra randf() draw unless deterred (keeps early game identical)
		# VS-020: the Hive scouts a fortified Sovereign sector and calls the raid off.
		# VS-036: ...and sends it at the nearest Union station instead (same tracker marker and ETA); no Union station = it just turns back.
		var alt: StationData = nearest_union_station(target.sector) if redirect_enabled and union_ship_count() >= Defs.RAID_REDIRECT_MIN_UNION_SHIPS else null
		_report_turned_back(target, alt)
		deterred_count += 1
		if alt == null:
			return
		redirected_count += 1
		redirected_from = u.sectors[target.sector].name
		target = alt
	raid_count += 1
	var nest: StationData = nests[randi() % nests.size()]
	var n := raid_size()
	if redirected_from != "":
		n = maxi(1, roundi(float(n) * Defs.RAID_REDIRECT_SIZE_MULT))
	var launched: Array[ShipData] = []
	for i in n:
		var cls := "drone"
		if u.time > Defs.RAVAGER_TIME and i % 3 == 0:
			cls = "ravager"
		if u.time > Defs.DREAD_TIME and i == 0 and raid_count % 3 == 0:
			cls = "dreadnought"
		var s := u.spawn_ship(cls, Defs.Faction.HIVE, nest.sector, nest.pos + _rand_dir() * (nest.radius + 150.0))
		s.order = "raid"
		s.order_target = target.id
		s.order_sector = target.sector
		launched.append(s)
	tracker.add(launched, target, redirected_from)   # VS-025: the warning comes when the raid actually arrives


## VS-025: one "turned back" line per RAID_TURNED_BACK_THROTTLE s; deterred raids in between are counted into the next line.
func _report_turned_back(target: StationData, alt: StationData = null) -> void:
	if u.time - turned_back_at < Defs.RAID_TURNED_BACK_THROTTLE:
		turned_back_pending += 1
		return
	var extra := " (+%d earlier)" % turned_back_pending if turned_back_pending > 0 else ""
	turned_back_pending = 0
	turned_back_at = u.time
	var detour := ", redirected to %s" % alt.display_name if alt != null else ""
	u.message.emit("Hive raid on %s turned back by your Defense Platforms%s%s" % [u.sectors[target.sector].name, detour, extra], Defs.faction_color(Defs.Faction.PLAYER))


## VS-044: alive Union ships (the redirect gate).
func union_ship_count() -> int:
	var n := 0
	for e: SimEntity in u.entities.values():
		if e.alive and e is ShipData and e.faction == Defs.Faction.UNION:
			n += 1
	return n


## VS-036: the alive Union station fewest gate hops from `sector` (ties: lowest id); null if none.
func nearest_union_station(sector: int) -> StationData:
	var best: StationData = null
	var best_hops := 1 << 30
	for e: SimEntity in u.entities.values():
		if not e.alive or not (e is StationData) or e.faction != Defs.Faction.UNION:
			continue
		var hops := 0 if e.sector == sector else u.route(sector, e.sector, false).size()
		if hops == 0 and e.sector != sector:
			continue   # unreachable
		if hops < best_hops or (hops == best_hops and e.id < best.id):
			best = e as StationData
			best_hops = hops
	return best


## VS-025: true when the HQ is fortified enough that the next raid will most likely be turned back (HUD shows it calm).
func next_raid_likely_deterred() -> bool:
	return u.hq != null and u.hq.alive and raid_go_chance(u.hq) < 0.5


## VS-020: chance a raid on `target` goes ahead. Each Sovereign Defense Platform in the target's
## sector multiplies it by Defs.RAID_DETER_PER_PLATFORM from Defs.RAID_DETER_FROM on, so a defended player HQ sees fewer raids
## (an undefended one, and Union targets, are unaffected).
func raid_go_chance(target: StationData) -> float:
	if target == null or target.faction != Defs.Faction.PLAYER or u.time < Defs.RAID_DETER_FROM:
		return 1.0
	var platforms := 0
	for e: SimEntity in u.ents_in(target.sector):
		if e.alive and e is StationData and e.faction == Defs.Faction.PLAYER and (e as StationData).kind == "defense" \
				and e.pos.distance_to(target.pos) <= Defs.RAID_DETER_RANGE:
			platforms += 1
	return pow(Defs.RAID_DETER_PER_PLATFORM, platforms)


func _pick_raid_target() -> StationData:
	var player_sts: Array[StationData] = []
	var union_sts: Array[StationData] = []
	for e: SimEntity in u.entities.values():
		if not e.alive or not (e is StationData):
			continue
		if e.faction == Defs.Faction.PLAYER:
			player_sts.append(e as StationData)
		elif e.faction == Defs.Faction.UNION:
			union_sts.append(e as StationData)
	if not player_sts.is_empty() and (randf() < 0.65 or union_sts.is_empty()):
		return player_sts[randi() % player_sts.size()]
	if union_sts.is_empty():
		return null
	return union_sts[randi() % union_sts.size()]


func _union(delta: float) -> void:
	union_t -= delta
	if union_t > 0.0:
		return
	union_t = Defs.UNION_SPAWN_TIME
	var yards: Array[StationData] = []
	var counts: Dictionary = {}
	for e: SimEntity in u.entities.values():
		if not e.alive or e.faction != Defs.Faction.UNION:
			continue
		if e is StationData and (e as StationData).kind == "shipyard":
			yards.append(e as StationData)
		elif e is ShipData:
			var c: String = (e as ShipData).cls
			counts[c] = int(counts.get(c, 0)) + 1
	if yards.is_empty():
		return
	var yard: StationData = yards[0]
	for cls: String in Defs.UNION_QUOTA:
		var have: int = counts.get(cls, 0)
		var quota: int = Defs.UNION_QUOTA[cls]
		if have >= quota:
			continue
		var stocked := int(yard.stock["alloy"]) >= 20 and int(yard.stock["munitions"]) >= 8
		if stocked:
			yard.stock["alloy"] = int(yard.stock["alloy"]) - 20
			yard.stock["munitions"] = int(yard.stock["munitions"]) - 8
		elif have >= quota / 2:
			continue   # without materials, only rebuild a badly depleted fleet
		_assign(u.spawn_ship(cls, Defs.Faction.UNION, yard.sector, yard.pos + _rand_dir() * (yard.radius + 120.0)), yard.sector)
		return


func _assign(s: ShipData, home: int) -> void:
	match s.role:
		"trader":
			s.order = "trade"
		"miner":
			s.order = "mine"
		_:
			s.order = "patrol"
			var us := _union_sectors()
			s.order_sector = us[randi() % us.size()] if not us.is_empty() else home


func _union_sectors() -> Array[int]:
	var out: Array[int] = []
	for s: SectorData in u.sectors:
		if u.sector_has_nest(s.idx):
			continue
		for e: SimEntity in u.ents_in(s.idx):
			if e is StationData and e.faction == Defs.Faction.UNION:
				out.append(s.idx)
				break
	if out.is_empty():
		out.append(0)
	return out


func queue_rebuild(st: StationData) -> void:
	rebuild_queue.append({"kind": st.kind, "sector": st.sector, "pos": st.pos, "t": Defs.UNION_REBUILD_TIME})


func _rebuild(delta: float) -> void:
	for i in range(rebuild_queue.size() - 1, -1, -1):
		var r: Dictionary = rebuild_queue[i]
		r["t"] = float(r["t"]) - delta
		if float(r["t"]) <= 0.0:
			var sidx: int = r["sector"]
			rebuild_queue.remove_at(i)
			if not u.sector_has_nest(sidx):
				u.spawn_station(r["kind"], Defs.Faction.UNION, sidx, r["pos"])
				u.message.emit("Union rebuilt %s in %s" % [Defs.STATION[r["kind"]]["name"], u.sectors[sidx].name], Defs.faction_color(Defs.Faction.UNION))


func _rand_dir() -> Vector3:
	return Vector3(randf_range(-1, 1), randf_range(-0.3, 0.3), randf_range(-1, 1)).normalized()
