class_name OpeningWave
extends RefCounted
## VS-018 First Sortie: once per run, Defs.OPENING_WAVE_TIME seconds of play in, a few weakened
## Hive drones drop out of orbit over the home sector's Hive world (Ember) and make for the HQ,
## so the first minutes have a fight (and the "lock a Hive ship" tip has a target). Owned and
## stepped by Director, so it only advances while the Universe steps (RunFlow.sim_runs).
## Separate from raids: it never touches Director.raid_t or raid_count.

enum State { PENDING, ACTIVE, CLEARED }

var u: Universe
var t: float = Defs.OPENING_WAVE_TIME
var state: int = State.PENDING
var spawn_count: int = 0          # how many times the wave spawned (selftest: exactly once)
var ids: Array[int] = []
var active_t: float = 0.0
var rng := RandomNumberGenerator.new()   # wave-only draws; the main sim stream stays untouched


func _init(p_u: Universe) -> void:
	u = p_u


func step(delta: float) -> void:
	match state:
		State.PENDING:
			t -= delta
			if t <= 0.0:
				_spawn()
		State.ACTIVE:
			active_t += delta
			if active_t >= Defs.OPENING_WAVE_LINGER:
				_unmark()
			if alive() == 0:
				state = State.CLEARED
				var planet := u.sectors[u.hq.sector].planet_name
				u.message.emit("Scouts destroyed! They came from %s: fly there and land to strike the Hive Core" % planet, Defs.faction_color(Defs.Faction.PLAYER))


## Live ships of the wave.
func alive() -> int:
	var n := 0
	for id: int in ids:
		var e := u.get_ent(id)
		if e != null and e.alive:
			n += 1
	return n


## Combat filter (Universe.valid_target): sortie scouts and everything other than the
## player's own ships and warships ignore each other.
static func allows(e: SimEntity, t: SimEntity) -> bool:
	if t is ShipData and (t as ShipData).sortie:
		return _wing(e)
	if e is ShipData and (e as ShipData).sortie:
		return _wing(t)
	return true


static func _wing(x: SimEntity) -> bool:
	return x is ShipData and x.faction == Defs.Faction.PLAYER and ((x as ShipData).role == "combat" or (x as ShipData).is_player)


## Where the wave appears: OPENING_WAVE_RANGE ahead of the player (along its velocity, or
## away from the HQ / toward Ember when it is parked), leaning toward Ember's orbit.
func spawn_point() -> Vector3:
	var sec := u.sectors[u.hq.sector]
	var orbit := sec.planet_pos.normalized() * (Defs.PLANET_DIST - Defs.PLANET_RADIUS - Defs.OPENING_WAVE_ORBIT)
	var ps := u.player_ship
	var home := ps != null and ps.alive and ps.sector == sec.idx
	var from := ps.pos if home else u.hq.pos
	var dir := (orbit - from).normalized()
	if home and ps.vel.length() > 40.0:
		dir = (ps.vel.normalized() * 2.0 + dir).normalized()
	elif from.distance_to(u.hq.pos) > 300.0:
		dir = ((from - u.hq.pos).normalized() + dir).normalized()
	return from + dir * Defs.OPENING_WAVE_RANGE


func _unmark() -> void:
	for id: int in ids:
		var e := u.get_ent(id)
		if e is ShipData:
			(e as ShipData).sortie = false


func _spawn() -> void:
	if u.hq == null or not u.hq.alive:
		state = State.CLEARED
		return
	state = State.ACTIVE
	spawn_count += 1
	rng.seed = u.rng.seed + 18
	var sidx := u.hq.sector
	var base := spawn_point()
	var side := base.cross(Vector3.UP).normalized()
	for i in Defs.OPENING_WAVE_SIZE:
		# Fixed offsets (no randf here) keep the wave identical across runs of a seed.
		var p := base + side * (float(i) - float(Defs.OPENING_WAVE_SIZE - 1) * 0.5) * 140.0 + Vector3(0, 30.0 * float(i % 2), 0)
		var d := u.spawn_ship("drone", Defs.Faction.HIVE, sidx, p)
		d.sortie = true
		d.orbit_sign = 1.0 if rng.randf() < 0.5 else -1.0
		d.hull_max *= Defs.OPENING_WAVE_HULL
		d.hull = d.hull_max
		d.dps *= Defs.OPENING_WAVE_DPS
		d.display_name = "Hive Scout"
		# Hunt the player; if the player is away/dead, ShipAI drops them to a home patrol where
		# allows() limits them to the player's warships.
		var ps := u.player_ship
		if ps != null and ps.alive and ps.sector == sidx:
			d.order = "attack"
			d.order_target = ps.id
		else:
			d.order = "patrol"
		d.order_sector = sidx
		ids.append(d.id)
	var sec := u.sectors[sidx]
	u.message.emit("HIVE SCOUTS inbound from %s: %d drones hunting your wing!" % [sec.planet_name, Defs.OPENING_WAVE_SIZE], Defs.faction_color(Defs.Faction.HIVE))
