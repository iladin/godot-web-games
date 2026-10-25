class_name StationData
extends SimEntity
## A station: produces/consumes wares each cycle, buys and sells at stock-driven prices.

var kind: String = "solar"
var stock: Dictionary = {}
var capacity: int = Defs.STATION_CAPACITY
var cycle_t: float = 0.0
var shield_locked: bool = false   # Hive nests are invulnerable while their planet Core lives
var spawn_t: float = 0.0


func setup(p_kind: String, p_faction: int) -> void:
	kind = p_kind
	faction = p_faction
	is_station = true
	var d: Dictionary = Defs.STATION[kind]
	hull_max = float(d["hull"])
	hull = hull_max
	shield_max = float(d["shield"])
	shield = shield_max
	dps = float(d["dps"])
	weapon_range = float(d["range"])
	radius = float(d["radius"])
	display_name = String(d["name"])
	if kind == "trade":
		capacity = Defs.TRADE_HUB_CAPACITY
	for w: String in Defs.WARES:
		stock[w] = 0
	# Start half stocked so the market is alive on minute one.
	for w: String in inputs():
		stock[w] = capacity / 2
	for w: String in outputs():
		stock[w] = capacity / 3
	if kind == "trade":
		for w: String in Defs.WARES:
			stock[w] = capacity / 3
	cycle_t = randf() * Defs.CYCLE_TIME


func can_be_damaged() -> bool:
	return not shield_locked


func inputs() -> Dictionary:
	return Defs.STATION[kind]["in"]


func outputs() -> Dictionary:
	return Defs.STATION[kind]["out"]


func buys(ware: String) -> bool:
	return kind == "trade" or inputs().has(ware)


func sells(ware: String) -> bool:
	return kind == "trade" or outputs().has(ware)


func fill(ware: String) -> float:
	return float(stock.get(ware, 0)) / float(capacity)


func price(ware: String) -> float:
	var base: float = Defs.BASE_PRICE[ware]
	return base * lerpf(Defs.PRICE_HIGH, Defs.PRICE_LOW, clampf(fill(ware), 0.0, 1.0))


func room(ware: String) -> int:
	return capacity - int(stock.get(ware, 0))


## Runs production; returns true if a cycle completed.
func produce(delta: float) -> bool:
	var ins := inputs()
	var outs := outputs()
	if outs.is_empty():
		return false
	cycle_t += delta
	if cycle_t < Defs.CYCLE_TIME:
		return false
	cycle_t -= Defs.CYCLE_TIME
	for w: String in ins:
		if int(stock[w]) < int(ins[w]):
			return false
	for w: String in outs:
		if room(w) < int(outs[w]):
			return false
	for w: String in ins:
		stock[w] = int(stock[w]) - int(ins[w])
	for w: String in outs:
		stock[w] = int(stock[w]) + int(outs[w])
	return true


func value() -> float:
	return float(Defs.STATION[kind]["cost"]) * hull_frac()
