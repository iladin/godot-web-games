class_name TouchControls
extends Control
## On-screen stick + buttons. Appears after the first real touch. Views poll it.

const STICK_RADIUS := 90.0
const BTN_RADIUS := 46.0
const BG := Color(1, 1, 1, 0.08)
const FG := Color(1, 1, 1, 0.35)
const ACTIVE := Color(1.0, 0.7, 0.28, 0.55)
## Utility row (SND/TRVL/MAP) sits below the HUD message log (top-right, 24 px per line from
## y=30): clear of 4 stacked messages, above ACT, and right of the centred tutorial tip box.
const TOP_ROW_Y := 190.0

var active: bool = false          # a touch has ever been seen
var layout: String = "none"       # none | flight | surface
var paused: bool = false          # pause screen up: only SND acts; other taps fall through
var stick: Vector2 = Vector2.ZERO
var _stick_idx: int = -1
var _stick_origin: Vector2 = Vector2.ZERO
var _look_idx: int = -1
var _look_last: Vector2 = Vector2.ZERO
var _look_accum: Vector2 = Vector2.ZERO
var _buttons: Array[Dictionary] = []
var _held: Dictionary = {}        # name -> touch index
var _pressed: Dictionary = {}     # name -> true until consumed
var font: Font = ThemeDB.fallback_font

const LAYOUTS: Dictionary = {
	"flight": [["fire", "FIRE", Vector2(-120, -130), 62.0], ["boost", "BOOST", Vector2(-250, -90), 0.0],
		["thr_up", "THR+", Vector2(-110, -290), 0.0], ["thr_dn", "THR-", Vector2(-230, -230), 0.0],
		["target", "TGT", Vector2(-360, -80), 0.0], ["act", "ACT", Vector2(-120, -420), 0.0],
		["map", "MAP", Vector2(-80, TOP_ROW_Y), 0.0], ["travel", "TRVL", Vector2(-200, TOP_ROW_Y), 0.0],
		["mute", "SND", Vector2(-320, TOP_ROW_Y), 0.0]],
	"surface": [["fire", "FIRE", Vector2(-120, -130), 62.0], ["jump", "JUMP", Vector2(-250, -90), 0.0],
		["reload", "RLD", Vector2(-120, -290), 0.0], ["act", "ACT", Vector2(-260, -230), 0.0],
		["sprint", "RUN", Vector2(-380, -80), 0.0], ["mute", "SND", Vector2(-320, TOP_ROW_Y), 0.0]],
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_layout(l: String) -> void:
	if l == layout:
		return
	layout = l
	_held.clear()
	_pressed.clear()
	_stick_idx = -1
	_look_idx = -1
	stick = Vector2.ZERO
	_relayout()


func _relayout() -> void:
	_buttons.clear()
	var sz := size
	for b: Array in LAYOUTS.get(layout, []):
		var off: Vector2 = b[2]
		var c := Vector2(sz.x + off.x if off.x < 0 else off.x, sz.y + off.y if off.y < 0 else off.y)
		if off.y > 0:
			c.y = off.y
		var r: float = b[3] if float(b[3]) > 0.0 else BTN_RADIUS
		_buttons.append({"name": b[0], "label": b[1], "c": c, "r": r})


func held(n: String) -> bool:
	return _held.has(n)


func pressed(n: String) -> bool:
	if _pressed.has(n):
		_pressed.erase(n)
		return true
	return false


func take_look() -> Vector2:
	var v := _look_accum
	_look_accum = Vector2.ZERO
	return v


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if not active:
			active = true
			_relayout()
		if layout == "none":
			return
		if t.pressed:
			_touch_down(t.index, t.position)
		else:
			_touch_up(t.index)
	elif event is InputEventScreenDrag and layout != "none":
		var d := event as InputEventScreenDrag
		if d.index == _stick_idx:
			stick = ((d.position - _stick_origin) / STICK_RADIUS).limit_length(1.0)
		elif d.index == _look_idx:
			_look_accum += d.position - _look_last
			_look_last = d.position


func _touch_down(idx: int, p: Vector2) -> void:
	for b: Dictionary in _buttons:
		if p.distance_to(b["c"]) <= float(b["r"]) * 1.15:
			if not paused or b["name"] == "mute":   # paused: other buttons are inert (no resume)
				_held[b["name"]] = idx
				_pressed[b["name"]] = true
			get_viewport().set_input_as_handled()
			return
	if paused:
		return   # left unhandled: PauseGate resumes on it; no stick/look grab
	if p.x < size.x * 0.4 and p.y > size.y * 0.3 and _stick_idx < 0:
		_stick_idx = idx
		_stick_origin = p
		stick = Vector2.ZERO
	elif _look_idx < 0:
		_look_idx = idx
		_look_last = p


func _touch_up(idx: int) -> void:
	if idx == _stick_idx:
		_stick_idx = -1
		stick = Vector2.ZERO
	if idx == _look_idx:
		_look_idx = -1
	for n: String in _held.keys():
		if int(_held[n]) == idx:
			_held.erase(n)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_relayout()


func _process(_delta: float) -> void:
	if active:
		queue_redraw()


func _draw() -> void:
	if not active or layout == "none":
		return
	if _stick_idx >= 0:
		draw_circle(_stick_origin, STICK_RADIUS, BG)
		draw_arc(_stick_origin, STICK_RADIUS, 0, TAU, 32, FG, 2.0)
		draw_circle(_stick_origin + stick * STICK_RADIUS, 34.0, ACTIVE)
	else:
		var home := Vector2(150, size.y - 160)
		draw_arc(home, STICK_RADIUS, 0, TAU, 32, FG, 2.0)
		draw_string(font, home + Vector2(-60, 6), "MOVE", HORIZONTAL_ALIGNMENT_CENTER, 120, 20, FG)
	for b: Dictionary in _buttons:
		var c: Vector2 = b["c"]
		var r: float = b["r"]
		draw_circle(c, r, ACTIVE if held(b["name"]) else BG)
		draw_arc(c, r, 0, TAU, 32, FG, 2.0)
		draw_string(font, c + Vector2(-r, 7), b["label"], HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 20, Color(1, 1, 1, 0.8))
