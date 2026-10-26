class_name VoidMain
extends Node
## Void Sovereign — orchestrator. Owns the Universe (simulation) and switches between
## the three play layers: flight (SpaceView), command map (MapView), surface (SurfaceView).
## State machine: TITLE -> PLAYING -> OVER -> (restart). Keeps the --autoplay hook for check.sh.

const RESTART_DELAY := 0.8
const RESPAWN_DELAY := 2.5
const EVAC_HULL_LOSS := 0.4
const FADE_TIME := 0.35
const UI_FONT_SIZE := 18

enum State { TITLE, PLAYING, OVER }

var state: State = State.TITLE
var mode: String = "flight"           # flight | map | dock | surface
var u: Universe
var space: SpaceView
var surface: SurfaceView
var ui: CanvasLayer
var hud: Hud
var map: MapView
var dock: DockPanel
var touch: TouchControls
var hints: TutorialHints
var overlay: Overlay
var fade: ColorRect
var docked_at: StationData
var best: int = 0
var paused: bool = false
var state_time: float = 0.0
var respawn_t: float = -1.0
var autoplay: bool = false
var shot_mode: String = ""
var shot_file: String = ""
var driver: TestDriver
var sfx: Sfx
var flow: RunFlow
var pause_gate: PauseGate


func _ready() -> void:
	Controls.register()
	flow = RunFlow.new(self)
	pause_gate = PauseGate.new(self)
	add_child(pause_gate)   # first child: its _input runs after TouchControls', before the GUI
	best = flow.load_best()
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_mode = a.trim_prefix("--shot=")
		elif a.begins_with("--shotfile="):
			shot_file = a.trim_prefix("--shotfile=")
	autoplay = "--autoplay" in OS.get_cmdline_user_args() or shot_mode != ""
	driver = TestDriver.new(self)
	sfx = Sfx.new()
	add_child(sfx)
	sfx.mute_changed.connect(func(m: bool) -> void: u.message.emit("Sound off (N)" if m else "Sound on", Color("8fd8ff")))
	_build_ui()
	_new_world()
	# Plain --autoplay starts from the title (TestDriver checks the world is frozen there first);
	# shot scenarios other than "title" start a run straight away.
	if shot_mode != "" and shot_mode != "title":
		_start_game()


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font_size = UI_FONT_SIZE
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.02, 0.03, 0.08, 0.93)
	panel.border_color = Color("ffb347")
	panel.set_border_width_all(1)
	panel.set_content_margin_all(18)
	panel.set_corner_radius_all(6)
	theme.set_stylebox("panel", "PanelContainer", panel)
	root.theme = theme
	ui.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud = Hud.new()
	root.add_child(hud)
	map = MapView.new()
	root.add_child(map)
	map.visible = false
	map.close_requested.connect(func() -> void: _set_mode("flight"))
	dock = DockPanel.new()
	root.add_child(dock)
	dock.visible = false
	dock.undock_pressed.connect(func() -> void: _set_mode("flight"))
	touch = TouchControls.new()
	root.add_child(touch)
	hints = TutorialHints.new()
	hints.main = self
	root.add_child(hints)
	overlay = Overlay.new()
	root.add_child(overlay)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)


func _new_world() -> void:
	if space:
		space.queue_free()
	if surface:
		surface.queue_free()
		surface = null
	if u:
		u.director = null   # break the Universe <-> Director reference cycle
	u = Universe.new()
	u.setup(randi() % 100000 if not autoplay else 7)
	space = SpaceView.new()
	space.autoplay = autoplay
	add_child(space)
	space.setup(u, touch)
	space.spawn_player()
	space.dock_requested.connect(_on_dock)
	space.land_requested.connect(_on_land)
	space.player_hit_something.connect(func() -> void: hud.hit(); sfx.play("hit"))
	space.sfx.connect(func(n: String) -> void: sfx.play(n))
	space.player_damaged.connect(func(a: float) -> void: hud.damaged(a))
	u.player_died.connect(func() -> void: respawn_t = RESPAWN_DELAY)
	u.finished.connect(_on_finished)
	hud.bind(u)
	hud.space = space
	hud.surface = null
	if map.u == null:
		map.setup(u)
	else:
		map.u = u
		map.selected.clear()
	mode = "flight"
	space.flight_enabled = false
	hud.mode = "none"
	overlay.screen = "title"
	overlay.best = best


# --- State machine ---------------------------------------------------------------------------
func _start_game() -> void:
	flow.start()


func _on_finished(won: bool) -> void:
	flow.finish(won)


func _process(delta: float) -> void:
	if paused:
		return
	state_time += delta
	if RunFlow.sim_runs(state):   # frozen behind the title and end screens
		u.step(delta)
	if state == State.PLAYING and respawn_t >= 0.0:
		respawn_t -= delta
		if respawn_t < 0.0:
			if mode != "flight":
				_set_mode("flight")
			u.respawn_player()
			space.spawn_player()
	if mode == "surface" and surface:
		surface.tick(delta)
	elif space:
		space.tick(delta)
	if autoplay:
		driver.tick()


func _set_mode(m: String) -> void:
	var prev := mode
	mode = m
	if m != prev and (m == "map" or m == "dock" or prev == "map" or prev == "dock"):
		sfx.play("click")
	map.visible = m == "map"
	dock.visible = m == "dock"
	if prev == "dock" and m != "dock" and docked_at:
		space.set_docked(false, docked_at)
		docked_at = null
	var live := state == State.PLAYING
	space.flight_enabled = m == "flight" and live
	hud.mode = ("flight" if m == "flight" else ("surface" if m == "surface" else "none")) if live else "none"
	touch.set_layout(("flight" if m == "flight" else ("surface" if m == "surface" else "none")) if live else "none")
	if m == "map":
		map.open(space.sector_idx)
	if m == "map" or m == "dock":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_dock(st: StationData) -> void:
	if state != State.PLAYING:
		return
	docked_at = st
	space.set_docked(true)
	dock.open(u, st)
	_set_mode("dock")


func _on_land(sector_idx: int) -> void:
	if state != State.PLAYING:
		return
	var run_u := u
	await _fade_to(1.0)
	if state != State.PLAYING or u != run_u:   # run ended (or restarted) during the fade
		_fade_to(0.0)
		return
	u.player_ship.hidden = true
	space.visible = false
	space.remove_child(space.env)   # only one WorldEnvironment may be active
	surface = SurfaceView.new()
	surface.autoplay = autoplay
	add_child(surface)
	surface.setup(u, touch, sector_idx)
	surface.takeoff_requested.connect(_leave_surface.bind(false))
	surface.player_died.connect(func() -> void: _leave_surface.call_deferred(true))
	surface.hit_something.connect(func() -> void: hud.hit(); sfx.play("hit"))
	surface.sfx.connect(func(n: String) -> void: sfx.play(n))
	surface.player_damaged.connect(func(a: float) -> void: hud.damaged(a))
	hud.surface = surface
	_set_mode("surface")
	u.message.emit("Landed on %s. Destroy the shield pylons, then the Core." % u.sectors[sector_idx].planet_name, Color("ffb347"))
	_fade_to(0.0)


func _leave_surface(evac: bool) -> void:
	if surface == null:
		return
	await _fade_to(1.0)
	if surface == null:
		return
	surface.queue_free()
	surface = null
	hud.surface = null
	space.visible = true
	space.add_child(space.env)
	space.cam.make_current()
	var ps := u.player_ship
	ps.hidden = false
	var s := u.sectors[space.sector_idx]
	var out := (space.player.position - s.planet_pos).normalized()
	space.player.position = s.planet_pos + out * (Defs.PLANET_RADIUS + 300.0)
	space.player.look_at(space.player.position + out * 100.0, Vector3.UP)
	space.player.vel = out * 120.0
	ps.pos = space.player.position
	if evac:
		ps.hull = maxf(1.0, ps.hull - ps.hull_max * EVAC_HULL_LOSS)
		u.message.emit("Emergency evacuation to orbit — hull damaged", Color.ORANGE)
	_set_mode("flight")
	_fade_to(0.0)


func _fade_to(a: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", a, FADE_TIME)
	await tw.finished


# --- Input ------------------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	var press := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or event.is_action_pressed("ui_accept")
	if paused:   # PauseGate (_input) owns pause-screen input
		return
	match state:
		State.TITLE:
			if press:
				overlay.touch_hint = touch.active
				_start_game()
		State.OVER:
			if press and state_time > RESTART_DELAY:
				_new_world()
				_start_game()
		State.PLAYING:
			if event.is_action_pressed("map"):
				if mode == "flight":
					_set_mode("map")
				elif mode == "map":
					_set_mode("flight")
			elif event.is_action_pressed("pause"):
				_pause()
			elif event.is_action_pressed("ui_cancel") and (mode == "map" or mode == "dock"):
				_set_mode("flight")


func _physics_process(_delta: float) -> void:
	# Touch MAP button is polled (it doesn't produce an InputEvent action).
	if state == State.PLAYING and mode == "flight" and touch.pressed("map"):
		_set_mode("map")
	if touch.pressed("mute"):
		sfx.toggle_mute()


func _pause() -> void:
	flow.pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING and not autoplay:
		_pause()

