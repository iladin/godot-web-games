extends Node2D
## Falsify - find the hidden rule with as few experiments as possible.
## main.gd: state, layout, input, effects. Logic: lab.gd. Drawing: view.gd. AI interface: ai_bridge.gd.

const Lab := preload("res://scripts/lab.gd")
const Rules := preload("res://scripts/rules.gd")
const Bridge := preload("res://scripts/ai_bridge.gd")
const View := preload("res://scripts/view.gd")
const Controls := preload("res://scripts/controls.gd")

# --- Tunables ---------------------------------------------------------------
const COLUMN_W := 720.0
const ROW_H := 56.0
const INPUT_H := 340.0
const RESTART_DELAY := 0.6
const BOT_INTERVAL := 0.35
const BOT_GAMBLE := 0.25
const STRIKE_SPEED := 3.0
const SAVE_PATH := "user://save.cfg"
const HELP := "FALSIFY commands:\ntest a b c  - run an experiment (whole numbers 0-15)\nname X  - name the hidden rule (letter)\nnext  - continue after a round\nstart / restart\nTests cost 1 funding, a wrong name costs 2.\nFunding below 0 ends the game."

var lab: Lab
var bridge: Bridge
var view: View
var state_time: float = 0.0
var last_phase: int = -1
var paused: bool = false
var autoplay: bool = false
var bot_timer: float = 0.0
var best: int = 0
var new_best: bool = false

var slots: Array[int] = [-1, -1, -1]
var cur_slot: int = 0
var pending: bool = false      # current slot holds a lone "1" that may still become 10-15
var selected: int = -1         # hypothesis picked for naming

var strike: Array[float] = []  # per hypothesis: strike-through progress (0 = none)
var flash: Array[float] = []
var shake: float = 0.0
var screen_flash: float = 0.0
var screen_flash_color: Color = Color.WHITE
var particles: Array[Dictionary] = []
var floaters: Array[Dictionary] = []
var verdict_pop: float = 0.0
var buttons: Array[Dictionary] = []  # {id, rect, label, enabled}


func _ready() -> void:
	best = _load_best()
	lab = Lab.new()
	lab.event.connect(_on_lab_event)
	view = View.new()
	view.m = self
	add_child(view)
	bridge = Bridge.new()
	add_child(bridge)
	bridge.setup(lab.observe, _act, HELP)
	var controls := Controls.new()
	controls.m = self
	add_child(controls)
	if "--autoplay" in OS.get_cmdline_user_args():
		autoplay = true
		_act("start")
	if bridge.shot_name != "":
		_run_shot(bridge.shot_name)


## Every action (keyboard, touch, console, JS, bot) goes through here.
func _act(cmd: String) -> Dictionary:
	var res: Dictionary = lab.act(cmd)
	var p := cmd.strip_edges().to_lower().replace(",", " ").split(" ", false)
	if res.ok and p.size() == 4 and (p[0] == "test" or p[0] == "t"):
		slots = [int(p[1]), int(p[2]), int(p[3])]
		cur_slot = 0
		pending = false
	return res


func _on_lab_event(kind: String, data: Dictionary) -> void:
	var L := layout()
	match kind:
		"round":
			strike.clear()
			flash.clear()
			for k in lab.candidates.size():
				strike.append(0.0)
				flash.append(0.0)
			selected = -1
			slots = [-1, -1, -1]
			cur_slot = 0
			pending = false
		"test":
			verdict_pop = 1.0
			for k: int in data.ruled_out:
				strike[k] = 0.01
				flash[k] = 1.0
			screen_flash = 0.12
			screen_flash_color = View.ACCENT if data.fits else View.NO
			floaters.append({"text": "-1", "pos": L.header.position + Vector2(L.header.size.x * 0.5, 70.0), "t": 1.0, "color": View.GOLD})
		"wrong":
			strike[data.index] = 0.01
			flash[data.index] = 1.0
			shake = 18.0
			screen_flash = 0.3
			screen_flash_color = View.NO
			selected = -1
			floaters.append({"text": "-2", "pos": L.header.position + Vector2(L.header.size.x * 0.5, 70.0), "t": 1.0, "color": View.NO})
		"right":
			var r := row_rect(L, data.index)
			_burst(r.get_center(), 28)
			screen_flash = 0.25
			screen_flash_color = View.ACCENT
			floaters.append({"text": "+%d" % data.points, "pos": r.get_center() - Vector2(0, 20), "t": 1.4, "color": View.GOLD})
		"game_over", "win":
			if lab.score > best:
				best = lab.score
				new_best = true
				_save_best(best)


# --- Frame -------------------------------------------------------------------------
func _process(delta: float) -> void:
	queue_redraw()
	view.queue_redraw()
	if int(lab.phase) != last_phase:
		last_phase = int(lab.phase)
		state_time = 0.0
		if lab.phase == Lab.Phase.TESTING and lab.round_no == 1:
			new_best = false
	if paused:
		return
	state_time += delta
	for k in strike.size():
		if strike[k] > 0.0 and strike[k] < 1.0:
			strike[k] = minf(1.0, strike[k] + delta * STRIKE_SPEED)
		flash[k] = maxf(0.0, flash[k] - delta * 2.0)
	shake = maxf(0.0, shake - delta * 45.0)
	screen_flash = maxf(0.0, screen_flash - delta)
	verdict_pop = maxf(0.0, verdict_pop - delta * 3.0)
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p.vel += Vector2(0, 900) * delta
		p.pos += p.vel * delta
		p.t -= delta
		if p.t <= 0.0:
			particles.remove_at(i)
	for i in range(floaters.size() - 1, -1, -1):
		var f: Dictionary = floaters[i]
		f.pos += Vector2(0, -60) * delta
		f.t -= delta
		if f.t <= 0.0:
			floaters.remove_at(i)
	if autoplay and bridge.shot_name == "":
		bot_timer -= delta
		if bot_timer <= 0.0:
			bot_timer = BOT_INTERVAL
			bridge.run_command(lab.bot_command(BOT_GAMBLE))


func _burst(at: Vector2, n: int) -> void:
	for i in n:
		var a := randf() * TAU
		var sp := randf_range(150.0, 520.0)
		particles.append({"pos": at, "vel": Vector2(cos(a), sin(a)) * sp - Vector2(0, 250), "t": randf_range(0.5, 1.0),
			"color": View.ACCENT if i % 3 else View.GOLD})


# --- Layout ------------------------------------------------------------------------
func layout() -> Dictionary:
	var size := get_viewport_rect().size
	var n := maxi(lab.candidates.size(), 4)
	var L := {"size": size}
	if size.x >= size.y * 1.15:
		var colw := minf(COLUMN_W, (size.x - 80.0) * 0.5)
		var x0 := (size.x - colw * 2.0 - 40.0) * 0.5
		var x1 := x0 + colw + 40.0
		L.header = Rect2(x0, 16.0, colw, 96.0)
		L.cands = Rect2(x0, 124.0, colw, size.y - 140.0)
		L.row_h = minf(66.0, L.cands.size.y / n)
		L.input = Rect2(x1, size.y - INPUT_H - 16.0, colw, INPUT_H)
		L.notebook = Rect2(x1, 16.0, colw, L.input.position.y - 32.0)
	else:
		var w := minf(COLUMN_W, size.x) - 24.0
		var x := (size.x - w) * 0.5
		L.header = Rect2(x, 10.0, w, 96.0)
		L.input = Rect2(x, size.y - INPUT_H - 12.0, w, INPUT_H)
		var input_top: float = L.input.position.y
		var room: float = input_top - 118.0 - 200.0
		L.row_h = minf(ROW_H, room / n)
		L.cands = Rect2(x, 116.0, w, L.row_h * n)
		var nb_y: float = L.cands.end.y + 10.0
		L.notebook = Rect2(x, nb_y, w, L.input.position.y - nb_y - 10.0)
	return L


func row_rect(L: Dictionary, k: int) -> Rect2:
	var c: Rect2 = L.cands
	var h: float = L.row_h
	return Rect2(c.position.x, c.position.y + k * h, c.size.x, h - 6.0)


func build_buttons(L: Dictionary) -> void:
	buttons.clear()
	if lab.phase != Lab.Phase.TESTING:
		return
	for k in lab.candidates.size():
		var r := row_rect(L, k)
		buttons.append({"id": "cand:%d" % k, "rect": r, "label": "", "enabled": lab.alive[k]})
		if k == selected:
			buttons.append({"id": "name", "rect": Rect2(r.end.x - 150.0, r.position.y + 5.0, 140.0, r.size.y - 10.0), "label": "NAME IT", "enabled": true})
	var inp: Rect2 = L.input
	var slot_w := 120.0
	var sx := inp.position.x + (inp.size.x - (slot_w * 3.0 + 40.0)) * 0.5
	for i in 3:
		buttons.append({"id": "slot:%d" % i, "rect": Rect2(sx + i * (slot_w + 20.0), inp.position.y + 8.0, slot_w, 84.0), "label": "", "enabled": true})
	var kx := inp.position.x
	var kw := (inp.size.x - 4.0 * 10.0) / 5.0
	var ky := inp.position.y + 110.0
	var kh := 66.0
	var keys := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
	for i in 10:
		var col := i % 5
		@warning_ignore("integer_division")
		var row := i / 5
		buttons.append({"id": "key:" + keys[i], "rect": Rect2(kx + col * (kw + 10.0), ky + row * (kh + 10.0), kw, kh), "label": keys[i], "enabled": true})
	var y3 := ky + 2.0 * (kh + 10.0)
	buttons.append({"id": "del", "rect": Rect2(kx, y3, kw, kh), "label": "DEL", "enabled": true})
	buttons.append({"id": "clr", "rect": Rect2(kx + kw + 10.0, y3, kw, kh), "label": "CLR", "enabled": true})
	var ready := slots[0] >= 0 and slots[1] >= 0 and slots[2] >= 0 and lab.funding >= Lab.TEST_COST
	buttons.append({"id": "test", "rect": Rect2(kx + 2.0 * (kw + 10.0), y3, kw * 3.0 + 20.0, kh), "label": "TEST  (-1)", "enabled": ready})


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and lab != null and lab.phase == Lab.Phase.TESTING and not autoplay:
		paused = true


# --- Screenshot scenarios (scripts/studio/shots.sh style) --------------------------
func _run_shot(scenario: String) -> void:
	match scenario:
		"play", "select", "done", "console":
			_act("start")
			for i in 2:
				_act(lab.bot_command())
			if scenario == "select":
				selected = lab.secret
				slots = [3, 1, -1]
				cur_slot = 1
				pending = true
			elif scenario == "done":
				while lab.phase == Lab.Phase.TESTING:
					_act(lab.bot_command())
			elif scenario == "console":
				bridge.console_open = true
				bridge.buffer = "test 3 6 9"
				bridge.show_message(HELP)
		"over":
			_act("start")
			while lab.phase == Lab.Phase.TESTING:
				var st := lab.seed_triple
				if lab.funding > 0:
					_act("test %d %d %d" % [st.x, st.y, st.z])
				else:
					for k in lab.candidates.size():
						if lab.alive[k] and k != lab.secret:
							_act("name %s" % Lab.LETTERS[k])
							break
		"win":
			_act("start")
			while lab.phase != Lab.Phase.WIN:
				_act(lab.bot_command())
	bridge.capture_after(45)


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
