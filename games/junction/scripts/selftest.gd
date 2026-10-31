extends SceneTree


func _init() -> void:
	var Y := preload("res://scripts/yard.gd")
	var sw: Dictionary = {"S1": false, "S2": false, "S3": false, "S4": false}
	assert(Y.destination(sw) == 0)
	assert(Y.destination({"S1": false, "S2": true, "S4": true}) == 2)
	assert(Y.destination({"S1": true, "S3": true}) == 4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for t in 5:
		for n in 6:
			var s: Dictionary = {}
			for id in Y.SWITCH_IDS:
				s[id] = rng.randf() < 0.5
			for id in Y.flips_needed(s, t):
				s[id] = not s[id]
			assert(Y.destination(s) == t)
			assert(Y.flips_needed(s, t).is_empty())
	assert(is_equal_approx(Y.spawn_interval(0), 4.2))
	assert(is_equal_approx(Y.spawn_interval(1000), 1.5))
	assert(is_equal_approx(Y.train_speed(0), 110.0))
	assert(is_equal_approx(Y.train_speed(1000), 270.0))
	assert(Y.active_colours(0) == 3 and Y.active_colours(6) == 4 and Y.active_colours(16) == 5)
	assert(Y.active_colours(5) == 3 and Y.active_colours(15) == 4)
	assert(Y.multiplier(0) == 1 and Y.multiplier(4) == 2 and Y.multiplier(100) == 5)
	assert(Y.wants_right("S1", 4) == 1 and Y.wants_right("S1", 0) == 0 and Y.wants_right("S4", 0) == -1)
	assert(Y.active_stations(0).size() == 3 and not Y.is_active(1, 0) and Y.is_active(1, 6))
	var ep := Y.edge_points("S1", "S2")
	assert(ep.size() == 3 and ep[0] == Y.pos("S1") and ep[2] == Y.pos("S2"))
	var tr := Train.new()
	tr.set_edge("entry", "S1")
	assert(not tr.advance(0.1, 100.0))
	assert(tr.advance(10.0, 100.0))
	print("SELFTEST OK")
	quit()
