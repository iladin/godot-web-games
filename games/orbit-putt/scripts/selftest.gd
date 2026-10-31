extends SceneTree
## Pure-logic assertions for Orbit Putt. check.sh requires the SELFTEST OK line.

var failures := 0


func expect(cond: bool, what: String) -> void:
	if not cond:
		failures += 1
		print("SELFTEST FAIL: ", what)


func _init() -> void:
	var planet := {"pos": Vector2.ZERO, "r": 50.0, "strength": 1.0, "kind": 0, "moon": false}
	var a := OrbitPhysics.accel_at(Vector2(0, -200), [planet], 0.0)
	expect(a.y > 0.0 and absf(a.x) < 0.001, "gravity points toward planet")
	expect(absf(a.length() - OrbitPhysics.GRAVITY_K * 2500.0 / 40000.0) < 0.01, "gravity magnitude K*r^2/d^2")
	var rep := planet.duplicate()
	rep["strength"] = -1.0
	expect(OrbitPhysics.accel_at(Vector2(0, -200), [rep], 0.0).y < 0.0, "repulsor pushes away")

	var wall := {"pos": Vector2(360, 640), "r": 60.0, "strength": 1.0, "kind": 0, "moon": false}
	var res := OrbitPhysics.simulate(Vector2(360, 1000), Vector2(0, -500), [wall], 0.0, 600, Vector2(60, 60), 30.0)
	expect(res["result"] == "crash", "ball fired at planet crashes (got %s)" % res["result"])
	res = OrbitPhysics.simulate(Vector2(360, 600), Vector2(0, -500), [], 0.0, 600, Vector2(360, 400), 30.0)
	expect(res["result"] == "sink", "ball fired at cup sinks (got %s)" % res["result"])
	res = OrbitPhysics.simulate(Vector2(360, 600), Vector2(900, 0), [], 0.0, 600, Vector2(60, 60), 30.0)
	expect(res["result"] == "lost", "ball leaving the screen is lost (got %s)" % res["result"])

	expect(OrbitPhysics.result_name(1, 3) == "Hole-in-one", "hole-in-one")
	expect(OrbitPhysics.result_name(2, 3) == "Birdie", "birdie")
	expect(OrbitPhysics.result_name(3, 3) == "Par", "par")
	expect(OrbitPhysics.result_name(5, 3) == "Double", "double")

	for i in Course.count():
		var h := Course.hole(i)
		var pos: Vector2 = h["tee"]
		var origin := pos
		var t := 0.0
		var strokes := 0
		var sunk := false
		var par: int = h["par"]
		while strokes < par + 2 and not sunk:
			var shot := Solver.best_shot(pos, h["bodies"], t, h["cup"], h["cup_r"])
			var sim := OrbitPhysics.simulate(pos, OrbitPhysics.shot_velocity(shot.x, shot.y), h["bodies"], t,
				int(OrbitPhysics.MAX_FLIGHT / OrbitPhysics.DT), h["cup"], h["cup_r"], false)
			strokes += 1
			t += sim["steps"] * OrbitPhysics.DT + 0.5
			match sim["result"]:
				"sink": sunk = true
				"crash", "lost":
					strokes += 1
					pos = origin
				_:
					pos = sim["pos"]
					origin = pos
		expect(sunk, "hole %d solvable within par+2 (par %d, used %d)" % [i + 1, par, strokes])

	if failures == 0:
		print("SELFTEST OK")
	else:
		print("SELFTEST FAILED: %d" % failures)
	quit(1 if failures > 0 else 0)
