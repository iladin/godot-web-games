extends RefCounted
## Opcode puzzle set. Each puzzle: name, task text, a fixed first test (shown on screen),
## a generator for the hidden tests, the reference function, and a reference program whose
## size/cycles become the par. selftest.gd proves every reference program passes.

const VM := preload("res://scripts/vm.gd")
const TESTS_PER_PUZZLE := 3

static var _cache: Array[Dictionary] = []


static func count() -> int:
	return all().size()


static func all() -> Array[Dictionary]:
	if not _cache.is_empty():
		return _cache
	var p: Array[Dictionary] = []
	p.append(_mk("ECHO", "Copy every input to the output.",
		[3, -1, 4, 1, -5, 9, 2, -6], func(r: RandomNumberGenerator) -> Array: return _nums(r, 8, -9, 9),
		func(i: Array) -> Array: return i.duplicate(),
		"IN\nOUT"))
	p.append(_mk("PLUS FIVE", "Output each input plus 5.",
		[0, 3, -5, 12, -9, 7, 1, -2], func(r: RandomNumberGenerator) -> Array: return _nums(r, 8, -20, 20),
		func(i: Array) -> Array: return i.map(func(v: int) -> int: return v + 5),
		"IN\nADD 5\nOUT"))
	p.append(_mk("DOUBLE", "Output each input times two. There is no multiply instruction.",
		[1, 4, -3, 0, 7, -8, 5, 2], func(r: RandomNumberGenerator) -> Array: return _nums(r, 8, -20, 20),
		func(i: Array) -> Array: return i.map(func(v: int) -> int: return v * 2),
		"IN\nSTA X\nADD X\nOUT"))
	p.append(_mk("NO ZEROS", "Copy the inputs to the output, but drop every 0.",
		[5, 0, 0, -2, 7, 0, 1, 0, 0, 3, -4, 0], _gen_zeros,
		func(i: Array) -> Array: return i.filter(func(v: int) -> bool: return v != 0),
		"IN\nJEZ A\nOUT\nLBL A"))
	p.append(_mk("ABSOLUTE", "Output the absolute value of each input.",
		[-3, 5, 0, -8, 2, -1, 9, -6], func(r: RandomNumberGenerator) -> Array: return _nums(r, 8, -30, 30),
		func(i: Array) -> Array: return i.map(func(v: int) -> int: return absi(v)),
		"IN\nJGZ A\nNEG\nLBL A\nOUT"))
	p.append(_mk("RUNNING TOTAL", "Output the running total: the sum of all inputs so far.",
		[2, 3, -1, 4, 0, -6, 5, 1], func(r: RandomNumberGenerator) -> Array: return _nums(r, 8, -9, 9),
		_running,
		"IN\nADD X\nSTA X\nOUT"))
	p.append(_mk("DIFFERENCE", "Inputs come in pairs (a, b). Output a - b for each pair.",
		[5, 3, 2, 7, -4, -4, 9, 0, 0, 6, -3, 2], func(r: RandomNumberGenerator) -> Array: return _nums(r, 12, -9, 9),
		func(i: Array) -> Array: return _pairs(i, func(a: int, b: int) -> int: return a - b),
		"IN\nSTA X\nIN\nNEG\nADD X\nOUT"))
	p.append(_mk("COUNTDOWN", "For each input n (1-5), output n, n-1, ... down to 1.",
		[3, 1, 4, 2], func(r: RandomNumberGenerator) -> Array: return _nums(r, 4, 1, 5),
		_countdown,
		"IN\nLBL A\nOUT\nSUB 1\nJGZ A"))
	p.append(_mk("MAXIMUM", "Inputs come in pairs. Output the larger number of each pair.",
		[3, 8, 7, 2, -1, -5, 4, 4, 0, -3, -6, 6], func(r: RandomNumberGenerator) -> Array: return _nums(r, 12, -9, 9),
		func(i: Array) -> Array: return _pairs(i, func(a: int, b: int) -> int: return maxi(a, b)),
		"IN\nSTA X\nIN\nSUB X\nJGZ A\nLDA 0\nLBL A\nADD X\nOUT"))
	p.append(_mk("SIGN", "Output -1 for each negative input, 0 for zero, 1 for positive.",
		[7, -3, 0, 12, -1, 0, 5, -9], func(r: RandomNumberGenerator) -> Array: return _nums(r, 8, -15, 15),
		func(i: Array) -> Array: return i.map(func(v: int) -> int: return signi(v)),
		"IN\nJEZ A\nJGZ B\nLDA -1\nJMP A\nLBL B\nLDA 1\nLBL A\nOUT"))
	p.append(_mk("GROUP SUMS", "The input is groups of numbers, each ending in 0. Output the sum of each group.",
		[3, 4, 0, 1, 0, 5, -2, 6, 0, 9, -9, 0], _gen_groups,
		_group_sums,
		"LBL A\nIN\nJEZ B\nADD X\nSTA X\nJMP A\nLBL B\nSWP X\nOUT"))
	p.append(_mk("COUNT UP", "For each input n (1-5), output 1, 2, ... up to n.",
		[3, 1, 4, 2], func(r: RandomNumberGenerator) -> Array: return _nums(r, 4, 1, 5),
		_countup,
		"LBL A\nIN\nSTA X\nLDA 0\nLBL B\nADD 1\nOUT\nSUB X\nJEZ A\nADD X\nJMP B"))
	p.append(_mk("DIVIDE BY 3", "Output each input (0-30) divided by 3, rounded down.",
		[9, 7, 0, 2, 30, 14], func(r: RandomNumberGenerator) -> Array: return _nums(r, 6, 0, 30),
		func(i: Array) -> Array: return i.map(func(v: int) -> int: return floori(v / 3.0)),
		"IN\nSTA Y\nLDA 0\nLBL A\nSWP Y\nSUB 3\nJLZ B\nSWP Y\nADD 1\nJMP A\nLBL B\nSWP Y\nOUT"))
	p.append(_mk("MULTIPLY", "Inputs come in pairs (a, b) with a 1-9 and b 0-9. Output a x b.",
		[3, 4, 7, 0, 1, 9, 6, 6], _gen_mul,
		func(i: Array) -> Array: return _pairs(i, func(a: int, b: int) -> int: return a * b),
		"IN\nSTA X\nIN\nLBL A\nJEZ B\nSUB 1\nSWP Y\nADD X\nSWP Y\nJMP A\nLBL B\nSWP Y\nOUT"))
	p.append(_mk("FIBONACCI", "For each input n (1-8), output the first n Fibonacci numbers: 1, 1, 2, 3, 5...",
		[3, 1, 6], func(r: RandomNumberGenerator) -> Array: return _nums(r, 3, 1, 8),
		_fib,
		"LDA 1\nSTA X\nSTA Y\nIN\nLBL A\nSWP X\nOUT\nADD Y\nSWP Y\nSWP X\nSUB 1\nJNZ A"))
	p.append(_mk("GCD", "Inputs come in pairs of positive numbers. Output their greatest common divisor.",
		[12, 18, 7, 5, 9, 9, 30, 12, 1, 8], _gen_gcd,
		func(i: Array) -> Array: return _pairs(i, _gcd),
		"IN\nSTA Y\nIN\nSWP Y\nLBL A\nSUB Y\nJEZ B\nJGZ A\nADD Y\nSWP Y\nJMP A\nLBL B\nLDA Y\nOUT"))
	_cache = p
	return p


static func _mk(name: String, task: String, fixed: Array, gen: Callable, solve: Callable, ref: String) -> Dictionary:
	return {"name": name, "task": task, "fixed": fixed, "gen": gen, "solve": solve, "ref": ref}


## The three tests for puzzle i (0-based). Test 1 is the fixed, on-screen one.
static func tests(i: int) -> Array:
	var pz: Dictionary = all()[i]
	if pz.has("tests"):
		return pz.tests
	var out: Array = []
	var rng := RandomNumberGenerator.new()
	for t in TESTS_PER_PUZZLE:
		var inp: Array
		if t == 0:
			inp = pz.fixed
		else:
			rng.seed = 7919 * (i + 1) + 104729 * t
			inp = (pz.gen as Callable).call(rng)
		out.append({"input": inp, "expected": (pz.solve as Callable).call(inp)})
	pz["tests"] = out
	return out


## Par = size and cycles of the reference program.
static func par(i: int) -> Dictionary:
	var pz: Dictionary = all()[i]
	if not pz.has("par"):
		var res := VM.run_all(ref_lines(i), tests(i))
		pz["par"] = {"size": res["size"], "cycles": res.cycles, "ok": res.ok}
	return pz.par


static func ref_lines(i: int) -> PackedStringArray:
	return str(all()[i].ref).split("\n")


# --- Generators / solvers ----------------------------------------------------------
static func _nums(r: RandomNumberGenerator, n: int, lo: int, hi: int) -> Array:
	var a: Array = []
	for k in n:
		a.append(r.randi_range(lo, hi))
	return a


static func _gen_zeros(r: RandomNumberGenerator) -> Array:
	var a: Array = []
	for k in 12:
		a.append(0 if r.randf() < 0.4 else (r.randi_range(1, 9) * (1 if r.randf() < 0.5 else -1)))
	a[1] = 4
	return a


static func _gen_groups(r: RandomNumberGenerator) -> Array:
	var a: Array = []
	for g in 4:
		for k in r.randi_range(1, 4):
			a.append(r.randi_range(1, 9) * (1 if r.randf() < 0.6 else -1))
		a.append(0)
	return a


static func _gen_mul(r: RandomNumberGenerator) -> Array:
	var a: Array = []
	for k in 4:
		a.append(r.randi_range(1, 9))
		a.append(r.randi_range(0, 9))
	return a


static func _gen_gcd(r: RandomNumberGenerator) -> Array:
	var a: Array = []
	for k in 5:
		var g := r.randi_range(1, 6)
		a.append(g * r.randi_range(1, 5))
		a.append(g * r.randi_range(1, 5))
	return a


static func _pairs(i: Array, f: Callable) -> Array:
	var o: Array = []
	for k in range(0, i.size() - 1, 2):
		o.append(f.call(int(i[k]), int(i[k + 1])))
	return o


static func _running(i: Array) -> Array:
	var o: Array = []
	var s := 0
	for v: int in i:
		s += v
		o.append(s)
	return o


static func _countdown(i: Array) -> Array:
	var o: Array = []
	for n: int in i:
		for v in range(n, 0, -1):
			o.append(v)
	return o


static func _countup(i: Array) -> Array:
	var o: Array = []
	for n: int in i:
		for v in range(1, n + 1):
			o.append(v)
	return o


static func _group_sums(i: Array) -> Array:
	var o: Array = []
	var s := 0
	for v: int in i:
		if v == 0:
			o.append(s)
			s = 0
		else:
			s += v
	return o


static func _fib(i: Array) -> Array:
	var o: Array = []
	for n: int in i:
		var a := 1
		var b := 1
		for k in n:
			o.append(a)
			var t := a + b
			a = b
			b = t
	return o


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return a
