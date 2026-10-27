class_name RunFlow
extends RefCounted
## Run lifecycle for VoidMain: start, end screen, pause and best-score save.
## Rules owned here: the Universe only simulates while a run is in progress (not behind the
## title or end screen), and ending a run closes the command map / dock so the full-screen
## MapView (mouse_filter STOP) can't eat the restart click or tap.

const SAVE_PATH := "user://save.cfg"

var g: VoidMain


func _init(p_g: VoidMain) -> void:
	g = p_g


## True when Universe.step() may run for this state (TITLE and OVER keep the world frozen).
static func sim_runs(state: VoidMain.State) -> bool:
	return state == VoidMain.State.PLAYING


## True when the on-foot layer (surface tick, FPS input, evacuation on death) may run: only mid-run.
static func surface_live(state: VoidMain.State) -> bool:
	return state == VoidMain.State.PLAYING


func start() -> void:
	g.state = VoidMain.State.PLAYING
	g.state_time = 0.0
	g.overlay.screen = "none"
	g.sfx.play("click")
	g._set_mode("flight")
	var tips_on := g.hints != null and g.hints.current() != ""   # tips teach the controls (VS-017)
	g.u.message.emit("Welcome, Sovereign." if tips_on else "Welcome, Sovereign. Kill the Hive Cores, then the Nests. M = command map", Color("ffb347"))


func finish(won: bool) -> void:
	if g.state != VoidMain.State.PLAYING:
		return
	g.state = VoidMain.State.OVER
	g.state_time = 0.0
	close_overlays()
	var u := g.u
	var score := u.score(won)
	var ov := g.overlay
	ov.new_best = score > g.best
	if score > g.best:
		g.best = score
		save_best(g.best)
	ov.screen = "over"
	ov.won = won
	ov.score = score
	ov.best = g.best
	ov.t = 0.0
	ov.stats = "Time %d:%02d  ·  Kills %d  ·  Colonies %d  ·  Net worth %s" % [int(u.time / 60.0), int(u.time) % 60, u.kills, u.colonies(), Hud._fmt(u.net_worth())]


## Hide map/dock (undocking), drop flight HUD and touch buttons, free the mouse.
## Called with state already OVER, so _set_mode leaves flight input and HUD off.
func close_overlays() -> void:
	g._set_mode("surface" if g.mode == "surface" else "flight")
	g.hud.mode = "none"
	g.touch.set_layout("none")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func pause() -> void:
	g.pause_gate.pause()


func load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	return int(cfg.get_value("score", "best", 0))


func save_best(value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", value)
	cfg.save(SAVE_PATH)
