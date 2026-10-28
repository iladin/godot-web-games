class_name TutorialHints
extends Control
## Contextual first-run tips (VS-004). One hint at a time, in STEPS order; a step is latched
## done the first time its condition holds, so the next one appears. H (or tapping the box)
## skips all tips for the rest of this page load. A step whose ctx["ready"][step] is false
## (e.g. "target" with no Hive ship in the sector) is passed over until it can be done (VS-017). Pure step logic lives in update()/current()
## so selftest.gd can drive it with plain dictionaries.

const STEPS: Array[String] = ["steer", "throttle", "target", "dock", "map", "land"]
const AMBER := Color("ffb347")
const CYAN := Color("5ee6ff")
const BOX_BG := Color(0.02, 0.03, 0.08, 0.78)
const BOX_W := 720.0
const BOX_H := 66.0
const BOX_Y_FRAC := 0.65          # top of the box, as a fraction of screen height; VS-038: just below the ship (ship ends ~0.63), above the HUD bars
const FADE_IN := 0.4
const SKIP_W := 140.0             # touch: dedicated skip chip, right of the steer zone
const SKIP_H := 44.0
const ENGAGE_RANGE := 1500.0      # VS-046: a living Hive ship this close (just beyond the Ravager's 1150 gun range) defers the tip
const SHIELD_HOLD := 4.0          # VS-046: seconds after the last shield/hull loss that still count as "in a fight"

static var on_screen: String = ""  # step drawn now; HUD hides its duplicate capture/prompt lines
static var pending: bool = false   # VS-058: a tip wants the touch message lane (HudLane picks the occupant)
static var deferred: bool = false  # VS-046: a tip is waiting out a fight; HUD keeps its own hint lines quiet too

var main: VoidMain                # null in selftest: no gathering, no drawing
var done: Dictionary = {}         # step -> true once completed
var can_do: Dictionary = {}        # step -> false while it cannot be completed (default ready)
var skipped: bool = false
var threatened: bool = false       # VS-046: fight in progress; current() defers (never skips) the tip
var _last_hp: float = -1.0
var _hurt_t: float = 99.0
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
	if ctx.has("ready"):
		can_do = ctx["ready"]
	if ctx.has("threat"):
		threatened = bool(ctx["threat"])


## First unfinished step that can be completed now, or "" when none (or tips were skipped).
func current() -> String:
	if skipped or threatened:
		return ""
	for s: String in STEPS:
		if not done.has(s) and bool(can_do.get(s, true)):
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
			return "Dock at the Union Trade Hub (tap ACT) to trade" if touch else "Fly to the Union Trade Hub and press F to dock and trade wares"
		"map":
			return "Tap MAP to open the command map" if touch else "Press M to open the command map"
		"land":
			return "Fly to planet %s and tap ACT to land" % planet if touch else "Fly to planet %s and press F to land" % planet
	return ""


static func skip_text(touch: bool) -> String:
	return "SKIP TIPS" if touch else "H: skip tips"


## VS-046: true while a living Hive ship is within ENGAGE_RANGE of pos in the sector.
static func hostile_near(u: Universe, sector_idx: int, pos: Vector3) -> bool:
	for e: SimEntity in u.ents_in(sector_idx):
		if e.faction == Defs.Faction.HIVE and e.alive and e.pos.distance_to(pos) - e.radius <= ENGAGE_RANGE:
			return true
	return false


## True when R / TGT has something to lock: a live Hive entity in the sector.
static func hostile_in(u: Universe, sector_idx: int) -> bool:
	for e: SimEntity in u.ents_in(sector_idx):
		if e.faction == Defs.Faction.HIVE and e.alive:
			return true
	return false


## Touch skip target: inside the right end of the tip box, outside the steer zone (x < 40%)
## and left of the THR-/THR+ buttons; the rest of the box no longer eats taps or drags.
func skip_rect() -> Rect2:
	return lane_skip_rect(_box)


## VS-058: the chip sits inside the one-line lane box, right end.
static func lane_skip_rect(box: Rect2) -> Rect2:
	return Rect2(box.end.x - SKIP_W - 4.0, box.position.y + 2.0, SKIP_W, box.size.y - 4.0)


## Tracks recent shield/hull loss; returns true while a fight is on (hostile near or hurt lately).
func _threat(delta: float) -> bool:
	var ps := main.u.player_ship
	var hp := ps.hull + ps.shield
	if _last_hp >= 0.0 and hp < _last_hp - 0.01:
		_hurt_t = 0.0
	_last_hp = hp
	_hurt_t += delta
	return _hurt_t < SHIELD_HOLD or hostile_near(main.u, main.space.sector_idx, ps.pos)


func _gather(delta: float = 0.0) -> Dictionary:
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
		"threat": _threat(delta),
		"ready": {"target": sp != null and hostile_in(main.u, sp.sector_idx)},
	}


func _wanted() -> bool:
	return main != null and main.state == VoidMain.State.PLAYING and not main.paused \
		and main.mode == "flight" and current() != ""


func _showing() -> bool:
	# VS-058: on touch the tip only shows when the message lane gives it the slot.
	return _wanted() and (not main.touch.active or HudLane.kind == "tip")


func _process(delta: float) -> void:
	if main == null:
		return
	if main.state == VoidMain.State.PLAYING and main.space and is_instance_valid(main.space.player):
		update(_gather(delta))
	pending = _wanted()
	var cur := current() if _showing() else ""
	on_screen = cur
	deferred = threatened and not skipped and main.mode == "flight"
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
			and _box.size.x > 0.0 and main.touch.active \
			and skip_rect().has_point((event as InputEventScreenTouch).position):
		skip()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	_box = Rect2()
	if _shown == "" or not _showing():
		return
	var touch := main.touch.active
	var planet := main.u.sectors[main.u.hq.sector].planet_name
	var a := clampf(_age / FADE_IN, 0.0, 1.0)
	var idx := STEPS.find(_shown) + 1
	var head := "TIP %d/%d  " % [idx, STEPS.size()]
	if touch:   # VS-058: one-line tip in the bottom message lane, skip chip inline
		_box = HudLane.rect(size)
		draw_rect(_box, Color(BOX_BG, BOX_BG.a * a))
		draw_rect(_box, Color(AMBER, 0.7 * a), false, 1.5)
		var tx := _box.position.x + 10.0
		var avail := _box.size.x - SKIP_W - 24.0
		var fs := 17
		var full := head + hint_text(_shown, true, planet)
		while font.get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > avail and fs > 12:
			fs -= 1
		draw_string(font, Vector2(tx, _box.position.y + 20), head, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(AMBER, a))
		var hw2 := font.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(tx + hw2, _box.position.y + 20), hint_text(_shown, true, planet), HORIZONTAL_ALIGNMENT_LEFT, avail - hw2, fs, Color(1, 1, 1, a))
		var sr2 := skip_rect()
		draw_rect(sr2, Color(BOX_BG, BOX_BG.a * a))
		draw_rect(sr2, Color(CYAN, 0.75 * a), false, 1.5)
		draw_string(font, sr2.position + Vector2(0, 19), skip_text(true), HORIZONTAL_ALIGNMENT_CENTER, SKIP_W, 15, Color(CYAN, a))
		return
	var w := minf(BOX_W, size.x - 32.0)
	_box = Rect2((size.x - w) * 0.5, size.y * BOX_Y_FRAC, w, BOX_H)
	draw_rect(_box, Color(BOX_BG, BOX_BG.a * a))
	draw_rect(_box, Color(AMBER, 0.7 * a), false, 1.5)
	var x := _box.position.x + 14.0
	draw_string(font, Vector2(x, _box.position.y + 28), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(AMBER, a))
	var hw := font.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(font, Vector2(x + hw, _box.position.y + 28), hint_text(_shown, false, planet), HORIZONTAL_ALIGNMENT_LEFT, w - 28.0 - hw, 19, Color(1, 1, 1, a))
	draw_string(font, Vector2(x, _box.position.y + 54), skip_text(false), HORIZONTAL_ALIGNMENT_RIGHT, w - 28.0, 15, Color(CYAN, 0.75 * a))
