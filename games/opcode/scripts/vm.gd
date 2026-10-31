extends RefCounted
## The Opcode machine: one accumulator (ACC), two registers (X, Y), an input tape and an
## output tape. Pure logic: parse, assemble, step, run. Shared by game, bot and selftest.
##
##   IN        ACC <- next input (no input left = the run fails)
##   OUT       write ACC to the output
##   NEG       ACC <- -ACC
##   LDA s     ACC <- s          s = X, Y or a number -99..99
##   STA r     r <- ACC          r = X or Y
##   SWP r     swap ACC and r
##   ADD s     ACC <- ACC + s
##   SUB s     ACC <- ACC - s
##   JMP L     jump to label L (A-F); JEZ/JNZ/JGZ/JLZ jump if ACC =0 / !=0 / >0 / <0
##   LBL L     define label L (free: no cycle, not counted in size)
## Falling off the last line wraps to the first. Every instruction except LBL takes 1 cycle.

const MAX_CYCLES := 4000
const VALUE_LIMIT := 999
const LIT_MIN := -99
const LIT_MAX := 99
const LABELS := "ABCDEF"
## op -> operand kind: "" none, "src" register or number, "reg" register, "lbl" label
const OPS := {
	"IN": "", "OUT": "", "NEG": "",
	"LDA": "src", "STA": "reg", "SWP": "reg", "ADD": "src", "SUB": "src",
	"JMP": "lbl", "JEZ": "lbl", "JNZ": "lbl", "JGZ": "lbl", "JLZ": "lbl", "LBL": "lbl",
}
const OP_ORDER: Array[String] = ["IN", "OUT", "NEG", "LDA", "STA", "SWP", "ADD", "SUB", "JMP", "JEZ", "JNZ", "JGZ", "JLZ", "LBL"]
const ISA_HELP := "IN | OUT | NEG | LDA s | STA r | SWP r | ADD s | SUB s | JMP L | JEZ L | JNZ L | JGZ L | JLZ L | LBL L\ns = X, Y or -99..99   r = X or Y   L = A-F\nLBL is free. The last line wraps to the first."


## Parse one line. Returns {"ok", "op", "arg" (String: "X"/"Y"/"A".. or number text), "text", "err"}.
static func parse_line(raw: String) -> Dictionary:
	var s := raw
	for c in [";", "#"]:
		var at := s.find(c)
		if at >= 0:
			s = s.left(at)
	s = s.strip_edges().to_upper().replace(",", " ")
	if s == "":
		return {"ok": false, "err": "empty line"}
	if s.ends_with(":") and s.length() == 2:
		s = "LBL " + s.left(1)
	var parts := s.split(" ", false)
	var op := parts[0]
	if not OPS.has(op):
		return {"ok": false, "err": "unknown instruction '%s'" % op}
	var kind: String = OPS[op]
	if kind == "":
		if parts.size() != 1:
			return {"ok": false, "err": "%s takes no operand" % op}
		return {"ok": true, "op": op, "arg": "", "text": op}
	if parts.size() != 2:
		return {"ok": false, "err": "%s needs one operand" % op}
	var arg := parts[1]
	match kind:
		"reg":
			if arg != "X" and arg != "Y":
				return {"ok": false, "err": "%s needs X or Y" % op}
		"lbl":
			if arg.length() != 1 or not LABELS.contains(arg):
				return {"ok": false, "err": "%s needs a label A-F" % op}
		"src":
			if arg != "X" and arg != "Y":
				if not arg.is_valid_int():
					return {"ok": false, "err": "%s needs X, Y or a number" % op}
				var v := int(arg)
				if v < LIT_MIN or v > LIT_MAX:
					return {"ok": false, "err": "numbers must be %d..%d" % [LIT_MIN, LIT_MAX]}
				arg = str(v)
	return {"ok": true, "op": op, "arg": arg, "text": "%s %s" % [op, arg]}


## Assemble program lines. Returns {"ok", "code": Array[Dictionary], "err", "line"}.
static func assemble(lines: PackedStringArray) -> Dictionary:
	var code: Array[Dictionary] = []
	var labels := {}
	for i in lines.size():
		var p := parse_line(lines[i])
		if not p.ok:
			return {"ok": false, "err": "line %d: %s" % [i + 1, p.err], "line": i}
		if p.op == "LBL":
			if labels.has(p.arg):
				return {"ok": false, "err": "line %d: label %s defined twice" % [i + 1, p.arg], "line": i}
			labels[p.arg] = i
		code.append(p)
	for i in code.size():
		var ins: Dictionary = code[i]
		if OPS[ins.op] == "lbl" and ins.op != "LBL":
			if not labels.has(ins.arg):
				return {"ok": false, "err": "line %d: no LBL %s" % [i + 1, ins.arg], "line": i}
			ins["target"] = labels[ins.arg]
	if size_of(code) == 0:
		return {"ok": false, "err": "the program is empty", "line": -1}
	return {"ok": true, "code": code, "err": "", "line": -1}


## Program size = instructions excluding LBL.
static func size_of(code: Array[Dictionary]) -> int:
	var n := 0
	for ins in code:
		if ins.op != "LBL":
			n += 1
	return n


static func new_state(inputs: Array, expected: Array) -> Dictionary:
	return {"pc": 0, "acc": 0, "x": 0, "y": 0, "in_ptr": 0, "out": [], "cycles": 0,
		"status": "running", "reason": "", "inputs": inputs, "expected": expected, "last_pc": -1}


static func _val(st: Dictionary, arg: String) -> int:
	if arg == "X":
		return st.x
	if arg == "Y":
		return st.y
	return int(arg)


static func _clamp(v: int) -> int:
	return clampi(v, -VALUE_LIMIT, VALUE_LIMIT)


## Execute one instruction (labels are skipped for free). Mutates and returns st.
static func step(st: Dictionary, code: Array[Dictionary]) -> Dictionary:
	if st.status != "running":
		return st
	var n := code.size()
	var guard := 0
	while code[st.pc].op == "LBL":
		st.pc = (st.pc + 1) % n
		guard += 1
		if guard > n:
			st.status = "fail"
			st.reason = "the program has no instructions"
			return st
	var ins: Dictionary = code[st.pc]
	var next_pc: int = (st.pc + 1) % n
	st.last_pc = st.pc
	st.cycles += 1
	match str(ins.op):
		"IN":
			if st.in_ptr >= (st.inputs as Array).size():
				st.status = "fail"
				st.reason = "IN with no input left (expected %d more output%s)" % [(st.expected as Array).size() - (st.out as Array).size(), "" if (st.expected as Array).size() - (st.out as Array).size() == 1 else "s"]
				return st
			st.acc = st.inputs[st.in_ptr]
			st.in_ptr += 1
		"OUT":
			var outs: Array = st.out
			var exp: Array = st.expected
			outs.append(st.acc)
			var k := outs.size() - 1
			if k >= exp.size() or int(exp[k]) != int(st.acc):
				st.status = "fail"
				st.reason = "output #%d was %d, expected %s" % [k + 1, st.acc, str(exp[k]) if k < exp.size() else "nothing"]
				return st
			if outs.size() == exp.size():
				st.status = "pass"
		"NEG":
			st.acc = -int(st.acc)
		"LDA":
			st.acc = _val(st, ins.arg)
		"STA":
			if ins.arg == "X":
				st.x = st.acc
			else:
				st.y = st.acc
		"SWP":
			var t: int = st.acc
			if ins.arg == "X":
				st.acc = st.x
				st.x = t
			else:
				st.acc = st.y
				st.y = t
		"ADD":
			st.acc = _clamp(int(st.acc) + _val(st, ins.arg))
		"SUB":
			st.acc = _clamp(int(st.acc) - _val(st, ins.arg))
		"JMP":
			next_pc = ins.target
		"JEZ":
			if st.acc == 0:
				next_pc = ins.target
		"JNZ":
			if st.acc != 0:
				next_pc = ins.target
		"JGZ":
			if st.acc > 0:
				next_pc = ins.target
		"JLZ":
			if st.acc < 0:
				next_pc = ins.target
	st.pc = next_pc
	if st.status == "running" and st.cycles >= MAX_CYCLES:
		st.status = "fail"
		st.reason = "timed out after %d cycles" % MAX_CYCLES
	return st


static func run(code: Array[Dictionary], inputs: Array, expected: Array) -> Dictionary:
	var st := new_state(inputs, expected)
	if expected.is_empty():
		st.status = "pass"
		return st
	while st.status == "running":
		step(st, code)
	return st


## Run every test. Returns {"ok", "cycles" (average, rounded up), "size", "failed_test", "reason", "states"}.
static func run_all(lines: PackedStringArray, tests: Array) -> Dictionary:
	var asm := assemble(lines)
	if not asm.ok:
		return {"ok": false, "reason": asm.err, "failed_test": -1, "size": 0, "cycles": 0, "line": asm.line}
	var code: Array[Dictionary] = asm.code
	var total := 0
	for t in tests.size():
		var st := run(code, tests[t].input, tests[t].expected)
		if st.status != "pass":
			return {"ok": false, "reason": "test %d: %s" % [t + 1, st.reason], "failed_test": t, "size": size_of(code), "cycles": 0, "line": st.last_pc, "state": st}
		total += int(st.cycles)
	return {"ok": true, "reason": "", "failed_test": -1, "size": size_of(code), "cycles": ceili(float(total) / tests.size()), "line": -1}
