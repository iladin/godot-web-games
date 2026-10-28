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
	# Start inputs low and outputs high (Defs.START_FILL_*) so trade runs are profitable on minute one.
	for w: String in inputs():
		stock[w] = int(float(capacity) * Defs.START_FILL_INPUT)
	for w: String in outputs():
		stock[w] = int(float(capacity) * Defs.START_FILL_OUTPUT)
	if kind == "trade":
		for w: String in Defs.WARES:
			stock[w] = capacity / 3
	cycle_t = randf() * Defs.CYCLE_TIME


## VS-050: penalty fraction (0..Defs.WOUND_PENALTY_MAX) for a wounded Sovereign HQ; 0 for anything else.
func wound_penalty() -> float:
	return Defs.wound_penalty(hull_frac()) if kind == "hq" and faction == Defs.Faction.PLAYER else 0.0


func regen_mult() -> float:
	return 1.0 - wound_penalty()


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
	return price_at(ware, float(stock.get(ware, 0)))


## Unit price if the station held `units` of `ware` (linear in stock, clamped to [0, capacity]).
func price_at(ware: String, units: float) -> float:
	var base: float = Defs.BASE_PRICE[ware]
	return base * lerpf(Defs.PRICE_HIGH, Defs.PRICE_LOW, clampf(units / float(capacity), 0.0, 1.0))


## Total credits for moving `qty` units (buy=true: station sells). VS-016: each unit is priced at
## the stock level *after* it moves, so a batch walks the price curve and an immediate round trip
## at one station always loses (buying pays the higher side, selling gets the lower side).
## The curve is linear, so the sum is qty x price at the mean post-unit stock.
func batch_total(ware: String, qty: int, buy: bool) -> float:
	if qty <= 0:
		return 0.0
	var s := float(stock.get(ware, 0))
	var mid := s - float(qty + 1) * 0.5 if buy else s + float(qty + 1) * 0.5
	return price_at(ware, mid) * float(qty)


func room(ware: String) -> int:
	return capacity - int(stock.get(ware, 0))


## Runs production; returns true if a cycle completed.
func produce(delta: float) -> bool:
	var ins := inputs()
	var outs := outputs()
	if kind == "trade":
		return _export(delta)
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


## Trade Hub sink (Defs.TRADE_HUB_*): ships surplus stock off-map each cycle so hubs keep buying.
func _export(delta: float) -> bool:
	cycle_t += delta
	if cycle_t < Defs.CYCLE_TIME:
		return false
	cycle_t -= Defs.CYCLE_TIME
	var target := int(float(capacity) * Defs.TRADE_HUB_TARGET_FILL)
	for w: String in Defs.WARES:
		var surplus := int(stock[w]) - target
		if surplus > 0:
			stock[w] = int(stock[w]) - mini(surplus, Defs.TRADE_HUB_EXPORT)
	return true


func value() -> float:
	return float(Defs.STATION[kind]["cost"]) * hull_frac()
