extends RefCounted
## Falsify rule library + analysis. Pure logic, shared by the game, the bot and the selftest.
##
## A rule is a Dictionary: {"id", "text", "kind": "simple"|"and"|"or", "f" (simple only),
## "parts" (composites), "table" (lazily cached PackedByteArray over every triple)}.
## Numbers range over LO..HI, so there are SPACE possible triples.

const LO := 0
const HI := 15
const SPAN := HI - LO + 1
const SPACE := SPAN * SPAN * SPAN
const MIN_ACCEPT := 0.03   # rules that almost never / almost always fit are no fun
const MAX_ACCEPT := 0.88
const PRIMES: Array[int] = [2, 3, 5, 7, 11, 13]


static func index_of(a: int, b: int, c: int) -> int:
	return ((a - LO) * SPAN + (b - LO)) * SPAN + (c - LO)


@warning_ignore("integer_division")
static func triple_of(i: int) -> Vector3i:
	return Vector3i(i / (SPAN * SPAN) + LO, (i / SPAN) % SPAN + LO, i % SPAN + LO)


static func in_range(v: int) -> bool:
	return v >= LO and v <= HI


static func _p(v: int) -> bool:
	return v in PRIMES


static func _rule(id: String, text: String, f: Callable) -> Dictionary:
	return {"id": id, "text": text, "kind": "simple", "f": f}


static func simple_rules() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	r.append(_rule("inc", "Strictly increasing", func(a: int, b: int, c: int) -> bool: return a < b and b < c))
	r.append(_rule("dec", "Strictly decreasing", func(a: int, b: int, c: int) -> bool: return a > b and b > c))
	r.append(_rule("nondec", "Never goes down", func(a: int, b: int, c: int) -> bool: return a <= b and b <= c))
	r.append(_rule("first_lt_last", "First is less than last", func(a: int, _b: int, c: int) -> bool: return a < c))
	r.append(_rule("mid_max", "Middle is the biggest", func(a: int, b: int, c: int) -> bool: return b > a and b > c))
	r.append(_rule("mid_min", "Middle is the smallest", func(a: int, b: int, c: int) -> bool: return b < a and b < c))
	r.append(_rule("first_min", "First is the smallest", func(a: int, b: int, c: int) -> bool: return a < b and a < c))
	r.append(_rule("last_max", "Last is the biggest", func(a: int, b: int, c: int) -> bool: return c > a and c > b))
	r.append(_rule("mid_between", "Middle is between the others", func(a: int, b: int, c: int) -> bool: return (a < b and b < c) or (a > b and b > c)))
	r.append(_rule("all_even", "All even", func(a: int, b: int, c: int) -> bool: return a % 2 == 0 and b % 2 == 0 and c % 2 == 0))
	r.append(_rule("all_odd", "All odd", func(a: int, b: int, c: int) -> bool: return a % 2 == 1 and b % 2 == 1 and c % 2 == 1))
	r.append(_rule("sum_even", "Sum is even", func(a: int, b: int, c: int) -> bool: return (a + b + c) % 2 == 0))
	r.append(_rule("sum_odd", "Sum is odd", func(a: int, b: int, c: int) -> bool: return (a + b + c) % 2 == 1))
	r.append(_rule("one_odd", "Exactly one is odd", func(a: int, b: int, c: int) -> bool: return a % 2 + b % 2 + c % 2 == 1))
	r.append(_rule("has_even", "At least one is even", func(a: int, b: int, c: int) -> bool: return a % 2 + b % 2 + c % 2 < 3))
	r.append(_rule("same_parity", "All the same parity", func(a: int, b: int, c: int) -> bool: return a % 2 == b % 2 and b % 2 == c % 2))
	r.append(_rule("distinct", "All different", func(a: int, b: int, c: int) -> bool: return a != b and b != c and a != c))
	r.append(_rule("has_pair", "Two or more are equal", func(a: int, b: int, c: int) -> bool: return a == b or b == c or a == c))
	r.append(_rule("ends_equal", "First equals last", func(a: int, _b: int, c: int) -> bool: return a == c))
	r.append(_rule("arith", "Equal steps (b - a = c - b)", func(a: int, b: int, c: int) -> bool: return b - a == c - b))
	r.append(_rule("sum_ab", "First + middle = last", func(a: int, b: int, c: int) -> bool: return a + b == c))
	r.append(_rule("sum_ge15", "Sum is 15 or more", func(a: int, b: int, c: int) -> bool: return a + b + c >= 15))
	r.append(_rule("sum_lt12", "Sum is under 12", func(a: int, b: int, c: int) -> bool: return a + b + c < 12))
	r.append(_rule("sum_mul3", "Sum is a multiple of 3", func(a: int, b: int, c: int) -> bool: return (a + b + c) % 3 == 0))
	r.append(_rule("has_7", "Contains a 7", func(a: int, b: int, c: int) -> bool: return a == 7 or b == 7 or c == 7))
	r.append(_rule("has_zero", "Contains a 0", func(a: int, b: int, c: int) -> bool: return a == 0 or b == 0 or c == 0))
	r.append(_rule("max_le9", "Nothing above 9", func(a: int, b: int, c: int) -> bool: return maxi(a, maxi(b, c)) <= 9))
	r.append(_rule("has_gt10", "Something above 10", func(a: int, b: int, c: int) -> bool: return maxi(a, maxi(b, c)) > 10))
	r.append(_rule("all_prime", "All prime", func(a: int, b: int, c: int) -> bool: return _p(a) and _p(b) and _p(c)))
	r.append(_rule("has_prime", "Contains a prime", func(a: int, b: int, c: int) -> bool: return _p(a) or _p(b) or _p(c)))
	r.append(_rule("no_prime", "No primes at all", func(a: int, b: int, c: int) -> bool: return not (_p(a) or _p(b) or _p(c))))
	r.append(_rule("double", "Last is double the first", func(a: int, _b: int, c: int) -> bool: return c == 2 * a))
	r.append(_rule("spread_le4", "Biggest - smallest is 4 or less", func(a: int, b: int, c: int) -> bool: return maxi(a, maxi(b, c)) - mini(a, mini(b, c)) <= 4))
	r.append(_rule("spread_ge8", "Biggest - smallest is 8 or more", func(a: int, b: int, c: int) -> bool: return maxi(a, maxi(b, c)) - mini(a, mini(b, c)) >= 8))
	r.append(_rule("first_even", "First is even", func(a: int, _b: int, _c: int) -> bool: return a % 2 == 0))
	r.append(_rule("last_odd", "Last is odd", func(_a: int, _b: int, c: int) -> bool: return c % 2 == 1))
	r.append(_rule("has_mul5", "Contains 5, 10 or 15", func(a: int, b: int, c: int) -> bool: return (a > 0 and a % 5 == 0) or (b > 0 and b % 5 == 0) or (c > 0 and c % 5 == 0)))
	r.append(_rule("mid_gt5", "Middle is more than 5", func(_a: int, b: int, _c: int) -> bool: return b > 5))
	return r


static func combine(x: Dictionary, y: Dictionary, kind: String) -> Dictionary:
	var joiner := " AND " if kind == "and" else " OR "
	var second: String = y.text
	second = second.substr(0, 1).to_lower() + second.substr(1)
	return {"id": "%s%s%s" % [x.id, "&" if kind == "and" else "|", y.id], "text": str(x.text) + joiner + second,
		"kind": kind, "parts": [x, y]}


## Does the rule accept triple index i? Cheap for simple rules and composites of them.
static func fits_index(rule: Dictionary, i: int) -> bool:
	if rule.has("table"):
		return (rule.table as PackedByteArray)[i] == 1
	match str(rule.kind):
		"and":
			return fits_index(rule.parts[0], i) and fits_index(rule.parts[1], i)
		"or":
			return fits_index(rule.parts[0], i) or fits_index(rule.parts[1], i)
	var t := triple_of(i)
	return (rule.f as Callable).call(t.x, t.y, t.z)


static func fits(rule: Dictionary, a: int, b: int, c: int) -> bool:
	return fits_index(rule, index_of(a, b, c))


## Truth table over all triples (cached in the rule dictionary).
static func table(rule: Dictionary) -> PackedByteArray:
	if rule.has("table"):
		return rule.table
	var t := PackedByteArray()
	t.resize(SPACE)
	var kind: String = rule.kind
	if kind == "simple":
		var f: Callable = rule.f
		var i := 0
		for a in range(LO, HI + 1):
			for b in range(LO, HI + 1):
				for c in range(LO, HI + 1):
					t[i] = 1 if f.call(a, b, c) else 0
					i += 1
	else:
		var t1 := table(rule.parts[0])
		var t2 := table(rule.parts[1])
		for i in SPACE:
			if kind == "and":
				t[i] = t1[i] & t2[i]
			else:
				t[i] = t1[i] | t2[i]
	rule["table"] = t
	return t


static func acceptance(rule: Dictionary) -> float:
	var t := table(rule)
	var n := 0
	for v in t:
		n += v
	return float(n) / SPACE


static func acceptable(rule: Dictionary) -> bool:
	var a := acceptance(rule)
	return a >= MIN_ACCEPT and a <= MAX_ACCEPT


## For each triple, which candidates accept it (bitmask). Returns {mask: representative index}.
static func split_masks(tables: Array[PackedByteArray]) -> Dictionary:
	var masks := {}
	for i in SPACE:
		var m := 0
		for k in tables.size():
			if tables[k][i] == 1:
				m |= 1 << k
		if not masks.has(m):
			masks[m] = i
	return masks


## Minimum worst-case number of tests to pin down one rule among `alive` (bitmask).
static func par(alive: int, masks: Dictionary, memo: Dictionary) -> int:
	if _popcount(alive) <= 1:
		return 0
	if memo.has(alive):
		return memo[alive]
	var best := 99
	for m: int in masks:
		var yes := alive & m
		var no := alive & ~m
		if yes == 0 or no == 0:
			continue
		var v := 1 + maxi(par(yes, masks, memo), par(no, masks, memo))
		if v < best:
			best = v
			if best == _ceil_log2(_popcount(alive)):
				break
	memo[alive] = best
	return best


## A test (triple index) achieving the par for `alive`; ties broken by the most even split.
static func best_test(alive: int, masks: Dictionary, memo: Dictionary) -> int:
	var target := par(alive, masks, memo)
	var best_i := -1
	var best_bal := 999
	for m: int in masks:
		var yes := alive & m
		var no := alive & ~m
		if yes == 0 or no == 0:
			continue
		var v := 1 + maxi(par(yes, masks, memo), par(no, masks, memo))
		if v != target:
			continue
		var bal := absi(_popcount(yes) - _popcount(no))
		if bal < best_bal:
			best_bal = bal
			best_i = masks[m]
	return best_i


static func _popcount(x: int) -> int:
	var n := 0
	while x != 0:
		x &= x - 1
		n += 1
	return n


static func popcount(x: int) -> int:
	return _popcount(x)


static func _ceil_log2(n: int) -> int:
	var k := 0
	while (1 << k) < n:
		k += 1
	return k
