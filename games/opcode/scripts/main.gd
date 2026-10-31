extends Node2D
## Opcode - assembly puzzles for a three-register machine.
## main.gd: layout, input -> commands, effects, autoplay, shots. Model: game.gd. VM: vm.gd.
## Drawing: view.gd. AI interface (/ console, window.aiGame): ai_bridge.gd.

const Game := preload("res://scripts/game.gd")
const VM := preload("res://scripts/vm.gd")
const Puzzles := preload("res://scripts/puzzles.gd")
const Bridge := preload("res://scripts/ai_bridge.gd")
const View := preload("res://scripts/view.gd")
const Controls := preload("res://scripts/controls.gd")
const Harness := preload("res://scripts/harness.gd")

# --- Tunables ---------------------------------------------------------------
const COLUMN_W := 720.0
const LINE_H := 32.0
const BTN_H := 56.0
const BTN_GAP := 6.0
const RUN_START_SPEED := 6.0       # instructions per second when an animated run starts
const RUN_ACCEL := 14.0            # ... gaining this many per second
const RUN_MAX_SPEED := 160.0
const BOT_INTERVAL := 0.5
const SELECT_COLS := 4
const HELP := "OPCODE commands:\nopen N - open puzzle N    menu - puzzle list    next - next puzzle\nprogram IN | ADD 5 | OUT - replace the whole program ('|' separates lines)\ninsert I / delete N / replace N I / cursor N (0 = top) / clear / list\nrun - check all tests now    step - one instruction    animate - watch it run    stop\nisa - instruction set    reset progress\nKeyboard: type an instruction + Enter inserts it; Enter on empty line runs."

var game: Game
var bridge: Bridge
var view: View
var harness: Harness
var state_time: float = 0.0
var last_screen: int = -1
var paused: bool = false
var autoplay: bool = false
var bot_timer: float = 0.0
var bot_puzzle: int = 0

var pending_op: String = ""        # touch: instruction waiting for its operand
var pending_num: String = ""       # touch: number being built for a src operand
var buffer: String = ""            # keyboard: instruction being typed
var show_manual: bool = false
var select_focus: int = 0
var scroll: int = 0                # first visible code line
var run_speed: float = RUN_START_SPEED
var run_acc: float = 0.0
var last_out: int = 0

var shake: float = 0.0
var screen_flash: float = 0.0
var screen_flash_color: Color = Color.WHITE
var particles: Array[Dictionary] = []
var floaters: Array[Dictionary] = []
var pulse_line: float = 0.0
var buttons: Array[Dictionary] = []   # {id, rect, label, enabled, style}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var headless_run := "--autoplay" in args
	for a in args:
		if a.begins_with("--shot="):
			headless_run = true
	game = Game.new(not headless_run)
	game.event.connect(_on_game_event)
	view = View.new()
	view.m = self
	add_child(view)
	bridge = Bridge.new()
	add_child(bridge)
	bridge.setup(game.observe, _act, HELP)
	var controls := Controls.new()
	controls.m = self
	add_child(controls)
	harness = Harness.new()
	harness.m = self
	if "--autoplay" in args:
		autoplay = true
	if bridge.shot_name != "":
		harness.run_shot(bridge.shot_name)


func _act(cmd: String) -> Dictionary:
	var verb := cmd.strip_edges().split(" ", false)
	var res: Dictionary = game.act(cmd)
	if res.ok and verb.size() > 0 and verb[0].to_lower() in ["animate", "play"]:
		run_speed = RUN_START_SPEED
		run_acc = 0.0
	return res


func _on_game_event(kind: String, data: Dictionary) -> void:
	match kind:
		"screen":
			pending_op = ""
			pending_num = ""
			buffer = ""
			scroll = 0
			last_out = 0
		"solved":
			screen_flash = 0.3
			screen_flash_color = View.GREEN
			_burst(get_viewport_rect().size * Vector2(0.5, 0.42), 60 if data.get("first", false) else 30)
		"result":
			shake = 16.0
			screen_flash = 0.25
			screen_flash_color = View.RED
		"win":
			_burst(get_viewport_rect().size * 0.5, 80)


# --- Frame -------------------------------------------------------------------------
func _process(delta: float) -> void:
	view.queue_redraw()
	if int(game.screen) != last_screen:
		last_screen = int(game.screen)
		state_time = 0.0
	if paused:
		return
	state_time += delta
	shake = maxf(0.0, shake - delta * 45.0)
	screen_flash = maxf(0.0, screen_flash - delta)
	pulse_line = maxf(0.0, pulse_line - delta * 4.0)
	if game.animating:
		run_speed = minf(RUN_MAX_SPEED, run_speed + RUN_ACCEL * delta)
		run_acc += run_speed * delta
		var n := int(run_acc)
		if n > 0:
			run_acc -= n
			game.tick(n)
			pulse_line = 1.0
	_watch_outputs()
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p.vel += Vector2(0, 700) * delta
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
	if autoplay:
		bot_timer -= delta
		if bot_timer <= 0.0:
			bot_timer = BOT_INTERVAL
			harness.bot_step()


## Spark on every correct output while the machine runs.
func _watch_outputs() -> void:
	if game.machine.is_empty():
		last_out = 0
		return
	var outs: Array = game.machine.out
	if outs.size() > last_out:
		last_out = outs.size()
		var L := layout()
		var r: Rect2 = L.tape
		var col_w := r.size.x / 3.0
		var y := r.position.y + 50.0 + (last_out - 1 - tape_scroll()) * 30.0
		_burst(Vector2(r.position.x + col_w * 2.5, y), 8)


func _burst(at: Vector2, n: int) -> void:
	for i in n:
		var a := randf() * TAU
		var sp := randf_range(100.0, 420.0)
		particles.append({"pos": at, "vel": Vector2(cos(a), sin(a)) * sp - Vector2(0, 150), "t": randf_range(0.4, 0.9),
			"color": View.GREEN if i % 2 else View.GOLD})


# --- Layout ------------------------------------------------------------------------
func layout() -> Dictionary:
	var size := get_viewport_rect().size
	var L := {"size": size}
	var wide := size.x >= size.y * 1.15
	var w := minf(COLUMN_W, size.x) - 24.0
	if wide:
		w = minf(size.x - 40.0, 2100.0)
	var x := (size.x - w) * 0.5
	L.x = x
	L.w = w
	L.top = Rect2(x, 8.0, w, 72.0)
	L.task = Rect2(x, 86.0, w, 76.0)
	var pal_h := 4.0 * (BTN_H + BTN_GAP) + 76.0
	if wide:
		var left_w := w * 0.34
		var mid_w := w * 0.18
		L.code = Rect2(x, 170.0, left_w, size.y - 186.0)
		L.tape = Rect2(x + left_w + 14.0, 170.0, mid_w, size.y - 186.0)
		var tape_r: Rect2 = L.tape
		var px: float = tape_r.end.x + 14.0
		L.palette = Rect2(px, size.y - pal_h - 16.0, x + w - px, pal_h)
		L.regs = Rect2(px, 170.0, x + w - px, L.palette.position.y - 186.0)
	else:
		L.palette = Rect2(x, size.y - pal_h - 10.0, w, pal_h)
		var main_h: float = L.palette.position.y - 180.0
		var code_w := w * 0.56
		L.code = Rect2(x, 170.0, code_w, main_h)
		var sx := x + code_w + 12.0
		var regs_h := 236.0
		L.tape = Rect2(sx, 170.0, w - code_w - 12.0, main_h - regs_h - 10.0)
		L.regs = Rect2(sx, L.tape.end.y + 10.0, w - code_w - 12.0, regs_h)
	return L


func visible_lines(L: Dictionary) -> int:
	var c: Rect2 = L.code
	return maxi(4, int((c.size.y - 80.0) / LINE_H))


func code_line_rect(L: Dictionary, k: int) -> Rect2:
	var c: Rect2 = L.code
	return Rect2(c.position.x + 6.0, c.position.y + 44.0 + (k - scroll) * LINE_H, c.size.x - 12.0, LINE_H - 2.0)


## Keep the interesting line (running pc, else cursor) on screen.
func update_scroll(L: Dictionary) -> void:
	var n := visible_lines(L)
	var focus: int = game.cursor
	if not game.machine.is_empty():
		focus = int(game.machine.last_pc)
	if focus < scroll:
		scroll = maxi(focus, 0)
	elif focus >= scroll + n:
		scroll = focus - n + 1
	scroll = clampi(scroll, 0, maxi(0, game.program.size() - n + 1))


func tape_scroll() -> int:
	if game.machine.is_empty():
		return 0
	var outs: Array = game.machine.out
	return maxi(0, maxi(int(game.machine.in_ptr), outs.size()) - 10)


func build_buttons(L: Dictionary) -> void:
	buttons.clear()
	var size: Vector2 = L.size
	if show_manual:
		return
	match game.screen:
		Game.Screen.SELECT:
			var gw := minf(size.x - 40.0, 900.0)
			var cw := (gw - (SELECT_COLS - 1) * 14.0) / SELECT_COLS
			var gx := (size.x - gw) * 0.5
			for i in Puzzles.count():
				var col := i % SELECT_COLS
				@warning_ignore("integer_division")
				var row := i / SELECT_COLS
				buttons.append({"id": "open:%d" % i, "rect": Rect2(gx + col * (cw + 14.0), 190.0 + row * (cw * 0.82 + 14.0), cw, cw * 0.82),
					"label": "", "enabled": game.is_unlocked(i)})
			buttons.append({"id": "manual", "rect": Rect2(size.x * 0.5 - 130.0, size.y - 110.0, 260.0, 70.0), "label": "MANUAL", "enabled": true})
		Game.Screen.EDIT:
			var top: Rect2 = L.top
			buttons.append({"id": "menu", "rect": Rect2(top.position.x, top.position.y + 4.0, 130.0, 60.0), "label": "< MENU", "enabled": true})
			buttons.append({"id": "manual", "rect": Rect2(top.end.x - 64.0, top.position.y + 4.0, 64.0, 60.0), "label": "?", "enabled": true})
			if not game.result.is_empty():
				_result_buttons(size)
				return
			var n := visible_lines(L)
			for k in range(scroll, mini(game.program.size() + 1, scroll + n)):
				buttons.append({"id": "line:%d" % k, "rect": code_line_rect(L, k), "label": "", "enabled": true})
			var c: Rect2 = L.code
			buttons.append({"id": "line:-1", "rect": Rect2(c.position.x, c.position.y, c.size.x, 40.0), "label": "", "enabled": true})
			_palette_buttons(L)


func _palette_buttons(L: Dictionary) -> void:
	var p: Rect2 = L.palette
	var editing: bool = game.machine.is_empty()
	var bw := (p.size.x - 6.0 * BTN_GAP) / 7.0
	for i in VM.OP_ORDER.size():
		var col := i % 7
		@warning_ignore("integer_division")
		var row := i / 7
		var op: String = VM.OP_ORDER[i]
		buttons.append({"id": "op:" + op, "rect": Rect2(p.position.x + col * (bw + BTN_GAP), p.position.y + row * (BTN_H + BTN_GAP), bw, BTN_H),
			"label": op, "enabled": editing, "style": "op_sel" if op == pending_op else "op"})
	var y3 := p.position.y + 2.0 * (BTN_H + BTN_GAP)
	var y4 := y3 + BTN_H + BTN_GAP
	var kind: String = VM.OPS.get(pending_op, "")
	var row3: Array = []
	var row4: Array = []
	if pending_op != "":
		match kind:
			"src":
				row3 = ["X", "Y", "+/-", "#", "<", "OK", "CANCEL"]
				row4 = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
			"reg":
				row3 = ["X", "Y", "", "", "", "", "CANCEL"]
			"lbl":
				row3 = ["A", "B", "C", "D", "E", "F", "CANCEL"]
	for i in row3.size():
		if row3[i] == "":
			continue
		var id: String = "num" if row3[i] == "#" else "arg:" + row3[i]
		var label: String = (pending_num if pending_num != "" else "0") if row3[i] == "#" else row3[i]
		buttons.append({"id": id, "rect": Rect2(p.position.x + i * (bw + BTN_GAP), y3, bw, BTN_H), "label": label, "enabled": row3[i] != "#",
			"style": "num" if row3[i] == "#" else "arg"})
	var dw := (p.size.x - 9.0 * BTN_GAP) / 10.0
	for i in row4.size():
		buttons.append({"id": "digit:" + row4[i], "rect": Rect2(p.position.x + i * (dw + BTN_GAP), y4, dw, BTN_H), "label": row4[i], "enabled": true, "style": "arg"})
	var y5 := y4 + BTN_H + BTN_GAP + 8.0
	var ctl := [["up", "UP"], ["down", "DOWN"], ["del", "DEL"], ["step", "STEP"], ["run", "RUN"], ["fast", "CHECK"], ["stop", "STOP"]]
	for i in ctl.size():
		var id: String = ctl[i][0]
		var en := true
		if id in ["up", "down", "del"]:
			en = editing
		elif id == "stop":
			en = not editing
		buttons.append({"id": id, "rect": Rect2(p.position.x + i * (bw + BTN_GAP), y5, bw, 62.0), "label": ctl[i][1], "enabled": en,
			"style": "go" if id == "run" else "ctl"})


func _result_buttons(size: Vector2) -> void:
	var r := result_rect(size)
	var ok: bool = game.result.ok
	var bw := (r.size.x - 60.0) * 0.5
	buttons.append({"id": "dismiss", "rect": Rect2(r.position.x + 20.0, r.end.y - 86.0, bw, 66.0), "label": "EDIT", "enabled": true, "style": "ctl"})
	if ok and game.puzzle + 1 < Puzzles.count():
		buttons.append({"id": "nextpz", "rect": Rect2(r.end.x - 20.0 - bw, r.end.y - 86.0, bw, 66.0), "label": "NEXT >", "enabled": true, "style": "go"})


func result_rect(size: Vector2) -> Rect2:
	var w := minf(size.x - 40.0, 640.0)
	return Rect2((size.x - w) * 0.5, size.y * 0.5 - 250.0, w, 440.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and game != null and game.animating and not autoplay:
		paused = true
