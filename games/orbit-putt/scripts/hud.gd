class_name Hud
extends RefCounted
## Static HUD / screen text helpers. All coordinates are in 720x1280 world space.


static func text(ci: CanvasItem, s: String, y: float, fs: int, col: Color, x: float = 0.0,
		w: float = 720.0, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> void:
	ci.draw_string(ThemeDB.fallback_font, Vector2(x, y), s, align, w, fs, col)


## Text centred at `c`, scaled about its centre (pop-in / pulse effects).
static func pop(ci: CanvasItem, s: String, c: Vector2, fs: int, col: Color, k: float) -> void:
	ci.draw_set_transform(c, 0.0, Vector2(k, k))
	ci.draw_string(ThemeDB.fallback_font, Vector2(-360, 0), s, HORIZONTAL_ALIGNMENT_CENTER, 720.0, fs, col)
	ci.draw_set_transform(Vector2.ZERO)


static func rel(n: int) -> String:
	if n == 0:
		return "E"
	return "+%d" % n if n > 0 else "-%d" % -n


static func title(ci: CanvasItem, best_rel: int, time: float) -> void:
	var c := Vector2(360, 640)
	ci.draw_circle(c, 80.0, WorldDraw.PLANET.darkened(0.4))
	ci.draw_circle(c + Vector2(-14, -14), 66.0, WorldDraw.PLANET)
	for i in 2:
		var ph := fposmod(time * 0.3 + i * 0.5, 1.0)
		ci.draw_arc(c, lerpf(80.0, 240.0, ph), 0.0, TAU, 64, Color(1, 0.54, 0.36, (1.0 - ph) * 0.35), 2.0)
	var bp := c + Vector2.from_angle(time * 1.4) * 150.0
	WorldDraw.trail(ci, PackedVector2Array([c + Vector2.from_angle(time * 1.4 - 0.45) * 150.0,
		c + Vector2.from_angle(time * 1.4 - 0.3) * 150.0, c + Vector2.from_angle(time * 1.4 - 0.15) * 150.0]), 0.5)
	WorldDraw.ball(ci, bp)
	text(ci, "ORBIT PUTT", 330, 84, WorldDraw.ACCENT)
	text(ci, "Bend your shot around the planets", 400, 30, Color.WHITE)
	text(ci, "Best: " + ("-" if best_rel == 99 else rel(best_rel)), 460, 32, WorldDraw.BALL)
	text(ci, "Tap or press Space", 940, 40, WorldDraw.PLANET.lerp(Color.WHITE, 0.5 + 0.5 * sin(time * 4.0)))
	text(ci, "Drag back & release  |  Arrows + Space", 1010, 28, Color(1, 1, 1, 0.7))


static func play(ci: CanvasItem, hole_i: int, par: int, strokes: int, total_rel: int, power: float,
		pop_k: float, show_hint: bool) -> void:
	var acc := WorldDraw.ACCENT
	text(ci, "HOLE %d/9" % (hole_i + 1), 52, 30, Color.WHITE, 24.0, 300.0, HORIZONTAL_ALIGNMENT_LEFT)
	text(ci, "PAR %d" % par, 52, 30, acc)
	pop(ci, "STROKES %d" % strokes, Vector2(560, 52), 30, Color.WHITE, 1.0 + 0.3 * pop_k)
	text(ci, "TOTAL " + rel(total_rel), 92, 28, WorldDraw.BALL)
	var bar := Rect2(160, 1222, 400, 14)
	ci.draw_rect(bar, Color(1, 1, 1, 0.15))
	ci.draw_rect(Rect2(bar.position, Vector2(bar.size.x * power, bar.size.y)), acc)
	text(ci, "POWER %d%%" % int(power * 100.0), 1212, 28, Color.WHITE)
	if show_hint:
		text(ci, "Drag back & release to shoot", 1150, 30, Color(1, 1, 1, 0.8))


static func banner(ci: CanvasItem, word: String, sub: String, k: float) -> void:
	ci.draw_rect(Rect2(0, 470, 720, 220), Color(0.04, 0.06, 0.15, 0.82))
	pop(ci, word, Vector2(360, 590), 84, WorldDraw.ACCENT, k)
	text(ci, sub, 650, 32, Color.WHITE)


static func results(ci: CanvasItem, scores: Array, pars: Array, total: int, new_best: bool,
		best_rel: int, delay_ok: bool, time: float) -> void:
	text(ci, "COURSE COMPLETE", 170, 62, WorldDraw.ACCENT)
	text(ci, "Total " + rel(total), 250, 52, Color.WHITE)
	text(ci, "NEW BEST!" if new_best else "Best " + rel(best_rel), 305, 34, WorldDraw.PLANET if new_best else WorldDraw.BALL)
	for i in scores.size():
		var d: int = int(scores[i]) - int(pars[i])
		var y := 390.0 + i * 52.0
		text(ci, "Hole %d" % (i + 1), y, 30, Color(1, 1, 1, 0.8), 150.0, 200.0, HORIZONTAL_ALIGNMENT_LEFT)
		text(ci, "Par %d" % int(pars[i]), y, 30, Color(1, 1, 1, 0.8), 300.0, 120.0, HORIZONTAL_ALIGNMENT_LEFT)
		text(ci, "%d  (%s)" % [int(scores[i]), rel(d)], y, 30, WorldDraw.ACCENT if d <= 0 else WorldDraw.PLANET, 440.0, 200.0, HORIZONTAL_ALIGNMENT_LEFT)
	if delay_ok:
		text(ci, "Tap or press Space to play again", 950, 34, Color.WHITE.lerp(WorldDraw.ACCENT, 0.5 + 0.5 * sin(time * 4.0)))
