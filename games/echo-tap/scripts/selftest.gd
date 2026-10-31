extends SceneTree
## Logic assertions for Echo Tap. Run: godot --headless --path games/echo-tap --script res://scripts/selftest.gd

const L := preload("res://scripts/echo_logic.gd")
var failures := 0


func expect(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		print("SELFTEST FAIL: ", msg)


func _init() -> void:
	expect(L.judge(0.03, 0.14) == L.JUDGE_PERFECT, "0.03 is perfect")
	expect(L.judge(-0.1, 0.14) == L.JUDGE_GOOD, "-0.1 is good")
	expect(L.judge(0.2, 0.14) == L.JUDGE_MISS, "0.2 is miss")
	expect(L.length_for_round(1) == 3, "len r1")
	expect(L.length_for_round(50) == 12, "len r50")
	expect(L.bpm_for_round(1) == 90.0, "bpm r1")
	expect(L.bpm_for_round(100) == 170.0, "bpm r100")
	expect(is_equal_approx(L.bpm_for_round(2), 94.0), "bpm r2")
	expect(L.multiplier(0) == 1.0, "mult 0")
	expect(L.multiplier(20) == 3.0, "mult 20")
	expect(L.good_window_for_round(9) == 0.14 and L.good_window_for_round(10) == 0.11, "tight window")
	expect(L.note_points(L.JUDGE_PERFECT) == 100 and L.clear_bonus(4, true) == 400, "scoring")
	expect(L.pad_for_point(Vector2(360, 500), Vector2(360, 700), 110.0) == 0, "top pad")
	expect(L.pad_for_point(Vector2(600, 700), Vector2(360, 700), 110.0) == 1, "right pad")
	expect(L.pad_for_point(Vector2(360, 900), Vector2(360, 700), 110.0) == 2, "bottom pad")
	expect(L.pad_for_point(Vector2(100, 700), Vector2(360, 700), 110.0) == 3, "left pad")
	expect(L.pad_for_point(Vector2(380, 710), Vector2(360, 700), 110.0) == -1, "hub ignored")

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var p: Array = L.make_phrase(rng, 6)
	expect(p.size() == 8, "round 6 has 8 notes")
	_check_phrase(p, "r6")
	for r in range(1, 40):
		for s in 20:
			rng.seed = s
			var ph: Array = L.make_phrase(rng, r)
			expect(ph.size() == L.length_for_round(r), "length r%d" % r)
			_check_phrase(ph, "r%d s%d" % [r, s])
			if r < L.EIGHTH_FROM_ROUND:
				for n in ph:
					expect(fmod(float(n["beat"]), 1.0) == 0.0, "no eighths before round 4")

	if failures == 0:
		print("SELFTEST OK")
	quit(failures)


func _check_phrase(ph: Array, tag: String) -> void:
	var run := 1
	for i in ph.size():
		var pad: int = ph[i]["pad"]
		expect(pad >= 0 and pad <= 3, "pad range " + tag)
		if i > 0:
			expect(float(ph[i]["beat"]) > float(ph[i - 1]["beat"]), "beats increase " + tag)
			run = run + 1 if pad == int(ph[i - 1]["pad"]) else 1
			expect(run <= 3, "pad run " + tag)
