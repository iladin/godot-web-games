extends Node2D
## Crossfire - no weapon; every enemy shows its next strike; make them hit each other.
## main.gd: geometry, input -> commands, effects, autoplay, shots. Model: tactics.gd.
## Drawing: board_view.gd. AI interface (/ console, window.aiGame): ai_bridge.gd.

const T := preload("res://scripts/tactics.gd")
const Bridge := preload("res://scripts/ai_bridge.gd")
const BoardView := preload("res://scripts/board_view.gd")
const Controls := preload("res://scripts/controls.gd")

# --- Tunables ---------------------------------------------------------------
const COLUMN_W := 720.0
const PANEL_H := 470.0
const MOVE_LERP := 14.0
const FX_STAGGER := 0.16        # seconds between enemy attacks when they play out
const RESTART_DELAY := 0.8
const BOT_INTERVAL := 0.45
const SAVE_PATH := "user://save.cfg"
const HELP := "CROSSFIRE commands:\nmove <dir>  (or just the dir)   shove <dir>   end\ndirs: e w ne nw se sw   (W/E/A/D/Z/X keys; Shift = shove)\nmap - the board as text    threats - every enemy's next attack\nstart / restart\nOne move + one shove per turn. Enemies then strike exactly as shown,\nhitting whatever is there - including each other."

var game: T
var bridge: Bridge
var view: BoardView
var state_time: float = 0.0
var last_phase: int = -1
var paused: bool = false
var autoplay: bool = false
var bot_timer: float = 0.0
var best: int = 0
var new_best: bool = false
var shove_mode: bool = false
var hover_hex: Vector2i = Vector2i(99, 99)

var draw_pos: Dictionary = {}    # unit id -> Vector2 (animated position)
var flash: Dictionary = {}       # unit id -> seconds of hit flash
var ghosts: Array[Dictionary] = []   # dying units shown until their death plays out
var fx: Array[Dictionary] = []       # {type, delay, t, ...}
var particles: Array[Dictionary] = []
var floaters: Array[Dictionary] = []
var shake: float = 0.0
var screen_flash: float = 0.0
var screen_flash_color: Color = Color.WHITE
var buttons: Array[Dictionary] = []


func _ready() -> void:
	best = _load_best()
	var args := OS.get_cmdline_user_args()
	var seeded := false
	for a in args:
		if a.begins_with("--shot="):
			seeded = true
	game = T.new(7 if seeded else -1)
	game.event.connect(_on_game_event)
	view = BoardView.new()
	view.m = self
	add_child(view)
	bridge = Bridge.new()
	add_child(bridge)
	bridge.setup(game.observe, _act, HELP)
	var controls := Controls.new()
	controls.m = self
	add_child(controls)
	if "--autoplay" in args:
		autoplay = true
		_act("start")
	if bridge.shot_name != "":
		_run_shot(bridge.shot_name)


func _act(cmd: String) -> Dictionary:
	return game.act(cmd)


func _on_game_event(kind: String, data: Dictionary) -> void:
	match kind:
		"floor", "new_game":
			draw_pos.clear()
			ghosts.clear()
			fx.clear()
			shove_mode = false
		"shove":
			_play_log(data.log, 0.0)
		"enemy_phase":
			_play_log(data.log, 0.12)
		"floor_done":
			var L := layout()
			_burst(hex_px(L, T.EXIT), 30, BoardView.GOLD)
			if data.clean:
				floaters.append({"text": "CLEAN +1 HP", "pos": hex_px(L, T.EXIT), "t": 1.6, "delay": 0.0, "color": BoardView.GOLD})
		"game_over", "win":
			if game.score > best:
				best = game.score
				new_best = true
				_save_best(best)


## Turn a combat log into staggered visual effects.
func _play_log(log: Array, start: float) -> void:
	var L := layout()
	var delay := start
	for ev: Dictionary in log:
		match str(ev.type):
			"shot":
				fx.append({"type": "shot", "from": hex_px(L, ev.from), "to": hex_px(L, ev.to), "delay": delay, "t": 0.35})
				delay += FX_STAGGER
			"smash":
				fx.append({"type": "ring", "at": hex_px(L, ev.at), "color": BoardView.RED, "delay": delay, "t": 0.3, "size": 0.7})
				delay += FX_STAGGER
			"bomb":
				fx.append({"type": "ring", "at": hex_px(L, ev.at), "color": BoardView.ORANGE, "delay": delay, "t": 0.45, "size": 1.8})
				fx.append({"type": "burst", "at": hex_px(L, ev.at), "color": BoardView.ORANGE, "delay": delay, "n": 18})
				fx.append({"type": "shake", "amount": 10.0, "delay": delay})
				delay += FX_STAGGER * 1.5
			"slam", "collide":
				fx.append({"type": "burst", "at": hex_px(L, ev.at), "color": BoardView.INK, "delay": delay, "n": 8})
			"damage":
				fx.append({"type": "hit", "id": ev.id, "at": hex_px(L, ev.at), "delay": delay})
			"death":
				if ev.id != 0:
					ghosts.append({"id": ev.id, "kind": ev.kind, "pos": draw_pos.get(ev.id, hex_px(L, ev.at)), "delay": delay})
					fx.append({"type": "burst", "at": hex_px(L, ev.at), "color": BoardView.RED, "delay": delay, "n": 22})
					fx.append({"type": "float", "text": "+%d" % T.KILL_POINTS, "at": hex_px(L, ev.at), "delay": delay})


# --- Frame -------------------------------------------------------------------------
func _process(delta: float) -> void:
	view.queue_redraw()
	if int(game.phase) != last_phase:
		last_phase = int(game.phase)
		state_time = 0.0
		if game.phase == T.Phase.PLAYER and game.floor_no == 1:
			new_best = false
	if paused:
		return
	state_time += delta
	var L := layout()
	var k := 1.0 - exp(-MOVE_LERP * delta)
	for u: Dictionary in game.units:
		var target := hex_px(L, u.pos)
		draw_pos[u.id] = (draw_pos.get(u.id, target) as Vector2).lerp(target, k)
	for id in flash.keys():
		flash[id] = maxf(0.0, float(flash[id]) - delta)
	for i in range(fx.size() - 1, -1, -1):
		var f: Dictionary = fx[i]
		if f.delay > 0.0:
			f.delay -= delta
			continue
		match str(f.type):
			"burst":
				_burst(f.at, f.n, f.color)
				fx.remove_at(i)
				continue
			"shake":
				shake = maxf(shake, f.amount)
				fx.remove_at(i)
				continue
			"hit":
				flash[f.id] = 0.18
				floaters.append({"text": "-1", "pos": f.at, "t": 1.0, "delay": 0.0, "color": BoardView.RED})
				if f.id == 0:
					shake = 18.0
					screen_flash = 0.3
					screen_flash_color = BoardView.RED
				fx.remove_at(i)
				continue
			"float":
				floaters.append({"text": f.text, "pos": f.at, "t": 1.0, "delay": 0.0, "color": BoardView.GOLD})
				fx.remove_at(i)
				continue
		f.t -= delta
		if f.t <= 0.0:
			fx.remove_at(i)
	for i in range(ghosts.size() - 1, -1, -1):
		ghosts[i].delay -= delta
		if ghosts[i].delay <= 0.0:
			ghosts.remove_at(i)
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p.vel *= 0.92
		p.pos += p.vel * delta
		p.t -= delta
		if p.t <= 0.0:
			particles.remove_at(i)
	for i in range(floaters.size() - 1, -1, -1):
		var f: Dictionary = floaters[i]
		f.pos += Vector2(0, -50) * delta
		f.t -= delta
		if f.t <= 0.0:
			floaters.remove_at(i)
	shake = maxf(0.0, shake - delta * 45.0)
	screen_flash = maxf(0.0, screen_flash - delta)
	if autoplay and bridge.shot_name == "":
		bot_timer -= delta
		if bot_timer <= 0.0:
			bot_timer = BOT_INTERVAL
			bridge.run_command(game.bot_command(), false)


func _burst(at: Vector2, n: int, color: Color) -> void:
	for i in n:
		var a := randf() * TAU
		particles.append({"pos": at, "vel": Vector2(cos(a), sin(a)) * randf_range(120.0, 460.0), "t": randf_range(0.3, 0.7), "color": color})


# --- Geometry ----------------------------------------------------------------------
func layout() -> Dictionary:
	var size := get_viewport_rect().size
	var L := {"size": size}
	if size.x >= size.y * 1.15:
		var bw := minf(size.y * 1.1, size.x - 640.0)
		var x0 := (size.x - bw - 600.0) * 0.5
		L.header = Rect2(x0, 10.0, bw, 80.0)
		L.board = Rect2(x0, 90.0, bw, size.y - 100.0)
		L.panel = Rect2(x0 + bw + 30.0, 20.0, 570.0, size.y - 40.0)
	else:
		var w := minf(COLUMN_W, size.x) - 24.0
		var x := (size.x - w) * 0.5
		L.header = Rect2(x, 10.0, w, 80.0)
		L.panel = Rect2(x, size.y - PANEL_H - 10.0, w, PANEL_H)
		var panel_top: float = L.panel.position.y
		L.board = Rect2(x, 96.0, w, panel_top - 106.0)
	var b: Rect2 = L.board
	L.hex = minf(b.size.x / (sqrt(3.0) * (2 * T.RADIUS + 1) + 0.4), b.size.y / (3.0 * T.RADIUS + 2.2))
	L.center = b.get_center()
	return L


func hex_px(L: Dictionary, h: Vector2i) -> Vector2:
	var s: float = L.hex
	return (L.center as Vector2) + Vector2(sqrt(3.0) * (h.x + h.y * 0.5), 1.5 * h.y) * s


func px_hex(L: Dictionary, p: Vector2) -> Vector2i:
	var s: float = L.hex
	var v: Vector2 = (p - (L.center as Vector2)) / s
	var q := (sqrt(3.0) / 3.0 * v.x - v.y / 3.0)
	var r := 2.0 / 3.0 * v.y
	var x := q
	var z := r
	var y := -x - z
	var rx := roundf(x)
	var ry := roundf(y)
	var rz := roundf(z)
	var dx := absf(rx - x)
	var dy := absf(ry - y)
	var dz := absf(rz - z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2i(int(rx), int(rz))


func build_buttons(L: Dictionary) -> void:
	buttons.clear()
	if game.phase != T.Phase.PLAYER:
		return
	var p: Rect2 = L.panel
	var end_w := minf(250.0, p.size.x - 330.0)
	buttons.append({"id": "end", "rect": Rect2(p.end.x - end_w, p.position.y + 12.0, end_w, 84.0), "label": "END TURN"})
	buttons.append({"id": "mode", "rect": Rect2(p.position.x, p.position.y + 12.0, 190.0, 84.0), "label": "SHOVE MODE" if shove_mode else "MOVE MODE"})


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and game != null and game.phase == T.Phase.PLAYER and not autoplay:
		paused = true


# --- Screenshot scenarios ------------------------------------------------------------
func _run_shot(scenario: String) -> void:
	match scenario:
		"play", "console", "hover":
			_act("start")
			var guard := 0
			while game.floor_no < 5 and game.phase == T.Phase.PLAYER and guard < 400:
				guard += 1
				_act(game.bot_command())
			for i in 2:
				if game.phase == T.Phase.PLAYER:
					_act(game.bot_command())
			if scenario == "console":
				bridge.console_open = true
				bridge.buffer = "shove ne"
				bridge.run_command("map")
			if scenario == "hover":
				shove_mode = true
		"over":
			_act("start")
			var n := 0
			while game.phase == T.Phase.PLAYER and n < 300:
				n += 1
				_act("end")
	fx.clear()
	ghosts.clear()
	floaters.clear()
	bridge.capture_after(40)


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
