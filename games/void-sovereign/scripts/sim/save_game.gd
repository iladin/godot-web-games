class_name SaveGame
extends RefCounted
## VS-026: versioned, JSON-safe snapshot of a whole Universe (data layer only; no UI, no file I/O).
## capture() is read-only: it never touches an RNG or mutates the Universe. restore() builds a fresh
## Universe (no setup(), so no RNG draws for layout) or returns null for a wrong version / malformed dict.
## Free-form dictionaries (plans, cargo, stock, ledger) go through _enc/_dec, which tags ints and Vector3
## so they survive JSON (which turns every number into a float). 64-bit RNG values are stored as strings.
## Limitation: the engine's global RNG (randf(), used by AI/combat jitter) has no readable state, so a
## restored run reseeds it from the saved sim RNG state; the continuation is valid but not bit-identical.

const VERSION := 1


# --- Capture -----------------------------------------------------------------------------
static func capture(u: Universe) -> Dictionary:
	var ents: Array = []
	for e: SimEntity in u.entities.values():
		ents.append(_cap_ent(e))
	var secs: Array = []
	for s: SectorData in u.sectors:
		var gates: Array = []
		for g: Dictionary in s.gates:
			gates.append({"pos": _v(g["pos"]), "to": int(g["to"])})
		var fields: Array = []
		for f: Dictionary in s.fields:
			fields.append({"pos": _v(f["pos"]), "radius": float(f["radius"])})
		secs.append({"idx": s.idx, "name": s.name, "map_pos": [s.map_pos.x, s.map_pos.y], "gates": gates, "fields": fields,
				"planet_pos": _v(s.planet_pos), "planet_name": s.planet_name, "planet_state": s.planet_state,
				"level": s.level, "rng_seed": s.rng_seed})
	var d := u.director
	var rq: Array = []
	for r: Dictionary in d.rebuild_queue:
		rq.append(_enc(r))
	var raids: Array = []
	for r: Dictionary in d.tracker.raids:
		raids.append(_enc(r))
	var ow := d.opening
	return {
		"version": VERSION,
		"time": u.time, "credits": u.credits, "kills": u.kills, "over": u.over, "next_id": u.next_id,
		"player_evasion": u.player_evasion,
		"player_id": u.player_ship.id if u.player_ship != null else 0,
		"hq_id": u.hq.id if u.hq != null else 0,
		"rng": {"seed": str(u.rng.seed), "state": str(u.rng.state)},
		"sectors": secs,
		"entities": ents,
		"ledger": {"totals": _enc(u.ledger.totals), "buckets": _enc(u.ledger._buckets)},
		"director": {"raid_t": d.raid_t, "union_t": d.union_t, "raid_count": d.raid_count, "rebuild_queue": rq,
				"turned_back_at": d.turned_back_at, "turned_back_pending": d.turned_back_pending,
				"breach_t": d.breach_t, "breach_count": d.breach_count},
		"tracker": {"raids": raids, "t": d.tracker._t, "history": _enc(d.tracker.history)},
		"opening": {"t": ow.t, "state": ow.state, "spawn_count": ow.spawn_count, "ids": _enc(ow.ids), "active_t": ow.active_t, "engaged": ow.engaged, "eased": ow.eased,
				"rng_seed": str(ow.rng.seed), "rng_state": str(ow.rng.state)},
	}


static func _cap_ent(e: SimEntity) -> Dictionary:
	var d := {
		"kind": "station" if e is StationData else "ship",
		"id": e.id, "faction": e.faction, "sector": e.sector, "pos": _v(e.pos), "vel": _v(e.vel),
		"hull": e.hull, "hull_max": e.hull_max, "shield": e.shield, "shield_max": e.shield_max,
		"dps": e.dps, "weapon_range": e.weapon_range, "radius": e.radius, "alive": e.alive,
		"display_name": e.display_name, "target_id": e.target_id, "retarget_cd": e.retarget_cd,
		"fire_cd": e.fire_cd, "since_hit": e.since_hit, "last_attacker": e.last_attacker,
	}
	if e is StationData:
		var st := e as StationData
		d["type"] = st.kind
		d["stock"] = _enc(st.stock)
		d["capacity"] = st.capacity
		d["cycle_t"] = st.cycle_t
		d["shield_locked"] = st.shield_locked
		d["spawn_t"] = st.spawn_t
	else:
		var s := e as ShipData
		d["type"] = s.cls
		d["role"] = s.role
		d["speed"] = s.speed
		d["cargo_cap"] = s.cargo_cap
		d["cargo"] = _enc(s.cargo)
		d["is_player"] = s.is_player
		d["breach"] = s.breach
		d["sortie"] = s.sortie
		d["hidden"] = s.hidden
		d["order"] = s.order
		d["order_pos"] = _v(s.order_pos)
		d["order_sector"] = s.order_sector
		d["order_target"] = s.order_target
		d["route"] = _enc(s.route)
		d["ai_state"] = s.ai_state
		d["ai_timer"] = s.ai_timer
		d["plan"] = _enc(s.plan)
		d["orbit_sign"] = s.orbit_sign
	return d


# --- Restore -------------------------------------------------------------------------------
## Returns a ready-to-step Universe, or null if `d` is not a valid version-VERSION save.
static func restore(d: Dictionary) -> Universe:
	if not _valid(d):
		return null
	var u := Universe.new()
	u.time = float(d["time"])
	u.credits = float(d["credits"])
	u.kills = int(d["kills"])
	u.over = bool(d["over"])
	u.next_id = int(d["next_id"])
	u.player_evasion = float(d["player_evasion"])
	var rg: Dictionary = d["rng"]
	u.rng.seed = int(str(rg["seed"]))
	u.rng.state = int(str(rg["state"]))
	seed(int(str(rg["state"])) ^ 0x5DEECE66D)   # global RNG state is unreadable: reseed deterministically from the sim RNG
	for sd: Dictionary in d["sectors"]:
		var s := SectorData.new()
		s.idx = int(sd["idx"])
		s.name = str(sd["name"])
		var mp: Array = sd["map_pos"]
		s.map_pos = Vector2(float(mp[0]), float(mp[1]))
		for g: Dictionary in sd["gates"]:
			s.gates.append({"pos": _unv(g["pos"]), "to": int(g["to"])})
		for f: Dictionary in sd["fields"]:
			s.fields.append({"pos": _unv(f["pos"]), "radius": float(f["radius"])})
		s.planet_pos = _unv(sd["planet_pos"])
		s.planet_name = str(sd["planet_name"])
		s.planet_state = str(sd["planet_state"])
		s.level = int(sd["level"])
		s.rng_seed = int(sd["rng_seed"])
		u.sectors.append(s)
		u.sector_ents.append([])
		u.hive_presence.append(0)
	for ed: Dictionary in d["entities"]:
		var e := _rest_ent(ed)
		u.entities[e.id] = e
	u.player_ship = u.get_ent(int(d["player_id"])) as ShipData
	u.hq = u.get_ent(int(d["hq_id"])) as StationData
	var lg: Dictionary = d["ledger"]
	u.ledger.totals = _dec(lg["totals"])
	u.ledger._buckets.clear()
	for b in _dec(lg["buckets"]) as Array:
		u.ledger._buckets.append(b as Dictionary)
	var dir := Director.new(u)
	u.director = dir
	var dd: Dictionary = d["director"]
	dir.raid_t = float(dd["raid_t"])
	dir.union_t = float(dd["union_t"])
	dir.raid_count = int(dd["raid_count"])
	for r in dd["rebuild_queue"] as Array:
		dir.rebuild_queue.append(_dec(r) as Dictionary)
	dir.turned_back_at = float(dd["turned_back_at"])
	dir.turned_back_pending = int(dd["turned_back_pending"])
	dir.breach_t = float(dd["breach_t"])
	dir.breach_count = int(dd["breach_count"])
	var td: Dictionary = d["tracker"]
	dir.tracker._t = float(td["t"])
	for r in td["raids"] as Array:
		var rr: Dictionary = _dec(r)
		var ids: Array[int] = []
		for i in rr["ids"] as Array:
			ids.append(int(i))
		rr["ids"] = ids
		dir.tracker.raids.append(rr)
	for h: Variant in _dec(td.get("history", [])) as Array:
		dir.tracker.history.append(h as Dictionary)
	var od: Dictionary = d["opening"]
	var ow := dir.opening
	ow.t = float(od["t"])
	ow.state = int(od["state"])
	ow.spawn_count = int(od["spawn_count"])
	for i in _dec(od["ids"]) as Array:
		ow.ids.append(int(i))
	ow.active_t = float(od["active_t"])
	ow.engaged = bool(od.get("engaged", false))
	ow.eased = bool(od.get("eased", false))
	ow.rng.seed = int(str(od["rng_seed"]))
	ow.rng.state = int(str(od["rng_state"]))
	u._rebuild_cache()
	return u


static func _rest_ent(d: Dictionary) -> SimEntity:
	var e: SimEntity
	if str(d["kind"]) == "station":
		var st := StationData.new()
		st.kind = str(d["type"])
		st.is_station = true
		st.stock = _dec(d["stock"])
		st.capacity = int(d["capacity"])
		st.cycle_t = float(d["cycle_t"])
		st.shield_locked = bool(d["shield_locked"])
		st.spawn_t = float(d["spawn_t"])
		e = st
	else:
		var s := ShipData.new()
		s.cls = str(d["type"])
		s.role = str(d["role"])
		s.speed = float(d["speed"])
		s.cargo_cap = int(d["cargo_cap"])
		s.cargo = _dec(d["cargo"])
		s.is_player = bool(d["is_player"])
		s.breach = bool(d["breach"])
		s.sortie = bool(d["sortie"])
		s.hidden = bool(d["hidden"])
		s.order = str(d["order"])
		s.order_pos = _unv(d["order_pos"])
		s.order_sector = int(d["order_sector"])
		s.order_target = int(d["order_target"])
		for r in _dec(d["route"]) as Array:
			s.route.append(int(r))
		s.ai_state = str(d["ai_state"])
		s.ai_timer = float(d["ai_timer"])
		s.plan = _dec(d["plan"])
		s.orbit_sign = float(d["orbit_sign"])
		e = s
	e.id = int(d["id"])
	e.faction = int(d["faction"])
	e.sector = int(d["sector"])
	e.pos = _unv(d["pos"])
	e.vel = _unv(d["vel"])
	e.hull = float(d["hull"])
	e.hull_max = float(d["hull_max"])
	e.shield = float(d["shield"])
	e.shield_max = float(d["shield_max"])
	e.dps = float(d["dps"])
	e.weapon_range = float(d["weapon_range"])
	e.radius = float(d["radius"])
	e.alive = bool(d["alive"])
	e.display_name = str(d["display_name"])
	e.target_id = int(d["target_id"])
	e.retarget_cd = float(d["retarget_cd"])
	e.fire_cd = float(d["fire_cd"])
	e.since_hit = float(d["since_hit"])
	e.last_attacker = int(d["last_attacker"])
	return e


# --- Validation ----------------------------------------------------------------------------
const _TOP_KEYS: Array[String] = ["time", "credits", "kills", "over", "next_id", "player_evasion", "player_id", "hq_id",
		"rng", "sectors", "entities", "ledger", "director", "tracker", "opening"]
const _ENT_KEYS: Array[String] = ["kind", "id", "faction", "sector", "pos", "vel", "hull", "hull_max", "shield", "shield_max",
		"dps", "weapon_range", "radius", "alive", "display_name", "target_id", "retarget_cd", "fire_cd", "since_hit",
		"last_attacker", "type"]
const _SHIP_KEYS: Array[String] = ["role", "speed", "cargo_cap", "cargo", "is_player", "breach", "sortie", "hidden", "order",
		"order_pos", "order_sector", "order_target", "route", "ai_state", "ai_timer", "plan", "orbit_sign"]
const _STATION_KEYS: Array[String] = ["stock", "capacity", "cycle_t", "shield_locked", "spawn_t"]
const _SECTOR_KEYS: Array[String] = ["idx", "name", "map_pos", "gates", "fields", "planet_pos", "planet_name", "planet_state",
		"level", "rng_seed"]


static func _has(d: Variant, keys: Array[String]) -> bool:
	if not (d is Dictionary):
		return false
	for k: String in keys:
		if not (d as Dictionary).has(k):
			return false
	return true


static func _is_num(v: Variant) -> bool:
	return v is float or v is int


static func _is_v3(v: Variant) -> bool:
	return v is Array and (v as Array).size() == 3 and _is_num(v[0]) and _is_num(v[1]) and _is_num(v[2])


## Structural check; anything it lets through restores without runtime errors.
static func _valid(d: Dictionary) -> bool:
	if not d.has("version") or not _is_num(d["version"]) or int(d["version"]) != VERSION:
		return false
	if not _has(d, _TOP_KEYS):
		return false
	for k: String in ["time", "credits", "player_evasion"]:
		if not _is_num(d[k]):
			return false
	for k: String in ["kills", "next_id", "player_id", "hq_id"]:
		if not _is_num(d[k]):
			return false
	if not (d["over"] is bool) or not (d["sectors"] is Array) or not (d["entities"] is Array):
		return false
	if not _has(d["rng"], ["seed", "state"]) or not _has(d["ledger"], ["totals", "buckets"]):
		return false
	if not _has(d["director"], ["raid_t", "union_t", "raid_count", "rebuild_queue", "turned_back_at", "turned_back_pending",
			"breach_t", "breach_count"]):
		return false
	if not _has(d["tracker"], ["raids", "t"]) or not _has(d["opening"], ["t", "state", "spawn_count", "ids", "active_t", "rng_seed", "rng_state"]):
		return false
	if not (d["director"]["rebuild_queue"] is Array) or not (d["tracker"]["raids"] is Array):
		return false
	var nsec: int = (d["sectors"] as Array).size()
	if nsec != Defs.SECTORS.size():
		return false
	for i in nsec:
		var s: Variant = d["sectors"][i]
		if not _has(s, _SECTOR_KEYS) or not (s["gates"] is Array) or not (s["fields"] is Array) or not _is_v3(s["planet_pos"]):
			return false
		if not (s["map_pos"] is Array) or (s["map_pos"] as Array).size() != 2 or int(s["idx"]) != i:
			return false
		for g: Variant in s["gates"]:
			if not _has(g, ["pos", "to"]) or not _is_v3(g["pos"]) or int(g["to"]) < 0 or int(g["to"]) >= nsec:
				return false
		for f: Variant in s["fields"]:
			if not _has(f, ["pos", "radius"]) or not _is_v3(f["pos"]):
				return false
	var ids: Dictionary = {}
	for e: Variant in d["entities"]:
		if not _has(e, _ENT_KEYS):
			return false
		var is_st: bool = str(e["kind"]) == "station"
		if not is_st and str(e["kind"]) != "ship":
			return false
		if not _has(e, _STATION_KEYS if is_st else _SHIP_KEYS):
			return false
		if not _is_v3(e["pos"]) or not _is_v3(e["vel"]) or not _is_num(e["sector"]) or int(e["sector"]) < 0 or int(e["sector"]) >= nsec:
			return false
		var table: Dictionary = Defs.STATION if is_st else Defs.SHIP
		if not table.has(str(e["type"])):
			return false
		if not is_st and (not _is_v3(e["order_pos"]) or not (e["plan"] is Dictionary) or not (e["cargo"] is Dictionary) or not (e["route"] is Array)):
			return false
		if is_st and not (e["stock"] is Dictionary):
			return false
		ids[int(e["id"])] = true
	if not ids.has(int(d["player_id"])) or not ids.has(int(d["hq_id"])):
		return false
	# Tagged-value payloads must decode to the shapes restore() casts them to.
	if not (d["ledger"]["totals"] is Dictionary) or not (d["ledger"]["buckets"] is Array) or not (d["opening"]["ids"] is Array):
		return false
	if d["tracker"].has("history") and not (d["tracker"]["history"] is Array):
		return false
	for r: Variant in d["tracker"]["raids"]:
		if not _has(r, ["ids", "n", "target_sector", "target_name", "arrived", "last_sector", "eta", "sector"]) or not (r["ids"] is Array):
			return false
	return true


# --- JSON-safe value tagging ---------------------------------------------------------------------
static func _v(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func _unv(a: Variant) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


## Ints become {"$i": n} and Vector3 {"$v": [x, y, z]}; floats, strings and bools pass through.
static func _enc(v: Variant) -> Variant:
	match typeof(v):
		TYPE_INT:
			return {"$i": v}
		TYPE_VECTOR3:
			return {"$v": _v(v)}
		TYPE_DICTIONARY:
			var out: Dictionary = {}
			for k: Variant in v:
				out[str(k)] = _enc(v[k])
			return out
		TYPE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY:
			var arr: Array = []
			for x: Variant in v:
				arr.append(_enc(x))
			return arr
	return v


static func _dec(v: Variant) -> Variant:
	if v is Dictionary:
		var dv := v as Dictionary
		if dv.size() == 1 and dv.has("$i"):
			return int(dv["$i"])
		if dv.size() == 1 and dv.has("$v"):
			return _unv(dv["$v"])
		var out: Dictionary = {}
		for k: Variant in dv:
			out[k] = _dec(dv[k])
		return out
	if v is Array:
		var arr: Array = []
		for x: Variant in v:
			arr.append(_dec(x))
		return arr
	return v
