extends Node2D
## Lantern Run: state machine (TITLE -> PLAYING -> GAME_OVER), input, save, juice wiring.
## Gameplay numbers live in runner_logic.gd (RunnerLogic); look & flow tunables are below.

# --- Tunables ---------------------------------------------------------------
const BG := Color("07060d")
const ACCENT := Color("ffb347")
const FLAME := Color("ffe9a8")
const DANGER := Color("e2493b")
const SHAKE_PX := 8.0
const SHAKE_TIME := 0.25
const FLASH_TIME := 0.3
const RESTART_DELAY := 0.6
const AUTO_RESTART := 1.2        # autoplay bot restarts itself after this long
const TITLE_LIGHT := 300.0
const SAVE_PATH := "user://save.cfg"

enum State { TITLE, PLAYING, GAME_OVER }

var state: State = State.TITLE
var state_time := 0.0
var score := 0
var best := 0
var new_best := false
var paused := false
var autoplay := false
var shake := 0.0
var bot := LanternBot.new()
var world: LanternWorld
var dark: ColorRect
var hud: LanternHud
var sfx: LanternSfx
var shot_file := ""
var frames := 0


func _ready() -> void:
	_register_actions()
	RenderingServer.set_default_clear_color(BG)
	world = LanternWorld.new()
	add_child(world)
	var dl := CanvasLayer.new()
	dl.layer = 1
	add_child(dl)
	dark = ColorRect.new()
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark.material = ShaderMaterial.new()
	(dark.material as ShaderMaterial).shader = preload("res://scripts/darkness.gdshader")
	dl.add_child(dark)
	var hl := CanvasLayer.new()
	hl.layer = 2
	add_child(hl)
	hud = LanternHud.new()
	hl.add_child(hud)
	sfx = LanternSfx.new()
	add_child(sfx)
	world.died.connect(_on_died)
	world.picked.connect(func(kind: int, _p: Vector2) -> void: sfx.play(&"oil" if kind == LanternWorld.OIL else &"ember"))
	world.jumped.connect(func(d: bool) -> void: sfx.play(&"jump2" if d else &"jump"))
	world.landed.connect(func() -> void: sfx.play(&"land"))
	world.footstep.connect(func() -> void: sfx.play(&"step"))
	best = _load_best()
	world.reset()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shotfile="):
			shot_file = a.substr(11)
	if "--autoplay" in OS.get_cmdline_user_args():
		autoplay = true
		sfx.enabled = true
		_start_game()


func _register_actions() -> void:
	_add_keys(&"jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_keys(&"pause", [KEY_ESCAPE, KEY_P])
	_add_keys(&"start", [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER])


func _add_keys(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k: Key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


# --- State machine ---------------------------------------------------------------
func _start_game() -> void:
	state = State.PLAYING
	state_time = 0.0
	score = 0
	new_best = false
	shake = 0.0
	world.reset()


func _on_died(_reason: String) -> void:
	state = State.GAME_OVER
	state_time = 0.0
	score = world.score()
	shake = SHAKE_TIME
	hud.flash = FLASH_TIME
	sfx.play(&"die")
	if score > best:
		best = score
		new_best = true
		_save_best(best)
	if autoplay:
		print("AUTOPLAY run ended: score=%d dist=%dm t=%.1fs reason=%s" % [score, int(world.distance / 10.0), world.t, _reason])


func _process(delta: float) -> void:
	frames += 1
	if shot_file != "" and frames >= 180:
		get_viewport().get_texture().get_image().save_png(shot_file)
		get_tree().quit()
		return
	if paused:
		_update_visuals()
		return
	state_time += delta
	hud.t += delta
	hud.flash = maxf(hud.flash - delta / FLASH_TIME, 0.0)
	shake = maxf(shake - delta, 0.0)
	world.fx(delta)
	match state:
		State.PLAYING:
			if autoplay:
				_bot_input()
			world.step(delta)
			score = world.score()
		State.GAME_OVER:
			if autoplay and state_time > AUTO_RESTART:
				_start_game()
	_update_visuals()


func _bot_input() -> void:
	var a := bot.decide(world)
	if a == 0:
		return
	var ev := InputEventAction.new()
	ev.action = &"jump"
	ev.pressed = a > 0
	Input.parse_input_event(ev)


func _update_visuals() -> void:
	var off := Vector2.ZERO
	if shake > 0.0:
		off = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * SHAKE_PX * (shake / SHAKE_TIME)
	world.position = off
	var size := get_viewport_rect().size
	dark.size = size
	var m := dark.material as ShaderMaterial
	var radius := TITLE_LIGHT if state == State.TITLE else world.light_radius()
	m.set_shader_parameter("light_pos", world.lantern_screen() + off)
	m.set_shader_parameter("light_radius", radius)
	var danger := 0.0
	if state == State.PLAYING and world.light < RunnerLogic.LOW_LIGHT_WARN:
		danger = 0.6 + 0.4 * sin(world.vt * 8.0)
	m.set_shader_parameter("danger", danger)
	hud.mode = state
	hud.score = score
	hud.best = best
	hud.new_best = new_best
	hud.dist_m = int(world.distance / 10.0)
	hud.light_frac = world.light / RunnerLogic.LIGHT_MAX
	hud.low_light = world.light < RunnerLogic.LOW_LIGHT_WARN
	hud.out_warn = world.out_timer > 0.0
	hud.paused = paused
	hud.show_retry = state_time > RESTART_DELAY


# --- Input -------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	var down := false
	var up := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		down = event.pressed
		up = not event.pressed
		if down and state == State.PLAYING and not paused and hud.pause_rect().has_point(event.position):
			paused = true
			return
	elif event.is_action_pressed(&"pause") and state == State.PLAYING:
		paused = not paused
		return
	elif event.is_action_pressed(&"jump") or event.is_action_pressed(&"start"):
		down = true
	elif event.is_action_released(&"jump"):
		up = true
	if not (down or up):
		return
	sfx.enabled = true
	if paused:
		if down:
			paused = false
		return
	match state:
		State.TITLE:
			if down:
				_start_game()
		State.PLAYING:
			if down:
				world.press_jump()
			else:
				world.release_jump()
		State.GAME_OVER:
			if down and state_time > RESTART_DELAY:
				_start_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING:
		paused = true


# --- Save --------------------------------------------------------------------------
func _load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	return int(cfg.get_value("save", "best", 0))


func _save_best(value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "best", value)
	cfg.save(SAVE_PATH)
