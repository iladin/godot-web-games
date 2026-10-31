extends Node2D
## Orbit Putt: slingshot a comet-ball round planets into the cup. 9 holes, score vs par.
## State machine TITLE -> PLAYING -> HOLE_DONE -> (PLAYING ...) -> GAME_OVER. `--autoplay` runs a solver bot
## through the same pointer handlers a player uses; `--shotfile=<png>` saves a screenshot and quits.
## Physics tunables live in physics.gd, solver tunables in solver.gd, colours in draw_world.gd.

# --- Tunables ---------------------------------------------------------------
const ACCENT := WorldDraw.ACCENT
const DRAG_FULL := AimInput.DRAG_FULL  # drag/key tunables live in aim_input.gd
const PICKUP_OVER := 3         # strokes over par before the hole is forfeited (scored par + 4)
const PICKUP_SCORE_OVER := 4
const HOLE_BANNER_TIME := 1.4
const RESTART_DELAY := 0.6
const SINK_TIME := 0.35
const TRAIL_LEN := 24
const SHAKE_PX := 12.0
const SHAKE_DECAY := 0.25
const FLASH_ALPHA := 0.25
const AUTOPLAY_AIM_DELAY := 0.5

enum State { TITLE, PLAYING, HOLE_DONE, GAME_OVER }
enum Phase { AIM, FLY, SINK }

var state: State = State.TITLE
var phase: Phase = Phase.AIM
var hole_idx := 0
var bodies: Array = []
var par := 3
var cup := Vector2.ZERO
var cup_r := 30.0
var preview_steps := 90
var ball_pos := Vector2.ZERO
var ball_vel := Vector2.ZERO
var shot_origin := Vector2.ZERO
var strokes := 0
var scores: Array = []
var pars: Array = []
var total_rel := 0
var hios := 0
var t := 0.0
var aim := AimInput.new()
var flight_t := 0.0
var preview := PackedVector2Array()
var trail := PackedVector2Array()
var tint := 0.0
var sink_t := 0.0
var sink_ang := 0.0
var banner_word := ""
var banner_sub := ""
var stroke_pop := 0.0
var shake_t := 0.0
var flash := 0.0
var best_rel := 99
var best_hios := 0
var new_best := false
var state_time := 0.0
var anim_t := 0.0
var paused := false
var autoplay := false
var bot := AutoBot.new()
var shotfile := ""
var frames := 0
var star_list: Array = []
var fx := Fx.new()
var audio := OrbitAudio.new()


func _ready() -> void:
	var saved := SaveData.load_best()
	best_rel = saved.x
	best_hios = saved.y
	star_list = WorldDraw.make_stars()
	add_child(audio)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shotfile="):
			shotfile = a.substr(11)
	if "--autoplay" in OS.get_cmdline_user_args():
		autoplay = true
		_start_game()


func _view() -> Vector2:
	return get_viewport_rect().size


# --- State machine -----------------------------------------------------------
func _start_game() -> void:
	state = State.PLAYING
	state_time = 0.0
	hole_idx = 0
	scores.clear()
	pars.clear()
	total_rel = 0
	hios = 0
	new_best = false
	_start_hole(0)


func _start_hole(i: int) -> void:
	var h := Course.hole(i)
	hole_idx = i
	bodies = h["bodies"]
	par = h["par"]
	cup = h["cup"]
	cup_r = h["cup_r"]
	preview_steps = h["preview"]
	ball_pos = h["tee"]
	shot_origin = ball_pos
	ball_vel = Vector2.ZERO
	strokes = 0
	t = 0.0
	phase = Phase.AIM
	aim.angle = (cup - ball_pos).angle()
	aim.power = 0.6
	trail.clear()
	aim.dragging = false
	bot.reset()


func _finish_hole(pickup: bool) -> void:
	var score := par + PICKUP_SCORE_OVER if pickup else strokes
	scores.append(score)
	pars.append(par)
	total_rel += score - par
	if not pickup and strokes == 1:
		hios += 1
	banner_word = "Pick-up" if pickup else OrbitPhysics.result_name(strokes, par)
	print("hole %d: %s" % [hole_idx + 1, banner_word])
	banner_sub = "%d strokes (%s)" % [score, Hud.rel(score - par)]
	if not pickup:
		fx.burst(cup, ACCENT, 24, 260.0)
		audio.sink()
	state = State.HOLE_DONE
	state_time = 0.0
	trail.clear()
	preview.clear()


func _next_hole() -> void:
	if hole_idx + 1 >= Course.count():
		_end_game()
		return
	state = State.PLAYING
	state_time = 0.0
	_start_hole(hole_idx + 1)


func _end_game() -> void:
	state = State.GAME_OVER
	state_time = 0.0
	new_best = total_rel < best_rel
	if new_best:
		best_rel = total_rel
	best_hios = maxi(best_hios, hios)
	if not autoplay:  # the bot must not overwrite a human's best
		SaveData.save_best(best_rel, best_hios)
	print("course done, total %s" % Hud.rel(total_rel))


func _process(delta: float) -> void:
	position = ((_view() - OrbitPhysics.WORLD) * 0.5).floor()
	queue_redraw()
	frames += 1
	if shotfile != "" and frames >= 180:
		get_viewport().get_texture().get_image().save_png(shotfile)
		get_tree().quit()
		return
	if paused:
		return
	state_time += delta
	anim_t += delta
	fx.update(delta)
	shake_t = maxf(shake_t - delta, 0.0)
	flash = maxf(flash - delta * 1.2, 0.0)
	stroke_pop = maxf(stroke_pop - delta * 4.0, 0.0)
	if autoplay:
		bot.drive(self, delta)
	if state == State.PLAYING and phase == Phase.AIM:
		aim.keys(delta)
	elif state == State.HOLE_DONE and state_time >= HOLE_BANNER_TIME:
		_next_hole()


func _physics_process(_delta: float) -> void:
	if paused or state != State.PLAYING:
		return
	var t_now := t
	t += OrbitPhysics.DT
	match phase:
		Phase.AIM:
			_update_preview()
		Phase.FLY:
			_fly_step(t_now)
		Phase.SINK:
			sink_t += OrbitPhysics.DT
			if sink_t >= SINK_TIME:
				_finish_hole(false)


# --- Flight ------------------------------------------------------------------
func _shoot() -> void:
	if state != State.PLAYING or phase != Phase.AIM:
		return
	strokes += 1
	stroke_pop = 1.0
	ball_vel = OrbitPhysics.shot_velocity(aim.angle, aim.power)
	shot_origin = ball_pos
	flight_t = 0.0
	phase = Phase.FLY
	aim.dragging = false
	preview.clear()
	trail.clear()
	audio.shoot()


func _fly_step(t_now: float) -> void:
	var r := OrbitPhysics.step(ball_pos, ball_vel, bodies, t_now, OrbitPhysics.DT)
	ball_pos = r[0]
	ball_vel = r[1]
	flight_t += OrbitPhysics.DT
	var accel := OrbitPhysics.accel_at(ball_pos, bodies, t).length()
	tint = lerpf(tint, 1.0 if accel > 300.0 else 0.0, 0.15)
	trail.append(ball_pos)
	if trail.size() > TRAIL_LEN:
		trail.remove_at(0)
	match OrbitPhysics.judge(ball_pos, ball_vel, bodies, t, cup, cup_r):
		"sink":
			phase = Phase.SINK
			sink_t = 0.0
			sink_ang = (ball_pos - cup).angle()
			trail.clear()
		"crash":
			_crash()
		"lost":
			flash = FLASH_ALPHA * 0.6
			_penalty()
		_:
			if OrbitPhysics.is_rest(ball_vel, flight_t):
				phase = Phase.AIM
				shot_origin = ball_pos
				aim.angle = (cup - ball_pos).angle()
				trail.clear()
				_check_pickup()


func _crash() -> void:
	var col := WorldDraw.PLANET
	var at := ball_pos
	var best_d := INF
	for b in bodies:
		var d := ball_pos.distance_to(OrbitPhysics.body_pos(b, t))
		if d < best_d:
			best_d = d
			col = WorldDraw.body_color(b)
	fx.burst(at, col, 14, 240.0)
	shake_t = SHAKE_DECAY
	flash = FLASH_ALPHA
	audio.crash()
	_penalty()


func _penalty() -> void:
	strokes += 1
	stroke_pop = 1.0
	ball_pos = shot_origin
	ball_vel = Vector2.ZERO
	phase = Phase.AIM
	trail.clear()
	_check_pickup()


func _check_pickup() -> void:
	if state == State.PLAYING and strokes >= par + PICKUP_OVER:
		_finish_hole(true)


func _update_preview() -> void:
	if aim.in_deadzone():
		preview.clear()
		return
	var res := OrbitPhysics.simulate(ball_pos, OrbitPhysics.shot_velocity(aim.angle, aim.power),
		bodies, t, preview_steps, cup, cup_r)
	preview = res["path"]


# --- Input -------------------------------------------------------------------
func _tap() -> void:
	match state:
		State.TITLE:
			_start_game()
		State.HOLE_DONE:
			if state_time > 0.3:
				_next_hole()
		State.GAME_OVER:
			if state_time > RESTART_DELAY:
				_start_game()


func _pointer_down(p: Vector2) -> void:
	audio.enable()
	if paused:
		paused = false
	elif state != State.PLAYING:
		_tap()
	elif phase == Phase.AIM:
		aim.begin(p)


func _pointer_move(p: Vector2) -> void:
	aim.move(p)


func _pointer_up(p: Vector2) -> void:
	if aim.release(p):
		_shoot()


func _unhandled_input(event: InputEvent) -> void:
	# Touch is emulated as mouse (project setting), so this covers phones too.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pointer_down(event.position - position)
		else:
			_pointer_up(event.position - position)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_pointer_move(event.position - position)
	elif event.is_action_pressed("ui_accept"):
		audio.enable()
		if paused:
			paused = false
		elif state == State.PLAYING:
			_shoot()
		else:
			_tap()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING:
		paused = true


func _draw() -> void:
	GameView.draw(self)
