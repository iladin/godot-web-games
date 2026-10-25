extends Node2D
## Starfall — catch gold stars, dodge red meteors. Three lives, speed ramps up.
## Everything is drawn in code: no assets to load.

# --- Tunables ---------------------------------------------------------------
const BG_TOP := Color("0b0d22")
const BG_BOTTOM := Color("1d1240")
const ACCENT := Color("5ee6ff")
const STAR_COLOR := Color("ffcc4d")
const METEOR_COLOR := Color("ff4d6d")
const PLAYER_RADIUS := 30.0
const PLAYER_Y_FROM_BOTTOM := 150.0
const PLAYER_FOLLOW := 14.0          # higher = snappier pointer follow
const PLAYER_KEY_SPEED := 950.0
const START_INTERVAL := 0.85         # seconds between spawns at t=0
const MIN_INTERVAL := 0.22
const INTERVAL_RAMP := 0.012         # interval shrink per second survived
const START_FALL_SPEED := 300.0
const FALL_RAMP := 7.0               # px/s added per second survived
const METEOR_CHANCE_START := 0.25
const METEOR_CHANCE_MAX := 0.55
const LIVES := 3
const INVULN_TIME := 1.0
const RESTART_DELAY := 0.7
const BG_STAR_COUNT := 70
const SAVE_PATH := "user://save.cfg"

enum State { TITLE, PLAYING, GAME_OVER }

# --- Runtime state -------------------------------------------------------------
var state: State = State.TITLE
var player_x: float = 0.0
var pointer_x: float = -1.0          # < 0 means no pointer target
var items: Array[Dictionary] = []     # {pos, speed, r, meteor, rot, spin}
var particles: Array[Dictionary] = [] # {pos, vel, life, max_life, color, size}
var popups: Array[Dictionary] = []    # {pos, text, life}
var bg_stars: Array[Vector3] = []     # x, y, speed
var score: int = 0
var best: int = 0
var new_best := false
var lives: int = LIVES
var combo: int = 0
var elapsed: float = 0.0
var spawn_timer: float = 0.0
var state_time: float = 0.0
var invuln: float = 0.0
var shake: float = 0.0
var flash: float = 0.0
var paused := false
var autoplay := false
var font: Font = ThemeDB.fallback_font


func _ready() -> void:
	best = _load_best()
	var size := _size()
	player_x = size.x * 0.5
	for i in BG_STAR_COUNT:
		bg_stars.append(Vector3(randf() * size.x, randf() * size.y, randf_range(20.0, 90.0)))
	if "--autoplay" in OS.get_cmdline_user_args():
		autoplay = true
		_start_game()


func _size() -> Vector2:
	return get_viewport_rect().size


func _player_pos() -> Vector2:
	return Vector2(player_x, _size().y - PLAYER_Y_FROM_BOTTOM)


# --- State machine ---------------------------------------------------------------
func _start_game() -> void:
	state = State.PLAYING
	state_time = 0.0
	score = 0
	combo = 0
	lives = LIVES
	elapsed = 0.0
	spawn_timer = 0.5
	invuln = 0.0
	new_best = false
	items.clear()
	popups.clear()


func _end_game() -> void:
	state = State.GAME_OVER
	state_time = 0.0
	if score > best:
		best = score
		new_best = true
		_save_best(best)


# --- Update ------------------------------------------------------------------------
func _process(delta: float) -> void:
	queue_redraw()
	_update_background(delta)
	_update_particles(delta)
	shake = maxf(shake - delta * 40.0, 0.0)
	flash = maxf(flash - delta * 3.0, 0.0)
	if paused:
		return
	state_time += delta
	if state != State.PLAYING:
		return

	elapsed += delta
	invuln = maxf(invuln - delta, 0.0)
	_update_player(delta)
	_update_spawning(delta)
	_update_items(delta)


func _update_background(delta: float) -> void:
	var size := _size()
	for i in bg_stars.size():
		var s := bg_stars[i]
		s.y += s.z * delta
		if s.y > size.y:
			s = Vector3(randf() * size.x, 0.0, s.z)
		bg_stars[i] = s


func _update_player(delta: float) -> void:
	var size := _size()
	var key_dir := Input.get_axis("ui_left", "ui_right")
	if autoplay:
		pointer_x = _autoplay_target()
	if key_dir != 0.0:
		pointer_x = -1.0
		player_x += key_dir * PLAYER_KEY_SPEED * delta
	elif pointer_x >= 0.0:
		player_x = lerpf(player_x, pointer_x, 1.0 - exp(-PLAYER_FOLLOW * delta))
	player_x = clampf(player_x, PLAYER_RADIUS, size.x - PLAYER_RADIUS)


func _autoplay_target() -> float:
	# Naive bot for headless smoke tests: chase the lowest star, ignore meteors.
	var target := player_x
	var lowest := -INF
	for it in items:
		if not it.meteor and it.pos.y > lowest:
			lowest = it.pos.y
			target = it.pos.x
	return target


func _update_spawning(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return
	spawn_timer = maxf(MIN_INTERVAL, START_INTERVAL - elapsed * INTERVAL_RAMP)
	var size := _size()
	var meteor_chance := minf(METEOR_CHANCE_MAX, METEOR_CHANCE_START + elapsed * 0.004)
	var is_meteor := randf() < meteor_chance
	var r: float = randf_range(26.0, 40.0) if is_meteor else randf_range(20.0, 28.0)
	items.append({
		"pos": Vector2(randf_range(r, size.x - r), -r),
		"speed": START_FALL_SPEED + elapsed * FALL_RAMP + randf_range(0.0, 140.0),
		"r": r,
		"meteor": is_meteor,
		"rot": randf() * TAU,
		"spin": randf_range(-3.0, 3.0),
	})


func _update_items(delta: float) -> void:
	var size := _size()
	var ppos := _player_pos()
	for i in range(items.size() - 1, -1, -1):
		var it: Dictionary = items[i]
		var pos: Vector2 = it.pos
		pos.y += it.speed * delta
		it.pos = pos
		it.rot += it.spin * delta
		if it.pos.distance_to(ppos) < it.r * 0.8 + PLAYER_RADIUS:
			items.remove_at(i)
			if it.meteor:
				_on_meteor_hit(it.pos)
				if state != State.PLAYING:
					return
			else:
				_on_star_caught(it.pos)
		elif it.pos.y - it.r > size.y:
			items.remove_at(i)
			if not it.meteor:
				combo = 0


func _on_star_caught(at: Vector2) -> void:
	combo += 1
	var gained := 10 * mini(combo, 5)
	score += gained
	_burst(at, STAR_COLOR, 14)
	popups.append({"pos": at, "text": "+%d" % gained, "life": 0.8})


func _on_meteor_hit(at: Vector2) -> void:
	if invuln > 0.0:
		return
	lives -= 1
	combo = 0
	invuln = INVULN_TIME
	shake = 22.0
	flash = 1.0
	_burst(at, METEOR_COLOR, 24)
	if lives <= 0:
		_burst(_player_pos(), ACCENT, 40)
		_end_game()


# --- Particles ---------------------------------------------------------------------
func _burst(at: Vector2, color: Color, count: int) -> void:
	for i in count:
		var angle := randf() * TAU
		var spd := randf_range(120.0, 420.0)
		var life := randf_range(0.35, 0.8)
		particles.append({
			"pos": at,
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"life": life,
			"max_life": life,
			"color": color,
			"size": randf_range(3.0, 7.0),
		})


func _update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p.life -= delta
		if p.life <= 0.0:
			particles.remove_at(i)
			continue
		p.vel = p.vel * (1.0 - 2.5 * delta) + Vector2(0.0, 500.0 * delta)
		p.pos += p.vel * delta
	for i in range(popups.size() - 1, -1, -1):
		var pp: Dictionary = popups[i]
		pp.life -= delta
		var ppos: Vector2 = pp.pos
		ppos.y -= 70.0 * delta
		pp.pos = ppos
		if pp.life <= 0.0:
			popups.remove_at(i)


# --- Input -------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	# Touch is emulated as mouse (project setting), so this covers phones too.
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		pointer_x = event.position.x if event.pressed else pointer_x
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		pointer_x = event.position.x
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
	var size := _size()
	var off := Vector2(randf_range(-shake, shake), randf_range(-shake, shake))

	# Background gradient (two triangles with vertex colors) + parallax stars.
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)]),
		PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM]))
	for s in bg_stars:
		var a := remap(s.z, 20.0, 90.0, 0.25, 0.9)
		draw_circle(Vector2(s.x, s.y), remap(s.z, 20.0, 90.0, 0.8, 2.2), Color(1, 1, 1, a))

	draw_set_transform(off)
	for it in items:
		if it.meteor:
			_draw_meteor(it.pos, it.r, it.rot)
		else:
			draw_colored_polygon(_star_points(it.pos, it.r, it.rot), STAR_COLOR)
	for p in particles:
		var c: Color = p.color
		c.a = p.life / p.max_life
		draw_circle(p.pos, p.size, c)

	if state == State.PLAYING:
		var blink := invuln > 0.0 and int(state_time * 12.0) % 2 == 0
		if not blink:
			var ppos := _player_pos()
			draw_circle(ppos, PLAYER_RADIUS + 10.0, Color(ACCENT, 0.18))
			draw_circle(ppos, PLAYER_RADIUS, ACCENT)
			draw_circle(ppos + Vector2(-9, -9), 8.0, Color(1, 1, 1, 0.55))
	draw_set_transform(Vector2.ZERO)

	for pp in popups:
		var pc := Color(STAR_COLOR, clampf(pp.life / 0.8, 0.0, 1.0))
		draw_string(font, pp.pos + Vector2(-40, 0), pp.text, HORIZONTAL_ALIGNMENT_CENTER, 80, 30, pc)

	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(METEOR_COLOR, flash * 0.35))

	_draw_hud(size)


func _draw_hud(size: Vector2) -> void:
	match state:
		State.TITLE:
			_text("STARFALL", size.y * 0.34, 92, STAR_COLOR)
			_text("Catch stars. Dodge meteors.", size.y * 0.42, 34, Color.WHITE)
			_text("Drag or ← → to move", size.y * 0.47, 28, ACCENT)
			var pulse := 0.5 + 0.5 * sin(state_time * 4.0)
			_text("Tap or press Space", size.y * 0.62, 36, Color.WHITE.lerp(STAR_COLOR, pulse))
			if best > 0:
				_text("Best %d" % best, size.y * 0.68, 28, ACCENT)
		State.PLAYING:
			_text("%d" % score, 96.0, 64, Color.WHITE)
			if combo >= 2:
				_text("x%d combo" % mini(combo, 5), 140.0, 28, STAR_COLOR)
			for i in LIVES:
				var col: Color = ACCENT if i < lives else Color(1, 1, 1, 0.15)
				draw_circle(Vector2(40.0 + i * 36.0, 60.0), 12.0, col)
		State.GAME_OVER:
			_text("GAME OVER", size.y * 0.36, 80, METEOR_COLOR)
			_text("Score %d" % score, size.y * 0.45, 48, Color.WHITE)
			_text("NEW BEST!" if new_best else "Best %d" % best, size.y * 0.51, 36, STAR_COLOR if new_best else ACCENT)
			if state_time > RESTART_DELAY:
				_text("Tap or press Space to play again", size.y * 0.64, 30, Color.WHITE)

	if paused:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
		_text("PAUSED — tap to resume", size.y * 0.5, 36, Color.WHITE)


func _draw_meteor(center: Vector2, r: float, rot: float) -> void:
	var pts := PackedVector2Array()
	for i in 9:
		var a := rot + i * TAU / 9.0
		var rr := r * (0.78 + 0.22 * sin(i * 2.3))
		pts.append(center + Vector2(cos(a), sin(a)) * rr)
	draw_line(center, center - Vector2(0, r * 2.2), Color(METEOR_COLOR, 0.35), r * 0.9)
	draw_colored_polygon(pts, METEOR_COLOR)
	draw_circle(center + Vector2(r * 0.2, -r * 0.2), r * 0.22, Color(0, 0, 0, 0.25))


func _star_points(center: Vector2, r: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var radius: float = r if i % 2 == 0 else r * 0.45
		var a := rot + i * TAU / 10.0 - PI / 2.0
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts


func _text(s: String, y: float, font_size: int, color: Color) -> void:
	draw_string(font, Vector2(0.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, _size().x, font_size, color)
