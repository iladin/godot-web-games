extends SceneTree
## Logic assertions for Lantern Run. Run: godot --headless --script res://scripts/selftest.gd

const R := preload("res://scripts/runner_logic.gd")


func _check(cond: bool, msg: String) -> void:
	if not cond:
		push_error("SELFTEST FAIL: " + msg)
		print("SELFTEST FAILED: " + msg)
		quit(1)


func _init() -> void:
	_check(R.drain_light(100.0, 20.0, 1.0) == 80.0, "drain_light basic")
	_check(R.drain_light(65.0, 20.0, 1.0) == R.LIGHT_MIN, "drain_light clamps at LIGHT_MIN")
	_check(R.add_oil(R.LIGHT_MAX - 10.0) == R.LIGHT_MAX, "add_oil caps at LIGHT_MAX")
	_check(R.add_oil(200.0) == 200.0 + R.OIL_LIGHT_GAIN, "add_oil adds gain")
	_check(R.speed_at(0.0) == R.SPEED_START, "speed_at(0)")
	_check(R.speed_at(10000.0) == R.SPEED_MAX, "speed_at caps")
	_check(R.speed_at(10.0) == R.SPEED_START + 10.0 * R.SPEED_RAMP, "speed ramps")
	var ground: Array = [Vector2(0, 100), Vector2(200, 400)]
	_check(R.is_over_pit(150.0, ground), "150 is over the pit")
	_check(not R.is_over_pit(50.0, ground), "50 is on ground")
	_check(R.gap_at(0.0, 320.0) == R.GAP_START, "gap at start")
	_check(R.gap_at(10000.0, 720.0) == 720.0 * 0.45, "gap scales with speed floor")
	_check(R.gap_at(10000.0, 320.0) == R.GAP_MIN, "gap min")
	_check(R.pit_range_at(10.0).y == R.PIT_MAX_EARLY and R.pit_range_at(50.0).y == R.PIT_MAX_LATE, "pit width grows")
	_check(R.oil_every(0.0) == 3 and R.oil_every(61.0) == 5, "oil cadence")
	_check(R.score_for(1000.0, 2, 1) == 100 + 100 + 200, "score_for")
	_check(R.hits_stalag(500.0, R.GROUND_Y, 500.0, 50.0), "standing in stalagmite hits")
	_check(not R.hits_stalag(500.0, R.GROUND_Y - 80.0, 500.0, 50.0), "jumping over stalagmite is safe")
	_check(not R.hits_stalag(600.0, R.GROUND_Y, 500.0, 50.0), "far away is safe")
	var tip := R.GROUND_Y - R.SPIKE_TIP_H
	_check(not R.hits_spike(500.0, R.GROUND_Y, 500.0, tip), "running under spike is safe")
	_check(R.hits_spike(500.0, R.GROUND_Y - 200.0, 500.0, tip), "high jump hits spike")
	print("SELFTEST OK")
	quit()
