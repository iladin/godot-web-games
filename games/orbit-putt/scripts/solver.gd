class_name Solver
extends RefCounted
## Brute-force shot finder used by --autoplay and the selftest.

const SOLVER_ANGLES := 24
const SOLVER_POWERS := 4
const SOLVER_STEPS := 300
const REFINE_ROUNDS := 2


static func _score(res: Dictionary, cup: Vector2) -> float:
	if res["result"] == "sink":
		return -1.0
	var s: float = (res["pos"] as Vector2).distance_to(cup)
	if res["result"] == "crash" or res["result"] == "lost":
		s += 10000.0
	return s


## Returns Vector2(angle, power); power is always >= 0.25 so it clears the drag deadzone.
static func best_shot(pos: Vector2, bodies: Array, t: float, cup: Vector2, cup_r: float) -> Vector2:
	var best := Vector2(0.0, 0.5)
	var best_s := INF
	var step_a := TAU / SOLVER_ANGLES
	for ai in SOLVER_ANGLES:
		for pi in SOLVER_POWERS:
			var a := ai * step_a
			var pw := float(pi + 1) / SOLVER_POWERS
			var s := _eval(pos, bodies, t, cup, cup_r, a, pw)
			if s < best_s:
				best_s = s
				best = Vector2(a, pw)
			if s < 0.0:
				return best
	var da := step_a * 0.5
	var dp := 0.125
	for _round in REFINE_ROUNDS:
		var centre := best
		for oa in [-1.0, -0.5, 0.5, 1.0]:
			for op in [-1.0, 0.0, 1.0]:
				var a: float = centre.x + oa * da
				var pw: float = clampf(centre.y + op * dp, 0.25, 1.0)
				var s := _eval(pos, bodies, t, cup, cup_r, a, pw)
				if s < best_s:
					best_s = s
					best = Vector2(a, pw)
				if s < 0.0:
					return best
		da *= 0.4
		dp *= 0.5
	return best


static func _eval(pos: Vector2, bodies: Array, t: float, cup: Vector2, cup_r: float, a: float, pw: float) -> float:
	var res := OrbitPhysics.simulate(pos, OrbitPhysics.shot_velocity(a, pw), bodies, t, SOLVER_STEPS, cup, cup_r, false)
	return _score(res, cup)
