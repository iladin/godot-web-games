extends Node2D
## Crossfire drawing: hex board, telegraphed attacks, units, effects, HUD.
## Reads state from main.gd (m) and its tactics model; owns no game state.

const T := preload("res://scripts/tactics.gd")

# --- Palette (dusk dungeon) -----------------------------------------------------
const BG := Color("12101a")
const FLOOR := Color("221f31")
const FLOOR_EDGE := Color("302b45")
const WALL := Color("4a4560")
const WALL_TOP := Color("67608a")
const PIT := Color("040308")
const GOLD := Color("ffcf5a")     # stairs, score, shove
const CYAN := Color("5ee6ff")     # you
const RED := Color("ff4d6d")      # danger, melee
const ORANGE := Color("ff9a3c")   # bombs
const MAGENTA := Color("d35cff")  # archers
const GREEN := Color("7dffb0")    # where you can move
const INK := Color("ece8ff")
const DIM := Color("8a84a3")
const DARK := Color("0b0a10")
const RESTART_DELAY := 0.8

var m: Node2D  # main.gd
var font: Font = ThemeDB.fallback_font
var _boxes: Dictionary = {}


func _draw() -> void:
	var game: T = m.game
	var L: Dictionary = m.layout()
	var size: Vector2 = L.size
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	var s: float = m.shake
	draw_set_transform(Vector2(randf_range(-s, s), randf_range(-s, s)))
	if game.phase == T.Phase.TITLE:
		_title(size, L)
	else:
		_header(L, game)
		_board(L, game)
		_effects(L)
		_panel(L, game)
		if game.phase == T.Phase.GAME_OVER or game.phase == T.Phase.WIN:
			_end_screen(size, game)
	for p: Dictionary in m.particles:
		draw_circle(p.pos, 4.0 * clampf(p.t * 2.0, 0.2, 1.0), p.color)
	for f: Dictionary in m.floaters:
		_text_c(f.text, f.pos, 34, Color(f.color, clampf(f.t, 0.0, 1.0)))
	draw_set_transform(Vector2.ZERO)
	if m.screen_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(m.screen_flash_color, m.screen_flash * 0.45))
	if m.paused:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.65))
		_text_c("PAUSED - tap to resume", size * 0.5, 36, INK)


# --- Screens -----------------------------------------------------------------------
func _title(size: Vector2, L: Dictionary) -> void:
	var cx := size.x * 0.5
	var t: float = m.state_time
	var y := size.y * 0.17
	_text_c("CROSSFIRE", Vector2(cx, y), 104, RED.lerp(ORANGE, 0.5 + 0.5 * sin(t * 2.0)))
	_text_c("You have no weapon.", Vector2(cx, y + 74.0), 34, INK)
	var lines := [
		[RED, "Every enemy shows exactly where it will strike next."],
		[GOLD, "Each turn: one move and one shove, in any order."],
		[ORANGE, "Shove them into pits, walls, each other - and into each other's attacks."],
		[CYAN, "Reach the stairs. Ten floors down is the way out."]]
	var w := minf(size.x - 80.0, 700.0)
	var ly := y + 150.0
	for row: Array in lines:
		draw_circle(Vector2(cx - w * 0.5 + 10.0, ly - 8.0), 9.0, row[0])
		draw_multiline_string(font, Vector2(cx - w * 0.5 + 34.0, ly), row[1], HORIZONTAL_ALIGNMENT_LEFT, w - 34.0, 26, 2, Color(INK, 0.9))
		ly += 78.0
	var iy := ly + 30.0
	var kinds := ["brute", "knight", "archer", "bomber"]
	var names := ["Brute: smashes next to it", "Knight: brute with 2 HP", "Archer: shoots along lines", "Bomber: lobs a blast that pushes"]
	var hs: float = 40.0
	for i in 4:
		var p := Vector2(cx - w * 0.5 + 30.0, iy + i * 62.0)
		_unit(p, hs, kinds[i], 0, 1.0, 2 if kinds[i] == "knight" else 1)
		_text_l(names[i], p + Vector2(46.0, 9.0), 24, DIM)
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	_text_c("Tap or press Space to start", Vector2(cx, size.y * 0.86), 36, GOLD.lerp(INK, pulse))
	_text_c("AI players: press / for a command line (try /help, /map)", Vector2(cx, size.y * 0.86 + 50.0), 22, DIM)
	if int(m.best) > 0:
		_text_c("Best %d" % m.best, Vector2(cx, size.y * 0.86 + 90.0), 24, DIM)


func _header(L: Dictionary, game: T) -> void:
	var r: Rect2 = L.header
	_text_l("FLOOR %d / %d" % [game.floor_no, T.FLOORS], r.position + Vector2(8.0, 46.0), 32, INK)
	var hp: int = game.player().hp if not game.units.is_empty() else 0
	var hx := r.get_center().x - 50.0
	for i in T.PLAYER_HP:
		_heart(Vector2(hx + i * 44.0, r.position.y + 34.0), 15.0, i < hp)
	_text_r("SCORE %d" % game.score, Vector2(r.end.x - 8.0, r.position.y + 46.0), 32, GOLD)


func _board(L: Dictionary, game: T) -> void:
	var hs: float = L.hex
	for h: Vector2i in game.tiles:
		_tile(m.hex_px(L, h), hs, str(game.tiles[h]), h)
	var pv: Dictionary = game.preview()
	_threats(L, game, pv)
	if game.phase == T.Phase.PLAYER:
		_hints(L, game)
	var dying := {}
	for id in pv.deaths:
		dying[id] = true
	for g: Dictionary in m.ghosts:
		_unit(g.pos, hs, g.kind, -1, 0.6 + 0.4 * sin(float(m.state_time) * 30.0), 1)
	for i in game.units.size():
		var u: Dictionary = game.units[i]
		if not u.alive:
			continue
		var p: Vector2 = m.draw_pos.get(u.id, m.hex_px(L, u.pos))
		_unit(p, hs, u.kind, i, 1.0, u.hp)
		if float(m.flash.get(u.id, 0.0)) > 0.0:
			draw_circle(p, hs * 0.55, Color(1, 1, 1, 0.7))
		if dying.has(u.id):
			var a := 0.6 + 0.4 * sin(float(m.state_time) * 8.0)
			draw_line(p + Vector2(-0.35, -0.35) * hs, p + Vector2(0.35, 0.35) * hs, Color(INK, a), 4.0)
			draw_line(p + Vector2(0.35, -0.35) * hs, p + Vector2(-0.35, 0.35) * hs, Color(INK, a), 4.0)
	if pv.player_damage > 0 and game.phase == T.Phase.PLAYER:
		var pp: Vector2 = m.draw_pos.get(0, m.hex_px(L, game.player().pos))
		var a := 0.5 + 0.5 * sin(float(m.state_time) * 8.0)
		draw_arc(pp, hs * 0.72, 0.0, TAU, 32, Color(RED, a), 4.0)


func _threats(L: Dictionary, game: T, pv: Dictionary) -> void:
	var hs: float = L.hex
	for ev: Dictionary in pv.log:
		match str(ev.type):
			"smash":
				var from: Vector2 = m.hex_px(L, ev.from)
				var to: Vector2 = m.hex_px(L, ev.at)
				_hex_fill(to, hs * 0.92, Color(RED, 0.28))
				_hex_line(to, hs * 0.92, RED, 3.0)
				_arrow(from.lerp(to, 0.35), from.lerp(to, 0.8), RED, 5.0)
			"shot":
				var from: Vector2 = m.hex_px(L, ev.from)
				var to: Vector2 = m.hex_px(L, ev.to)
				if ev.to != ev.from:
					draw_dashed_line(from, to, Color(MAGENTA, 0.9), 3.0, 12.0)
					_hex_line(to, hs * 0.8, MAGENTA, 3.0)
					_arrow(to.lerp(from, 0.25 * hs / maxf(1.0, from.distance_to(to)) * 2.0), to, MAGENTA, 4.0)
			"bomb":
				var at: Vector2 = m.hex_px(L, ev.at)
				_hex_fill(at, hs * 0.92, Color(ORANGE, 0.35))
				_hex_line(at, hs * 0.92, ORANGE, 3.0)
				for d in 6:
					var n: Vector2 = m.hex_px(L, (ev.at as Vector2i) + T.DIRS[d])
					_arrow(at.lerp(n, 0.55), at.lerp(n, 0.85), Color(ORANGE, 0.8), 3.0)
	for i in range(1, game.units.size()):
		var u: Dictionary = game.units[i]
		if u.alive and u.kind == "bomber" and not (u.intent as Dictionary).is_empty():
			draw_dashed_line(m.hex_px(L, u.pos), m.hex_px(L, u.intent.target), Color(ORANGE, 0.5), 2.0, 8.0)


func _hints(L: Dictionary, game: T) -> void:
	var hs: float = L.hex
	var pp: Vector2i = game.player().pos
	for d in 6:
		var h: Vector2i = pp + T.DIRS[d]
		if not game.tiles.has(h):
			continue
		var c: Vector2 = m.hex_px(L, h)
		var j := game.unit_at(h)
		if j > 0 and game.shove_left:
			var dest: Vector2i = h + T.DIRS[d]
			var dc: Vector2 = m.hex_px(L, dest)
			var t: String = game.tiles.get(dest, "")
			var col := GOLD if m.shove_mode else Color(GOLD, 0.6)
			_arrow(c.lerp(dc, 0.25), c.lerp(dc, 0.75), col, 4.0)
			if t == "pit":
				_text_c("FALL", dc + Vector2(0, -hs * 0.45), 16, GOLD)
			elif t == "" or t == "wall" or game.unit_at(dest) >= 0:
				_text_c("SLAM", c.lerp(dc, 0.5) + Vector2(0, -hs * 0.35), 16, GOLD)
		elif j < 0 and game.move_left and game.passable(h) and not m.shove_mode:
			draw_circle(c, hs * 0.14, Color(GREEN, 0.75))
		_text_c(T.DIR_NAMES[d], c + Vector2(0.0, hs * 0.55), 15, Color(INK, 0.45))


func _effects(L: Dictionary) -> void:
	var hs: float = L.hex
	for f: Dictionary in m.fx:
		if f.delay > 0.0:
			continue
		match str(f.type):
			"shot":
				var a := clampf(f.t / 0.35, 0.0, 1.0)
				draw_line(f.from, f.to, Color(MAGENTA.lightened(0.4), a), 6.0 * a + 1.0)
			"ring":
				var k := 1.0 - clampf(f.t / 0.45, 0.0, 1.0)
				draw_arc(f.at, hs * float(f.size) * (0.4 + k), 0.0, TAU, 36, Color(f.color, 1.0 - k), 5.0)


func _panel(L: Dictionary, game: T) -> void:
	var r: Rect2 = L.panel
	m.build_buttons(L)
	for b: Dictionary in m.buttons:
		var br: Rect2 = b.rect
		if b.id == "end":
			_box(br, GOLD)
			_text_c(b.label, br.get_center(), 32, DARK)
		else:
			_box(br, FLOOR_EDGE if not m.shove_mode else GOLD.darkened(0.5))
			_text_c(b.label, br.get_center(), 22, INK)
	if game.phase == T.Phase.PLAYER:
		var tx := r.position.x + 206.0
		var ty := r.position.y + 24.0
		_pill(Rect2(tx, ty, 100.0, 26.0), "MOVE", GREEN if game.move_left else DIM.darkened(0.4))
		_pill(Rect2(tx, ty + 34.0, 100.0, 26.0), "SHOVE", GOLD if game.shove_left else DIM.darkened(0.4))
	if game.phase != T.Phase.PLAYER:
		return
	var pv: Dictionary = game.preview()
	var y := r.position.y + 136.0
	_text_l("IF YOU END THE TURN NOW", Vector2(r.position.x + 4.0, y), 20, DIM)
	var dmg: int = pv.player_damage
	_text_l("you take %d" % dmg, Vector2(r.position.x + 4.0, y + 36.0), 30, RED if dmg > 0 else GREEN)
	var deaths: int = pv.deaths.size()
	_text_r("%d enem%s die" % [deaths, "y" if deaths == 1 else "ies"], Vector2(r.end.x - 4.0, y + 36.0), 30, GOLD if deaths > 0 else DIM)
	var ly := y + 80.0
	for i in range(1, game.units.size()):
		var u: Dictionary = game.units[i]
		if not u.alive or ly > r.end.y - 60.0:
			continue
		_unit(Vector2(r.position.x + 22.0, ly - 8.0), 26.0, u.kind, -1, 1.0, u.hp)
		_text_l("#%d %s" % [i, str(u.kind).to_upper()], Vector2(r.position.x + 50.0, ly), 22, INK)
		_text_l(game.describe_intent(u), Vector2(r.position.x + 230.0, ly), 22, _intent_color(u))
		ly += 34.0
	_text_c("tap a neighbour: move  -  tap an adjacent enemy: shove", Vector2(r.get_center().x, r.end.y - 34.0), 18, DIM)
	_text_c("keys W E A D Z X  (Shift = shove)  -  Space ends turn  -  / commands", Vector2(r.get_center().x, r.end.y - 8.0), 18, DIM)


func _end_screen(size: Vector2, game: T) -> void:
	var won := game.phase == T.Phase.WIN
	var w := minf(size.x - 40.0, 620.0)
	var r := Rect2((size.x - w) * 0.5, size.y * 0.5 - 220.0, w, 420.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
	_box(r, FLOOR, GOLD if won else RED)
	var cx := r.get_center().x
	_text_c("ESCAPED!" if won else "FALLEN", Vector2(cx, r.position.y + 70.0), 64, GOLD if won else RED)
	_text_c(game.end_reason, Vector2(cx, r.position.y + 130.0), 26, INK)
	_text_c("Score %d" % game.score, Vector2(cx, r.position.y + 210.0), 48, INK)
	_text_c("%d enemies turned on each other" % game.kills, Vector2(cx, r.position.y + 256.0), 22, DIM)
	_text_c("NEW BEST!" if m.new_best else "Best %d" % m.best, Vector2(cx, r.position.y + 300.0), 30, CYAN)
	if float(m.state_time) > RESTART_DELAY:
		_text_c("Tap or press Space to try again", Vector2(cx, r.end.y - 40.0), 26, GOLD)


# --- Pieces ------------------------------------------------------------------------
func _tile(c: Vector2, hs: float, kind: String, h: Vector2i) -> void:
	match kind:
		"wall":
			_hex_fill(c + Vector2(0, 4), hs * 0.97, WALL.darkened(0.4))
			_hex_fill(c, hs * 0.93, WALL)
			_hex_fill(c - Vector2(0, 3), hs * 0.7, WALL_TOP)
		"pit":
			_hex_fill(c, hs * 0.97, FLOOR_EDGE)
			_hex_fill(c, hs * 0.8, PIT)
			draw_arc(c, hs * 0.45, 0.0, TAU, 24, Color(MAGENTA, 0.12), 3.0)
		"exit":
			_hex_fill(c, hs * 0.97, GOLD.darkened(0.35))
			for k in 4:
				var y := c.y - hs * 0.42 + k * hs * 0.24
				var half := hs * (0.42 - k * 0.08)
				draw_line(Vector2(c.x - half, y), Vector2(c.x + half, y), GOLD, 4.0)
		_:
			var shade := 0.03 * float(posmod(h.x * 7 + h.y * 13, 3))
			_hex_fill(c, hs * 0.97, FLOOR.lightened(shade))
			_hex_line(c, hs * 0.97, FLOOR_EDGE, 1.5)


func _unit(p: Vector2, hs: float, kind: String, order: int, alpha: float, hp: int) -> void:
	var r := hs * 0.5
	match kind:
		"player":
			draw_circle(p, r * 1.05, Color(CYAN, alpha))
			draw_circle(p, r * 0.6, Color(DARK, alpha))
			draw_circle(p, r * 0.35, Color(CYAN.lightened(0.5), alpha))
		"brute", "knight":
			var pts := PackedVector2Array([p + Vector2(0, -r * 1.1), p + Vector2(r * 1.1, 0), p + Vector2(0, r * 1.1), p + Vector2(-r * 1.1, 0)])
			draw_colored_polygon(pts, Color(RED, alpha))
			if kind == "knight":
				pts.append(pts[0])
				draw_polyline(pts, Color(INK, alpha), 3.0)
			draw_circle(p, r * 0.3, Color(DARK, alpha))
		"archer":
			var pts := PackedVector2Array([p + Vector2(0, -r * 1.1), p + Vector2(r, r * 0.8), p + Vector2(-r, r * 0.8)])
			draw_colored_polygon(pts, Color(MAGENTA, alpha))
			draw_circle(p + Vector2(0, r * 0.15), r * 0.25, Color(DARK, alpha))
		"bomber":
			draw_circle(p, r * 0.9, Color(ORANGE, alpha))
			draw_line(p + Vector2(r * 0.5, -r * 0.6), p + Vector2(r * 0.9, -r * 1.1), Color(INK, alpha), 3.0)
			draw_circle(p + Vector2(r * 0.95, -r * 1.15), 4.0, Color(GOLD, alpha))
	if kind == "knight" and hp >= 2:
		draw_circle(p + Vector2(-6, r * 1.35), 4.0, Color(INK, alpha))
		draw_circle(p + Vector2(6, r * 1.35), 4.0, Color(INK, alpha))
	if order > 0:
		var b := p + Vector2(r * 0.95, -r * 0.95)
		draw_circle(b, 11.0, Color(DARK, 0.9))
		_text_c(str(order), b, 16, INK)


func _intent_color(u: Dictionary) -> Color:
	var it: Dictionary = u.intent
	if it.is_empty():
		return DIM
	match str(it.kind):
		"smash":
			return RED
		"shot":
			return MAGENTA
		"bomb":
			return ORANGE
	return DIM


func _hex_points(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := deg_to_rad(60.0 * i - 30.0)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


func _hex_fill(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(_hex_points(c, r), col)


func _hex_line(c: Vector2, r: float, col: Color, w: float) -> void:
	var pts := _hex_points(c, r)
	pts.append(pts[0])
	draw_polyline(pts, col, w)


func _arrow(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	draw_line(a, b, col, w)
	var dir := (b - a).normalized()
	var side := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([b + dir * 8.0, b - dir * 6.0 + side * 8.0, b - dir * 6.0 - side * 8.0]), col)


func _heart(c: Vector2, r: float, full: bool) -> void:
	var col := RED if full else Color(DIM, 0.35)
	draw_circle(c + Vector2(-r * 0.5, -r * 0.2), r * 0.55, col)
	draw_circle(c + Vector2(r * 0.5, -r * 0.2), r * 0.55, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.02, 0.0), c + Vector2(r * 1.02, 0.0), c + Vector2(0, r * 1.05)]), col)


func _pill(r: Rect2, label: String, col: Color) -> void:
	_box(r, col)
	_text_c(label, r.get_center(), 16, DARK)


func _box(r: Rect2, color: Color, border: Color = Color.TRANSPARENT) -> void:
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


func _text_c(s: String, pos: Vector2, fs: int, c: Color) -> void:
	var sz := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(font, pos + Vector2(-sz.x * 0.5, fs * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
