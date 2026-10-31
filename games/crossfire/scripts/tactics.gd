extends RefCounted
## Crossfire model: hex board, units, telegraphed enemy attacks, shoves, floors.
## Deterministic given the RNG seed. Everything a player can do is a text command (act),
## everything they can see is in observe(). Coordinates are axial (q, r), pointy-top hexes,
## r grows downward. Unit 0 is always the player.

enum Phase { TITLE, PLAYER, GAME_OVER, WIN }

# --- Tunables ---------------------------------------------------------------
const RADIUS := 4
const FLOORS := 10
const PLAYER_HP := 3
const SHOT_RANGE := 6
const ARCHER_RANGE := Vector2i(2, 5)   # preferred firing distance (also fires point-blank)
const BOMB_RANGE := Vector2i(2, 4)
const KILL_POINTS := 10
const COMBO_POINTS := 5                # extra per additional kill in the same phase
const FLOOR_POINTS := 25
const CLEAN_POINTS := 25               # exit with every enemy dead: bonus + heal 1
const WALL_COUNT := Vector2i(4, 7)
const PIT_COUNT := Vector2i(3, 6)
const MAX_ENEMIES := 7
const START := Vector2i(-2, 4)
const EXIT := Vector2i(2, -4)
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]
const DIR_NAMES: Array[String] = ["e", "ne", "nw", "w", "sw", "se"]
const KIND_HP := {"player": PLAYER_HP, "brute": 1, "archer": 1, "bomber": 1, "knight": 2}
const KIND_CHAR := {"player": "@", "brute": "B", "archer": "A", "bomber": "O", "knight": "K"}

signal event(kind: String, data: Dictionary)

var phase: Phase = Phase.TITLE
var rng := RandomNumberGenerator.new()
var floor_no: int = 0
var score: int = 0
var kills: int = 0
var turn: int = 0
var tiles: Dictionary = {}           # Vector2i -> "floor" | "wall" | "pit" | "exit"
var units: Array[Dictionary] = []    # {id, kind, pos, hp, alive, intent, reload}
var move_left: bool = true
var shove_left: bool = true
var next_id: int = 1
var end_reason: String = ""
var _preview_cache: Dictionary = {}


func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


# --- Hex helpers -----------------------------------------------------------------
@warning_ignore("integer_division")
static func hex_dist(a: Vector2i, b: Vector2i) -> int:
	var d := a - b
	return (absi(d.x) + absi(d.y) + absi(d.x + d.y)) / 2


## Direction index if b lies on a straight line from a (a != b), else -1.
static func line_dir(a: Vector2i, b: Vector2i) -> int:
	var d := b - a
	if d == Vector2i.ZERO:
		return -1
	var n := hex_dist(a, b)
	for i in 6:
		if DIRS[i] * n == d:
			return i
	return -1


static func dir_from_name(s: String) -> int:
	return DIR_NAMES.find(s.strip_edges().to_lower())


func passable(h: Vector2i) -> bool:
	var t: String = tiles.get(h, "")
	return t == "floor" or t == "exit"


func unit_at(h: Vector2i, us: Array[Dictionary] = units) -> int:
	for i in us.size():
		if us[i].alive and us[i].pos == h:
			return i
	return -1


func player() -> Dictionary:
	return units[0]


# --- Commands ---------------------------------------------------------------------
func act(raw: String) -> Dictionary:
	var p := raw.strip_edges().to_lower().split(" ", false)
	if p.is_empty():
		return _err("Empty command. Try 'help'.")
	var verb := p[0]
	if dir_from_name(verb) >= 0:
		return move(dir_from_name(verb))
	match verb:
		"start", "new", "restart":
			if phase == Phase.PLAYER and verb != "restart":
				return _err("A run is in progress. Use 'restart' to abandon it.")
			new_game()
			return _ok("Floor 1. Reach the stairs at the top. 'map' shows the board as text.")
		"move", "m", "go":
			if p.size() != 2 or dir_from_name(p[1]) < 0:
				return _err("Usage: move <e|ne|nw|w|sw|se>")
			return move(dir_from_name(p[1]))
		"shove", "push", "s":
			if p.size() != 2 or dir_from_name(p[1]) < 0:
				return _err("Usage: shove <e|ne|nw|w|sw|se>")
			return shove(dir_from_name(p[1]))
		"end", "wait", "pass":
			return end_turn()
		"map":
			var r := _ok("\n".join(ascii_map()) + "\n@ you  > stairs  # wall  o pit  * attacked\nB brute  K knight  A archer  O bomber")
			r["mono"] = true
			return r
		"threats", "intents":
			return _ok("\n".join(describe_threats()))
	return _err("Unknown command '%s'. Try: move ne, shove w, end, map" % verb)


func new_game() -> void:
	floor_no = 0
	score = 0
	kills = 0
	turn = 0
	end_reason = ""
	units = [{"id": 0, "kind": "player", "pos": START, "hp": PLAYER_HP, "alive": true, "intent": {}, "reload": false}]
	_next_floor()
	event.emit("new_game", {})


func move(d: int) -> Dictionary:
	if phase != Phase.PLAYER:
		return _err("Not your turn.")
	if not move_left:
		return _err("You already moved this turn. Shove or 'end'.")
	var dest: Vector2i = player().pos + DIRS[d]
	if not passable(dest):
		return _err("Can't move %s: %s." % [DIR_NAMES[d], tiles.get(dest, "edge of the board")])
	if unit_at(dest) >= 0:
		return _err("Can't move %s: occupied. Use 'shove %s'." % [DIR_NAMES[d], DIR_NAMES[d]])
	var from: Vector2i = player().pos
	player().pos = dest
	move_left = false
	_dirty()
	event.emit("move", {"id": 0, "from": from, "to": dest})
	if dest == EXIT:
		return _complete_floor()
	return _maybe_auto_end("Moved %s." % DIR_NAMES[d])


func shove(d: int) -> Dictionary:
	if phase != Phase.PLAYER:
		return _err("Not your turn.")
	if not shove_left:
		return _err("You already shoved this turn.")
	var target: Vector2i = player().pos + DIRS[d]
	var j := unit_at(target)
	if j <= 0:
		return _err("Nothing to shove %s." % DIR_NAMES[d])
	var log: Array = []
	var kind: String = units[j].kind
	_push(units, j, d, log)
	_purge()
	shove_left = false
	_score_deaths(log)
	_dirty()
	event.emit("shove", {"dir": d, "log": log})
	return _maybe_auto_end("Shoved %s %s." % [kind, DIR_NAMES[d]])


func end_turn() -> Dictionary:
	if phase != Phase.PLAYER:
		return _err("Not your turn.")
	var log: Array = []
	var hp_before: int = player().hp
	_resolve_attacks(units, log)
	_score_deaths(log)
	if not player().alive:
		phase = Phase.GAME_OVER
		end_reason = "Fell on floor %d." % floor_no
		event.emit("enemy_phase", {"log": log})
		event.emit("game_over", {})
		return _err("You died. Score %d." % score)
	_purge()
	_enemies_act(log)
	_purge()
	turn += 1
	move_left = true
	shove_left = true
	_dirty()
	event.emit("enemy_phase", {"log": log})
	var took: int = hp_before - int(player().hp)
	return _ok("Enemies struck: you took %d damage, HP %d." % [took, player().hp])


func _maybe_auto_end(msg: String) -> Dictionary:
	if not move_left and not shove_left and phase == Phase.PLAYER:
		var r := end_turn()
		return {"ok": r.ok, "msg": msg + " " + str(r.msg)}
	return _ok(msg)


func _complete_floor() -> Dictionary:
	var clean := true
	for i in range(1, units.size()):
		if units[i].alive:
			clean = false
	score += FLOOR_POINTS
	if clean:
		score += CLEAN_POINTS
		player().hp = mini(PLAYER_HP, int(player().hp) + 1)
	event.emit("floor_done", {"clean": clean})
	if floor_no >= FLOORS:
		phase = Phase.WIN
		end_reason = "Escaped all %d floors." % FLOORS
		event.emit("win", {})
		return _ok("You escaped! Score %d." % score)
	_next_floor()
	return _ok("Floor %d.%s" % [floor_no, " Clean sweep: +1 HP." if clean else ""])


# --- Floors -----------------------------------------------------------------------
func _next_floor() -> void:
	floor_no += 1
	turn = 0
	var p := player()
	for attempt in 200:
		tiles.clear()
		for q in range(-RADIUS, RADIUS + 1):
			for r in range(-RADIUS, RADIUS + 1):
				if absi(q + r) <= RADIUS:
					tiles[Vector2i(q, r)] = "floor"
		tiles[EXIT] = "exit"
		var cells: Array[Vector2i] = []
		for h: Vector2i in tiles:
			if hex_dist(h, START) > 1 and hex_dist(h, EXIT) > 1:
				cells.append(h)
		_shuffle(cells)
		var nw := rng.randi_range(WALL_COUNT.x, WALL_COUNT.y)
		var np := rng.randi_range(PIT_COUNT.x, PIT_COUNT.y)
		for k in nw + np:
			tiles[cells[k]] = "wall" if k < nw else "pit"
		var reach := _bfs({START: 0}, [])
		if not reach.has(EXIT):
			continue
		units = [p]
		p.pos = START
		p.intent = {}
		var spots: Array[Vector2i] = []
		for h: Vector2i in reach:
			if hex_dist(h, START) >= 3 and h != EXIT and tiles[h] == "floor":
				spots.append(h)
		_shuffle(spots)
		@warning_ignore("integer_division")
		var n := mini(2 + floor_no / 2, MAX_ENEMIES)
		if spots.size() < n:
			continue
		for k in n:
			var kind := _pick_kind()
			units.append({"id": next_id, "kind": kind, "pos": spots[k], "hp": KIND_HP[kind], "alive": true, "intent": {}, "reload": false})
			next_id += 1
		for i in range(1, units.size()):
			_plan_intent(i)
		move_left = true
		shove_left = true
		phase = Phase.PLAYER
		_dirty()
		event.emit("floor", {"floor": floor_no})
		return
	push_error("Crossfire: floor generation failed")


func _pick_kind() -> String:
	var pool: Array[String] = ["brute", "brute"]
	if floor_no >= 2:
		pool.append_array(["archer", "archer"])
	if floor_no >= 4:
		pool.append("bomber")
	if floor_no >= 6:
		pool.append("knight")
	return pool[rng.randi_range(0, pool.size() - 1)]


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t


## Multi-source BFS over passable hexes, avoiding `blocked`. Returns {hex: distance}.
func _bfs(sources: Dictionary, blocked: Array) -> Dictionary:
	var dist := sources.duplicate()
	var queue: Array = sources.keys()
	var head := 0
	while head < queue.size():
		var h: Vector2i = queue[head]
		head += 1
		for d in DIRS:
			var n: Vector2i = h + d
			if dist.has(n) or not passable(n) or n in blocked:
				continue
			dist[n] = int(dist[h]) + 1
			queue.append(n)
	return dist


# --- Combat resolution (works on any units array, so previews can simulate) -----------
func _resolve_attacks(us: Array[Dictionary], log: Array) -> void:
	for i in range(1, us.size()):
		var e: Dictionary = us[i]
		if not e.alive or (e.intent as Dictionary).is_empty():
			continue
		var it: Dictionary = e.intent
		match str(it.kind):
			"smash":
				var t: Vector2i = e.pos + DIRS[it.dir]
				log.append({"type": "smash", "id": e.id, "from": e.pos, "at": t})
				var j := unit_at(t, us)
				if j >= 0:
					_damage(us, j, 1, log)
			"shot":
				var p: Vector2i = e.pos
				var end: Vector2i = p
				var hit := -1
				for k in SHOT_RANGE:
					p += DIRS[it.dir]
					if not tiles.has(p) or tiles[p] == "wall":
						break
					end = p
					var j := unit_at(p, us)
					if j >= 0:
						hit = j
						break
				log.append({"type": "shot", "id": e.id, "from": e.pos, "to": end})
				if hit >= 0:
					_damage(us, hit, 1, log)
			"bomb":
				var t: Vector2i = it.target
				log.append({"type": "bomb", "id": e.id, "at": t})
				var j := unit_at(t, us)
				if j >= 0:
					_damage(us, j, 1, log)
				for d in 6:
					var k := unit_at(t + DIRS[d], us)
					if k >= 0:
						_push(us, k, d, log)
				e.reload = true


func _push(us: Array[Dictionary], j: int, d: int, log: Array) -> void:
	var u: Dictionary = us[j]
	var from: Vector2i = u.pos
	var dest: Vector2i = from + DIRS[d]
	var t: String = tiles.get(dest, "")
	if t == "" or t == "wall" or (t == "pit" and u.kind == "player"):
		log.append({"type": "slam", "id": u.id, "at": from, "dir": d})
		_damage(us, j, 1, log)
		return
	if t == "pit":
		u.pos = dest
		log.append({"type": "fall", "id": u.id, "from": from, "to": dest})
		u.hp = 0
		u.alive = false
		u.intent = {}
		log.append({"type": "death", "id": u.id, "kind": u.kind, "at": dest})
		return
	var k := unit_at(dest, us)
	if k >= 0:
		log.append({"type": "collide", "id": u.id, "other": us[k].id, "at": from, "dir": d})
		_damage(us, j, 1, log)
		_damage(us, k, 1, log)
		return
	u.pos = dest
	log.append({"type": "push", "id": u.id, "from": from, "to": dest})


func _damage(us: Array[Dictionary], j: int, amount: int, log: Array) -> void:
	var u: Dictionary = us[j]
	if not u.alive:
		return
	u.hp = int(u.hp) - amount
	log.append({"type": "damage", "id": u.id, "amount": amount, "at": u.pos})
	if u.hp <= 0:
		u.alive = false
		u.intent = {}
		log.append({"type": "death", "id": u.id, "kind": u.kind, "at": u.pos})


## Drop dead enemies (the player stays at index 0 even when dead).
func _purge() -> void:
	var keep: Array[Dictionary] = [units[0]]
	for i in range(1, units.size()):
		if units[i].alive:
			keep.append(units[i])
	units = keep


func _score_deaths(log: Array) -> void:
	var n := 0
	for ev: Dictionary in log:
		if ev.type == "death" and ev.kind != "player":
			score += KILL_POINTS + COMBO_POINTS * n
			n += 1
			kills += 1


# --- Enemy AI -----------------------------------------------------------------------
func _enemies_act(log: Array) -> void:
	for i in range(1, units.size()):
		var e: Dictionary = units[i]
		if not e.alive:
			continue
		var from: Vector2i = e.pos
		_move_enemy(i)
		if e.pos != from:
			log.append({"type": "step", "id": e.id, "from": from, "to": e.pos})
		if e.kind == "bomber" and e.reload:
			e.reload = false
			e.intent = {}
		else:
			_plan_intent(i)


func _goals(e: Dictionary) -> Array[Vector2i]:
	var pp: Vector2i = player().pos
	var goals: Array[Vector2i] = []
	match str(e.kind):
		"brute", "knight":
			for d in DIRS:
				goals.append(pp + d)
		"archer":
			for d in DIRS:
				for k in range(1, ARCHER_RANGE.y + 1):
					var h: Vector2i = pp + d * k
					if not tiles.has(h) or tiles[h] == "wall":
						break
					if k >= ARCHER_RANGE.x:
						goals.append(h)
		"bomber":
			for h: Vector2i in tiles:
				var dd := hex_dist(h, pp)
				if dd >= BOMB_RANGE.x and dd <= BOMB_RANGE.y:
					goals.append(h)
	return goals


func _move_enemy(i: int) -> void:
	var e: Dictionary = units[i]
	var blocked: Array = []
	for u in units:
		if u.alive and u.id != e.id:
			blocked.append(u.pos)
	var src := {}
	for g in _goals(e):
		if passable(g) and not (g in blocked):
			src[g] = 0
	if src.has(e.pos):
		return
	var dist := _bfs(src, blocked)
	var best: Vector2i = e.pos
	var best_d: int = dist.get(e.pos, 9999)
	for d in DIRS:
		var n: Vector2i = e.pos + d
		if dist.has(n) and int(dist[n]) < best_d:
			best_d = dist[n]
			best = n
	e.pos = best


func _plan_intent(i: int) -> void:
	var e: Dictionary = units[i]
	var pp: Vector2i = player().pos
	var dist := hex_dist(e.pos, pp)
	e.intent = {}
	match str(e.kind):
		"brute", "knight":
			if dist == 1:
				e.intent = {"kind": "smash", "dir": line_dir(e.pos, pp)}
		"archer":
			var d := line_dir(e.pos, pp)
			if d >= 0 and dist <= ARCHER_RANGE.y and _clear_line(e.pos, d, dist):
				e.intent = {"kind": "shot", "dir": d}
		"bomber":
			if dist >= BOMB_RANGE.x and dist <= BOMB_RANGE.y:
				e.intent = {"kind": "bomb", "target": pp}


func _clear_line(from: Vector2i, d: int, n: int) -> bool:
	for k in range(1, n):
		var h: Vector2i = from + DIRS[d] * k
		if not tiles.has(h) or tiles[h] == "wall" or unit_at(h) >= 0:
			return false
	return true


# --- Preview / queries ----------------------------------------------------------------
func _dirty() -> void:
	_preview_cache = {}


## What happens if the turn ends right now: {"player_damage", "deaths": [ids], "log"}.
func preview() -> Dictionary:
	if not _preview_cache.is_empty():
		return _preview_cache
	var sim := _clone_units()
	var log: Array = []
	_resolve_attacks(sim, log)
	var deaths: Array = []
	var dmg := 0
	for ev: Dictionary in log:
		if ev.type == "death" and ev.id != 0:
			deaths.append(ev.id)
		if ev.type == "damage" and ev.id == 0:
			dmg += int(ev.amount)
	_preview_cache = {"player_damage": dmg, "deaths": deaths, "log": log}
	return _preview_cache


func _clone_units() -> Array[Dictionary]:
	var c: Array[Dictionary] = []
	for u in units:
		c.append(u.duplicate(true))
	return c


## Hexes that some intent will strike, as {hex: true} (based on current positions).
func threatened() -> Dictionary:
	var out := {}
	for ev: Dictionary in preview().log:
		match str(ev.type):
			"smash", "bomb":
				out[ev.at] = true
			"shot":
				var a: Vector2i = ev.from
				var n := hex_dist(a, ev.to)
				var d := line_dir(a, ev.to)
				for k in range(1, n + 1):
					out[a + DIRS[d] * k] = true
	return out


func enemy_count() -> int:
	return units.size() - 1


func describe_intent(u: Dictionary) -> String:
	var it: Dictionary = u.intent
	if u.kind == "bomber" and u.reload:
		return "reloading"
	if it.is_empty():
		return "moving"
	match str(it.kind):
		"smash":
			return "smash %s" % DIR_NAMES[it.dir]
		"shot":
			return "shoot %s" % DIR_NAMES[it.dir]
		"bomb":
			var t: Vector2i = it.target
			return "bomb (%d,%d)" % [t.x, t.y]
	return "?"


func describe_threats() -> PackedStringArray:
	var lines := PackedStringArray()
	for i in range(1, units.size()):
		var u: Dictionary = units[i]
		lines.append("#%d %s at (%d,%d) hp %d: %s" % [i, u.kind, u.pos.x, u.pos.y, u.hp, describe_intent(u)])
	var pv := preview()
	lines.append("End turn now: you take %d, %d enem%s die." % [pv.player_damage, pv.deaths.size(), "y" if pv.deaths.size() == 1 else "ies"])
	return lines


func ascii_map() -> PackedStringArray:
	var rows := PackedStringArray()
	var threat := threatened()
	for r in range(-RADIUS, RADIUS + 1):
		var line := " ".repeat(absi(r))
		for q in range(-RADIUS, RADIUS + 1):
			var h := Vector2i(q, r)
			if not tiles.has(h):
				continue
			var ch := "."
			match str(tiles[h]):
				"wall":
					ch = "#"
				"pit":
					ch = "o"
				"exit":
					ch = ">"
			if threat.has(h):
				ch = "*"
			var j := unit_at(h)
			if j >= 0:
				ch = KIND_CHAR[units[j].kind]
			line += ch + " "
		rows.append(line.rstrip(" "))
	return rows


func legal_actions() -> PackedStringArray:
	var out := PackedStringArray()
	if phase != Phase.PLAYER:
		return PackedStringArray(["start"])
	var pp: Vector2i = player().pos
	for d in 6:
		var h: Vector2i = pp + DIRS[d]
		var j := unit_at(h)
		if move_left and passable(h) and j < 0:
			out.append("move " + DIR_NAMES[d])
		if shove_left and j > 0:
			out.append("shove " + DIR_NAMES[d])
	out.append("end")
	return out


func phase_name() -> String:
	return ["title", "your_turn", "game_over", "win"][phase]


func observe() -> Dictionary:
	var o := {"game": "crossfire", "phase": phase_name(), "floor": floor_no, "floors": FLOORS, "score": score,
		"kills": kills}
	if phase == Phase.TITLE:
		o["commands"] = ["start"]
		return o
	var pp: Vector2i = player().pos
	o["hp"] = player().hp
	o["max_hp"] = PLAYER_HP
	o["turn"] = turn
	o["you"] = [pp.x, pp.y]
	o["stairs"] = [EXIT.x, EXIT.y]
	o["move_left"] = move_left
	o["shove_left"] = shove_left
	var es: Array = []
	for i in range(1, units.size()):
		var u: Dictionary = units[i]
		es.append({"order": i, "kind": u.kind, "at": [u.pos.x, u.pos.y], "hp": u.hp, "intent": describe_intent(u)})
	o["enemies"] = es
	o["map"] = ascii_map()
	o["legend"] = "@ you, > stairs, # wall, o pit, * hex under attack, B brute, K knight (2 hp), A archer, O bomber"
	var pv := preview()
	o["if_you_end_turn_now"] = {"you_take": pv.player_damage, "enemies_die": pv.deaths.size()}
	o["legal"] = legal_actions()
	o["directions"] = "axial (q,r), r grows downward: e=(+1,0) w=(-1,0) ne=(+1,-1) nw=(0,-1) se=(0,+1) sw=(-1,+1)"
	o["rules"] = "Each turn: one move and one shove, any order, then enemies strike exactly as shown, then move and aim again. Shoved units hitting walls/units take 1 damage, into pits they fall. Enemy attacks hit whatever stands there - including other enemies."
	if end_reason != "":
		o["end"] = end_reason
	return o


# --- Bot (autoplay, selftest balance runs) -----------------------------------------------
## Best next command by brute-force search over this turn's move/shove plans.
func bot_command() -> String:
	if phase != Phase.PLAYER:
		return "start"
	var plans: Array = [[]]
	var moves: Array = []
	var shoves: Array = []
	for d in 6:
		if move_left:
			moves.append(["move", d])
		if shove_left:
			shoves.append(["shove", d])
	for m in moves:
		plans.append([m])
	for s in shoves:
		plans.append([s])
		for m in moves:
			plans.append([s, m])
			plans.append([m, s])
	var best_v := -INF
	var best: Array = []
	for plan: Array in plans:
		var v := _eval_plan(plan)
		if v > best_v:
			best_v = v
			best = plan
	if best.is_empty():
		return "end"
	var first: Array = best[0]
	return "%s %s" % [first[0], DIR_NAMES[first[1]]]


func _eval_plan(plan: Array) -> float:
	var sim := _clone_units()
	var log: Array = []
	for step: Array in plan:
		var d: int = step[1]
		if step[0] == "move":
			var dest: Vector2i = sim[0].pos + DIRS[d]
			if not passable(dest) or unit_at(dest, sim) >= 0:
				return -INF
			sim[0].pos = dest
			if dest == EXIT:
				return 10000.0 - 1000.0 * float(enemy_alive(sim))
		else:
			var j := unit_at(sim[0].pos + DIRS[d], sim)
			if j <= 0:
				return -INF
			_push(sim, j, d, log)
	_resolve_attacks(sim, log)
	var v := 0.0
	for ev: Dictionary in log:
		if ev.type == "damage" and ev.id == 0:
			v -= 300.0
		if ev.type == "death" and ev.id != 0:
			v += 60.0
	v -= 8.0 * hex_dist(sim[0].pos, EXIT)
	for u: Dictionary in sim:
		if u.alive and u.id != 0 and hex_dist(u.pos, sim[0].pos) == 1:
			v -= 15.0
	v += 0.001 * float(rng.randi_range(0, 100))
	return v


static func enemy_alive(us: Array[Dictionary]) -> int:
	var n := 0
	for u in us:
		if u.alive and u.id != 0:
			n += 1
	return n


func _ok(msg: String) -> Dictionary:
	return {"ok": true, "msg": msg}


func _err(msg: String) -> Dictionary:
	return {"ok": false, "msg": msg}
