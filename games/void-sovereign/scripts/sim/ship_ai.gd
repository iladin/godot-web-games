class_name ShipAI
extends RefCounted
## Order execution for every non-player ship. Pure functions over Universe data.

const ACCEL := 220.0
const MINE_RATE := 3.5           # ore per second while inside a field
const ESCORT_LEASH := 1800.0
const PATROL_RADIUS := 2600.0
const TRADE_HOPS := 2


static func update(u: Universe, s: ShipData, delta: float) -> void:
	if s.hidden:
		return
	var t := u.get_ent(s.target_id)
	var has_target := u.valid_target(s, t) and s.armed()
	match s.order:
		"move":
			if _travel(u, s, s.order_sector, s.order_pos, 80.0, delta):
				s.order = "idle"
		"goto":
			if _travel(u, s, s.order_sector, Vector3.ZERO, 900.0, delta):
				s.order = "patrol" if s.armed() else "idle"
		"attack":
			var at := u.get_ent(s.order_target)
			if at == null or not at.alive:
				s.order = "patrol" if s.armed() else "idle"
				s.order_sector = s.sector
			elif at.sector != s.sector:
				_travel(u, s, at.sector, at.pos, 200.0, delta)
			else:
				_engage(s, at, delta)
		"patrol":
			if has_target:
				_engage(s, t, delta)
			elif s.sector != s.order_sector:
				_travel(u, s, s.order_sector, Vector3.ZERO, 600.0, delta)
			else:
				_wander(s, delta)
		"escort":
			_escort(u, s, t, has_target, delta)
		"raid":
			_raid(u, s, t, has_target, delta)
		"trade":
			_trade(u, s, delta)
		"mine":
			_mine(u, s, delta)
		_:
			if has_target:
				_engage(s, t, delta)
			else:
				_brake(s, delta)


# --- Movement primitives ------------------------------------------------------------------
static func fly_to(s: ShipData, target: Vector3, arrive: float, delta: float, speed_mul: float = 1.0) -> bool:
	var to := target - s.pos
	var d := to.length()
	if d <= arrive:
		_brake(s, delta)
		return true
	var spd := s.speed * speed_mul * clampf((d - arrive) / 300.0 + 0.15, 0.15, 1.0)
	_accel_to(s, to / d * spd, delta)
	return false


static func _accel_to(s: ShipData, desired: Vector3, delta: float) -> void:
	s.vel = s.vel.move_toward(desired, ACCEL * delta)
	s.pos += s.vel * delta


static func _brake(s: ShipData, delta: float) -> void:
	_accel_to(s, Vector3.ZERO, delta)


## Multi-sector travel through gates. Returns true once at dest_pos in dest_sector.
static func _travel(u: Universe, s: ShipData, dest_sector: int, dest_pos: Vector3, arrive: float, delta: float) -> bool:
	if s.sector != dest_sector:
		if s.route.is_empty() or s.route[s.route.size() - 1] != dest_sector:
			s.route = u.route(s.sector, dest_sector, s.faction == Defs.Faction.UNION)
			if s.route.is_empty():
				s.route = u.route(s.sector, dest_sector, false)
			if s.route.is_empty():
				return true
		var nxt: int = s.route[0]
		var gate := u.sectors[s.sector].gate_to(nxt)
		if gate.is_empty():
			s.route.clear()
			return false
		if fly_to(s, gate["pos"], Defs.GATE_DIST * 0.6, delta):
			jump(u, s, nxt)
		return false
	s.route.clear()
	return fly_to(s, dest_pos, arrive, delta)


static func jump(u: Universe, s: ShipData, nxt: int) -> void:
	var from := s.sector
	s.sector = nxt
	if not s.route.is_empty() and s.route[0] == nxt:
		s.route.pop_front()
	var gin := u.sectors[nxt].gate_to(from)
	var gp: Vector3 = gin["pos"] if not gin.is_empty() else Vector3.ZERO
	var inward := -gp.normalized() if gp.length() > 1.0 else Vector3.FORWARD
	s.pos = gp + inward * 260.0 + Vector3(randf_range(-60, 60), randf_range(-40, 40), randf_range(-60, 60))
	s.vel = inward * s.speed * 0.5
	s.target_id = 0


## Circle-strafe a target at ~70% weapon range.
static func _engage(s: ShipData, t: SimEntity, delta: float) -> void:
	var to := t.pos - s.pos
	var d := to.length()
	var want := maxf(s.weapon_range * 0.65, t.radius + 120.0)
	var radial := to / maxf(d, 0.01)
	var tangent := radial.cross(Vector3.UP).normalized() * s.orbit_sign
	if tangent.length() < 0.1:
		tangent = Vector3.RIGHT
	var radial_speed := clampf((d - want) / 200.0, -1.0, 1.0)
	var desired := (radial * radial_speed + tangent * 0.8).normalized() * s.speed
	desired.y += clampf(t.pos.y - s.pos.y, -50.0, 50.0)
	_accel_to(s, desired, delta)


static func _wander(s: ShipData, delta: float) -> void:
	s.ai_timer -= delta
	if s.ai_timer <= 0.0 or s.plan.get("wp") == null:
		var a := randf() * TAU
		var r := randf_range(400.0, PATROL_RADIUS)
		s.plan["wp"] = Vector3(cos(a) * r, randf_range(-200.0, 200.0), sin(a) * r)
		s.ai_timer = randf_range(12.0, 25.0)
	if fly_to(s, s.plan["wp"], 120.0, delta, 0.6):
		s.ai_timer = minf(s.ai_timer, 1.0)


static func _escort(u: Universe, s: ShipData, t: SimEntity, has_target: bool, delta: float) -> void:
	var lead: ShipData = u.player_ship
	if lead == null or not lead.alive or lead.hidden:
		if has_target:
			_engage(s, t, delta)
		else:
			_brake(s, delta)
		return
	if lead.sector != s.sector:
		_travel(u, s, lead.sector, lead.pos, 200.0, delta)
		return
	if has_target and t.pos.distance_to(lead.pos) < ESCORT_LEASH:
		_engage(s, t, delta)
		return
	var slot := lead.pos + Vector3(cos(float(s.id)) * 90.0, 30.0 + float(s.id % 3) * 20.0, sin(float(s.id)) * 90.0)
	var to := slot - s.pos
	var d := to.length()
	var desired := lead.vel + to.normalized() * minf(d * 1.2, s.speed * 1.4)
	if d < 40.0:
		desired = lead.vel
	_accel_to(s, desired.limit_length(s.speed * 1.6), delta)


static func _raid(u: Universe, s: ShipData, t: SimEntity, has_target: bool, delta: float) -> void:
	if has_target and (s.sector == s.order_sector or s.pos.distance_to(t.pos) < 1400.0):
		_engage(s, t, delta)
		return
	var goal := u.get_ent(s.order_target)
	if goal == null or not goal.alive:
		s.order = "patrol"
		s.order_sector = s.sector
		return
	_travel(u, s, goal.sector, goal.pos, s.weapon_range * 0.6, delta)


# --- Economy AI -----------------------------------------------------------------------------
static func _trade(u: Universe, s: ShipData, delta: float) -> void:
	match s.ai_state:
		"buy":
			var seller := u.get_ent(int(s.plan.get("from", 0))) as StationData
			if seller == null or not seller.alive:
				s.ai_state = "sell" if s.cargo_used() > 0 else ""
				return
			if _travel(u, s, seller.sector, seller.pos, Defs.DOCK_DIST, delta):
				var ware: String = s.plan["ware"]
				u.transact(s, seller, ware, int(s.plan["qty"]), true)
				s.ai_state = "sell" if s.cargo_used() > 0 else ""
		"sell":
			var buyer := u.get_ent(int(s.plan.get("to", 0))) as StationData
			var ware2: String = s.plan.get("ware", "")
			if buyer == null or not buyer.alive or not buyer.buys(ware2):
				buyer = best_buyer(u, s, ware2)
				if buyer == null:
					s.ai_state = "wait"
					s.ai_timer = 5.0
					return
				s.plan["to"] = buyer.id
			if _travel(u, s, buyer.sector, buyer.pos, Defs.DOCK_DIST, delta):
				for w: String in s.cargo.keys():
					u.transact(s, buyer, w, int(s.cargo[w]), false)
				if s.cargo_used() > 0:
					s.plan["to"] = 0   # buyer full: find another
				else:
					s.ai_state = ""
		"wait":
			_brake(s, delta)
			s.ai_timer -= delta
			if s.ai_timer <= 0.0:
				s.ai_state = ""
		_:
			if s.cargo_used() > 0:
				s.plan["ware"] = s.cargo.keys()[0]
				s.plan["to"] = 0
				s.ai_state = "sell"
				return
			s.plan = plan_trade(u, s)
			s.ai_state = "buy" if not s.plan.is_empty() else "wait"
			s.ai_timer = 4.0


## Best (ware, seller, buyer) within TRADE_HOPS jumps by profit per unit × quantity.
static func plan_trade(u: Universe, s: ShipData) -> Dictionary:
	var reach := u.sectors_within(s.sector, TRADE_HOPS, true)
	var stations: Array[StationData] = []
	for idx: int in reach:
		for e: SimEntity in u.ents_in(idx):
			if e is StationData and e.faction != Defs.Faction.HIVE:
				stations.append(e as StationData)
	var best: Dictionary = {}
	var best_profit := 0.0
	for ware: String in Defs.WARES:
		for a: StationData in stations:
			if not a.sells(ware) or int(a.stock[ware]) < 10:
				continue
			var pa := a.price(ware)
			for b: StationData in stations:
				if b == a or not b.buys(ware) or b.room(ware) < 10:
					continue
				var pb := b.price(ware)
				var qty := mini(s.cargo_cap, mini(int(a.stock[ware]), b.room(ware)))
				var profit := (pb - pa) * float(qty) - a.pos.distance_to(b.pos) * 0.01
				if a.sector != b.sector:
					profit -= 150.0
				# A station that needs inputs is worth supplying even at a thin margin.
				if b.kind != "trade" and b.fill(ware) < 0.3:
					profit += 120.0
				if profit > best_profit:
					best_profit = profit
					best = {"ware": ware, "from": a.id, "to": b.id, "qty": qty}
	return best


static func best_buyer(u: Universe, s: ShipData, ware: String) -> StationData:
	var best: StationData = null
	var best_p := 0.0
	for idx: int in u.sectors_within(s.sector, TRADE_HOPS, true):
		for e: SimEntity in u.ents_in(idx):
			if e is StationData and e.faction != Defs.Faction.HIVE:
				var st := e as StationData
				if st.buys(ware) and st.room(ware) > 5:
					var p := st.price(ware) - (150.0 / 60.0 if st.sector != s.sector else 0.0)
					if p > best_p:
						best_p = p
						best = st
	return best


static func _mine(u: Universe, s: ShipData, delta: float) -> void:
	match s.ai_state:
		"go":
			var fsec: int = s.plan.get("sector", s.sector)
			var fpos: Vector3 = s.plan.get("pos", Vector3.ZERO)
			if _travel(u, s, fsec, fpos, 120.0, delta):
				s.ai_state = "mining"
		"mining":
			_brake(s, delta)
			s.plan["acc"] = float(s.plan.get("acc", 0.0)) + MINE_RATE * delta
			var whole := int(s.plan["acc"])
			if whole > 0:
				s.plan["acc"] = float(s.plan["acc"]) - float(whole)
				s.cargo["ore"] = mini(int(s.cargo.get("ore", 0)) + whole, s.cargo_cap)
			if s.cargo_free() <= 0:
				s.ai_state = "sell"
				s.plan["to"] = 0
		"sell":
			var buyer := u.get_ent(int(s.plan.get("to", 0))) as StationData
			if buyer == null or not buyer.alive:
				buyer = best_buyer(u, s, "ore")
				if buyer == null:
					_brake(s, delta)
					return
				s.plan["to"] = buyer.id
			if _travel(u, s, buyer.sector, buyer.pos, Defs.DOCK_DIST, delta):
				u.transact(s, buyer, "ore", int(s.cargo.get("ore", 0)), false)
				if s.cargo_used() > 0:
					s.plan["to"] = 0
				else:
					s.ai_state = ""
		_:
			if s.cargo_free() <= 0:
				s.ai_state = "sell"
				return
			var best_d := INF
			for idx: int in u.sectors_within(s.sector, 1, true):
				for f: Dictionary in u.sectors[idx].fields:
					var d := (f["pos"] as Vector3).distance_to(s.pos) + (0.0 if idx == s.sector else 6000.0)
					if d < best_d:
						best_d = d
						var off := Vector3(randf_range(-1, 1), randf_range(-0.3, 0.3), randf_range(-1, 1)) * float(f["radius"]) * 0.5
						s.plan = {"sector": idx, "pos": (f["pos"] as Vector3) + off}
			s.ai_state = "go" if s.plan.has("pos") else ""
