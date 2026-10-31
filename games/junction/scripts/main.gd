extends Node2D
## Junction: flip the points so every coloured train docks at its matching station.
## State machine TITLE -> PLAYING -> GAME_OVER; --autoplay runs a bot with real flip inputs.
## Ramp tunables (speed, spawn rate, unlocks, combo) live at the top of yard.gd.

# --- Tunables ---------------------------------------------------------------
const R := preload("res://scripts/render.gd")
const ACCENT := R.ACCENT
const DANGER := R.DANGER
const LIVES := 3
const BASE_POINTS := 10
const FIRST_SPAWN := 1.5
const REPEAT_CHANCE_EARLY := 0.35
const REPEAT_CHANCE_LATE := 0.15
const LATE_AT := 25
const PREVIEW_TIME := 1.5
const SWITCH_HIT_R := R.SWITCH_HIT_R
const SWITCH_LOCK_DIST := 26.0
const FLIP_ANIM := 0.12
const SHAKE_PX := 14.0
const SHAKE_TIME := 0.3
const FLASH_ALPHA := 0.3
const POPUP_TIME := 0.7
const CONFETTI := 20
const SMOKE_STEP := 0.4
const RESTART_DELAY := 0.6
const AUTOPLAY_REACTION := 0.35
const AUTOPLAY_LOOKAHEAD := 260.0
const AUTOPLAY_MISROUTE_EVERY := 7
const SHOT_FRAMES := 180

enum State { TITLE, PLAYING, GAME_OVER }

var state: State = State.TITLE
var switches: Dictionary = {}
var flip_anim: Dictionary = {}
var pulse: Dictionary = {}
var shake_sw: Dictionary = {}
var trains: Array[Train] = []
var fx := Fx.new()
const Bot := preload("res://scripts/bot.gd")
const Hud := preload("res://scripts/hud.gd")
const Save := preload("res://scripts/save.gd")
var audio: Node
var station_flash: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var next_colour: int = 0
var last_colour: int = -1
var spawn_timer: float = FIRST_SPAWN
var spawned: int = 0
var score: int = 0
var correct: int = 0
var delivered: int = 0
var combo: int = 0
var lives: int = LIVES
var selected: int = 0
var show_sel := false
var best: int = 0
var new_best := false
var state_time: float = 0.0
var shake: float = 0.0
var flash: float = 0.0
var paused := false
var autoplay := false
var shot_file := ""
var frames: int = 0
var font: Font = ThemeDB.fallback_font


func _ready() -> void:
	best = Save.load_best()
	audio = preload("res://scripts/audio.gd").new()
	add_child(audio)
	_reset_board()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shotfile="):
			shot_file = a.substr(11)
	if "--autoplay" in OS.get_cmdline_user_args():
		autoplay = true
		_start_game()


# --- State machine ---------------------------------------------------------------
func _reset_board() -> void:
	for id in Yard.SWITCH_IDS:
		switches[id] = false
		flip_anim[id] = 0.0
		pulse[id] = 0.0
		shake_sw[id] = 0.0
	trains.clear()
	fx = Fx.new()
	score = 0; correct = 0; delivered = 0; combo = 0; spawned = 0
	lives = LIVES
	selected = 0
	shake = 0.0; flash = 0.0
	spawn_timer = FIRST_SPAWN
	last_colour = -1
	next_colour = Yard.pick_colour(correct, delivered, last_colour, REPEAT_CHANCE_EARLY, REPEAT_CHANCE_LATE, LATE_AT)


func _start_game() -> void:
	_reset_board()
	state = State.PLAYING
	state_time = 0.0
	new_best = false


func _end_game() -> void:
	state = State.GAME_OVER
	state_time = 0.0
	if score > best:
		best = score
		new_best = true
		Save.save_best(best)


func _process(delta: float) -> void:
	frames += 1
	if shot_file != "" and frames >= SHOT_FRAMES:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot_file)
		get_tree().quit()
		return
	queue_redraw()
	if paused:
		return
	state_time += delta
	shake = maxf(shake - delta * SHAKE_PX / SHAKE_TIME, 0.0)
	flash = maxf(flash - delta, 0.0)
	fx.update(delta, POPUP_TIME)
	for i in 5:
		station_flash[i] = maxf(station_flash[i] - delta * 4.0, 0.0)
	for id in Yard.SWITCH_IDS:
		var goal := 1.0 if switches[id] else 0.0
		flip_anim[id] = move_toward(float(flip_anim[id]), goal, delta / FLIP_ANIM)
		pulse[id] = maxf(float(pulse[id]) - delta * 5.0, 0.0)
		shake_sw[id] = maxf(float(shake_sw[id]) - delta, 0.0)
	if state != State.PLAYING:
		return
	if autoplay:
		Bot.step(self)
	_update_spawn(delta)
	_update_trains(delta)


# --- Trains ------------------------------------------------------------------------
func _entry_clear() -> bool:
	for t in trains:
		if t.from_id == "entry" and t.dist < Train.CAR_GAP * 2.0 + 40.0:
			return false
	return true


func _update_spawn(delta: float) -> void:
	spawn_timer = maxf(spawn_timer - delta, 0.0)
	if spawn_timer > 0.0 or not _entry_clear():
		return
	var t := Train.new()
	t.colour = next_colour
	t.bot_target = t.colour
	spawned += 1
	if autoplay and spawned % AUTOPLAY_MISROUTE_EVERY == 0:
		t.bot_target = (t.colour + 1) % 5
	t.set_edge("entry", "S1")
	trains.append(t)
	last_colour = next_colour
	next_colour = Yard.pick_colour(correct, delivered, last_colour, REPEAT_CHANCE_EARLY, REPEAT_CHANCE_LATE, LATE_AT)
	spawn_timer = Yard.spawn_interval(delivered)


func _update_trains(delta: float) -> void:
	var speed := Yard.train_speed(delivered)
	for i in range(trains.size() - 1, -1, -1):
		if state != State.PLAYING:
			return
		var t := trains[i]
		t.smoke_t -= delta
		if t.smoke_t <= 0.0 and t.car(0)[2]:
			t.smoke_t = SMOKE_STEP
			fx.smoke((t.car(0)[0] as Vector2) + Vector2(0, -14))
		if not t.advance(delta, speed):
			continue
		var over := t.dist - t.length
		var node := t.to_id
		if Yard.kind(node) == "station":
			trains.remove_at(i)
			_dock(t)
		else:
			t.set_edge(node, Yard.next_node(node, switches))
			t.dist = over


func _dock(t: Train) -> void:
	var st: int = int(Yard.NODES[t.to_id]["station"])
	var at := Yard.station_pos(st)
	var col := R.TRAIN_COLOURS[t.colour]
	delivered += 1
	if st == t.colour:
		combo += 1
		correct += 1
		var pts := BASE_POINTS * Yard.multiplier(combo)
		score += pts
		station_flash[st] = 1.0
		fx.burst(at, col, CONFETTI)
		fx.popup(at + Vector2(0, -20), "+%d" % pts, col)
		audio.play("chime", 1.0 + minf(combo, 8) * 0.04)
		if correct == Yard.UNLOCK_4_AT or correct == Yard.UNLOCK_5_AT:
			fx.popup(Vector2(360, 700), "NEW STATION!", ACCENT, 48)
			audio.play("unlock")
	else:
		combo = 0
		lives -= 1
		shake = SHAKE_PX
		flash = SHAKE_TIME
		fx.popup(at + Vector2(0, -20), "WRONG!", DANGER)
		fx.fall(Vector2(50.0 + lives * 58.0, 60.0))
		audio.play("buzz")
		if lives <= 0:
			_end_game()


# --- Switches & input ------------------------------------------------------------------
func _is_locked(id: String) -> bool:
	for t in trains:
		if t.to_id == id and t.length - t.dist <= SWITCH_LOCK_DIST:
			return true
		if t.from_id == id and t.dist < SWITCH_LOCK_DIST:
			return true
	return false


func _try_flip(id: String) -> bool:
	if _is_locked(id):
		shake_sw[id] = 0.25
		audio.play("buzz", 1.5)
		return false
	switches[id] = not switches[id]
	pulse[id] = 1.0
	audio.play("click", randf_range(0.95, 1.1))
	return true


func _switch_at(p: Vector2) -> String:
	var best_id := ""
	var best_d := SWITCH_HIT_R
	for id in Yard.SWITCH_IDS:
		var d := p.distance_to(Yard.pos(id))
		if d <= best_d:
			best_d = d
			best_id = id
	return best_id


func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	var tap := Vector2(-1000, -1000)
	var key_flip := ""
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed = true
		tap = event.position
	elif event is InputEventKey and event.pressed and not event.echo:
		show_sel = true
		var k: Key = event.physical_keycode
		if k >= KEY_1 and k <= KEY_4:
			key_flip = Yard.SWITCH_IDS[k - KEY_1]
		elif k == KEY_LEFT or k == KEY_A:
			selected = posmod(selected - 1, 4)
		elif k == KEY_RIGHT or k == KEY_D:
			selected = posmod(selected + 1, 4)
		elif k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER:
			pressed = true
			key_flip = "sel"
	if not pressed and key_flip == "":
		return
	audio.enable()
	if paused:
		paused = false
		return
	match state:
		State.TITLE:
			if pressed:
				_start_game()
		State.GAME_OVER:
			if pressed and state_time > RESTART_DELAY:
				_start_game()
		State.PLAYING:
			if autoplay:
				return
			if key_flip == "sel":
				key_flip = Yard.SWITCH_IDS[selected]
			elif key_flip != "":
				selected = Yard.SWITCH_IDS.find(key_flip)
			elif tap.x > -500.0:
				key_flip = _switch_at(tap)
				show_sel = false
			if key_flip != "":
				_try_flip(key_flip)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING:
		paused = true


# --- Drawing -----------------------------------------------------------------------
func _draw() -> void:
	var size := get_viewport_rect().size
	R.background(self, size)
	var ofs := Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	R.edges(self, switches, ofs)
	var glow := -1
	if state == State.PLAYING and spawn_timer < PREVIEW_TIME:
		glow = next_colour
	R.tunnel(self, font, glow, spawn_timer, ofs)
	for i in 5:
		R.station(self, i, Yard.is_active(i, correct), station_flash[i], ofs)
	for i in 4:
		var id: String = Yard.SWITCH_IDS[i]
		R.switch_node(self, font, id, i + 1, flip_anim[id], pulse[id], shake_sw[id], show_sel and i == selected and state == State.PLAYING, ofs)
	for t in trains:
		R.train(self, t, ofs)
	fx.draw(self, font, ofs, POPUP_TIME)
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(DANGER, FLASH_ALPHA * flash / SHAKE_TIME))
	Hud.draw(self, size)
