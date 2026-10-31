class_name LanternWorld
extends Node2D
## Run simulation (custom kinematics, level generation) and all in-world drawing.

signal died(reason: String)
signal picked(kind: int, pos: Vector2)
signal jumped(is_double: bool)
signal landed
signal footstep

enum { STALAG, SPIKE }
enum { OIL, EMBER }

const ROCK := Color("2a2238")
const AMBER := Color("ffb347")
const FLAME := Color("ffe9a8")
const DANGER := Color("e2493b")
const FAR := 1e9
const STEP_DIST := 110.0
const PICK_RADIUS := 46.0

var cam_x := 0.0
var t := 0.0
var vt := 0.0               # visual time, always advances
var speed := RunnerLogic.SPEED_START
var light := RunnerLogic.LIGHT_START
var out_timer := 0.0
var distance := 0.0
var oil_n := 0
var ember_n := 0
var pos_y := RunnerLogic.GROUND_Y
var vel_y := 0.0
var on_ground := true
var jumps_left := RunnerLogic.MAX_JUMPS
var coyote := 0.0
var buffer := 0.0
var cut_done := false
var squash := 0.0
var pulse := 0.0
var flick := 0.0
var alive := true
var gen_x := 0.0
var haz_count := 0
var step_acc := 0.0
var ground: Array[Vector2] = []
var hazards: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var parts: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var font: Font = ThemeDB.fallback_font


func reset() -> void:
	cam_x = 0.0
	t = 0.0
	speed = RunnerLogic.SPEED_START
	light = RunnerLogic.LIGHT_START
	out_timer = 0.0
	distance = 0.0
	oil_n = 0
	ember_n = 0
	pos_y = RunnerLogic.GROUND_Y
	vel_y = 0.0
	on_ground = true
	jumps_left = RunnerLogic.MAX_JUMPS
	coyote = 0.0
	buffer = 0.0
	alive = true
	haz_count = 0
	step_acc = 0.0
	ground = [Vector2(-1000.0, FAR)]
	hazards.clear()
	pickups.clear()
	parts.clear()
	popups.clear()
	gen_x = RunnerLogic.SAFE_START_PX - RunnerLogic.GAP_START
	_fill_ahead()


func player_x() -> float:
	return cam_x + RunnerLogic.PLAYER_SCREEN_X


func score() -> int:
	return RunnerLogic.score_for(distance, oil_n, ember_n)


func lantern_screen() -> Vector2:
	return Vector2(RunnerLogic.PLAYER_SCREEN_X + 26.0, pos_y - 34.0 + 4.0 * sin(vt * 9.0))


func light_radius() -> float:
	var r := light + flick + pulse * 45.0
	if out_timer > 0.0:
		r *= randf_range(0.45, 1.0)
	return r


# --- Input from main -----------------------------------------------------------
func press_jump() -> void:
	buffer = RunnerLogic.JUMP_BUFFER


func release_jump() -> void:
	buffer = 0.0
	if vel_y < 0.0 and not cut_done:
		vel_y *= RunnerLogic.JUMP_CUT
		cut_done = true


# --- Simulation ------------------------------------------------------------------
func step(dt: float) -> void:
	if not alive:
		return
	t += dt
	speed = RunnerLogic.speed_at(t)
	cam_x += speed * dt
	distance += speed * dt
	light = RunnerLogic.drain_light(light, RunnerLogic.drain_rate_at(t), dt)
	if light <= RunnerLogic.LIGHT_MIN:
		out_timer += dt
		if out_timer >= RunnerLogic.OUT_GRACE:
			_die("dark")
			return
	else:
		out_timer = 0.0
	_physics(dt)
	if not alive:
		return
	_collide()
	_fill_ahead()
	_cull()


func _physics(dt: float) -> void:
	var px := player_x()
	buffer -= dt
	coyote -= dt
	var over_pit := RunnerLogic.is_over_pit(px, ground)
	if on_ground:
		coyote = RunnerLogic.COYOTE_TIME
		if over_pit:
			on_ground = false
			jumps_left = RunnerLogic.MAX_JUMPS - 1
	if buffer > 0.0:
		if on_ground or coyote > 0.0:
			_jump(RunnerLogic.JUMP_VELOCITY, false)
		elif jumps_left > 0:
			jumps_left -= 1
			_jump(RunnerLogic.DOUBLE_JUMP_VELOCITY, true)
	if not on_ground:
		vel_y += RunnerLogic.GRAVITY * dt
		pos_y += vel_y * dt
		var gy := RunnerLogic.GROUND_Y
		if not over_pit and vel_y >= 0.0 and pos_y >= gy and pos_y <= gy + 30.0:
			pos_y = gy
			vel_y = 0.0
			on_ground = true
			jumps_left = RunnerLogic.MAX_JUMPS
			squash = 1.0
			_burst(Vector2(RunnerLogic.PLAYER_SCREEN_X, gy), 6, ROCK.lightened(0.5), 120.0)
			landed.emit()
		elif pos_y > gy + 200.0:
			_die("pit")
	else:
		step_acc += speed * dt
		if step_acc >= STEP_DIST:
			step_acc = 0.0
			footstep.emit()
		if randf() < 0.25:
			parts.append({"p": Vector2(RunnerLogic.PLAYER_SCREEN_X - 10.0, pos_y - 2.0), "v": Vector2(-90.0, randf_range(-50.0, -10.0)), "life": 0.0, "max": 0.4, "col": ROCK.lightened(0.6), "size": 3.0, "g": 0.0})


func _jump(v: float, is_double: bool) -> void:
	vel_y = v
	on_ground = false
	buffer = 0.0
	coyote = 0.0
	cut_done = false
	if not is_double:
		jumps_left = RunnerLogic.MAX_JUMPS - 1
	squash = -0.6
	_burst(Vector2(RunnerLogic.PLAYER_SCREEN_X, pos_y), 5, ROCK.lightened(0.5), 100.0)
	jumped.emit(is_double)


func _collide() -> void:
	var px := player_x()
	for h in hazards:
		if absf(h.x - px) > 80.0:
			continue
		if h.kind == STALAG and RunnerLogic.hits_stalag(px, pos_y, h.x, h.h):
			_die("stalagmite")
			return
		if h.kind == SPIKE and RunnerLogic.hits_spike(px, pos_y, h.x, h.h):
			_die("spike")
			return
	var centre := Vector2(px, pos_y - RunnerLogic.PLAYER_SIZE.y * 0.5)
	for p in pickups:
		if not p.taken and centre.distance_to(Vector2(p.x, p.y)) < PICK_RADIUS:
			p.taken = true
			_on_pickup(p)


func _on_pickup(p: Dictionary) -> void:
	var spos := Vector2(p.x - cam_x, p.y)
	if p.kind == OIL:
		oil_n += 1
		light = RunnerLogic.add_oil(light)
		out_timer = 0.0
		_popup("+%d" % RunnerLogic.OIL_POINTS, spos, AMBER)
		_burst(spos, 14, FLAME, 260.0)
		var tw := create_tween()
		pulse = 1.0
		tw.tween_property(self, "pulse", 0.0, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		ember_n += 1
		_popup("+%d" % RunnerLogic.EMBER_POINTS, spos, FLAME)
		_burst(spos, 18, AMBER, 320.0)
	picked.emit(p.kind, spos)


func _die(reason: String) -> void:
	alive = false
	_burst(Vector2(RunnerLogic.PLAYER_SCREEN_X, pos_y - 28.0), 24, FLAME, 380.0)
	died.emit(reason)


# --- Level generation ---------------------------------------------------------------
func _fill_ahead() -> void:
	var limit := cam_x + get_viewport_rect().size.x + 800.0
	while gen_x < limit:
		_spawn_next()


func _spawn_next() -> void:
	var gap := RunnerLogic.gap_at(t, speed)
	var hx := gen_x + gap
	haz_count += 1
	var from_x := gen_x
	var ember_x := hx
	var pits := RunnerLogic.pit_range_at(t)
	var roll := randf()
	if t >= RunnerLogic.SPIKE_TIME and roll < RunnerLogic.SPIKE_CHANCE:
		var h := randf_range(RunnerLogic.STALAG_H_MIN, RunnerLogic.STALAG_H_MAX - 15.0)
		hazards.append({"x": hx, "kind": STALAG, "h": h})
		hazards.append({"x": hx, "kind": SPIKE, "h": RunnerLogic.GROUND_Y - RunnerLogic.SPIKE_TIP_H})
		gen_x = hx + 30.0
	elif roll > 0.5:
		var w := randf_range(pits.x, pits.y)
		ground[ground.size() - 1].y = hx
		ground.append(Vector2(hx + w, FAR))
		gen_x = hx + w
		ember_x = hx + w * 0.5
	else:
		hazards.append({"x": hx, "kind": STALAG, "h": randf_range(RunnerLogic.STALAG_H_MIN, RunnerLogic.STALAG_H_MAX)})
		gen_x = hx + 30.0
	if haz_count % RunnerLogic.oil_every(t) == 0:
		var oy := RunnerLogic.GROUND_Y - (60.0 if randf() < 0.7 else 190.0)
		pickups.append({"x": from_x + gap * 0.5, "y": oy, "kind": OIL, "taken": false})
	if randf() < RunnerLogic.EMBER_CHANCE:
		pickups.append({"x": ember_x, "y": RunnerLogic.GROUND_Y - 270.0, "kind": EMBER, "taken": false})


func _cull() -> void:
	var lim := cam_x - 200.0
	hazards = hazards.filter(func(h: Dictionary) -> bool: return h.x > lim)
	pickups = pickups.filter(func(p: Dictionary) -> bool: return p.x > lim and not p.taken)
	while ground.size() > 1 and ground[0].y < lim:
		ground.remove_at(0)


# --- Effects (always run) ------------------------------------------------------------
func fx(dt: float) -> void:
	vt += dt
	squash = move_toward(squash, 0.0, dt / 0.12)
	flick = lerpf(flick, randf_range(-4.0, 4.0), 0.4)
	if alive and randf() < 0.5:
		var lp := lantern_screen()
		parts.append({"p": lp, "v": Vector2(randf_range(-90.0, -30.0), randf_range(-70.0, -20.0)), "life": 0.0, "max": randf_range(0.5, 1.0), "col": AMBER, "size": 2.5, "g": -20.0})
	for i in range(parts.size() - 1, -1, -1):
		var q: Dictionary = parts[i]
		q.life += dt
		q.v = Vector2(q.v.x, q.v.y + q.g * dt)
		q.p += q.v * dt
		if q.life >= q.max:
			parts.remove_at(i)
	for i in range(popups.size() - 1, -1, -1):
		popups[i].life += dt
		popups[i].pos = popups[i].pos - Vector2(0.0, 70.0 * dt)
		if popups[i].life > 0.8:
			popups.remove_at(i)
	queue_redraw()


func _burst(pos: Vector2, n: int, col: Color, spd: float) -> void:
	for i in n:
		var a := randf() * TAU
		var v := Vector2(cos(a), sin(a)) * randf_range(0.3, 1.0) * spd
		parts.append({"p": pos, "v": v, "life": 0.0, "max": randf_range(0.3, 0.7), "col": col, "size": randf_range(2.0, 4.0), "g": 500.0})


func _popup(text: String, pos: Vector2, col: Color) -> void:
	popups.append({"text": text, "pos": pos, "life": 0.0, "col": col})


# --- Drawing ----------------------------------------------------------------------------
func _draw() -> void:
	var vw := get_viewport_rect().size.x
	var gy := RunnerLogic.GROUND_Y
	draw_rect(Rect2(-50.0, -50.0, vw + 100.0, RunnerLogic.CEILING_Y + 50.0), ROCK)
	for seg in ground:
		var x0 := maxf(seg.x - cam_x, -50.0)
		var x1 := minf(seg.y - cam_x, vw + 50.0)
		if x1 <= x0:
			continue
		draw_rect(Rect2(x0, gy, x1 - x0, 500.0), ROCK)
		draw_rect(Rect2(x0, gy, x1 - x0, 3.0), Color(AMBER, 0.3))
	for h in hazards:
		_draw_hazard(h)
	for p in pickups:
		_draw_pickup(p)
	for q in parts:
		var a: float = 1.0 - q.life / q.max
		draw_circle(q.p, q.size * (0.5 + a * 0.5), Color(q.col, a))
	_draw_player()
	for pu in popups:
		var a: float = 1.0 - pu.life / 0.8
		draw_string(font, pu.pos - Vector2(60.0, 0.0), pu.text, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 34, Color(pu.col, a))


func _draw_hazard(h: Dictionary) -> void:
	var x: float = h.x - cam_x
	var hw := RunnerLogic.HAZARD_HALF_W
	if h.kind == STALAG:
		var base := RunnerLogic.GROUND_Y
		draw_colored_polygon(PackedVector2Array([Vector2(x - hw, base), Vector2(x + hw, base), Vector2(x, base - h.h)]), ROCK.lightened(0.12))
		draw_polyline(PackedVector2Array([Vector2(x - hw, base), Vector2(x, base - h.h), Vector2(x + hw, base)]), Color(AMBER, 0.5), 2.0)
	else:
		var c := RunnerLogic.CEILING_Y
		draw_colored_polygon(PackedVector2Array([Vector2(x - hw, c), Vector2(x + hw, c), Vector2(x, h.h)]), ROCK.lightened(0.12))
		var k := 0.35
		draw_colored_polygon(PackedVector2Array([Vector2(x - hw * k, h.h - (h.h - c) * k), Vector2(x + hw * k, h.h - (h.h - c) * k), Vector2(x, h.h)]), DANGER)


func _draw_pickup(p: Dictionary) -> void:
	var pos := Vector2(p.x - cam_x, p.y)
	if p.kind == OIL:
		pos.y += sin(vt * 4.0 + p.x) * 5.0
		draw_rect(Rect2(pos.x - 13.0, pos.y - 8.0, 26.0, 28.0), FLAME)
		draw_rect(Rect2(pos.x - 6.0, pos.y - 18.0, 12.0, 11.0), FLAME)
		draw_rect(Rect2(pos.x - 8.0, pos.y - 21.0, 16.0, 4.0), AMBER)
		draw_circle(pos + Vector2(-5.0, 2.0), 3.5 + sin(vt * 6.0), Color(1, 1, 1, 0.9))
	else:
		var r := 22.0
		var a := vt * 2.5
		var pts := PackedVector2Array()
		for i in 4:
			var ang := a + i * PI * 0.5
			var rad := r if i % 2 == 0 else r * 0.55
			pts.append(pos + Vector2(cos(ang), sin(ang)) * rad)
		draw_colored_polygon(pts, AMBER)
		draw_circle(pos, 5.0, FLAME)


func _draw_player() -> void:
	var feet := Vector2(RunnerLogic.PLAYER_SCREEN_X, pos_y)
	var sq := clampf(squash, -1.0, 1.0)
	draw_set_transform(feet, 0.0, Vector2(1.0 + 0.2 * sq, 1.0 - 0.2 * sq))
	var cloak := PackedVector2Array([Vector2(-17, 0), Vector2(17, 0), Vector2(0, -46)])
	draw_colored_polygon(cloak, ROCK.lightened(0.15))
	draw_polyline(PackedVector2Array([Vector2(-17, 0), Vector2(0, -46), Vector2(17, 0), Vector2(-17, 0)]), AMBER, 2.5)
	draw_circle(Vector2(0, -44), 10.0, ROCK.lightened(0.15))
	draw_arc(Vector2(0, -44), 10.0, 0.0, TAU, 20, AMBER, 2.0)
	draw_set_transform(Vector2.ZERO)
	var lp := lantern_screen()
	draw_line(Vector2(RunnerLogic.PLAYER_SCREEN_X + 8.0, pos_y - 30.0), lp, AMBER, 2.0)
	draw_circle(lp, 22.0, Color(AMBER, 0.18))
	draw_circle(lp, 10.0, FLAME)
