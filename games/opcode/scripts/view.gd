extends Node2D
## Opcode drawing: phosphor-terminal look. Reads state from main.gd (m) and its game model.

const Game := preload("res://scripts/game.gd")
const VM := preload("res://scripts/vm.gd")
const Puzzles := preload("res://scripts/puzzles.gd")

# --- Palette -------------------------------------------------------------------
const BG := Color("0a0d13")
const SCAN := Color(1, 1, 1, 0.025)
const PANEL := Color("141a25")
const PANEL_HI := Color("1f2838")
const GREEN := Color("7dff9a")    # accent: IO, success, run
const GOLD := Color("ffc857")     # jumps, selection, stars
const CYAN := Color("5ad1ff")     # labels, registers
const RED := Color("ff5d73")      # failure
const INK := Color("dfe7f2")
const DIM := Color("5f6b80")
const DARK := Color("070a0f")

var m: Node2D  # main.gd
var font: Font = ThemeDB.fallback_font
var _boxes: Dictionary = {}


func _draw() -> void:
	var game: Game = m.game
	var L: Dictionary = m.layout()
	var size: Vector2 = L.size
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	for y in range(0, int(size.y), 4):
		draw_line(Vector2(0, y), Vector2(size.x, y), SCAN, 1.0)
	var s: float = m.shake
	draw_set_transform(Vector2(randf_range(-s, s), randf_range(-s, s)))
	m.build_buttons(L)
	match game.screen:
		Game.Screen.TITLE:
			_title(size)
		Game.Screen.SELECT:
			_select(size, game)
		Game.Screen.EDIT:
			_edit(L, game)
		Game.Screen.WIN:
			_win(size, game)
	if m.show_manual:
		_manual(size)
	for p: Dictionary in m.particles:
		draw_rect(Rect2(p.pos - Vector2(3, 3), Vector2(6, 6)), Color(p.color, clampf(p.t * 2.0, 0.0, 1.0)))
	for f: Dictionary in m.floaters:
		_text_c(f.text, f.pos, 54, Color(f.color, clampf(f.t, 0.0, 1.0)))
	draw_set_transform(Vector2.ZERO)
	if m.screen_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(m.screen_flash_color, m.screen_flash * 0.4))
	if m.paused:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.65))
		_text_c("PAUSED - tap to resume", size * 0.5, 36, INK)


# --- Screens -----------------------------------------------------------------------
func _title(size: Vector2) -> void:
	var t: float = m.state_time
	var demo := ["IN", "STA X", "IN", "LBL A", "JEZ B", "SUB 1", "SWP Y", "ADD X", "SWP Y", "JMP A", "LBL B", "SWP Y", "OUT"]
	var cx := size.x * 0.5
	for i in demo.size():
		var y := size.y * 0.42 + i * 34.0 - fmod(t * 20.0, 34.0)
		var a := 0.12 + 0.12 * sin(t * 2.0 + i)
		_text_l("%02d  %s" % [i + 1, demo[i]], Vector2(cx - 120.0, y), 26, Color(GREEN, a))
	_text_c("OPCODE", Vector2(cx, size.y * 0.2), 120, GREEN)
	_text_c("Assembly puzzles for a tiny machine.", Vector2(cx, size.y * 0.2 + 80.0), 30, INK)
	_text_c("One accumulator. Two registers. Fourteen instructions.", Vector2(cx, size.y * 0.2 + 120.0), 24, DIM)
	_text_c("Every puzzle has a par for cycles and for size.", Vector2(cx, size.y * 0.2 + 154.0), 24, DIM)
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	_text_c("Tap or press Space to start", Vector2(cx, size.y * 0.86), 36, GREEN.lerp(INK, pulse))
	_text_c("AI players: press / for a command line (try /help)", Vector2(cx, size.y * 0.86 + 48.0), 22, DIM)


func _select(size: Vector2, game: Game) -> void:
	_text_c("OPCODE", Vector2(size.x * 0.5, 70.0), 64, GREEN)
	_star(Vector2(size.x * 0.5 - 70.0, 132.0), 14.0, true)
	_text_l("%d / %d" % [game.total_stars(), Puzzles.count() * 3], Vector2(size.x * 0.5 - 48.0, 142.0), 30, GOLD)
	for b: Dictionary in m.buttons:
		var id: String = b.id
		var r: Rect2 = b.rect
		if id.begins_with("open:"):
			var i := int(id.substr(5))
			var open: bool = b.enabled
			var focus: bool = m.select_focus == i
			_panel(r, PANEL_HI if focus else PANEL, GREEN if focus else (Color.TRANSPARENT if open else Color(DIM, 0.3)))
			var pz: Dictionary = Puzzles.all()[i]
			_text_c("%02d" % (i + 1), r.position + Vector2(r.size.x * 0.5, r.size.y * 0.3), 40, GREEN if open else DIM)
			var name_size := 20 if str(pz.name).length() <= 11 else 16
			_text_c(pz.name, r.position + Vector2(r.size.x * 0.5, r.size.y * 0.58), name_size, INK if open else DIM)
			if open:
				var st := game.stars(i)
				for k in 3:
					_star(r.position + Vector2(r.size.x * 0.5 + (k - 1) * 30.0, r.size.y * 0.8), 11.0, k < st)
			else:
				_text_c("LOCKED", r.position + Vector2(r.size.x * 0.5, r.size.y * 0.8), 16, DIM)
		elif id == "manual":
			_button(b)
	_text_c("Tap a puzzle  -  arrows + Enter  -  M for the manual", Vector2(size.x * 0.5, size.y - 140.0), 20, DIM)


func _edit(L: Dictionary, game: Game) -> void:
	var pz: Dictionary = Puzzles.all()[game.puzzle]
	var par := Puzzles.par(game.puzzle)
	var top: Rect2 = L.top
	_text_c("%02d  %s" % [game.puzzle + 1, pz.name], Vector2(top.get_center().x, top.position.y + 30.0), 34, GREEN)
	for k in 3:
		_star(Vector2(top.get_center().x + (k - 1) * 26.0, top.position.y + 60.0), 9.0, k < game.stars(game.puzzle))
	var task: Rect2 = L.task
	draw_multiline_string(font, task.position + Vector2(4.0, 24.0), pz.task, HORIZONTAL_ALIGNMENT_LEFT, task.size.x - 8.0, 24, 3, INK)
	_code_panel(L, game, par)
	_tape_panel(L, game)
	_regs_panel(L, game, par)
	for b: Dictionary in m.buttons:
		var id: String = b.id
		if id.begins_with("line:"):
			continue
		if id in ["dismiss", "nextpz"]:
			continue
		_button(b)
	if not game.result.is_empty():
		_result(L.size, game)
		for b: Dictionary in m.buttons:
			if str(b.id) in ["dismiss", "nextpz", "menu"]:
				_button(b)


func _code_panel(L: Dictionary, game: Game, par: Dictionary) -> void:
	var c: Rect2 = L.code
	_panel(c, PANEL)
	var size_now := 0
	for line in game.program:
		if not line.begins_with("LBL"):
			size_now += 1
	_text_l("PROGRAM", c.position + Vector2(14.0, 30.0), 20, DIM)
	_text_r("SIZE %d / par %d" % [size_now, par["size"]], c.position + Vector2(c.size.x - 14.0, 30.0), 20, GREEN if size_now <= par["size"] else GOLD)
	m.update_scroll(L)
	var n: int = m.visible_lines(L)
	var running: bool = not game.machine.is_empty()
	var fail_line: int = -1
	if not game.result.is_empty() and not game.result.ok:
		fail_line = int(game.result.get("line", -1))
	var scroll: int = m.scroll
	for k in range(scroll, mini(game.program.size(), scroll + n)):
		var r: Rect2 = m.code_line_rect(L, k)
		if running and k == int(game.machine.last_pc):
			draw_rect(r, Color(GOLD, 0.18 + 0.2 * float(m.pulse_line)))
		elif k == fail_line:
			draw_rect(r, Color(RED, 0.3))
		elif not running and k == game.cursor:
			draw_rect(r, PANEL_HI)
		_text_r("%d" % (k + 1), Vector2(r.position.x + 40.0, r.position.y + 23.0), 20, DIM)
		var line: String = game.program[k]
		_text_l(line, Vector2(r.position.x + 56.0, r.position.y + 24.0), 26, _op_color(line))
		if running and k == int(game.machine.pc):
			_text_l(">", Vector2(r.position.x + 2.0, r.position.y + 24.0), 26, GREEN)
	if not running:
		var cy: float = (m.code_line_rect(L, game.cursor + 1) as Rect2).position.y - 2.0
		if cy >= c.position.y + 40.0 and cy <= c.end.y - 40.0:
			draw_line(Vector2(c.position.x + 50.0, cy), Vector2(c.end.x - 10.0, cy), GREEN, 3.0)
			draw_circle(Vector2(c.position.x + 50.0, cy), 5.0, GREEN)
	if game.program.is_empty():
		_text_l("empty - tap an instruction below", c.position + Vector2(56.0, 100.0), 20, DIM)
	var by := c.end.y - 14.0
	draw_line(Vector2(c.position.x + 8.0, by - 32.0), Vector2(c.end.x - 8.0, by - 32.0), Color(INK, 0.08), 1.0)
	var buf: String = m.buffer
	if buf != "":
		var caret := "_" if fmod(float(m.state_time), 1.0) < 0.6 else " "
		_text_l("> " + buf + caret, Vector2(c.position.x + 14.0, by), 24, GREEN)
	elif m.pending_op != "":
		var shown: String = m.pending_op + " " + (str(m.pending_num) if m.pending_num != "" else "?")
		_text_l("> " + shown, Vector2(c.position.x + 14.0, by), 24, GOLD)
	else:
		_text_l("type: ADD X + Enter  -  Enter = run", Vector2(c.position.x + 14.0, by), 18, DIM)


func _tape_panel(L: Dictionary, game: Game) -> void:
	var r: Rect2 = L.tape
	_panel(r, PANEL)
	var t: Dictionary = Puzzles.tests(game.puzzle)[0]
	var inp: Array = t.input
	var exp: Array = t.expected
	var st: Dictionary = game.machine
	if st.is_empty() and game.result.get("failed_test", -1) == 0 and game.result.has("state"):
		st = game.result.state   # show how test 1 went wrong
	var outs: Array = [] if st.is_empty() else st.out
	var in_ptr := -1 if st.is_empty() else int(st.in_ptr)
	var col_w := r.size.x / 3.0
	var heads := ["IN", "WANT", "OUT"]
	for c in 3:
		_text_c(heads[c], Vector2(r.position.x + col_w * (c + 0.5), r.position.y + 24.0), 20, DIM)
	var rows := int((r.size.y - 50.0) / 30.0)
	var first: int = m.tape_scroll()
	for i in range(first, first + rows):
		var y := r.position.y + 50.0 + (i - first) * 30.0
		if i < inp.size():
			var col := INK
			if in_ptr >= 0 and i < in_ptr:
				col = DIM
			if i == in_ptr:
				draw_rect(Rect2(r.position.x + 4.0, y - 14.0, col_w - 8.0, 28.0), Color(CYAN, 0.18))
			_text_c(str(inp[i]), Vector2(r.position.x + col_w * 0.5, y), 22, col)
		if i < exp.size():
			_text_c(str(exp[i]), Vector2(r.position.x + col_w * 1.5, y), 22, INK)
		if i < outs.size():
			var good := i < exp.size() and int(outs[i]) == int(exp[i])
			_text_c(str(outs[i]), Vector2(r.position.x + col_w * 2.5, y), 22, GREEN if good else RED)
	draw_line(Vector2(r.position.x + col_w, r.position.y + 40.0), Vector2(r.position.x + col_w, r.end.y - 8.0), Color(INK, 0.06), 1.0)
	draw_line(Vector2(r.position.x + col_w * 2.0, r.position.y + 40.0), Vector2(r.position.x + col_w * 2.0, r.end.y - 8.0), Color(INK, 0.06), 1.0)


func _regs_panel(L: Dictionary, game: Game, par: Dictionary) -> void:
	var r: Rect2 = L.regs
	_panel(r, PANEL)
	var st: Dictionary = game.machine
	var names := ["ACC", "X", "Y"]
	var keys := ["acc", "x", "y"]
	var bw := (r.size.x - 40.0) / 3.0
	for i in 3:
		var b := Rect2(r.position.x + 10.0 + i * (bw + 10.0), r.position.y + 12.0, bw, 84.0)
		_panel(b, PANEL_HI)
		_text_c(names[i], b.position + Vector2(bw * 0.5, 20.0), 18, CYAN)
		_text_c(str(st.get(keys[i], 0)) if not st.is_empty() else "0", b.position + Vector2(bw * 0.5, 58.0), 32, INK if not st.is_empty() else DIM)
	var y := r.position.y + 132.0
	var cyc := "-" if st.is_empty() else str(st.cycles)
	_text_l("CYCLES %s" % cyc, Vector2(r.position.x + 14.0, y), 22, INK)
	_text_r("par %d" % par.cycles, Vector2(r.end.x - 14.0, y), 22, DIM)
	var b: Dictionary = game.best.get(game.puzzle, {})
	if not b.is_empty():
		_text_l("BEST  %d cyc  %d size" % [b.cycles, b["size"]], Vector2(r.position.x + 14.0, y + 34.0), 20, GOLD)
	_text_l("test 1 of %d shown" % Puzzles.TESTS_PER_PUZZLE, Vector2(r.position.x + 14.0, y + 68.0), 18, DIM)


func _result(size: Vector2, game: Game) -> void:
	var res: Dictionary = game.result
	var r: Rect2 = m.result_rect(size)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
	_panel(r, PANEL, GREEN if res.ok else RED)
	var cx := r.get_center().x
	if res.ok:
		_text_c("SOLVED", Vector2(cx, r.position.y + 60.0), 56, GREEN)
		var rows := [["CYCLES", int(res.cycles), int(res.par_cycles), res.get("new_cycles", false)],
			["SIZE", int(res["size"]), int(res.par_size), res.get("new_size", false)]]
		for i in 2:
			var y := r.position.y + 140.0 + i * 70.0
			var row: Array = rows[i]
			var hit: bool = row[1] <= row[2]
			_text_l(row[0], Vector2(r.position.x + 40.0, y), 26, DIM)
			_text_l(str(row[1]), Vector2(r.position.x + 190.0, y), 40, GREEN if hit else INK)
			_text_l("par %d" % row[2], Vector2(r.position.x + 290.0, y), 24, DIM)
			_star(Vector2(r.end.x - 120.0, y - 12.0), 16.0, hit)
			if row[3]:
				_text_l("BEST", Vector2(r.end.x - 90.0, y), 20, GOLD)
		var bar_w := r.size.x - 80.0
		var ratio := clampf(float(res.par_cycles) / maxf(1.0, float(res.cycles)), 0.05, 1.0)
		draw_rect(Rect2(r.position.x + 40.0, r.position.y + 270.0, bar_w, 10.0), PANEL_HI)
		draw_rect(Rect2(r.position.x + 40.0, r.position.y + 270.0, bar_w * ratio, 10.0), GREEN)
		_text_c("%d / 3 stars" % game.stars(game.puzzle), Vector2(cx, r.position.y + 318.0), 26, GOLD)
	else:
		_text_c("FAILED", Vector2(cx, r.position.y + 60.0), 56, RED)
		draw_multiline_string(font, r.position + Vector2(30.0, 130.0), str(res.reason), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 60.0, 28, 4, INK)
		if int(res.get("line", -1)) >= 0:
			_text_c("Line %d is highlighted." % (int(res.line) + 1), Vector2(cx, r.position.y + 300.0), 22, DIM)


func _win(size: Vector2, game: Game) -> void:
	var cx := size.x * 0.5
	_text_c("MACHINE MASTERED", Vector2(cx, size.y * 0.36), 56, GREEN)
	_text_c("All %d puzzles solved." % Puzzles.count(), Vector2(cx, size.y * 0.36 + 70.0), 30, INK)
	_star(Vector2(cx - 80.0, size.y * 0.5), 22.0, true)
	_text_l("%d / %d" % [game.total_stars(), Puzzles.count() * 3], Vector2(cx - 50.0, size.y * 0.5 + 14.0), 44, GOLD)
	_text_c("Missing stars? Beat the pars for cycles and size.", Vector2(cx, size.y * 0.6), 24, DIM)
	_text_c("Tap or press Space to continue", Vector2(cx, size.y * 0.75), 30, GREEN)


func _manual(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.8))
	var w := minf(size.x - 40.0, 680.0)
	var r := Rect2((size.x - w) * 0.5, 40.0, w, minf(size.y - 80.0, 1080.0))
	_panel(r, PANEL, GREEN)
	_text_c("MANUAL", Vector2(r.get_center().x, r.position.y + 50.0), 40, GREEN)
	var rows := [
		["IN", "ACC <- next input"], ["OUT", "write ACC to the output"], ["NEG", "ACC <- -ACC"],
		["LDA s", "ACC <- s"], ["STA r", "r <- ACC"], ["SWP r", "swap ACC and r"],
		["ADD s", "ACC <- ACC + s"], ["SUB s", "ACC <- ACC - s"], ["JMP L", "jump to LBL L"],
		["JEZ L", "jump if ACC = 0"], ["JNZ L", "jump if ACC != 0"], ["JGZ L", "jump if ACC > 0"],
		["JLZ L", "jump if ACC < 0"], ["LBL L", "label (free: 0 cycles, 0 size)"]]
	var y := r.position.y + 110.0
	for row: Array in rows:
		_text_l(row[0], Vector2(r.position.x + 40.0, y), 26, _op_color(row[0]))
		_text_l(row[1], Vector2(r.position.x + 200.0, y), 24, INK)
		y += 46.0
	var notes := "s = X, Y or a number -99..99.  r = X or Y.  L = A-F.\nThe last line wraps around to the first. Running out of input fails. A run passes the moment the output is complete. Cycles = average over 3 tests."
	draw_multiline_string(font, Vector2(r.position.x + 40.0, y + 10.0), notes, HORIZONTAL_ALIGNMENT_LEFT, w - 80.0, 22, 6, DIM)
	_text_c("Tap anywhere to close", Vector2(r.get_center().x, r.end.y - 30.0), 22, GREEN)


# --- Primitives --------------------------------------------------------------------
func _op_color(line: String) -> Color:
	var op := line.split(" ", false)[0] if line != "" else ""
	if op in ["IN", "OUT"]:
		return GREEN
	if op == "LBL":
		return CYAN
	if op.begins_with("J"):
		return GOLD
	return INK


func _button(b: Dictionary) -> void:
	var r: Rect2 = b.rect
	var style: String = b.get("style", "ctl")
	var en: bool = b.enabled
	var bg := PANEL
	var fg := INK
	match style:
		"op":
			fg = _op_color(str(b.label))
		"op_sel":
			bg = GOLD
			fg = DARK
		"arg":
			bg = PANEL_HI
		"num":
			bg = DARK
			fg = GOLD
		"go":
			bg = GREEN
			fg = DARK
	if not en and style != "num":
		bg = bg.darkened(0.4)
		fg = Color(fg, 0.35)
	_panel(r, bg, Color(INK, 0.08) if style != "go" else Color.TRANSPARENT)
	var label: String = b.label
	var fs := 24 if label.length() <= 4 else 20
	_text_c(label, r.get_center(), fs, fg)


func _star(c: Vector2, rad: float, filled: bool) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var rr := rad if i % 2 == 0 else rad * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	if filled:
		draw_colored_polygon(pts, GOLD)
	else:
		pts.append(pts[0])
		draw_polyline(pts, Color(DIM, 0.8), 2.0)


func _panel(r: Rect2, color: Color, border: Color = Color.TRANSPARENT) -> void:
	var key := "%s|%s" % [color.to_html(), border.to_html()]
	var sb: StyleBoxFlat = _boxes.get(key)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = color
		sb.set_corner_radius_all(8)
		if border.a > 0.0:
			sb.border_color = border
			sb.set_border_width_all(2)
		_boxes[key] = sb
	draw_style_box(sb, r)


func _text_l(s: String, pos: Vector2, fs: int, c: Color) -> void:
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)


func _text_r(s: String, pos: Vector2, fs: int, c: Color) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, pos - Vector2(w, 0.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)


func _text_c(s: String, pos: Vector2, fs: int, c: Color) -> void:
	var sz := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(font, pos + Vector2(-sz.x * 0.5, fs * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
