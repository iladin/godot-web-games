class_name Pads
extends Node2D
## Play-field visuals: four wedge pads, centre hub with beat ring, particles, judgement popups, shake/flash.

const PAD_CENTER := Vector2(360, 700)
const PAD_R_INNER := 110.0
const PAD_R_OUTER := 320.0
const PAD_GAP_DEG := 6.0
const HUB_RADIUS := 90.0
const POP_SCALE := 1.12
const POP_TIME := 0.15
const SHAKE_PX := 10.0
const SHAKE_TIME := 0.3
const LIT_DECAY := 3.5
const BASE_COL := Color("1c1838")
const DIM_ALPHA := 0.25
const LIVE_ALPHA := 0.6
const COLORS: Array[Color] = [Color("3fe0ff"), Color("ff4fa3"), Color("ffd23f"), Color("8cff6b")]

var dim := true          # listening: pads are dimmed
var pulse := 0.0         # 1 on the beat -> 0
var progress := 0.0      # 0..1 echoed fraction
var hub_text := ""
var _lit: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _pop: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _parts: Array[Dictionary] = []
var _texts: Array[Dictionary] = []
var _shake := 0.0
var _flash := 0.0
var _font: Font = ThemeDB.fallback_font


func pad_at(p: Vector2) -> int:
	return EchoLogic.pad_for_point(p, PAD_CENTER, PAD_R_INNER)


func pad_pos(i: int) -> Vector2:
	var a: float = deg_to_rad(-90.0 + 90.0 * float(i))
	return PAD_CENTER + Vector2(cos(a), sin(a)) * (PAD_R_INNER + PAD_R_OUTER) * 0.5


func light(i: int) -> void:
	_lit[i] = 1.0
	_pop[i] = POP_TIME


func popup(text: String, col: Color, pos: Vector2) -> void:
	_texts.append({"s": text, "c": col, "p": pos, "t": 0.5})


func burst(pos: Vector2, col: Color, n: int, speed: float = 280.0) -> void:
	for k in n:
		var a: float = randf() * TAU
		var v: Vector2 = Vector2(cos(a), sin(a)) * speed * randf_range(0.4, 1.0)
		_parts.append({"p": pos, "v": v, "t": 0.6, "m": 0.6, "c": col})


func ring_burst(col: Color) -> void:
	for k in 48:
		var a: float = TAU * float(k) / 48.0
		_parts.append({"p": PAD_CENTER + Vector2(cos(a), sin(a)) * HUB_RADIUS, "v": Vector2(cos(a), sin(a)) * 420.0, "t": 0.8, "m": 0.8, "c": col})


func fail_fx() -> void:
	_shake = SHAKE_TIME
	_flash = 1.0


func reset() -> void:
	_parts.clear()
	_texts.clear()
	_shake = 0.0
	_flash = 0.0
	progress = 0.0
	for i in 4:
		_lit[i] = 0.0
		_pop[i] = 0.0


func _process(delta: float) -> void:
	for i in 4:
		_lit[i] = maxf(_lit[i] - delta * LIT_DECAY, 0.0)
		_pop[i] = maxf(_pop[i] - delta, 0.0)
	_flash = maxf(_flash - delta * 3.0, 0.0)
	_shake = maxf(_shake - delta, 0.0)
	var amp: float = SHAKE_PX * _shake / SHAKE_TIME
	position = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
	for i in range(_parts.size() - 1, -1, -1):
		var q: Dictionary = _parts[i]
		q["t"] = float(q["t"]) - delta
		if float(q["t"]) <= 0.0:
			_parts.remove_at(i)
			continue
		q["v"] = Vector2(q["v"]) * (1.0 - 2.0 * delta) + Vector2(0, 300.0) * delta
		q["p"] = Vector2(q["p"]) + Vector2(q["v"]) * delta
	for i in range(_texts.size() - 1, -1, -1):
		var tx: Dictionary = _texts[i]
		tx["t"] = float(tx["t"]) - delta
		if float(tx["t"]) <= 0.0:
			_texts.remove_at(i)
			continue
		tx["p"] = Vector2(tx["p"]) + Vector2(0, -70.0) * delta
	queue_redraw()


func _wedge(i: int, scale: float) -> PackedVector2Array:
	var mid: float = -90.0 + 90.0 * float(i)
	var a0: float = deg_to_rad(mid - 45.0 + PAD_GAP_DEG * 0.5)
	var a1: float = deg_to_rad(mid + 45.0 - PAD_GAP_DEG * 0.5)
	var pts := PackedVector2Array()
	for k in 13:
		var a: float = lerpf(a0, a1, float(k) / 12.0)
		pts.append(PAD_CENTER + Vector2(cos(a), sin(a)) * PAD_R_OUTER * scale)
	for k in 13:
		var a: float = lerpf(a1, a0, float(k) / 12.0)
		pts.append(PAD_CENTER + Vector2(cos(a), sin(a)) * PAD_R_INNER * scale)
	return pts


func _draw() -> void:
	var base_a: float = DIM_ALPHA if dim else LIVE_ALPHA
	for i in 4:
		var sc: float = 1.0
		if _pop[i] > 0.0:
			sc = 1.0 + (POP_SCALE - 1.0) * sin(PI * (1.0 - _pop[i] / POP_TIME))
		var pts := _wedge(i, sc)
		draw_colored_polygon(pts, BASE_COL)
		var col: Color = COLORS[i]
		col.a = lerpf(base_a, 1.0, _lit[i])
		draw_colored_polygon(pts, col)
		if _lit[i] > 0.0:
			draw_circle(pad_pos(i), 60.0 * _lit[i], Color(1, 1, 1, 0.35 * _lit[i]))
	draw_circle(PAD_CENTER, HUB_RADIUS, BASE_COL)
	draw_arc(PAD_CENTER, HUB_RADIUS + 6.0 + 12.0 * (1.0 - pulse), 0.0, TAU, 64, Color(0.95, 0.94, 1.0, 0.25 + 0.6 * pulse), 6.0)
	if progress > 0.0:
		draw_arc(PAD_CENTER, HUB_RADIUS - 12.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, Color("ffd23f"), 6.0)
	if hub_text != "":
		draw_string(_font, PAD_CENTER + Vector2(-60, 12), hub_text, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 34, Color("f2f0ff"))
	for q in _parts:
		var c: Color = q["c"]
		c.a = float(q["t"]) / float(q["m"])
		draw_circle(Vector2(q["p"]), 6.0, c)
	for tx in _texts:
		var tc: Color = tx["c"]
		tc.a = clampf(float(tx["t"]) / 0.3, 0.0, 1.0)
		draw_string(_font, Vector2(tx["p"]) + Vector2(-100, 0), String(tx["s"]), HORIZONTAL_ALIGNMENT_CENTER, 200.0, 40, tc)
	if _flash > 0.0:
		draw_rect(Rect2(-40, -40, 800, 1360), Color(1.0, 0.15, 0.2, 0.28 * _flash))
