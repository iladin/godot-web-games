extends Node2D
## Falsify drawing. Reads everything from main.gd (m) and its lab; owns no game state.

const Lab := preload("res://scripts/lab.gd")

# --- Palette (lab notebook at night) -------------------------------------------
const BG := Color("0e1320")
const GRID := Color(1, 1, 1, 0.035)
const PANEL := Color("182136")
const PANEL_HI := Color("26365e")
const ACCENT := Color("4fd1c5")   # fits / alive
const NO := Color("ff6b81")       # does not fit / ruled out
const GOLD := Color("ffd166")     # funding, selection, score
const INK := Color("e6edf7")
const DIM := Color("7482a0")
const DARK := Color("0b0f19")
const RESTART_DELAY := 0.6

var m: Node2D  # main.gd
var font: Font = ThemeDB.fallback_font
var _boxes: Dictionary = {}


func _draw() -> void:
	var lab: Lab = m.lab
	var L: Dictionary = m.layout()
	var size: Vector2 = L.size
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	for x in range(0, int(size.x), 48):
		draw_line(Vector2(x, 0), Vector2(x, size.y), GRID, 1.0)
	for y in range(0, int(size.y), 48):
		draw_line(Vector2(0, y), Vector2(size.x, y), GRID, 1.0)
	var s: float = m.shake
	draw_set_transform(Vector2(randf_range(-s, s), randf_range(-s, s)))
	if lab.phase == Lab.Phase.TITLE:
		_title(size)
	else:
		m.build_buttons(L)
		_header(L, lab)
		_candidates(L, lab)
		_notebook(L, lab)
		_input_panel(L, lab)
		if lab.phase == Lab.Phase.ROUND_DONE:
			_round_done(size, lab)
		elif lab.phase == Lab.Phase.GAME_OVER or lab.phase == Lab.Phase.WIN:
			_end_screen(size, lab)
	for p: Dictionary in m.particles:
		draw_circle(p.pos, 5.0 * clampf(p.t * 2.0, 0.2, 1.0), p.color)
	for f: Dictionary in m.floaters:
		_text_c(f.text, f.pos, 40, Color(f.color, clampf(f.t, 0.0, 1.0)))
	draw_set_transform(Vector2.ZERO)
	if m.screen_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(m.screen_flash_color, m.screen_flash * 0.5))
	if m.paused:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.65))
		_text_c("PAUSED - tap to resume", size * 0.5, 36, INK)


# --- Screens -----------------------------------------------------------------------
func _title(size: Vector2) -> void:
	var w := minf(size.x - 60.0, 780.0)
	var x := (size.x - w) * 0.5
	var y := size.y * 0.16
	_text_c("FALSIFY", Vector2(size.x * 0.5, y), 112, ACCENT)
	_text_c("Find the hidden rule. Every experiment costs.", Vector2(size.x * 0.5, y + 70.0), 30, INK)
	var body := "A secret rule decides which triples of numbers (0-15) fit. You see one triple that fits and a list of suspect rules. Each test answers FITS or NO and crosses out every suspect that disagrees. Name the rule before the funding runs out.\n\nIn 1960 Peter Wason handed people 2-4-6 and asked for the rule. Most only tried triples they expected to fit, and learned nothing. The tests worth paying for are the ones that could prove you wrong."
	draw_multiline_string(font, Vector2(x, y + 140.0), body, HORIZONTAL_ALIGNMENT_LEFT, w, 26, -1, Color(INK, 0.85))
	var cy := size.y * 0.66
	_text_c("Tap numbers, then TEST.  Tap a suspect, then NAME IT.", Vector2(size.x * 0.5, cy), 24, DIM)
	_text_c("Keys: type 3 6 9 + Enter to test,  letter + Enter to name.", Vector2(size.x * 0.5, cy + 36.0), 24, DIM)
	_text_c("AI players: press / for a command line (try /help)", Vector2(size.x * 0.5, cy + 72.0), 24, DIM)
	var pulse := 0.5 + 0.5 * sin(float(m.state_time) * 4.0)
	_text_c("Tap or press Space to start", Vector2(size.x * 0.5, size.y * 0.82), 36, GOLD.lerp(INK, pulse))
	if int(m.best) > 0:
		_text_c("Best %d" % m.best, Vector2(size.x * 0.5, size.y * 0.82 + 52.0), 26, DIM)


func _header(L: Dictionary, lab: Lab) -> void:
	var r: Rect2 = L.header
	_panel(r, PANEL)
	_text_l("ROUND %d / %d" % [lab.round_no, Lab.ROUNDS], Vector2(r.position.x + 20.0, r.position.y + 40.0), 30, INK)
	_text_r("SCORE %d" % lab.score, Vector2(r.end.x - 20.0, r.position.y + 40.0), 30, GOLD)
	var y := r.position.y + 76.0
	_text_l("FUNDING", Vector2(r.position.x + 20.0, y), 22, DIM)
	var cx := r.position.x + 140.0
	for i in mini(maxi(lab.funding, 0), 16):
		draw_circle(Vector2(cx + i * 22.0, y - 8.0), 8.0, GOLD)
	var after := cx + mini(maxi(lab.funding, 0), 16) * 22.0 + 6.0
	_text_l(str(lab.funding), Vector2(after, y), 26, GOLD if lab.funding > 0 else NO)
	_text_r("PAR %d   LEFT %d" % [lab.par, lab.alive_count()], Vector2(r.end.x - 20.0, y), 24, DIM)


func _candidates(L: Dictionary, lab: Lab) -> void:
	for k in lab.candidates.size():
		var r: Rect2 = m.row_rect(L, k)
		var alive: bool = lab.alive[k]
		var sel: bool = m.selected == k
		var bg := PANEL_HI if sel else PANEL
		if not alive:
			bg = PANEL.darkened(0.35)
		bg = bg.lerp(NO, float(m.flash[k]) * 0.5)
		_panel(r, bg, GOLD if sel else Color.TRANSPARENT)
		var cy := r.get_center().y
		draw_circle(Vector2(r.position.x + 30.0, cy), minf(18.0, r.size.y * 0.38), ACCENT if alive else DIM)
		_text_c(Lab.LETTERS[k], Vector2(r.position.x + 30.0, cy), 24, DARK)
		var avail := r.size.x - 80.0 - (160.0 if sel else 0.0)
		var txt: String = lab.candidates[k].text
		var fs := 26
		while fs > 16 and font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > avail:
			fs -= 2
		_text_l(txt, Vector2(r.position.x + 60.0, cy + fs * 0.35), fs, INK if alive else DIM)
		var st: float = m.strike[k]
		if st > 0.0:
			var x0 := r.position.x + 54.0
			var tw := minf(font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 12.0, avail + 10.0)
			draw_line(Vector2(x0, cy), Vector2(x0 + tw * st, cy), NO, 3.0)
		if sel and alive:
			var b := Rect2(r.end.x - 150.0, r.position.y + 5.0, 140.0, r.size.y - 10.0)
			_panel(b, GOLD)
			_text_c("NAME IT", b.get_center(), 24, DARK)


func _notebook(L: Dictionary, lab: Lab) -> void:
	var r: Rect2 = L.notebook
	if r.size.y < 60.0:
		return
	_panel(r, PANEL.darkened(0.25))
	_text_l("LAB NOTEBOOK", Vector2(r.position.x + 16.0, r.position.y + 30.0), 22, DIM)
	_text_r("%d test%s" % [lab.tests.size(), "" if lab.tests.size() == 1 else "s"], Vector2(r.end.x - 16.0, r.position.y + 30.0), 22, DIM)
	var row_h := 40.0
	var max_rows := int((r.size.y - 48.0) / row_h)
	var rows: Array[Dictionary] = []
	for i in range(lab.tests.size() - 1, -1, -1):
		rows.append(lab.tests[i])
	rows.append({"triple": lab.seed_triple, "fits": true, "seed": true})
	var y := r.position.y + 44.0
	for i in mini(rows.size(), max_rows):
		var e: Dictionary = rows[i]
		if i == 0 and m.verdict_pop > 0.0 and not e.has("seed"):
			draw_rect(Rect2(r.position.x + 6.0, y, r.size.x - 12.0, row_h - 4.0), Color(INK, m.verdict_pop * 0.15))
		var pill := Rect2(r.position.x + 14.0, y + 5.0, 72.0, row_h - 14.0)
		_panel(pill, ACCENT if e.fits else NO)
		_text_c("FITS" if e.fits else "NO", pill.get_center(), 18, DARK)
		var t: Vector3i = e.triple
		_text_l("%2d  %2d  %2d" % [t.x, t.y, t.z], Vector2(r.position.x + 100.0, y + 28.0), 26, INK)
		var detail := ""
		var dcol := DIM
		if e.has("seed"):
			detail = "given - fits the rule"
		elif (e.ruled_out as Array).is_empty():
			detail = "nothing ruled out - 0 bits"
			dcol = NO.lerp(DIM, 0.4)
		else:
			detail = "ruled out %s  -  %.2f bit%s" % [lab._letters(e.ruled_out), e.bits, "" if is_equal_approx(e.bits, 1.0) else "s"]
		_text_l(detail, Vector2(r.position.x + 230.0, y + 27.0), 20, dcol)
		y += row_h
	if rows.size() > max_rows:
		_text_l("+%d earlier" % (rows.size() - max_rows), Vector2(r.position.x + 16.0, r.end.y - 10.0), 18, DIM)


func _input_panel(L: Dictionary, lab: Lab) -> void:
	var r: Rect2 = L.input
	for b: Dictionary in m.buttons:
		var id: String = b.id
		var br: Rect2 = b.rect
		if id.begins_with("slot:"):
			var i := int(id.substr(5))
			var active: bool = i == m.cur_slot
			var v: int = m.slots[i]
			var edge := ACCENT if active else Color(INK, 0.15)
			if active and m.pending and fmod(float(m.state_time), 0.8) < 0.4:
				edge = GOLD
			_panel(br, PANEL_HI if active else PANEL, edge)
			_text_c(str(v) if v >= 0 else "_", br.get_center(), 48, INK if v >= 0 else DIM)
		elif id.begins_with("key:") or id == "del" or id == "clr":
			_panel(br, PANEL)
			_text_c(str(b.label), br.get_center(), 30, INK)
		elif id == "test":
			_panel(br, ACCENT if b.enabled else PANEL.darkened(0.2))
			_text_c(str(b.label), br.get_center(), 30, DARK if b.enabled else DIM)
	if lab.funding < Lab.TEST_COST and lab.phase == Lab.Phase.TESTING:
		_text_c("Out of funding - name the rule!", Vector2(r.get_center().x, r.position.y + 104.0), 22, NO)


func _round_done(size: Vector2, lab: Lab) -> void:
	var w := minf(size.x - 40.0, 660.0)
	var r := Rect2((size.x - w) * 0.5, size.y * 0.5 - 230.0, w, 460.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
	_panel(r, PANEL, ACCENT)
	var cx := r.get_center().x
	_text_c("RULE FOUND", Vector2(cx, r.position.y + 60.0), 46, ACCENT)
	draw_multiline_string(font, Vector2(r.position.x + 30.0, r.position.y + 120.0), lab.candidates[lab.secret].text, HORIZONTAL_ALIGNMENT_CENTER, w - 60.0, 32, 3, INK)
	var t := lab.tests.size()
	var verdict := "under par!" if t < lab.par else ("on par" if t == lab.par else "%d over par" % (t - lab.par))
	_text_c("%d test%s - par %d - %s" % [t, "" if t == 1 else "s", lab.par, verdict], Vector2(cx, r.position.y + 240.0), 28, INK)
	_text_c("+%d points    +%d funding" % [lab.last_points, lab.last_reward], Vector2(cx, r.position.y + 285.0), 30, GOLD)
	var b := lab.best_first
	_text_c("Lab note: a best first test was  %d %d %d" % [b.x, b.y, b.z], Vector2(cx, r.position.y + 340.0), 22, DIM)
	var pulse := 0.5 + 0.5 * sin(float(m.state_time) * 4.0)
	_text_c("Tap or press Enter for round %d" % (lab.round_no + 1), Vector2(cx, r.end.y - 40.0), 26, GOLD.lerp(INK, pulse))


func _end_screen(size: Vector2, lab: Lab) -> void:
	var won := lab.phase == Lab.Phase.WIN
	var w := minf(size.x - 40.0, 660.0)
	var r := Rect2((size.x - w) * 0.5, size.y * 0.5 - 230.0, w, 460.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
	_panel(r, PANEL, GOLD if won else NO)
	var cx := r.get_center().x
	_text_c("TENURE GRANTED" if won else "DEFUNDED", Vector2(cx, r.position.y + 70.0), 52, GOLD if won else NO)
	draw_multiline_string(font, Vector2(r.position.x + 30.0, r.position.y + 130.0), lab.end_reason, HORIZONTAL_ALIGNMENT_CENTER, w - 60.0, 26, 3, INK)
	_text_c("Score %d" % lab.score, Vector2(cx, r.position.y + 260.0), 46, INK)
	_text_c("NEW BEST!" if m.new_best else "Best %d" % m.best, Vector2(cx, r.position.y + 310.0), 30, ACCENT)
	if float(m.state_time) > RESTART_DELAY:
		_text_c("Tap or press Space to play again", Vector2(cx, r.end.y - 50.0), 26, GOLD)


# --- Primitives --------------------------------------------------------------------
func _panel(r: Rect2, color: Color, border: Color = Color.TRANSPARENT) -> void:
	var key := "%s|%s" % [color.to_html(), border.to_html()]
	var sb: StyleBoxFlat = _boxes.get(key)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = color
		sb.set_corner_radius_all(10)
		if border.a > 0.0:
			sb.border_color = border
			sb.set_border_width_all(3)
		_boxes[key] = sb
	draw_style_box(sb, r)


func _text_l(s: String, pos: Vector2, fs: int, c: Color) -> void:
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)


func _text_r(s: String, pos: Vector2, fs: int, c: Color) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, pos - Vector2(w, 0.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)


## Centered on pos (both axes, approximately).
func _text_c(s: String, pos: Vector2, fs: int, c: Color) -> void:
	var sz := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(font, pos + Vector2(-sz.x * 0.5, fs * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
