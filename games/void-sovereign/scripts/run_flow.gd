class_name RunFlow
extends RefCounted
## Run lifecycle for VoidMain: start, end screen, pause and best-score save.
## Rules owned here: the Universe only simulates while a run is in progress (not behind the
## title or end screen), and ending a run closes the command map / dock so the full-screen
## MapView (mouse_filter STOP) can't eat the restart click or tap.

const SAVE_PATH := "user://save.cfg"
const CONFIRM_GUARD := 0.35      # seconds before the confirming press counts (VS-028)
const SAVE_FAIL_MSG_GAP := 300.0  # seconds between "autosave failed" HUD messages (VS-033)
const AUTOSAVE_INTERVAL := 60.0   # seconds of PLAYING between autosaves (VS-027)

var g: VoidMain
var save_path: String = RunSave.PATH
var _save_t: float = 0.0
var _fail_msg_at: float = -1.0   # when the last save-failure HUD message was shown
var _confirm_at: float = -1.0   # >= 0 while the title asks "replace your saved run?"


func _init(p_g: VoidMain) -> void:
	g = p_g


## True when Universe.step() may run for this state (TITLE and OVER keep the world frozen).
static func sim_runs(state: VoidMain.State) -> bool:
	return state == VoidMain.State.PLAYING


## True when the on-foot layer (surface tick, FPS input, evacuation on death) may run: only mid-run.
static func surface_live(state: VoidMain.State) -> bool:
	return state == VoidMain.State.PLAYING


func start(msg: String = "") -> void:
	_confirm_at = -1.0
	_save_t = 0.0
	g.state = VoidMain.State.PLAYING
	g.state_time = 0.0
	g.overlay.screen = "none"
	g.sfx.play("click")
	g._set_mode("flight")
	var tips_on := g.hints != null and g.hints.current() != ""   # tips teach the controls (VS-017)
	if msg == "":
		msg = "Welcome, Sovereign." if tips_on else "Welcome, Sovereign. Kill the Hive Cores, then the Nests. M = command map"
	g.u.message.emit(msg, Color("ffb347"))


## Autosave bookkeeping (VS-027): called every frame; saves each AUTOSAVE_INTERVAL of PLAYING time.
func autosave_tick(delta: float) -> void:
	if g.state != VoidMain.State.PLAYING:
		return
	_save_t += delta
	if _save_t >= AUTOSAVE_INTERVAL:
		autosave()


## Only a plain in-space moment is saved: not on the surface (restore can't rebuild it) and not while dead.
func autosave() -> bool:
	_save_t = 0.0
	if g.state != VoidMain.State.PLAYING or g.surface != null or g.mode == "surface" or g.respawn_t >= 0.0:
		return false
	if RunSave.write(g.u, save_path):
		return true
	report_save_failure(Time.get_ticks_msec() / 1000.0)
	return false


## One HUD warning per SAVE_FAIL_MSG_GAP seconds when an autosave write fails. Returns true if shown.
func report_save_failure(now: float) -> bool:
	if _fail_msg_at >= 0.0 and now - _fail_msg_at < SAVE_FAIL_MSG_GAP:
		return false
	_fail_msg_at = now
	g.u.message.emit("Autosave failed — storage may be full or blocked", Color("ff6b5a"))
	return true


## Title "New Game" gate (VS-028): with a valid save the first press only arms a confirmation, and a
## second press (after CONFIRM_GUARD, so a double-tap can't skip it) starts over and deletes the save.
## Returns true when a new run should start now. `now` is seconds (injectable for tests).
func request_new_game(has_save: bool, now: float) -> bool:
	if not has_save:
		_confirm_at = -1.0
		return true
	if _confirm_at < 0.0:
		_confirm_at = now
		return false
	if now - _confirm_at < CONFIRM_GUARD:
		return false
	_confirm_at = -1.0
	clear_save()
	return true


func cancel_new_game() -> void:
	_confirm_at = -1.0


func confirming() -> bool:
	return _confirm_at >= 0.0


func clear_save() -> void:
	RunSave.delete(save_path)


## Title "Continue": rebuild the main view around the restored Universe and enter PLAYING.
func continue_run() -> bool:
	var r := RunSave.load_universe(save_path)
	if r == null:
		g.overlay.continue_time = -1.0
		g.overlay.confirm_new = false
		cancel_new_game()
		return false
	g._new_world(r)
	start("Run restored — welcome back, Sovereign.")
	return true


func finish(won: bool) -> void:
	if g.state != VoidMain.State.PLAYING:
		return
	g.state = VoidMain.State.OVER
	g.state_time = 0.0
	clear_save()   # a finished run can't be continued
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
