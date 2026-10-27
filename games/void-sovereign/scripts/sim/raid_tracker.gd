class_name RaidTracker
extends RefCounted
## VS-025: follows every launched Hive raid to its end and reports it honestly: one "arriving" cue when the
## raid reaches its target sector (never for a raid that dies/withdraws on the way) and one outcome message.
## Pure bookkeeping: draws no RNG, so raid balance is unaffected.

var u: Universe
var raids: Array[Dictionary] = []   # {ids, n, target_sector, target_name, arrived, last_sector, eta, sector}
var _t: float = 0.0


func _init(p_u: Universe) -> void:
	u = p_u


func add(ships: Array[ShipData], target: StationData) -> void:
	var ids: Array[int] = []
	for s: ShipData in ships:
		ids.append(s.id)
	raids.append({"ids": ids, "n": ids.size(), "target_sector": target.sector, "target_name": target.display_name,
			"arrived": false, "last_sector": ships[0].sector, "sector": ships[0].sector, "eta": 0.0})
	_refresh(raids[-1])


func step(delta: float) -> void:
	_t += delta
	if _t < Defs.RAID_TRACK_INTERVAL:
		return
	_t = 0.0
	var done: Array[Dictionary] = []
	for r: Dictionary in raids:
		if _refresh(r):
			done.append(r)
	for r: Dictionary in done:
		raids.erase(r)


## Updates one raid; returns true (after emitting its outcome) when the raid is over.
func _refresh(r: Dictionary) -> bool:
	var live: Array[ShipData] = []
	var dead := 0
	for id: int in r["ids"]:
		var s := u.get_ent(id) as ShipData
		if s == null or not s.alive:
			dead += 1
		elif s.order == "raid":
			live.append(s)
	var hive := Defs.faction_color(Defs.Faction.HIVE)
	if live.is_empty():
		var where: String = u.sectors[int(r["last_sector"])].name
		if dead > 0:
			u.message.emit("Raid intercepted in %s (%d/%d destroyed)" % [where, dead, int(r["n"])], Defs.faction_color(Defs.Faction.PLAYER))
		else:
			u.message.emit("Raid withdrew from %s" % where, Defs.faction_color(Defs.Faction.PLAYER))
		return true
	var lead := live[0]
	r["last_sector"] = lead.sector
	r["sector"] = lead.sector
	r["eta"] = _eta(lead, int(r["target_sector"]))
	if not bool(r["arrived"]):
		for s: ShipData in live:
			if s.sector == int(r["target_sector"]):
				r["arrived"] = true
				r["sector"] = s.sector
				u.message.emit("RAID ARRIVING in %s: %d ships on %s" % [u.sectors[s.sector].name, live.size(), r["target_name"]], hive)
				break
	return false


func _eta(s: ShipData, target_sector: int) -> float:
	if s.sector == target_sector:
		return 0.0
	var hops := u.route(s.sector, target_sector, false)
	if hops.is_empty():
		return 0.0
	var gate := u.sectors[s.sector].gate_to(hops[0])
	var d := 0.0
	if not gate.is_empty():
		d = s.pos.distance_to(gate["pos"])
	return d / maxf(s.speed, 1.0) + float(hops.size() - 1) * Defs.RAID_HOP_ETA + Defs.RAID_HOP_ETA * 0.5


## Active raids for the UI: [{sector, target_sector, eta, ships, arrived}]
func active() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Dictionary in raids:
		var n := 0
		for id: int in r["ids"]:
			var s := u.get_ent(id)
			if s != null and s.alive:
				n += 1
		out.append({"sector": r["sector"], "target_sector": r["target_sector"], "eta": r["eta"], "ships": n, "arrived": r["arrived"]})
	return out
