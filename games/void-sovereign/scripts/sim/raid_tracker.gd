class_name RaidTracker
extends RefCounted
## VS-025: follows every launched Hive raid to its end and reports it honestly: one "arriving" cue when the
## raid reaches its target sector (never for a raid that dies/withdraws on the way) and one outcome message.
## Pure bookkeeping: draws no RNG, so raid balance is unaffected.

var u: Universe
var raids: Array[Dictionary] = []   # {ids, n, target_id, target_sector, target_name, arrived, last_sector, eta, sector}
## VS-039: one entry per finished raid {t, kind: intercepted|withdrew|succeeded, text}; the map panel lists the last RAID_HISTORY_WINDOW s.
var history: Array[Dictionary] = []
var _t: float = 0.0


func _init(p_u: Universe) -> void:
	u = p_u


func add(ships: Array[ShipData], target: StationData) -> void:
	var ids: Array[int] = []
	for s: ShipData in ships:
		ids.append(s.id)
	raids.append({"ids": ids, "n": ids.size(), "target_id": target.id, "target_sector": target.sector, "target_name": target.display_name,
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
		var target := u.get_ent(int(r.get("target_id", -1)))
		var green := Defs.faction_color(Defs.Faction.PLAYER)
		if int(r.get("target_id", -1)) >= 0 and (target == null or not target.alive):
			_finish("succeeded", "Raid SUCCEEDED: %s destroyed in %s" % [r["target_name"], u.sectors[int(r["target_sector"])].name], hive)
		elif dead > 0:
			_finish("intercepted", "Raid intercepted in %s (%d/%d destroyed)" % [where, dead, int(r["n"])], green)
		else:
			_finish("withdrew", "Raid withdrew from %s" % where, green)
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


## The single place a raid outcome is written: one message and one history line.
func _finish(kind: String, text: String, col: Color) -> void:
	history.append({"t": u.time, "kind": kind, "text": text})
	while history.size() > Defs.RAID_HISTORY_MAX:
		history.remove_at(0)
	u.message.emit(text, col)


## Outcomes of the last RAID_HISTORY_WINDOW s, newest first: [{age, kind, text}]
func recent() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(history.size() - 1, -1, -1):
		var age: float = u.time - float(history[i]["t"])
		if age <= Defs.RAID_HISTORY_WINDOW:
			out.append({"age": maxf(age, 0.0), "kind": history[i]["kind"], "text": history[i]["text"]})
	return out


## Short label for one active() row (inset marker and map panel): "RAID x3 > Ember ETA 42s".
func label_for(rd: Dictionary) -> String:
	var tname: String = u.sectors[int(rd["target_sector"])].name
	if bool(rd["arrived"]) or int(rd["sector"]) == int(rd["target_sector"]):
		return "RAID x%d ON %s" % [int(rd["ships"]), tname]
	return "RAID x%d > %s ETA %ds" % [int(rd["ships"]), tname, int(float(rd["eta"]))]


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
