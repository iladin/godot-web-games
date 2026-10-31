extends RefCounted
## Opcode game model: screens, program editing, running, progress and saving.
## Every action is a text command (act) and everything visible is in observe(), so humans,
## the bot and AI agents all drive the same code path.

const VM := preload("res://scripts/vm.gd")
const Puzzles := preload("res://scripts/puzzles.gd")

enum Screen { TITLE, SELECT, EDIT, WIN }

# --- Tunables ---------------------------------------------------------------
const MAX_LINES := 30
const UNLOCK_AHEAD := 3          # how many unsolved puzzles are open at once
const SAVE_PATH := "user://save.cfg"

signal event(kind: String, data: Dictionary)

var screen: Screen = Screen.TITLE
var puzzle: int = 0
var program: PackedStringArray = []
var cursor: int = -1             # inserts go after this line (-1 = at the top)
var programs: Dictionary = {}    # puzzle -> PackedStringArray
var best: Dictionary = {}        # puzzle -> {"size": int, "cycles": int}
var solved: Dictionary = {}      # puzzle -> true
var machine: Dictionary = {}     # VM state of test 1 while stepping/animating ({} = editing)
var code: Array[Dictionary] = []
var animating: bool = false
var result: Dictionary = {}      # last run outcome; non-empty = overlay showing
var win_shown: bool = false
var persist: bool = true


func _init(load_save: bool = true) -> void:
	persist = load_save
	if load_save:
		_load()


# --- Commands ------------------------------------------------------------------
func act(raw: String) -> Dictionary:
	var line := raw.strip_edges()
	var sp := line.find(" ")
	var verb := (line if sp < 0 else line.left(sp)).to_lower()
	var rest := "" if sp < 0 else line.substr(sp + 1).strip_edges()
	match verb:
		"start", "menu", "select":
			stop()
			result = {}
			screen = Screen.SELECT
			event.emit("screen", {})
			return _ok("Puzzle select. %d/%d stars. Use 'open N'." % [total_stars(), Puzzles.count() * 3])
		"open", "puzzle":
			if not rest.is_valid_int():
				return _err("Usage: open N  (1-%d)" % Puzzles.count())
			return open(int(rest) - 1)
		"next":
			if screen == Screen.TITLE or screen == Screen.WIN:
				return act("start")
			return open(puzzle + 1)
		"isa", "manual":
			return _ok(VM.ISA_HELP)
		"reset":
			if rest.to_lower() == "progress":
				programs.clear()
				best.clear()
				solved.clear()
				win_shown = false
				_save()
				screen = Screen.SELECT
				return _ok("Progress wiped.")
			return _err("Did you mean 'stop' (stop the machine) or 'reset progress'?")
	if screen != Screen.EDIT:
		return _err("Open a puzzle first: 'open N'.")
	match verb:
		"program", "code":
			return set_program(rest.replace("|", "\n").split("\n", false))
		"insert", "add", "i":
			return insert(rest)
		"delete", "del", "d":
			if rest == "":
				return delete_line(cursor)
			if not rest.is_valid_int():
				return _err("Usage: delete [N]")
			return delete_line(int(rest) - 1)
		"replace":
			var p := rest.split(" ", false, 1)
			if p.size() != 2 or not p[0].is_valid_int():
				return _err("Usage: replace N INSTRUCTION")
			return replace_line(int(p[0]) - 1, p[1])
		"cursor", "line":
			if not rest.is_valid_int():
				return _err("Usage: cursor N  (0 = top)")
			_edit_begin()
			cursor = clampi(int(rest) - 1, -1, program.size() - 1)
			return _ok("Cursor after line %d." % (cursor + 1))
		"up":
			cursor = maxi(cursor - 1, -1)
			return _ok("")
		"down":
			cursor = mini(cursor + 1, program.size() - 1)
			return _ok("")
		"clear":
			_edit_begin()
			program = PackedStringArray()
			cursor = -1
			_store_program()
			return _ok("Program cleared.")
		"list", "show":
			return _ok(listing() if not program.is_empty() else "(empty program)")
		"tests", "test":
			var t: Dictionary = Puzzles.tests(puzzle)[0]
			return _ok("in:  %s\nout: %s" % [str(t.input), str(t.expected)])
		"run", "check", "fast":
			return run_all()
		"step", "s":
			return step()
		"animate", "play":
			if machine.is_empty() and not _begin_machine():
				return _err(str(result.reason))
			animating = true
			result = {}
			return _ok("Running test 1...")
		"stop", "edit":
			stop()
			result = {}
			return _ok("Stopped.")
		"ok", "dismiss", "close":
			stop()
			result = {}
			_maybe_win()
			return _ok("")
	return _err("Unknown command '%s'. Try 'help'." % verb)


func open(i: int) -> Dictionary:
	if i < 0 or i >= Puzzles.count():
		return _err("No puzzle %d (1-%d)." % [i + 1, Puzzles.count()])
	if not is_unlocked(i):
		return _err("Puzzle %d is locked - solve earlier puzzles first." % (i + 1))
	stop()
	result = {}
	puzzle = i
	program = programs.get(i, PackedStringArray())
	cursor = program.size() - 1
	screen = Screen.EDIT
	event.emit("screen", {})
	var pz: Dictionary = Puzzles.all()[i]
	return _ok("%02d %s: %s" % [i + 1, pz.name, pz.task])


func set_program(lines: PackedStringArray) -> Dictionary:
	var clean := PackedStringArray()
	for k in lines.size():
		if lines[k].strip_edges() == "":
			continue
		var p := VM.parse_line(lines[k])
		if not p.ok:
			if p.err == "empty line":
				continue
			return _err("line %d: %s" % [clean.size() + 1, p.err])
		clean.append(p.text)
	if clean.size() > MAX_LINES:
		return _err("Too long: %d lines (max %d)." % [clean.size(), MAX_LINES])
	_edit_begin()
	program = clean
	cursor = program.size() - 1
	_store_program()
	event.emit("edit", {})
	return _ok("Program set: %d lines." % program.size())


func insert(text: String) -> Dictionary:
	var p := VM.parse_line(text)
	if not p.ok:
		return _err(str(p.err))
	if program.size() >= MAX_LINES:
		return _err("Program is full (%d lines)." % MAX_LINES)
	_edit_begin()
	program.insert(cursor + 1, p.text)
	cursor += 1
	_store_program()
	event.emit("edit", {"line": cursor})
	return _ok("%d: %s" % [cursor + 1, p.text])


func delete_line(k: int) -> Dictionary:
	if k < 0 or k >= program.size():
		return _err("No line %d to delete." % (k + 1))
	_edit_begin()
	program.remove_at(k)
	cursor = clampi(k - 1, -1, program.size() - 1)
	_store_program()
	event.emit("edit", {})
	return _ok("Deleted line %d." % (k + 1))


func replace_line(k: int, text: String) -> Dictionary:
	if k < 0 or k >= program.size():
		return _err("No line %d." % (k + 1))
	var p := VM.parse_line(text)
	if not p.ok:
		return _err(str(p.err))
	_edit_begin()
	program[k] = p.text
	cursor = k
	_store_program()
	event.emit("edit", {"line": k})
	return _ok("%d: %s" % [k + 1, p.text])


# --- Running -------------------------------------------------------------------
func run_all() -> Dictionary:
	stop()
	var res := VM.run_all(program, Puzzles.tests(puzzle))
	_finish(res)
	return _ok(_result_text()) if res.ok else _err(_result_text())


func step() -> Dictionary:
	if machine.is_empty():
		if not _begin_machine():
			return _err(str(result.reason))
	animating = false
	result = {}
	VM.step(machine, code)
	if machine.status != "running":
		return _machine_done()
	return _ok("cycle %d  ACC=%d X=%d Y=%d  next line %d" % [machine.cycles, machine.acc, machine.x, machine.y, int(machine.pc) + 1])


## Advance the animated run by n instructions. Called by main every frame.
func tick(n: int) -> void:
	if not animating or machine.is_empty():
		return
	for k in n:
		VM.step(machine, code)
		if machine.status != "running":
			animating = false
			_machine_done()
			return


func stop() -> void:
	machine = {}
	animating = false


func _begin_machine() -> bool:
	var asm := VM.assemble(program)
	if not asm.ok:
		result = {"ok": false, "reason": asm.err, "failed_test": -1, "line": asm.line}
		event.emit("result", result)
		return false
	code = asm.code
	var t: Dictionary = Puzzles.tests(puzzle)[0]
	machine = VM.new_state(t.input, t.expected)
	return true


func _machine_done() -> Dictionary:
	if machine.status == "pass":
		var res := VM.run_all(program, Puzzles.tests(puzzle))
		_finish(res)
	else:
		_finish({"ok": false, "reason": "test 1: %s" % machine.reason, "failed_test": 0, "line": machine.last_pc,
			"size": VM.size_of(code), "cycles": 0, "state": machine.duplicate()})
	return _ok(_result_text()) if result.ok else _err(_result_text())


func _finish(res: Dictionary) -> void:
	var par := Puzzles.par(puzzle)
	result = res.duplicate()
	result["par_size"] = par["size"]
	result["par_cycles"] = par.cycles
	if res.ok:
		var first := not solved.has(puzzle)
		var b: Dictionary = best.get(puzzle, {"size": 9999, "cycles": 99999})
		result["new_size"] = res["size"] < b["size"]
		result["new_cycles"] = res.cycles < b.cycles
		b["size"] = mini(b["size"], res["size"])
		b.cycles = mini(b.cycles, res.cycles)
		best[puzzle] = b
		solved[puzzle] = true
		result["first"] = first
		result["stars"] = stars(puzzle)
		_save()
		event.emit("solved", result)
	else:
		event.emit("result", result)


func _result_text() -> String:
	if result.is_empty():
		return ""
	if result.ok:
		return "SOLVED  cycles %d (par %d)  size %d (par %d)  stars %d/3" % [result.cycles, result.par_cycles, result["size"], result.par_size, stars(puzzle)]
	return "FAILED: %s" % result.reason


func _maybe_win() -> void:
	if solved.size() == Puzzles.count() and not win_shown:
		win_shown = true
		_save()
		screen = Screen.WIN
		event.emit("win", {})


func _edit_begin() -> void:
	stop()
	result = {}


# --- Queries -------------------------------------------------------------------
func is_unlocked(i: int) -> bool:
	return solved.has(i) or i < solved.size() + UNLOCK_AHEAD


func stars(i: int) -> int:
	if not solved.has(i):
		return 0
	var par := Puzzles.par(i)
	var b: Dictionary = best[i]
	return 1 + (1 if b["size"] <= par["size"] else 0) + (1 if b.cycles <= par.cycles else 0)


func total_stars() -> int:
	var n := 0
	for i in Puzzles.count():
		n += stars(i)
	return n


func listing() -> String:
	var out := PackedStringArray()
	for k in program.size():
		out.append("%2d  %s" % [k + 1, program[k]])
	return "\n".join(out)


func screen_name() -> String:
	return ["title", "select", "edit", "win"][screen]


func observe() -> Dictionary:
	var o := {"game": "opcode", "screen": screen_name(), "stars": total_stars(), "max_stars": Puzzles.count() * 3,
		"isa": VM.ISA_HELP}
	var list: Array = []
	for i in Puzzles.count():
		var pz: Dictionary = Puzzles.all()[i]
		list.append({"number": i + 1, "name": pz.name, "unlocked": is_unlocked(i), "stars": stars(i)})
	o["puzzles"] = list
	if screen == Screen.EDIT:
		var pz: Dictionary = Puzzles.all()[puzzle]
		var par := Puzzles.par(puzzle)
		var t: Dictionary = Puzzles.tests(puzzle)[0]
		o["puzzle"] = {"number": puzzle + 1, "name": pz.name, "task": pz.task, "par_size": par["size"],
			"par_cycles": par.cycles, "test_1": {"input": t.input, "expected": t.expected},
			"hidden_tests": Puzzles.TESTS_PER_PUZZLE - 1, "best": best.get(puzzle, {}), "stars": stars(puzzle)}
		o["program"] = Array(program)
		o["cursor_after_line"] = cursor + 1
		if not machine.is_empty():
			o["machine"] = {"acc": machine.acc, "x": machine.x, "y": machine.y, "next_line": int(machine.pc) + 1,
				"cycles": machine.cycles, "inputs_read": machine.in_ptr, "output": machine.out, "status": machine.status}
		if not result.is_empty():
			o["result"] = {"ok": result.ok, "text": _result_text()}
	o["commands"] = ["open N", "program L1 | L2 | ...", "insert I", "delete N", "replace N I", "cursor N", "run", "step", "stop", "list", "next", "menu", "isa"]
	return o


# --- Save ----------------------------------------------------------------------
func _store_program() -> void:
	programs[puzzle] = program
	_save()


func _save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	for i: int in programs:
		cfg.set_value("p%d" % i, "program", "\n".join(programs[i]))
	for i: int in best:
		cfg.set_value("p%d" % i, "best_size", best[i]["size"])
		cfg.set_value("p%d" % i, "best_cycles", best[i]["cycles"])
	for i: int in solved:
		cfg.set_value("p%d" % i, "solved", true)
	cfg.set_value("meta", "win_shown", win_shown)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	win_shown = bool(cfg.get_value("meta", "win_shown", false))
	for i in Puzzles.count():
		var sec := "p%d" % i
		if not cfg.has_section(sec):
			continue
		var text: String = cfg.get_value(sec, "program", "")
		if text != "":
			programs[i] = text.split("\n", false)
		if cfg.get_value(sec, "solved", false):
			solved[i] = true
			best[i] = {"size": int(cfg.get_value(sec, "best_size", 9999)), "cycles": int(cfg.get_value(sec, "best_cycles", 99999))}


func _ok(msg: String) -> Dictionary:
	return {"ok": true, "msg": msg}


func _err(msg: String) -> Dictionary:
	return {"ok": false, "msg": msg}
