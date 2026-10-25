extends Node2D
## Template game: move the dot, grab orbs before the clock runs out.
## Replace the gameplay; keep the state machine, input helpers, save, focus-pause
## and the --autoplay hook (scripts/check.sh relies on it).

# --- Tunables ---------------------------------------------------------------
const BG := Color("0d0f1f")
const ACCENT := Color("5ee6ff")
const GOLD := Color("ffcc4d")
const PLAYER_SPEED := 700.0
const PLAYER_RADIUS := 26.0
const ORB_RADIUS := 18.0
const ROUND_TIME := 30.0
const RESTART_DELAY := 0.6
const SAVE_PATH := "user://save.cfg"

enum State { TITLE, PLAYING, GAME_OVER }

# --- Runtime state -------------------------------------------------------------
var state: State = State.TITLE
var player_pos := Vector2.ZERO
var pointer_target := Vector2.ZERO
var pointer_active := false
var orb_pos := Vector2.ZERO
var score: int = 0
var best: int = 0
var new_best := false
var time_left: float = ROUND_TIME
var state_time: float = 0.0
var paused := false
var autoplay := false
var font: Font = ThemeDB.fallback_font


func _ready() -> void:
	best = _load_best()
	player_pos = _view().size * 0.5
	if "--autoplay" in OS.get_cmdline_user_args():
		autoplay = true
		_start_game()


func _view() -> Rect2:
	return get_viewport_rect()


# --- State machine ---------------------------------------------------------------
func _start_game() -> void:
	state = State.PLAYING
	state_time = 0.0
	score = 0
	new_best = false
	time_left = ROUND_TIME
	player_pos = _view().size * 0.5
	_place_orb()


func _end_game() -> void:
	state = State.GAME_OVER
	state_time = 0.0
	if score > best:
		best = score
		new_best = true
		_save_best(best)


func _process(delta: float) -> void:
	queue_redraw()
	if paused:
		return
	state_time += delta
	if state != State.PLAYING:
		return

	time_left -= delta
	if time_left <= 0.0:
		_end_game()
		return

	var dir := _move_input()
	player_pos += dir * PLAYER_SPEED * delta
	var size := _view().size
	player_pos = player_pos.clamp(Vector2(PLAYER_RADIUS, PLAYER_RADIUS), size - Vector2(PLAYER_RADIUS, PLAYER_RADIUS))

	if player_pos.distance_to(orb_pos) < PLAYER_RADIUS + ORB_RADIUS:
		score += 1
		_place_orb()


func _place_orb() -> void:
	var size := _view().size
	var margin := 80.0
	orb_pos = Vector2(randf_range(margin, size.x - margin), randf_range(margin + 120.0, size.y - margin))


# --- Input -----------------------------------------------------------------------
func _move_input() -> Vector2:
	if autoplay:
		return (orb_pos - player_pos).limit_length(1.0)
	var kb := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if kb != Vector2.ZERO:
		pointer_active = false
		return kb
	if pointer_active:
		var to_target := pointer_target - player_pos
		if to_target.length() > 6.0:
			return to_target.limit_length(60.0) / 60.0
	return Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	# Touch is emulated as mouse (project setting), so this covers phones too.
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_active = event.pressed
		pointer_target = event.position
		pressed = event.pressed
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		pointer_target = event.position
	elif event.is_action_pressed("ui_accept"):
		pressed = true

	if not pressed:
		return
	if paused:
		paused = false
		return
	match state:
		State.TITLE:
			_start_game()
		State.GAME_OVER:
			if state_time > RESTART_DELAY:
				_start_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING:
		paused = true


# --- Save --------------------------------------------------------------------------
func _load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	return int(cfg.get_value("score", "best", 0))


func _save_best(value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", value)
	cfg.save(SAVE_PATH)


# --- Drawing -----------------------------------------------------------------------
func _draw() -> void:
	var size := _view().size
	draw_rect(Rect2(Vector2.ZERO, size), BG)

	match state:
		State.TITLE:
			_text("__TITLE__", size.y * 0.38, 72, ACCENT)
			_text("Grab the orbs before time runs out", size.y * 0.46, 30, Color.WHITE)
			_text("Tap or press Space", size.y * 0.62, 34, GOLD.lerp(Color.WHITE, 0.5 + 0.5 * sin(state_time * 4.0)))
		State.PLAYING:
			var pulse := 1.0 + 0.15 * sin(state_time * 8.0)
			draw_circle(orb_pos, ORB_RADIUS * pulse, GOLD)
			draw_circle(player_pos, PLAYER_RADIUS, ACCENT)
			_text("%d" % score, 90.0, 56, Color.WHITE)
			_text("%.1f" % maxf(time_left, 0.0), 140.0, 28, ACCENT)
		State.GAME_OVER:
			_text("TIME!", size.y * 0.36, 80, GOLD)
			_text("Score %d" % score, size.y * 0.45, 44, Color.WHITE)
			_text("NEW BEST!" if new_best else "Best %d" % best, size.y * 0.51, 34, ACCENT)
			if state_time > RESTART_DELAY:
				_text("Tap or press Space to retry", size.y * 0.64, 30, Color.WHITE)

	if paused:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
		_text("PAUSED — tap to resume", size.y * 0.5, 36, Color.WHITE)


func _text(s: String, y: float, font_size: int, color: Color) -> void:
	var w := _view().size.x
	draw_string(font, Vector2(0.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, w, font_size, color)
