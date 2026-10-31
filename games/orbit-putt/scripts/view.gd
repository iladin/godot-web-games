class_name GameView
extends RefCounted
## All _draw() rendering for main.gd. `g` is the main Node2D (reads its state, never mutates it).


static func draw(g: Node2D) -> void:
	var view: Vector2 = g.get_viewport_rect().size
	var origin: Vector2 = -g.position
	g.draw_rect(Rect2(origin - Vector2(20, 20), view + Vector2(40, 40)), WorldDraw.BG)
	var shake := Vector2.ZERO
	if g.shake_t > 0.0:
		shake = Vector2.from_angle(randf() * TAU) * g.SHAKE_PX * g.shake_t / g.SHAKE_DECAY
	g.draw_set_transform(shake)
	WorldDraw.stars(g, g.star_list)
	if g.state == g.State.TITLE:
		g.draw_set_transform(Vector2.ZERO)
		Hud.title(g, g.best_rel, g.anim_t)
	else:
		if g.state != g.State.GAME_OVER:
			_world(g)
		g.draw_set_transform(Vector2.ZERO)
		if g.flash > 0.0:
			g.draw_rect(Rect2(origin, view), Color(1, 0.15, 0.15, g.flash))
		if g.state == g.State.GAME_OVER:
			Hud.results(g, g.scores, g.pars, g.total_rel, g.new_best, g.best_rel, g.state_time > g.RESTART_DELAY, g.anim_t)
		else:
			Hud.play(g, g.hole_idx, g.par, g.strokes, g.total_rel, g.aim.power, g.stroke_pop, g.hole_idx == 0 and g.strokes == 0)
		if g.state == g.State.HOLE_DONE:
			var k: float = lerpf(1.0, 1.6, pow(1.0 - clampf(g.state_time / 0.3, 0.0, 1.0), 2.0))
			Hud.banner(g, g.banner_word, g.banner_sub, k)
	if g.paused:
		g.draw_rect(Rect2(origin, view), Color(0, 0, 0, 0.6))
		Hud.text(g, "PAUSED - tap to resume", 640, 40, Color.WHITE)


static func _world(g: Node2D) -> void:
	for b in g.bodies:
		WorldDraw.body(g, b, g.t, g.anim_t)
	WorldDraw.cup(g, g.cup, g.cup_r)
	WorldDraw.trail(g, g.trail, g.tint)
	if g.phase == g.Phase.SINK:
		var k: float = clampf(g.sink_t / g.SINK_TIME, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 3.0)
		var rad := lerpf(OrbitPhysics.BALL_RADIUS * 1.5, 0.0, e)
		WorldDraw.ball(g, g.cup + Vector2.from_angle(g.sink_ang + e * TAU * 1.5) * rad, 1.0 - 0.7 * e)
	else:
		WorldDraw.ball(g, g.ball_pos)
	if g.state == g.State.PLAYING and g.phase == g.Phase.AIM:
		_aim(g)
	g.fx.draw(g)


static func _aim(g: Node2D) -> void:
	var dir := Vector2.from_angle(g.aim.angle)
	var acc := WorldDraw.ACCENT
	var pulse: float = 0.6 + 0.4 * sin(g.anim_t * 8.0 * (0.5 + g.aim.power))
	g.draw_line(g.ball_pos, g.ball_pos + dir * (30.0 + 90.0 * g.aim.power), Color(acc, pulse), 3.0)
	g.draw_line(g.ball_pos, g.ball_pos - dir * 70.0 * g.aim.power, Color(1, 1, 1, 0.3), 5.0)
	var n: int = g.preview.size()
	for i in range(0, n, 3):
		g.draw_circle(g.preview[i], 3.5, Color(acc, 1.0 - 0.7 * i / maxf(n, 1.0)))
