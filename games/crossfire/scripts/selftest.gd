extends SceneTree
## Logic checks for Crossfire: hex math, shove/push/collision/pit rules, friendly fire,
## bombs, previews, floor generation, and bot balance runs through the text API.

const T := preload("res://scripts/tactics.gd")


func _init() -> void:
	assert(T.hex_dist(Vector2i(0, 0), Vector2i(2, -1)) == 2)
	assert(T.line_dir(Vector2i(0, 0), Vector2i(0, 3)) == 5)
	assert(T.line_dir(Vector2i(0, 0), Vector2i(1, 1)) == -1)
	assert(T.dir_from_name("SW") == 4)

	# Shove into a pit: enemy falls and dies, score goes up.
	var g := _arena({Vector2i(2, 0): "pit"}, [["brute", Vector2i(1, 0)]])
	assert(g.act("shove e").ok)
	assert(g.enemy_count() == 0 and g.score == T.KILL_POINTS)
	# Shove into a wall: 1 damage (brute dies, knight survives).
	g = _arena({Vector2i(2, 0): "wall"}, [["knight", Vector2i(1, 0)]])
	g.act("shove e")
	assert(g.enemy_count() == 1 and g.units[1].hp == 1 and g.units[1].pos == Vector2i(1, 0))
	# Collision: both take 1.
	g = _arena({}, [["brute", Vector2i(1, 0)], ["archer", Vector2i(2, 0)]])
	g.act("shove e")
	assert(g.enemy_count() == 0 and g.score == T.KILL_POINTS * 2 + T.COMBO_POINTS)
	# Shoving a brute moves its smash with it.
	g = _arena({}, [["brute", Vector2i(1, 0)]])
	assert(g.units[1].intent.kind == "smash")
	assert(g.preview().player_damage == 1)
	g.act("shove e")
	assert(g.preview().player_damage == 0)
	# Friendly fire: the archer's shot hits the first unit in line.
	g = _arena({}, [["archer", Vector2i(-3, 0)], ["brute", Vector2i(2, -2)]])
	assert(g.units[1].intent.kind == "shot")
	g.units[2].pos = Vector2i(-1, 0)
	g.units[2].intent = {}
	g._dirty()
	var pv := g.preview()
	assert(pv.player_damage == 0 and pv.deaths.size() == 1)
	assert(g.act("end").ok and g.player().hp == T.PLAYER_HP)
	# Bombs: hit the target hex and push neighbours outward.
	g = _arena({}, [["bomber", Vector2i(0, -3)], ["brute", Vector2i(-1, 0)]])
	assert(g.units[1].intent.kind == "bomb")
	g.units[2].intent = {}
	g._dirty()
	g.act("end")
	assert(g.player().hp == T.PLAYER_HP - 1)
	assert(not g.units.is_empty())
	# Bad commands are rejected without side effects.
	assert(not g.act("move up").ok)
	assert(not g.act("fly").ok)

	# Floors 1-10 generate with a path and the right number of enemies.
	var f := T.new(99)
	f.new_game()
	for k in T.FLOORS:
		assert(f.enemy_count() == mini(2 + f.floor_no / 2, T.MAX_ENEMIES))
		assert(f._bfs({T.START: 0}, []).has(T.EXIT))
		f.units[0].pos = T.EXIT + Vector2i(0, 1)
		f.move_left = true
		if f.phase != T.Phase.PLAYER:
			break
		f.act("move nw")
		if f.phase == T.Phase.WIN:
			break

	# Balance: the search bot plays full runs through the command API.
	var t0 := Time.get_ticks_msec()
	var floors_sum := 0
	var wins := 0
	var runs := 12
	for s in runs:
		var b := T.new(1000 + s)
		b.act("start")
		var guard := 0
		while b.phase == T.Phase.PLAYER and guard < 3000:
			guard += 1
			var cmd := b.bot_command()
			var r: Dictionary = b.act(cmd)
			assert(r.ok or b.phase != T.Phase.PLAYER, "bot command failed: %s -> %s" % [cmd, r.msg])
		floors_sum += b.floor_no
		if b.phase == T.Phase.WIN:
			wins += 1
	print("bot: avg floor %.1f, wins %d/%d, %d ms" % [float(floors_sum) / runs, wins, runs, Time.get_ticks_msec() - t0])
	assert(float(floors_sum) / runs >= 2.0)
	print("SELFTEST OK")
	quit()


## A fresh open board (no walls/pits except `special`), player at the centre, given enemies.
func _arena(special: Dictionary, enemies: Array) -> T:
	var g := T.new(5)
	g.new_game()
	for h: Vector2i in g.tiles:
		g.tiles[h] = "floor"
	for h: Vector2i in special:
		g.tiles[h] = special[h]
	g.units = [g.units[0]]
	g.units[0].pos = Vector2i(0, 0)
	g.units[0].hp = T.PLAYER_HP
	for e: Array in enemies:
		g.units.append({"id": g.next_id, "kind": e[0], "pos": e[1], "hp": T.KIND_HP[e[0]], "alive": true, "intent": {}, "reload": false})
		g.next_id += 1
	for i in range(1, g.units.size()):
		g._plan_intent(i)
	g.move_left = true
	g.shove_left = true
	g._dirty()
	return g
