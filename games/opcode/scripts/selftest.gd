extends SceneTree
## Logic checks for Opcode: parser, VM semantics, every reference solution, and a full
## playthrough via text commands.

const VM := preload("res://scripts/vm.gd")
const Puzzles := preload("res://scripts/puzzles.gd")
const Game := preload("res://scripts/game.gd")


func _init() -> void:
	# Parser
	assert(VM.parse_line("add x").text == "ADD X")
	assert(VM.parse_line("  lda -7 ; comment").text == "LDA -7")
	assert(VM.parse_line("B:").text == "LBL B")
	assert(not VM.parse_line("STA 5").ok)
	assert(not VM.parse_line("JMP G").ok)
	assert(not VM.parse_line("ADD 100").ok)
	assert(not VM.parse_line("FOO").ok)
	assert(not VM.assemble(PackedStringArray(["JMP A"])).ok)
	assert(not VM.assemble(PackedStringArray(["LBL A", "LBL A", "OUT"])).ok)
	assert(not VM.assemble(PackedStringArray(["LBL A"])).ok)

	# VM semantics: wrap-around, labels are free, wrong output fails fast, timeouts.
	var echo := VM.run_all(PackedStringArray(["IN", "LBL A", "OUT"]), [{"input": [1, 2], "expected": [1, 2]}])
	assert(echo.ok and echo.cycles == 4 and echo["size"] == 2)
	var wrong := VM.run_all(PackedStringArray(["IN", "ADD 1", "OUT"]), [{"input": [1, 2], "expected": [1, 2]}])
	assert(not wrong.ok and wrong.reason.contains("output #1"))
	var starve := VM.run_all(PackedStringArray(["IN", "JEZ A", "OUT", "LBL A"]), [{"input": [0, 0], "expected": [5]}])
	assert(not starve.ok and starve.reason.contains("no input left"))
	var spin := VM.run_all(PackedStringArray(["LBL A", "JMP A"]), [{"input": [1], "expected": [1]}])
	assert(not spin.ok and spin.reason.contains("timed out"))
	var swp := VM.run_all(PackedStringArray(["IN", "SWP X", "LDA 9", "SWP X", "OUT"]), [{"input": [4], "expected": [4]}])
	assert(swp.ok)

	# Every reference program solves its puzzle; pars are what the UI promises.
	for i in Puzzles.count():
		var res := VM.run_all(Puzzles.ref_lines(i), Puzzles.tests(i))
		assert(res.ok, "reference for puzzle %d (%s) fails: %s" % [i + 1, Puzzles.all()[i].name, res.reason])
		var par := Puzzles.par(i)
		assert(par.ok and par["size"] > 0 and par.cycles > 0)
		for t: Dictionary in Puzzles.tests(i):
			assert(not (t.expected as Array).is_empty(), "puzzle %d has an empty test" % (i + 1))
		print("%02d %-14s par size %2d  cycles %4d" % [i + 1, Puzzles.all()[i].name, par["size"], par.cycles])

	# Full playthrough through the command API (no save file).
	var g := Game.new(false)
	assert(not g.act("run").ok)
	assert(g.act("start").ok)
	assert(not g.act("open 9").ok)       # locked
	assert(g.act("open 1").ok)
	assert(g.act("insert IN").ok)
	assert(g.act("insert OUT").ok)
	assert(g.program.size() == 2)
	assert(g.act("cursor 0").ok and g.act("insert LBL A").ok and g.program[0] == "LBL A")
	assert(g.act("delete 1").ok and g.program[0] == "IN")
	assert(not g.act("insert WAT").ok)
	for k in 3:
		assert(g.act("step").ok)
	assert(int(g.machine.cycles) == 3)
	assert(g.act("run").ok and g.solved.has(0))
	assert(g.stars(0) == 3)
	for i in Puzzles.count():
		assert(g.act("open %d" % (i + 1)).ok, "could not open %d" % (i + 1))
		assert(g.act("program " + str(Puzzles.all()[i].ref).replace("\n", " | ")).ok)
		var r := g.act("run")
		assert(r.ok, "puzzle %d: %s" % [i + 1, r.msg])
		assert(g.stars(i) == 3)
		g.act("ok")
	assert(g.screen == Game.Screen.WIN)
	assert(g.total_stars() == Puzzles.count() * 3)
	# A deliberately bloated solution solves but misses the size star.
	var g2 := Game.new(false)
	g2.act("start")
	g2.act("open 2")
	g2.act("program IN | ADD 2 | ADD 3 | OUT")
	assert(g2.act("run").ok and g2.stars(1) == 1)
	print("SELFTEST OK")
	quit()
