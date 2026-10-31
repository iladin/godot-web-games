class_name OrbitPhysics
extends RefCounted
## Pure orbit physics: no nodes, no globals. Bodies are Dictionaries:
## {pos, r, strength, kind(0 planet,1 repulsor,2 moon), moon, center, orbit_r, speed, phase}

const WORLD := Vector2(720.0, 1280.0)
const GRAVITY_K := 1400.0      # accel at planet surface (px/s^2): K * strength * r^2 / d^2
const MIN_ACCEL_DIST := 40.0   # clamp d to avoid singularities
const REPULSOR_STRENGTH := -0.8
const MOON_GAP := 70.0
const MOON_SPEED := 0.6
const MOON_STRENGTH := 0.5
const LINEAR_DAMP := 0.35      # per second
const MIN_SHOT := 180.0
const MAX_SHOT := 950.0
const BALL_RADIUS := 11.0
const SINK_MAX_SPEED := 900.0
const STOP_SPEED := 22.0
const MIN_FLIGHT := 0.4
const MAX_FLIGHT := 6.0
const OOB_MARGIN := 90.0
const DT := 1.0 / 60.0


static func body_pos(b: Dictionary, t: float) -> Vector2:
	if b.get("moon", false):
		var c: Vector2 = b["center"]
		return c + Vector2.from_angle(float(b["phase"]) + t * float(b["speed"])) * float(b["orbit_r"])
	return b["pos"]


static func accel_at(p: Vector2, bodies: Array, t: float) -> Vector2:
	var a := Vector2.ZERO
	for b in bodies:
		var d: Dictionary = b
		var delta: Vector2 = body_pos(d, t) - p
		var dist: float = maxf(delta.length(), MIN_ACCEL_DIST)
		var r: float = d["r"]
		var k: float = d["strength"]
		a += delta / dist * (GRAVITY_K * k * r * r / (dist * dist))
	return a


## Semi-implicit Euler. Returns [pos, vel].
static func step(pos: Vector2, vel: Vector2, bodies: Array, t: float, dt: float) -> Array:
	var v: Vector2 = vel + accel_at(pos, bodies, t) * dt
	v *= 1.0 - LINEAR_DAMP * dt
	return [pos + v * dt, v]


## "sink", "crash", "lost" or "" (still flying). t is the time AFTER the step.
static func judge(pos: Vector2, vel: Vector2, bodies: Array, t: float, cup: Vector2, cup_r: float) -> String:
	for b in bodies:
		var d: Dictionary = b
		if pos.distance_to(body_pos(d, t)) < float(d["r"]) + BALL_RADIUS:
			return "crash"
	if pos.distance_to(cup) < cup_r and vel.length() < SINK_MAX_SPEED:
		return "sink"
	if pos.x < -OOB_MARGIN or pos.y < -OOB_MARGIN or pos.x > WORLD.x + OOB_MARGIN or pos.y > WORLD.y + OOB_MARGIN:
		return "lost"
	return ""


static func is_rest(vel: Vector2, flight_t: float) -> bool:
	return (flight_t >= MIN_FLIGHT and vel.length() < STOP_SPEED) or flight_t >= MAX_FLIGHT


static func simulate(pos: Vector2, vel: Vector2, bodies: Array, t0: float, max_steps: int,
		cup: Vector2, cup_r: float, with_path: bool = true) -> Dictionary:
	var path := PackedVector2Array()
	var p := pos
	var v := vel
	var result := "rest"
	var i := 0
	while i < max_steps:
		var r := step(p, v, bodies, t0 + i * DT, DT)
		p = r[0]
		v = r[1]
		i += 1
		if with_path:
			path.append(p)
		var j := judge(p, v, bodies, t0 + i * DT, cup, cup_r)
		if j != "":
			result = j
			break
		if is_rest(v, i * DT):
			break
	return {"result": result, "pos": p, "vel": v, "steps": i, "path": path}


static func shot_velocity(angle: float, power: float) -> Vector2:
	return Vector2.from_angle(angle) * lerpf(MIN_SHOT, MAX_SHOT, power)


static func result_name(strokes: int, par: int) -> String:
	if strokes <= 1:
		return "Hole-in-one"
	match strokes - par:
		-1: return "Birdie"
		0: return "Par"
		1: return "Bogey"
		2: return "Double"
	return "Eagle" if strokes < par else "Triple+"
