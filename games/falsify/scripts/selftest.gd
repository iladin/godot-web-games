extends SceneTree
## Logic checks for Falsify: rules, analysis, and full games played through the text API.

const Rules := preload("res://scripts/rules.gd")
const Lab := preload("res://scripts/lab.gd")


func _init() -> void:
	var rs := Rules.simple_rules()
	var by_id := {}
	for r in rs:
		by_id[r.id] = r
	assert(Rules.triple_of(Rules.index_of(3, 14, 0)) == Vector3i(3, 14, 0))
	assert(Rules.fits(by_id["inc"], 2, 4, 6))
	assert(not Rules.fits(by_id["inc"], 2, 2, 6))
	assert(Rules.fits(by_id["arith"], 3, 6, 9))
	assert(Rules.fits(by_id["sum_ab"], 3, 4, 7))
	assert(Rules.fits(by_id["has_mul5"], 1, 10, 3) and not Rules.fits(by_id["has_mul5"], 0, 1, 2))
	var c := Rules.combine(by_id["inc"], by_id["all_even"], "and")
	assert(Rules.fits(c, 2, 4, 6) and not Rules.fits(c, 1, 2, 3))
	var o := Rules.combine(by_id["all_even"], by_id["all_odd"], "or")
	assert(Rules.table(o) == Rules.table(by_id["same_parity"]))
	# par: 4 rules where single tests can split 2/2 -> par 2
	var four: Array[PackedByteArray] = [Rules.table(by_id["inc"]), Rules.table(by_id["all_even"]), Rules.table(by_id["sum_even"]), Rules.table(by_id["distinct"])]
	var masks := Rules.split_masks(four)
	assert(Rules.par(15, masks, {}) == 2)
	assert(Rules.par(1, masks, {}) == 0)

	# Whole games: the minimax bot must always win, and commands must validate input.
	var t0 := Time.get_ticks_msec()
	for s in 6:
		var lab := Lab.new(4242 + s)
		assert(not lab.act("test 1 2 3").ok)
		assert(lab.act("start").ok)
		assert(lab.candidates.size() == Lab.ROUND_SIZES[0])
		assert(not lab.act("test 1 2 99").ok)
		assert(not lab.act("name Z").ok)
		assert(not lab.act("dance").ok)
		var guard := 0
		while lab.phase != Lab.Phase.WIN and lab.phase != Lab.Phase.GAME_OVER and guard < 400:
			guard += 1
			if lab.phase == Lab.Phase.TESTING:
				# every hypothesis fits the seed triple
				for k in lab.candidates.size():
					assert(lab.tables[k][Rules.index_of(lab.seed_triple.x, lab.seed_triple.y, lab.seed_triple.z)] == 1)
			var cmd := lab.bot_command()
			var res: Dictionary = lab.act(cmd)
			assert(res.ok, "bot command failed: %s -> %s" % [cmd, res.msg])
		assert(lab.phase == Lab.Phase.WIN, "minimax bot lost on seed %d" % s)
		print("seed %d: score %d funding %d" % [s, lab.score, lab.funding])
	print("6 games in %d ms" % (Time.get_ticks_msec() - t0))

	# A careless scientist (only re-tests the seed) must eventually lose.
	var lab2 := Lab.new(7)
	lab2.act("start")
	var g := 0
	while lab2.phase == Lab.Phase.TESTING and g < 50:
		g += 1
		var st := lab2.seed_triple
		if lab2.funding >= 1:
			lab2.act("test %d %d %d" % [st.x, st.y, st.z])
		else:
			for k in lab2.candidates.size():
				if lab2.alive[k] and k != lab2.secret:
					lab2.act("name %s" % Lab.LETTERS[k])
					break
	assert(lab2.phase == Lab.Phase.GAME_OVER)
	assert(lab2.observe().has("end"))
	print("SELFTEST OK")
	quit()
