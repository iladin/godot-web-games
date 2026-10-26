class_name TutorialHints
extends Control
## Contextual first-run tips (VS-004). One hint at a time, in STEPS order; a step is latched
## done the first time its condition holds, so the next one appears. H (or tapping the box)
## skips all tips for the rest of this page load. Pure step logic lives in update()/current()
## so selftest.gd can drive it with plain dictionaries.

const STEPS: Array[String] = ["steer", "throttle", "target", "dock", "map", "land"]
const AMBER := Color("ffb347")
const CYAN := Color("5ee6ff")
const BOX_BG := Color(0.02, 0.03, 0.08, 0.78)
const BOX_W := 760.0
const BOX_H := 66.0
const BOX_Y_FRAC := 0.58          # top of the box, as a fraction of screen height
const FADE_IN := 0.4

var main: VoidMain                # null in selftest: no gathering, no drawing
var done: Dictionary = {}         # step -> true once completed
var skipped: bool = false
var font: Font = ThemeDB.fallback_font
var _shown: String = ""
var _age: float = 0.0
var _box: Rect2 = Rect2()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Marks every step whose condition is true in ctx (step name -> bool) as done.
func update(ctx: Dictionary) -> void:
	for s: String in STEPS:
		if bool(ctx.get(s, false)):
			done[s] = true


## First unfinished step, or "" when all are done or tips were skipped.
func current() -> String:
	if skipped:
		return ""
	for s: String in STEPS:
		if not done.has(s):
			return s
	return ""


func skip() -> void:
	if skipped or current() == "":
		return
	skipped = true
	if main:
		main.sfx.play("click")
		main.u.message.emit("Tips hidden for this run", Color("8fd8ff"))


static func hint_text(step: String, touch: bool, planet: String) -> String:
	match step:
		"steer":
			return "Drag on the left side of the screen to steer" if touch else "Click the view to capture the mouse, then move it to steer"
		"throttle":
			return "Hold THR+ / THR- to change throttle" if touch else "Hold W / S to raise or lower throttle"
		"target":
			return "Tap TGT to lock onto a Hive ship, then FIRE" if touch else "Press R to lock onto a Hive ship, then fire with LMB or Space"
		"dock":
			return "Fly close to your HQ station and tap ACT to dock" if touch else "Fly close to your HQ station and press F to dock"
		"map":
			return "Tap MAP to open the command map" if touch else "Press M to open the command map"
		"land":
			return "Fly to planet %s and tap ACT to land" % planet if touch else "Fly to planet %s and press F to land" % planet
	return ""


static func skip_text(touch: bool) -> String:
	return "Tap this box to skip tips" if touch else "H: skip tips"


func _gather() -> Dictionary:
	var sp := main.space
	var t := main.touch
	var kb_steer := Input.get_axis("yaw_l", "yaw_r") != 0.0 or Input.get_axis("pitch_up", "pitch_dn") != 0.0
	return {
		"steer": Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or kb_steer or (t.active and t.stick != Vector2.ZERO),
		"throttle": main.mode == "flight" and (Input.is_action_pressed("thr_up") or Input.is_action_pressed("thr_dn") or t.held("thr_up") or t.held("thr_dn")),
		"target": sp != null and sp.target_id != 0,
		"dock": main.mode == "dock",
		"map": main.mode == "map",
		"land": main.mode == "surface",
	}


func _showing() -> bool:
	return main != null and main.state == VoidMain.State.PLAYING and not main.paused \
		and main.mode == "flight" and current() != ""


func _process(delta: float) -> void:
	if main == null:
		return
	if main.state == VoidMain.State.PLAYING and main.space and is_instance_valid(main.space.player):
		update(_gather())
	var cur := current() if _showing() else ""
	if cur != _shown:
		_shown = cur
		_age = 0.0
	_age += delta
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not _showing():
		return
	if event.is_action_pressed("skip_hints"):
		skip()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed \
			and _box.has_point((event as InputEventScreenTouch).position):
		skip()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	_box = Rect2()
	if _shown == "" or not _showing():
		return
	var touch := main.touch.active
	var planet := main.u.sectors[main.u.hq.sector].planet_name
	var a := clampf(_age / FADE_IN, 0.0, 1.0)
	var w := minf(BOX_W, size.x - 32.0)
	_box = Rect2((size.x - w) * 0.5, size.y * BOX_Y_FRAC, w, BOX_H)
	draw_rect(_box, Color(BOX_BG, BOX_BG.a * a))
	draw_rect(_box, Color(AMBER, 0.7 * a), false, 1.5)
	var idx := STEPS.find(_shown) + 1
	var head := "TIP %d/%d  " % [idx, STEPS.size()]
	var x := _box.position.x + 14.0
	draw_string(font, Vector2(x, _box.position.y + 28), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(AMBER, a))
	var hw := font.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(font, Vector2(x + hw, _box.position.y + 28), hint_text(_shown, touch, planet), HORIZONTAL_ALIGNMENT_LEFT, w - 28.0 - hw, 19, Color(1, 1, 1, a))
	draw_string(font, Vector2(x, _box.position.y + 54), skip_text(touch), HORIZONTAL_ALIGNMENT_RIGHT, w - 28.0, 15, Color(CYAN, 0.75 * a))
