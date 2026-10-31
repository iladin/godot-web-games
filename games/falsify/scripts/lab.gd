extends RefCounted
## Falsify game model: rounds, funding, tests, guesses, scoring.
## Everything a player can do is a text command (act) and everything they can see is in
## observe(), so humans (via main.gd), the bot and AI agents all play the same game.

const Rules := preload("res://scripts/rules.gd")

enum Phase { TITLE, TESTING, ROUND_DONE, GAME_OVER, WIN }

# --- Tunables ---------------------------------------------------------------
const ROUNDS := 10
const ROUND_SIZES: Array[int] = [4, 4, 5, 6, 6, 7, 8, 8, 9, 10]          # hypotheses per round
const COMPOSITE_SHARE: Array[float] = [0.0, 0.0, 0.0, 0.2, 0.3, 0.4, 0.5, 0.55, 0.6, 0.7]
const START_FUNDING := 6
const TEST_COST := 1
const WRONG_COST := 2
const PAR_REWARD_BONUS := 1      # solve within par: funding += par + 1, else += par
const BASE_POINTS := 100
const POINTS_PER_TEST_UNDER_PAR := 30
const WRONG_PENALTY_POINTS := 40
const MIN_POINTS := 10
const FUNDING_POINTS := 10       # leftover funding is worth this much at the end
const LETTERS := "ABCDEFGHIJKL"

signal event(kind: String, data: Dictionary)

var phase: Phase = Phase.TITLE
var rng := RandomNumberGenerator.new()
var simple: Array[Dictionary] = []
var round_no: int = 0
var funding: int = START_FUNDING
var score: int = 0
var candidates: Array[Dictionary] = []
var tables: Array[PackedByteArray] = []
var alive: Array[bool] = []
var secret: int = 0
var seed_triple := Vector3i.ZERO
var tests: Array[Dictionary] = []      # {triple: Vector3i, fits: bool, ruled_out: Array[int], bits: float}
var wrong: int = 0
var par: int = 0
var best_first := Vector3i.ZERO
var masks: Dictionary = {}
var memo: Dictionary = {}
var last_points: int = 0
var last_reward: int = 0
var end_reason: String = ""


func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	simple = Rules.simple_rules()


# --- Commands ------------------------------------------------------------------
func act(raw: String) -> Dictionary:
	var parts := raw.strip_edges().to_lower().replace(",", " ").split(" ", false)
	if parts.is_empty():
		return _err("Empty command. Try 'help'.")
	var verb := parts[0]
	match verb:
		"start", "new", "restart":
			if phase == Phase.TESTING or phase == Phase.ROUND_DONE:
				if verb != "restart":
					return _err("A game is running. Use 'restart' to abandon it.")
			new_game()
			return _ok("Round 1. Seed triple %s fits the rule." % _fmt(seed_triple))
		"test", "t":
			if parts.size() != 4:
				return _err("Usage: test a b c   (numbers %d-%d)" % [Rules.LO, Rules.HI])
			for k in range(1, 4):
				if not parts[k].is_valid_int():
					return _err("'%s' is not a whole number." % parts[k])
			return test(int(parts[1]), int(parts[2]), int(parts[3]))
		"name", "guess", "n":
			if parts.size() != 2:
				return _err("Usage: name <letter>, e.g. name B")
			return name_rule(_letter_index(parts[1]))
		"next", "continue":
			if phase == Phase.ROUND_DONE:
				next_round()
				return _ok("Round %d. Seed triple %s fits the rule." % [round_no, _fmt(seed_triple)])
			if phase == Phase.TITLE or phase == Phase.GAME_OVER or phase == Phase.WIN:
				new_game()
				return _ok("Round 1. Seed triple %s fits the rule." % _fmt(seed_triple))
			return _err("Nothing to continue - the round is still running.")
	return _err("Unknown command '%s'. Commands: test a b c | name X | next | start | restart" % verb)


func new_game() -> void:
	round_no = 0
	funding = START_FUNDING
	score = 0
	end_reason = ""
	next_round()
	event.emit("new_game", {})


func next_round() -> void:
	round_no += 1
	_build_round()
	phase = Phase.TESTING
	event.emit("round", {"round": round_no})


func test(a: int, b: int, c: int) -> Dictionary:
	if phase != Phase.TESTING:
		return _err("No round in progress.")
	for v in [a, b, c]:
		if not Rules.in_range(v):
			return _err("Numbers must be %d-%d." % [Rules.LO, Rules.HI])
	if funding < TEST_COST:
		return _err("Out of funding - you must name the rule now.")
	funding -= TEST_COST
	var i := Rules.index_of(a, b, c)
	var verdict := tables[secret][i] == 1
	var before := alive_count()
	var ruled_out: Array[int] = []
	for k in candidates.size():
		if alive[k] and (tables[k][i] == 1) != verdict:
			alive[k] = false
			ruled_out.append(k)
	var after := alive_count()
	var bits := log(float(before) / float(after)) / log(2.0)
	var entry := {"triple": Vector3i(a, b, c), "fits": verdict, "ruled_out": ruled_out, "bits": bits}
	tests.append(entry)
	event.emit("test", entry)
	var msg := "%s %s. " % [_fmt(Vector3i(a, b, c)), "FITS" if verdict else "does NOT fit"]
	if ruled_out.is_empty():
		msg += "Nothing ruled out (0 bits) - a wasted experiment."
	else:
		msg += "Ruled out %s (%.2f bits). %d left." % [_letters(ruled_out), bits, after]
	return _ok(msg)


func name_rule(k: int) -> Dictionary:
	if phase != Phase.TESTING:
		return _err("No round in progress.")
	if k < 0 or k >= candidates.size():
		return _err("No such hypothesis. Use a letter A-%s." % LETTERS[candidates.size() - 1])
	if not alive[k]:
		return _err("%s is already ruled out by your evidence." % LETTERS[k])
	if k == secret:
		var t := tests.size()
		last_points = maxi(MIN_POINTS, BASE_POINTS + POINTS_PER_TEST_UNDER_PAR * (par - t) - WRONG_PENALTY_POINTS * wrong)
		last_reward = par + (PAR_REWARD_BONUS if t <= par and wrong == 0 else 0)
		score += last_points
		funding += last_reward
		phase = Phase.ROUND_DONE
		event.emit("right", {"index": k, "points": last_points, "reward": last_reward})
		if round_no >= ROUNDS:
			score += funding * FUNDING_POINTS
			phase = Phase.WIN
			end_reason = "All %d rules found." % ROUNDS
			event.emit("win", {})
			return _ok("Correct! +%d. Final score %d." % [last_points, score])
		return _ok("Correct! %s. +%d points, +%d funding. Say 'next'." % [candidates[k].text, last_points, last_reward])
	alive[k] = false
	wrong += 1
	funding -= WRONG_COST
	event.emit("wrong", {"index": k})
	if funding < 0:
		phase = Phase.GAME_OVER
		end_reason = "Defunded. The rule was: %s" % candidates[secret].text
		event.emit("game_over", {})
		return _err("Wrong - and the lab is out of money. Game over.")
	return _err("Wrong! %s is not the rule. -%d funding." % [LETTERS[k], WRONG_COST])


# --- Round generation ---------------------------------------------------------
func _build_round() -> void:
	var idx := mini(round_no, ROUNDS) - 1
	var n: int = ROUND_SIZES[idx]
	var share: float = COMPOSITE_SHARE[idx]
	for attempt in 300:
		var sec := _pick_rule(share)
		if not _proper(sec):
			continue
		var seed_i := _pick_seed(sec)
		var chosen: Array[Dictionary] = [sec]
		var chosen_t: Array[PackedByteArray] = [Rules.table(sec)]
		var tries := 0
		while chosen.size() < n and tries < 120:
			tries += 1
			var r := _pick_rule(share * 0.8)
			if not Rules.fits_index(r, seed_i):
				continue
			if not _proper(r):
				continue
			var t := Rules.table(r)
			var dup := false
			for other in chosen_t:
				if other == t:
					dup = true
					break
			if dup:
				continue
			chosen.append(r)
			chosen_t.append(t)
		if chosen.size() < n:
			continue
		# shuffle, remembering where the secret went
		var order: Array[int] = []
		for k in n:
			order.append(k)
		for k in range(n - 1, 0, -1):
			var j := rng.randi_range(0, k)
			var tmp := order[k]
			order[k] = order[j]
			order[j] = tmp
		candidates.clear()
		tables.clear()
		alive.clear()
		for k in n:
			candidates.append(chosen[order[k]])
			tables.append(chosen_t[order[k]])
			alive.append(true)
			if order[k] == 0:
				secret = k
		seed_triple = Rules.triple_of(seed_i)
		tests.clear()
		wrong = 0
		masks = Rules.split_masks(tables)
		memo = {}
		var all_mask := (1 << n) - 1
		par = Rules.par(all_mask, masks, memo)
		best_first = Rules.triple_of(Rules.best_test(all_mask, masks, memo))
		return
	push_error("Falsify: could not build round %d" % round_no)


func _pick_rule(composite_share: float) -> Dictionary:
	var x: Dictionary = simple[rng.randi_range(0, simple.size() - 1)]
	if rng.randf() >= composite_share:
		return x
	var y: Dictionary = simple[rng.randi_range(0, simple.size() - 1)]
	if y.id == x.id:
		return x
	return Rules.combine(x, y, "and" if rng.randf() < 0.6 else "or")


## Acceptance in range, and a composite must differ from both of its parts.
func _proper(r: Dictionary) -> bool:
	if not Rules.acceptable(r):
		return false
	if r.kind == "simple":
		return true
	var t := Rules.table(r)
	return t != Rules.table(r.parts[0]) and t != Rules.table(r.parts[1])


## Seed: a triple the secret accepts. Prefer ones many simple rules accept, like 2-4-6.
func _pick_seed(sec: Dictionary) -> int:
	var t := Rules.table(sec)
	var best_i := -1
	var best_score := -1
	for k in 24:
		var i := rng.randi_range(0, Rules.SPACE - 1)
		var guard := 0
		while t[i] == 0 and guard < 400:
			i = rng.randi_range(0, Rules.SPACE - 1)
			guard += 1
		if t[i] == 0:
			continue
		var s := 0
		for r in simple:
			if Rules.fits_index(r, i):
				s += 1
		if s > best_score:
			best_score = s
			best_i = i
	return best_i


# --- Queries -------------------------------------------------------------------
func alive_count() -> int:
	var n := 0
	for v in alive:
		if v:
			n += 1
	return n


func alive_mask() -> int:
	var m := 0
	for k in alive.size():
		if alive[k]:
			m |= 1 << k
	return m


## Best next test for the current evidence (used by the bot and the post-round lab note).
func suggest_test() -> Vector3i:
	var i := Rules.best_test(alive_mask(), masks, memo)
	return Rules.triple_of(i) if i >= 0 else seed_triple


## The command an optimal (minimax) scientist would send next. gamble = chance to guess at 50/50.
func bot_command(gamble: float = 0.0) -> String:
	match phase:
		Phase.TITLE, Phase.GAME_OVER, Phase.WIN:
			return "start"
		Phase.ROUND_DONE:
			return "next"
	var left: Array[int] = []
	for k in alive.size():
		if alive[k]:
			left.append(k)
	if left.size() == 1 or funding < TEST_COST:
		return "name %s" % LETTERS[left[0]]
	if left.size() == 2 and rng.randf() < gamble:
		return "name %s" % LETTERS[left[rng.randi_range(0, 1)]]
	var t := suggest_test()
	return "test %d %d %d" % [t.x, t.y, t.z]


func phase_name() -> String:
	return ["title", "testing", "round_done", "game_over", "win"][phase]


func observe() -> Dictionary:
	var cands: Array = []
	for k in candidates.size():
		cands.append({"letter": LETTERS[k], "rule": candidates[k].text, "alive": alive[k]})
	var log_entries: Array = []
	for e in tests:
		var t: Vector3i = e.triple
		log_entries.append({"triple": [t.x, t.y, t.z], "fits": e.fits, "ruled_out": _letters(e.ruled_out), "bits": snappedf(e.bits, 0.01)})
	var o := {
		"game": "falsify", "phase": phase_name(), "round": round_no, "rounds": ROUNDS,
		"funding": funding, "score": score, "number_range": [Rules.LO, Rules.HI],
		"test_cost": TEST_COST, "wrong_guess_cost": WRONG_COST,
	}
	if phase != Phase.TITLE:
		o["seed_triple_fits"] = [seed_triple.x, seed_triple.y, seed_triple.z]
		o["hypotheses"] = cands
		o["tests"] = log_entries
		o["par"] = par
		o["alive"] = alive_count()
	if phase == Phase.ROUND_DONE or phase == Phase.WIN or phase == Phase.GAME_OVER:
		o["rule_was"] = candidates[secret].text if not candidates.is_empty() else ""
		o["best_first_test"] = [best_first.x, best_first.y, best_first.z]
	if end_reason != "":
		o["end"] = end_reason
	o["commands"] = _commands()
	return o


func _commands() -> PackedStringArray:
	match phase:
		Phase.TESTING:
			return PackedStringArray(["test a b c", "name <letter>", "restart"])
		Phase.ROUND_DONE:
			return PackedStringArray(["next"])
	return PackedStringArray(["start"])


# --- Helpers -------------------------------------------------------------------
func _letter_index(s: String) -> int:
	var up := s.strip_edges().to_upper()
	if up.length() == 1 and LETTERS.contains(up):
		return LETTERS.find(up)
	if up.is_valid_int():
		return int(up) - 1
	return -1


func _letters(ks: Array) -> String:
	var out: PackedStringArray = []
	for k: int in ks:
		out.append(LETTERS[k])
	return ", ".join(out)


func _fmt(t: Vector3i) -> String:
	return "%d %d %d" % [t.x, t.y, t.z]


func _ok(msg: String) -> Dictionary:
	return {"ok": true, "msg": msg}


func _err(msg: String) -> Dictionary:
	return {"ok": false, "msg": msg}
